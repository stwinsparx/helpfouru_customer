import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/inline_checkout.dart';
import '../l10n/app_localizations.dart';
import '../models/service_category.dart' show ServiceAddOn, ServiceDetailResult;
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Lets the customer change which add-ons are attached to an already-placed
/// order or sub-order — fetches the full add-on catalog for [serviceId] from
/// `GET /customer/service-detail/:serviceId` (the same endpoint
/// `BookingScreen`/`AddMoreServicesScreen` already use), pre-selects the ones
/// already on the order via [initialAddOnIds], and saves the new selection
/// with `PUT /customer/orders/:orderId/add-ons`.
///
/// NOTE: no confirmed backend contract for editing an existing order's
/// add-ons yet — `PUT /customer/orders/:orderId/add-ons` with
/// `{ "addon_ids": [...] }` is a best-effort guess following this app's
/// existing snake_case convention (see `payment_screen.dart`'s place-order
/// call for the same caveat). Adjust the endpoint/body once the real
/// contract is known. [orderId] is whichever order this add-on set actually
/// belongs to — the primary order's id when editing its own add-ons, or a
/// sub-order's own id when editing one of those.
///
/// Saving goes through the same create → pay → confirm flow as placing a
/// brand-new order (see [InlineCheckout]): if the update response carries
/// Razorpay fields, checkout opens for the extra amount due (the newly
/// added add-ons' total) before the change is considered saved; otherwise
/// (e.g. only add-ons were removed, or nothing new needed payment) it's
/// applied immediately.
///
/// Pops with `true` once the change has actually been saved and paid for
/// (the caller should re-fetch order detail), or `false`/`null` if the
/// customer backed out without saving.
class EditAddonsScreen extends StatefulWidget {
  const EditAddonsScreen({
    super.key,
    required this.orderId,
    required this.serviceId,
    required this.serviceLabel,
    required this.initialAddOnIds,
  });

  /// The specific order or sub-order id these add-ons belong to.
  final int orderId;

  /// The service this order is for — its own add-on catalog is what gets
  /// offered here.
  final int serviceId;

  /// Shown in the header so it's clear which service's add-ons are being
  /// edited.
  final String serviceLabel;

  /// `add_on_id`s already attached to this order, used to pre-check the
  /// matching rows once the catalog loads.
  final Set<int> initialAddOnIds;

  @override
  State<EditAddonsScreen> createState() => _EditAddonsScreenState();
}

class _EditAddonsScreenState extends State<EditAddonsScreen> {
  final _apiService = ApiService();
  late final _checkout = InlineCheckout(apiService: _apiService);
  bool _isLoading = true;
  bool _hasError = false;
  List<ServiceAddOn> _addOns = const [];
  late final Set<int> _selectedAddOnIds = {...widget.initialAddOnIds};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchAddOns();
  }

  @override
  void dispose() {
    _checkout.dispose();
    super.dispose();
  }

  /// Total of only the newly-added add-ons (in [_selectedAddOnIds] but not
  /// [EditAddonsScreen.initialAddOnIds]) — what checkout, if required,
  /// charges. Add-ons already on the order were already paid for; removing
  /// one isn't charged for here either.
  int get _extraAmountDue => _addOns
      .where(
        (a) =>
            _selectedAddOnIds.contains(a.id) &&
            !widget.initialAddOnIds.contains(a.id),
      )
      .fold<int>(0, (sum, a) => sum + a.price);

  Future<void> _fetchAddOns() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await _apiService.get(
        '/customer/service-detail/${widget.serviceId}',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final result = ServiceDetailResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() => _addOns = result.addOns);
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint('Service detail API error: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleAddOn(int addOnId) {
    setState(() {
      if (!_selectedAddOnIds.remove(addOnId)) _selectedAddOnIds.add(addOnId);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    var isSuccess = false;
    Map<String, dynamic>? data;
    String? errorMessage;
    try {
      final response = await _apiService.put(
        '/customer/orders/${widget.orderId}/add-ons',
        data: {'addon_ids': _selectedAddOnIds.toList()},
      );
      isSuccess = response.data['is_success'] == true;
      if (isSuccess) {
        data = response.data['data'] as Map<String, dynamic>?;
      } else {
        errorMessage = response.data['message'] as String?;
      }
    } on DioException catch (e) {
      errorMessage =
          e.response?.data?['message'] as String? ??
          l10n.somethingWentWrongTryAgain;
    } catch (e) {
      debugPrint('Update add-ons API error: $e');
      errorMessage = l10n.somethingWentWrongTryAgain;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    if (!isSuccess) {
      showAppToast(context, errorMessage ?? l10n.somethingWentWrongTryAgain);
      return;
    }

    // Mirrors PaymentScreen: the new selection is already saved server-side
    // at this point, just possibly still awaiting payment for what changed.
    if (data != null && InlineCheckout.needsPayment(data)) {
      setState(() => _isSaving = true);
      await _checkout.pay(
        context: context,
        data: data,
        payableAmount: _extraAmountDue,
        onDone: () {
          if (!mounted) return;
          setState(() => _isSaving = false);
          showAppToast(context, l10n.addonsUpdatedToast);
          Navigator.of(context).pop(true);
        },
        onError: (message) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          showAppToast(context, message);
        },
      );
      return;
    }

    showAppToast(context, l10n.addonsUpdatedToast);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MiniHeader(
                title: l10n.editAddonsTitle,
                subtitle: widget.serviceLabel,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                  ? _EmptyState(
                      message: l10n.availableServicesLoadError,
                      onRetry: _fetchAddOns,
                    )
                  : _addOns.isEmpty
                  ? _EmptyState(message: l10n.noAddonsAvailable)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.optionalAddonsLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              for (final addOn in _addOns)
                                _AddOnRow(
                                  addOn: addOn,
                                  added: _selectedAddOnIds.contains(addOn.id),
                                  isLast: addOn == _addOns.last,
                                  onTap: () => _toggleAddOn(addOn.id),
                                ),
                            ],
                          ),
                        ),
                        if (_extraAmountDue > 0)
                          AppCard(
                            child: TotalRow(
                              label: l10n.extraAmountDueLabel,
                              value: '₹$_extraAmountDue',
                            ),
                          ),
                      ],
                    ),
            ),
            if (!_isLoading && !_hasError && _addOns.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: PrimaryButton(
                  label: _isSaving ? l10n.savingAddons : l10n.saveAddons,
                  onTap: _isSaving ? null : _save,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single selectable add-on row — mirrors `BookingScreen`'s own
/// `_AddOnRow` (and `AddMoreServicesScreen`'s copy of it) for visual
/// consistency; each screen keeps its own private copy rather than sharing
/// one, matching how this app already structures per-screen widgets.
class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.addOn,
    required this.added,
    required this.isLast,
    required this.onTap,
  });

  final ServiceAddOn addOn;
  final bool added;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = [
      if (addOn.displayQuantity != null) addOn.displayQuantity!,
      if (addOn.displayWarranty != null)
        l10n.warrantyDurationLabel(addOn.displayWarranty!),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEDF1F4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.ink),
                    children: [
                      TextSpan(
                        text: addOn.itemName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ${addOn.displayPrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: added ? AppColors.greenDark : const Color(0xFFE6F7EF),
                border: Border.all(color: AppColors.mintBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                added ? l10n.added : l10n.add,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: added ? Colors.white : AppColors.greenDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  l10n.retryLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
