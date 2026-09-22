import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/services/api_service.dart';
import '../core/services/razorpay_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'order_success_screen.dart';

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

  @override
  void dispose() {
    _razorpay?.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context);
    final state = AppStateScope.of(context);

    setState(() => _isPlacingOrder = true);
    var isSuccess = false;
    var isSlotConflict = false;
    String? errorMessage;
    String? orderNumber;
    String? razorpayOrderId;
    String? razorpayKey;
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
          'payment_method': _paymentMethod,
          'amount': state.amount,
          'addons_total': state.addonsTotal,
          'platform_fee': AppState.platformFee,
          'payable_amount': state.payable,
        },
      );
      isSuccess = response.data['is_success'] == true;
      if (isSuccess) {
        final data = response.data['data'] as Map<String, dynamic>?;
        orderNumber = data?['order_number'] as String? ??
            data?['order_id']?.toString();
        // NOTE: field name for the Razorpay order id hasn't been confirmed
        // against a real response yet — trying the likely candidates.
        razorpayOrderId = data?['razorpay_order_id'] as String? ??
            data?['razorpay_id'] as String?;
        razorpayKey = data?['razorpay_key'] as String?;
      } else {
        errorMessage = response.data['message'] as String?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        isSlotConflict = true;
        errorMessage =
            e.response?.data?['message'] as String? ?? l10n.slotAlreadyBookedError;
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
      showAppToast(
        context,
        errorMessage ?? l10n.somethingWentWrongTryAgain,
      );
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

  void _onRazorpaySuccess(PaymentSuccessResponse response) {
    _confirmRazorpayStatus(
      status: 'success',
      paymentId: response.paymentId,
      signature: response.signature,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(orderNumber: _pendingOrderNumber),
      ),
    );
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
                  TotalRow(label: l10n.payableLabel, value: '₹${state.subtotal}'),
                ],
              ),
            ),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paymentMethod,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
                  DetailRow(label: l10n.serviceAmountLabel, value: '₹${state.amount}'),
                  DetailRow(label: l10n.addonsLabel, value: '₹${state.addonsTotal}'),
                  DetailRow(
                    label: l10n.platformFeeLabel,
                    value: '₹${AppState.platformFee}',
                    showDivider: false,
                  ),
                  TotalRow(label: l10n.totalLabel, value: '₹${state.payable}'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(
              label: _isPlacingOrder ? l10n.placingOrder : l10n.payAndPlaceOrder,
              onTap: _isPlacingOrder ? null : _placeOrder,
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
