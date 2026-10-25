import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/inline_checkout.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../models/service_category.dart' show ServiceAddOn, ServiceDetailResult;
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// "Add More Services" — fetches
/// `GET /customer/orders/:orderId/available-services` (already scoped to
/// the primary order's provider and excluding anything already on the
/// order) and lets the customer pick one to add as a sub-order via
/// `POST /customer/orders/:orderId/sub-orders`.
///
/// Once a service is picked, its own add-ons are fetched from
/// `GET /customer/service-detail/:serviceId` (the same endpoint
/// `BookingScreen` uses) and offered as an optional toggleable list, mirroring
/// that screen's "Recommended Add-ons" card — kept local to this screen's own
/// state rather than the shared `AppState`, since that's scoped to the main
/// booking flow.
///
/// No slot picker for v1 — the new sub-order defaults to the primary order's
/// own booking date with no specific slot, which the API supports
/// (`slot`/`booking_date` are both optional on create). [primaryBookingDate],
/// when known, is shown to the customer so they know what date the new
/// service will fall under.
///
/// Confirming goes through the same create → pay → confirm flow as placing a
/// brand-new order (see [InlineCheckout]): if the create response carries
/// Razorpay fields, checkout opens for the new service's price before the
/// sub-order is considered added; otherwise it's added immediately.
///
/// Pops with `true` once a sub-order has actually been created and paid for
/// (the caller should re-fetch order detail), or `false`/`null` if the
/// customer backed out without adding anything.
class AddMoreServicesScreen extends StatefulWidget {
  const AddMoreServicesScreen({
    super.key,
    required this.orderId,
    this.primaryBookingDate,
  });

  /// The primary order's id — every call in this screen is scoped to it.
  final int orderId;

  /// The primary order's `booking_date`, formatted for display (not the
  /// API `YYYY-MM-DD` value) — shown as a note since the new sub-order
  /// defaults to this same date.
  final String? primaryBookingDate;

  @override
  State<AddMoreServicesScreen> createState() => _AddMoreServicesScreenState();
}

class _AddMoreServicesScreenState extends State<AddMoreServicesScreen> {
  final _apiService = ApiService();
  late final _checkout = InlineCheckout(apiService: _apiService);
  bool _isLoading = true;
  bool _hasError = false;
  List<AvailableService> _services = const [];
  int? _selectedServiceId;
  bool _isSubmitting = false;

  bool _isLoadingAddOns = false;
  List<ServiceAddOn> _addOns = const [];
  final Set<int> _selectedAddOnIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailableServices();
  }

  @override
  void dispose() {
    _checkout.dispose();
    super.dispose();
  }

  /// The selected service's own price plus every selected add-on's — what
  /// checkout, if required, will charge.
  int get _payableAmount {
    final service = _services.firstWhere(
      (s) => s.id == _selectedServiceId,
      orElse: () => const AvailableService(id: -1),
    );
    final servicePrice =
        num.tryParse(
          (service.serviceOfferPrice?.isNotEmpty ?? false)
              ? service.serviceOfferPrice!
              : (service.serviceStartPrice ?? '0'),
        )?.round() ??
        0;
    final addOnsTotal = _addOns
        .where((a) => _selectedAddOnIds.contains(a.id))
        .fold<int>(0, (sum, a) => sum + a.price);
    return servicePrice + addOnsTotal;
  }

  /// Selects [service] and re-fetches its own add-ons, replacing whatever
  /// add-on selection belonged to a previously picked service.
  Future<void> _selectService(AvailableService service) async {
    setState(() {
      _selectedServiceId = service.id;
      _addOns = const [];
      _selectedAddOnIds.clear();
      _isLoadingAddOns = true;
    });
    try {
      final response = await _apiService.get(
        '/customer/service-detail/${service.id}',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final result = ServiceDetailResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        if (mounted && _selectedServiceId == service.id) {
          setState(() => _addOns = result.addOns);
        }
      }
    } catch (e) {
      debugPrint('Service detail API error: $e');
    } finally {
      if (mounted && _selectedServiceId == service.id) {
        setState(() => _isLoadingAddOns = false);
      }
    }
  }

  void _toggleAddOn(int addOnId) {
    setState(() {
      if (!_selectedAddOnIds.remove(addOnId)) _selectedAddOnIds.add(addOnId);
    });
  }

  Future<void> _fetchAvailableServices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await _apiService.get(
        '/customer/orders/${widget.orderId}/available-services',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final result = AvailableServicesResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() => _services = result.services);
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint('Available services API error: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final serviceId = _selectedServiceId;
    if (serviceId == null) return;

    setState(() => _isSubmitting = true);
    var isSuccess = false;
    Map<String, dynamic>? data;
    String? errorMessage;
    try {
      final response = await _apiService.post(
        '/customer/orders/${widget.orderId}/sub-orders',
        data: {
          'service_id': serviceId,
          'addon_ids': _selectedAddOnIds.toList(),
        },
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
      debugPrint('Create sub-order API error: $e');
      errorMessage = l10n.somethingWentWrongTryAgain;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    if (!isSuccess) {
      showAppToast(context, errorMessage ?? l10n.somethingWentWrongTryAgain);
      return;
    }

    // Mirrors PaymentScreen: the sub-order is already created server-side at
    // this point, just possibly still awaiting payment. If the response
    // carries Razorpay fields, checkout must succeed before this screen
    // reports the sub-order as added; otherwise (e.g. no payment required
    // for this change) it's already final.
    if (data != null && InlineCheckout.needsPayment(data)) {
      setState(() => _isSubmitting = true);
      await _checkout.pay(
        context: context,
        data: data,
        payableAmount: _payableAmount,
        onDone: () {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          showAppToast(context, l10n.serviceAddedToast);
          Navigator.of(context).pop(true);
        },
        onError: (message) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          showAppToast(context, message);
        },
      );
      return;
    }

    showAppToast(context, l10n.serviceAddedToast);
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
                title: l10n.addMoreServicesTitle,
                subtitle: l10n.addMoreServicesSubtitle,
              ),
            ),
            if (widget.primaryBookingDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.usesPrimaryOrderDate(widget.primaryBookingDate!),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                  ? _EmptyState(
                      message: l10n.availableServicesLoadError,
                      onRetry: _fetchAvailableServices,
                    )
                  : _services.isEmpty
                  ? _EmptyState(message: l10n.noAvailableServices)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        for (final service in _services)
                          _AvailableServiceCard(
                            service: service,
                            selected: _selectedServiceId == service.id,
                            onTap: () => _selectService(service),
                          ),
                        if (_selectedServiceId != null) ...[
                          if (_isLoadingAddOns)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_addOns.isNotEmpty)
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
                                      added: _selectedAddOnIds.contains(
                                        addOn.id,
                                      ),
                                      isLast: addOn == _addOns.last,
                                      onTap: () => _toggleAddOn(addOn.id),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
            if (!_isLoading && !_hasError && _services.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Opacity(
                  opacity: _selectedServiceId == null ? 0.5 : 1,
                  child: PrimaryButton(
                    label: _isSubmitting
                        ? l10n.addingService
                        : l10n.confirmAddService,
                    onTap: (_selectedServiceId == null || _isSubmitting)
                        ? null
                        : _confirm,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvailableServiceCard extends StatelessWidget {
  const _AvailableServiceCard({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final AvailableService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5FCF8) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.mintBorder : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.displayLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (service.displayPrice != null)
                    Text(
                      service.displayPrice!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: selected ? AppColors.green : const Color(0xFFA3AFBD),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single selectable add-on row within the "Optional Add-ons" card —
/// mirrors `BookingScreen`'s own `_AddOnRow` for visual consistency, kept as
/// a separate private copy since that one is private to its own file too.
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
