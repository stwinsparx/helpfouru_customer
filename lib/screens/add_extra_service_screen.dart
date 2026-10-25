import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// "Add More Services" from `BookingScreen`, before checkout — lets the
/// customer bundle another service from the **same provider** onto the
/// order they're about to place, distinct from [AddMoreServicesScreen]
/// (which adds a sub-order to an order that's already been placed and
/// paid for). Fetches `GET /customer/providers/:providerId` (the same call
/// `ProviderProfileScreen` uses) for that provider's full service list,
/// excluding [excludeServiceIds] — the service already being booked, plus
/// any extra service already bundled in.
///
/// On picking a service, its own add-ons are offered the same way
/// `BookingScreen`/`AddMoreServicesScreen` do, fetched from
/// `GET /customer/service-detail/:serviceId`. Confirming pops an
/// [ExtraService] for the caller to add via `AppState.addExtraService` — no
/// API write happens here; this only builds up what will later be included
/// in the primary order's single Razorpay payment and, once that succeeds,
/// turned into real sub-orders by `PaymentScreen`.
class AddExtraServiceScreen extends StatefulWidget {
  const AddExtraServiceScreen({
    super.key,
    required this.providerId,
    required this.excludeServiceIds,
  });

  final int providerId;
  final Set<int> excludeServiceIds;

  @override
  State<AddExtraServiceScreen> createState() => _AddExtraServiceScreenState();
}

class _AddExtraServiceScreenState extends State<AddExtraServiceScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _hasError = false;
  List<ProviderService> _services = const [];
  int? _selectedServiceId;

  bool _isLoadingAddOns = false;
  List<ServiceAddOn> _addOns = const [];
  final Set<int> _selectedAddOnIds = {};

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await _apiService.get(
        '/customer/providers/${widget.providerId}',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final result = ProviderProfileResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(
          () => _services = result.services
              .where((s) => !widget.excludeServiceIds.contains(s.id))
              .toList(),
        );
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint('Provider profile API error: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Selects [service] and re-fetches its own add-ons, replacing whatever
  /// add-on selection belonged to a previously picked service.
  Future<void> _selectService(ProviderService service) async {
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

  void _confirm() {
    final serviceId = _selectedServiceId;
    if (serviceId == null) return;
    final service = _services.firstWhere((s) => s.id == serviceId);
    final servicePrice =
        num.tryParse(
          (service.serviceOfferPrice?.isNotEmpty ?? false)
              ? service.serviceOfferPrice!
              : (service.serviceStartPrice ?? '0'),
        )?.round() ??
        0;
    final selectedAddOns = _addOns
        .where((a) => _selectedAddOnIds.contains(a.id))
        .map((a) => Addon(a.itemName, a.price, id: a.id, source: a))
        .toList();
    Navigator.of(context).pop(
      ExtraService(
        serviceId: serviceId,
        label: service.displayLabel,
        servicePrice: servicePrice,
        addons: selectedAddOns,
      ),
    );
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                  ? _EmptyState(
                      message: l10n.availableServicesLoadError,
                      onRetry: _fetchServices,
                    )
                  : _services.isEmpty
                  ? _EmptyState(message: l10n.noAvailableServices)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        for (final service in _services)
                          _ProviderServiceCard(
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
                    label: l10n.confirmAddService,
                    onTap: _selectedServiceId == null ? null : _confirm,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderServiceCard extends StatelessWidget {
  const _ProviderServiceCard({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final ProviderService service;
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

/// A single selectable add-on row — mirrors `BookingScreen`'s own
/// `_AddOnRow` for visual consistency; each screen keeps its own private
/// copy rather than sharing one, matching how this app already structures
/// per-screen widgets.
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
