import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/services/api_service.dart';
import '../core/services/device_info_service.dart';
import '../core/services/razorpay_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'order_success_screen.dart';

/// Parses a JSON value that's supposed to be an int but may have been sent
/// as a numeric string — mirrors `models/order.dart`'s `_asInt`, kept local
/// here since this is the only place in this file that needs it.
int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return num.tryParse(value.toString())?.round();
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Razorpay is the only payment method for now — Cash is temporarily
  // removed; re-add an entry here if it comes back.
  static const _paymentMethod = 'razorpay';

  final _apiService = ApiService();
  RazorpayService? _razorpay;
  bool _isPlacingOrder = false;
  String? _pendingOrderNumber;
  String? _pendingRazorpayOrderId;

  bool _isLoadingPlatformFee = true;
  String? _platformFeeError;

  /// The primary order's own numeric id, captured from the place-order
  /// response — needed to turn `AppState.extraServices` (bundled in before
  /// checkout on `BookingScreen`) into real sub-orders once payment
  /// succeeds. `null` if the response didn't carry a recognisable id, in
  /// which case bundled extras are silently skipped rather than crashing —
  /// see [_createBundledSubOrders].
  int? _pendingPrimaryOrderId;

  @override
  void initState() {
    super.initState();
    // Deferred to just after the first frame rather than called directly:
    // _fetchPlatformFee reads AppStateScope.of(context) for the booking
    // type, and dependOnInheritedWidgetOfExactType (what that lookup uses
    // under the hood) must not be called from initState itself — see its
    // own doc. Posting it guarantees the first build (and so
    // didChangeDependencies) has already run by the time it fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchPlatformFee();
    });
  }

  @override
  void dispose() {
    _razorpay?.dispose();
    super.dispose();
  }

  /// Fetches the platform fee from `GET /customer/platform-fee` so the
  /// summary shown here always matches what Razorpay will actually charge
  /// (replaces the old hardcoded ₹49). Sends `booking_type` so the fee
  /// matches the kind of booking being made — `"instant"` for an Instant
  /// order (see `BookingScreen.isInstantOrder`/`AppState.bookingType`),
  /// `"regular"` otherwise, matching `platform_fees.regular` /
  /// `platform_fees.instant` in the response. No `zone_id` is sent — this
  /// app has no zone concept yet, so the backend falls back to the
  /// `zone-id` header, then the customer's saved zone, then a default fee.
  /// The `zone_id` the response names is echoed back on
  /// `POST /customer/orders` so the order is created in the exact zone this
  /// fee was calculated for.
  ///
  /// Called post-first-frame (see [initState]), so reading
  /// `AppStateScope.of(context)` here is safe.
  Future<void> _fetchPlatformFee() async {
    final bookingType = AppStateScope.of(context).bookingType;
    setState(() {
      _isLoadingPlatformFee = true;
      _platformFeeError = null;
    });
    try {
      final response = await _apiService.get(
        '/customer/platform-fee',
        queryParameters: {'booking_type': bookingType.apiValue},
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final isSuccess =
          response.data is Map && response.data['is_success'] == true;
      if (isSuccess) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final fee = _asInt(data?['platform_fee']);
        if (fee != null) {
          AppStateScope.of(
            context,
          ).setPlatformFee(fee: fee, zoneId: _asInt(data?['zone_id']));
        } else {
          setState(() => _platformFeeError = l10n.somethingWentWrongTryAgain);
        }
      } else {
        final message = response.data is Map
            ? response.data['message'] as String?
            : null;
        setState(
          () => _platformFeeError = message ?? l10n.somethingWentWrongTryAgain,
        );
      }
    } catch (e) {
      debugPrint('Platform fee API error: $e');
      if (mounted) {
        setState(
          () => _platformFeeError = AppLocalizations.of(
            context,
          ).somethingWentWrongTryAgain,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPlatformFee = false);
    }
  }

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context);
    final state = AppStateScope.of(context);

    // The "Pay & Place Order" button is already disabled until the platform
    // fee has loaded (see build()) — this is a defensive backstop so the
    // charged amount can never diverge from what the summary showed, even
    // if this is somehow reached before that.
    if (state.platformFee == null) return;

    setState(() => _isPlacingOrder = true);
    var isSuccess = false;
    var isSlotConflict = false;
    String? errorMessage;
    String? orderNumber;
    String? razorpayOrderId;
    String? razorpayKey;
    // Best-effort — "lat,lng" for whichever address the customer actually
    // selected on the home screen (see `AppState.selectedAddress`), not
    // just wherever the device currently is. A selected saved address uses
    // its own stored coordinates (the exact pin saved for it) when it has
    // one, falling back to forward-geocoding its text only if it doesn't.
    // `null` selectedAddress means "Use current location" was picked (or
    // nothing was ever picked, same default), so this falls back to live
    // GPS either way.
    final coordinates =
        state.selectedAddress?.coordinates ??
        await DeviceInfoService.orderCoordinates(
          addressLine: state.selectedAddress?.line,
        );
    if (!mounted) return;
    try {
      // NOTE: no confirmed backend contract for order placement yet — this
      // request body is a best-effort guess built from what's already on
      // screen (service, add-ons, slot, payment method), following the same
      // snake_case field-naming convention as the rest of this API. Adjust
      // field names/endpoint once the real contract is known.
      final response = await _apiService.post(
        '/customer/orders',
        data: {
          'service_id': state.bookingServiceId,
          'provider_id': state.bookingProviderId,
          // "lat,lng" for the customer's selected delivery address — mirrors
          // the `customer_coordinates` field already returned on order
          // detail (see `OrderDetailInfo`), so this is what populates it.
          'customer_coordinates': ?coordinates,
          'addon_ids': state.addons
              .where((a) => a.id != null)
              .map((a) => a.id)
              .toList(),
          // Full per-add-on line-item breakdown (id, name, price and, when
          // known, quantity/unit/warranty), not just bare ids/a lump total.
          'addons': state.addons
              .map(
                (a) => {
                  'id': a.id,
                  'name': a.name,
                  'price': a.price,
                  if (a.source?.quantity != null)
                    'quantity': a.source!.quantity,
                  if (a.source?.unitLabel != null)
                    'unit_label': a.source!.unitLabel,
                  if (a.source?.warranty != null)
                    'warranty': a.source!.warranty,
                  if (a.source?.warrantyUnitLabel != null)
                    'warranty_unit_label': a.source!.warrantyUnitLabel,
                },
              )
              .toList(),
          'slot': state.slot,
          'booking_date': state.bookingDateApiValue,
          // Same value sent as booking_type on GET /customer/platform-fee —
          // keeps the fee charged and the order's own record of its type in
          // agreement.
          'booking_type': state.bookingType.apiValue,
          'payment_method': _paymentMethod,
          'amount': state.amount,
          'addons_total': state.addonsTotal,
          'platform_fee': state.platformFee,
          // Echoes the zone GET /customer/platform-fee calculated this fee
          // for, so the order is created in that same zone rather than
          // relying on the backend's own fallback picking a matching one a
          // second time.
          'zone_id': ?state.platformFeeZoneId,
          'payable_amount': state.payable,
          // Extra services bundled in on BookingScreen ("Add More
          // Services") before checkout — included so the amount the server
          // charges via Razorpay matches state.payable, which already folds
          // these in. NOTE: no confirmed contract for how the backend wants
          // these communicated on the initial place-order call; each one is
          // still turned into its own real sub-order after payment succeeds
          // (see _createBundledSubOrders), so this is sent as an informational
          // heads-up for pricing purposes, not as a request to create them
          // here too.
          'extra_services_total': state.extraServicesTotal,
        },
      );
      isSuccess = response.data['is_success'] == true;
      if (isSuccess) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final orderId = _asInt(data?['order_id']) ?? _asInt(data?['id']);
        orderNumber = data?['order_number'] as String? ?? orderId?.toString();
        // NOTE: field name for the Razorpay order id hasn't been confirmed
        // against a real response yet — trying the likely candidates.
        razorpayOrderId =
            data?['razorpay_order_id'] as String? ??
            data?['razorpay_id'] as String?;
        razorpayKey = data?['razorpay_key'] as String?;
        _pendingPrimaryOrderId = orderId;
      } else {
        errorMessage = response.data['message'] as String?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        isSlotConflict = true;
        errorMessage =
            e.response?.data?['message'] as String? ??
            l10n.slotAlreadyBookedError;
      } else {
        debugPrint('Place order API error: $e');
      }
    } catch (e) {
      debugPrint('Place order API error: $e');
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }

    if (!mounted) return;
    if (isSlotConflict) {
      // The chosen slot was taken by someone else in the meantime — send
      // the customer back to the slot picker rather than treating this as
      // a generic error; BookingScreen re-fetches booked-slots on return.
      showAppToast(context, errorMessage ?? l10n.slotAlreadyBookedError);
      Navigator.of(context).pop();
      return;
    }
    if (!isSuccess) {
      showAppToast(context, errorMessage ?? l10n.somethingWentWrongTryAgain);
      return;
    }

    // The order is already created server-side at this point — don't
    // re-call place-order on retry, just re-open checkout.
    if (razorpayOrderId == null || razorpayKey == null) {
      showAppToast(context, l10n.razorpayOrderMissing);
      return;
    }
    _pendingOrderNumber = orderNumber;
    _pendingRazorpayOrderId = razorpayOrderId;
    _openRazorpayCheckout(razorpayKey, razorpayOrderId, state.payable);
  }

  Future<void> _openRazorpayCheckout(
    String keyId,
    String razorpayOrderId,
    int payableAmount,
  ) async {
    final user = await CurrentUser.load();
    if (!mounted) return;

    _razorpay?.dispose();
    _razorpay = RazorpayService(
      onSuccess: _onRazorpaySuccess,
      onError: _onRazorpayError,
    );
    _razorpay!.open(
      keyId: keyId,
      razorpayOrderId: razorpayOrderId,
      amountInPaise: payableAmount * 100,
      name: user?.name,
      email: user?.email,
      contact: user?.phone,
    );
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    _confirmRazorpayStatus(
      status: 'success',
      paymentId: response.paymentId,
      signature: response.signature,
    );
    await _createBundledSubOrders();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(orderNumber: _pendingOrderNumber),
      ),
    );
  }

  /// Turns every service bundled in via `BookingScreen`'s "Add More
  /// Services" (before checkout) into a real sub-order now that the primary
  /// order's single combined payment has succeeded — each one is already
  /// paid for as part of that payment, so this call is expected to attach
  /// it without asking for another charge (see the Order Edits API spec for
  /// the payment-required contract this assumes elsewhere; a bundled extra
  /// is different — it's paid for up front, not after the fact).
  ///
  /// Best-effort per service: one failing doesn't stop the others or block
  /// the success screen, since the customer has already been charged for
  /// everything — a failure here is a backend/reconciliation concern to
  /// surface separately, not something retrying at this point can fix.
  /// Skipped entirely if the primary order's id couldn't be determined from
  /// the place-order response.
  Future<void> _createBundledSubOrders() async {
    final orderId = _pendingPrimaryOrderId;
    final state = AppStateScope.of(context);
    if (orderId == null || state.extraServices.isEmpty) return;
    for (final extra in state.extraServices) {
      try {
        await _apiService.post(
          '/customer/orders/$orderId/sub-orders',
          data: {
            'service_id': extra.serviceId,
            'addon_ids': extra.addonIds,
            'booking_date': state.bookingDateApiValue,
            'already_paid': true,
          },
        );
      } catch (e) {
        debugPrint(
          'Bundled sub-order creation error (service ${extra.serviceId}): $e',
        );
      }
    }
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    _confirmRazorpayStatus(status: isCancelled ? 'pending' : 'failed');
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showAppToast(
      context,
      isCancelled
          ? l10n.paymentCancelled
          : l10n.paymentFailedWithReason(response.message ?? ''),
    );
  }

  /// Reports the checkout outcome back to the server so it can reconcile
  /// the order's payment status, per `POST /customer/orders/razorpay/status`.
  /// Best-effort — failures here don't block the UI flow already driven by
  /// the Razorpay SDK's own success/error callback.
  Future<void> _confirmRazorpayStatus({
    required String status,
    String? paymentId,
    String? signature,
  }) async {
    final orderId = _pendingRazorpayOrderId;
    if (orderId == null) return;
    try {
      await _apiService.post(
        '/customer/orders/razorpay/status',
        data: {
          'razorpay_order_id': orderId,
          'status': status,
          'razorpay_payment_id': ?paymentId,
          'razorpay_signature': ?signature,
        },
      );
    } catch (e) {
      debugPrint('Razorpay status confirmation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.securePayment),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.payingForLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizedServiceName(context, state.sub),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.providerWithSlot(state.slot),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  TotalRow(
                    label: l10n.payableLabel,
                    value: '₹${state.subtotal}',
                  ),
                ],
              ),
            ),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paymentMethod,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.mintBorder),
                      color: const Color(0xFFF5FCF8),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.circleCheck,
                          size: 16,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.paymentMethodRazorpay,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.paymentMethodRazorpaySub,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            AppCard(
              child: Column(
                children: [
                  DetailRow(
                    label: l10n.serviceAmountLabel,
                    value: '₹${state.amount}',
                  ),
                  DetailRow(
                    label: l10n.addonsLabel,
                    value: '₹${state.addonsTotal}',
                  ),
                  _PlatformFeeRow(
                    label: l10n.platformFeeLabel,
                    isInstant: state.bookingType == BookingType.instant,
                    instantLabel: l10n.orderTypeInstant,
                    value: _isLoadingPlatformFee
                        ? l10n.loadingEllipsis
                        : (state.platformFee != null
                              ? '₹${state.platformFee}'
                              : '—'),
                  ),
                  TotalRow(label: l10n.totalLabel, value: '₹${state.payable}'),
                ],
              ),
            ),
            if (_platformFeeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _platformFeeError!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _fetchPlatformFee,
                      child: Text(
                        l10n.retryLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),

            PrimaryButton(
              label: _isPlacingOrder
                  ? l10n.placingOrder
                  : l10n.payAndPlaceOrder,
              onTap:
                  (_isPlacingOrder ||
                      _isLoadingPlatformFee ||
                      state.platformFee == null)
                  ? null
                  : _placeOrder,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.securePaymentFooter,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Like `DetailRow`, but for the platform-fee line specifically — adds a
/// small "Instant" pill next to the label when [isInstant], so the customer
/// can see at a glance that the fee shown is the (usually higher) instant
/// rate rather than the regular one, not just a number that silently
/// changed from what they might remember seeing on a Schedule order.
class _PlatformFeeRow extends StatelessWidget {
  const _PlatformFeeRow({
    required this.label,
    required this.value,
    required this.isInstant,
    required this.instantLabel,
  });

  final String label;
  final String value;
  final bool isInstant;
  final String instantLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (isInstant) ...[
                const SizedBox(width: 6),
                Pill(label: instantLabel, fontSize: 9),
              ],
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
