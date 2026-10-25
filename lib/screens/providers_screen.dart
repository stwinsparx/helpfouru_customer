import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/api_service.dart';
import '../core/services/device_info_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/provider_card.dart';
import '../widgets/service_selection_sheets.dart';
import 'provider_profile_screen.dart';
import 'subcategory_screen.dart';
import 'booking_screen.dart';

/// Fetches `GET /customer/services/:categoryId/providers` for [categoryId],
/// re-fetching with `sub_category_id`/`filter_id`/`availability` set
/// whenever any of them changes.
///
/// [initialFilterId] is the filter chosen up-front via the mandatory bottom
/// sheet shown from the home screen before this screen is pushed.
///
/// [initialSubCategoryId], when set, means the caller already knows exactly
/// which sub-category to land on (e.g. a Popular Services sub-category tile
/// on Home) — this screen fetches straight into that sub-category and skips
/// the mandatory sub-category prompt entirely, since there's nothing left to
/// ask. When left `null` (the normal Explore Services flow), sub-category
/// selection happens here instead: once the first fetch resolves, this
/// screen shows its own mandatory sub-category sheet (skipped entirely if
/// there are no sub-categories to choose from) — dismissing it without
/// picking one pops back to Home, same "mandatory or cancel" treatment as
/// the filter sheet.
///
/// Right after a sub-category is resolved (either path above), a second
/// mandatory sheet asks Instant or Schedule (see [OrderType]) — Instant
/// re-fetches scoped to providers with an opening in the next 30 minutes,
/// Schedule fetches every provider as before. Dismissing it is the same
/// "mandatory or cancel" treatment as the other two sheets.
///
/// NOTE: the `availability`/`availability_window_minutes` query params and
/// each provider's `next_available_at` field aren't a confirmed backend
/// contract yet (see the "Instant vs Schedule API" spec) — sent/read
/// defensively so the screen still works, just unfiltered, against a
/// backend that doesn't recognise them yet.
///
/// A FAB lets the user reopen the sub-category sheet afterward to change
/// that selection, regardless of how the screen was entered; a chip next to
/// it reopens the order-type sheet.
class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({
    super.key,
    required this.categoryId,
    this.initialFilterId,
    this.initialSubCategoryId,
  });

  final int categoryId;
  final int? initialFilterId;
  final int? initialSubCategoryId;

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  static const _instantWindowMinutes = 30;

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<ServiceSubCategory> _subCategories = [];
  List<ServiceFilter> _serviceFilters = [];
  List<ProviderListing> _providers = [];
  int? _selectedSubCategoryId;
  int? _selectedFilterId;
  OrderType? _orderType;
  bool _locationRequired = false;
  num? _radiusKm;

  /// Reason the last location resolution failed — drives which "turn on
  /// location" copy/action to show. Only meaningful while [_locationRequired]
  /// is true.
  LocationStatus _locationStatus = LocationStatus.unavailable;

  /// Backend's `message` for the last `location_required: true` response,
  /// when present — e.g. "Turn on location to see providers near you".
  String? _locationMessage;

  /// "lat,lng" actually sent on the last fetch, resolved once per address
  /// selection (not re-resolved on every filter/tab re-fetch) — `null` means
  /// still resolving, or resolution failed (see [_locationRequired]).
  String? _coordinates;

  /// The [AppState.selectedAddress] used to resolve [_coordinates] — compared
  /// against the current one in [didChangeDependencies] so a re-fetch only
  /// happens when the customer actually switches address, not on every
  /// rebuild.
  SavedAddress? _coordinatesForAddress;
  bool _didResolveLocation = false;

  /// Set once the initial fetch resolves, so the mandatory sub-category
  /// sheet is only ever auto-shown the first time — subsequent re-fetches
  /// (from picking a filter, or from the FAB) must not re-trigger it. Also
  /// pre-set to true when [ProvidersScreen.initialSubCategoryId] is given,
  /// since the caller already resolved sub-category selection for us — in
  /// that case the order-type prompt still fires once, right after the
  /// first fetch, same as it would have after a manually-picked
  /// sub-category.
  late bool _hasPromptedSubCategory = widget.initialSubCategoryId != null;

  /// Set once the order-type sheet has been shown for the current
  /// sub-category, so re-fetches from the filter chips or the order-type
  /// FAB don't re-trigger it. Reset whenever the sub-category changes,
  /// since "how soon" is asked fresh for each service.
  bool _hasPromptedOrderType = false;

  @override
  void initState() {
    super.initState();
    _selectedFilterId = widget.initialFilterId;
    _selectedSubCategoryId = widget.initialSubCategoryId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectedAddress = AppStateScope.of(context).selectedAddress;
    // Re-resolve (and re-fetch) only when the customer's address selection
    // actually changes — not on every rebuild, and not on every GPS update
    // (this screen doesn't watch a live position stream at all; "current
    // location" mode resolves a single fresh fix per address selection,
    // same as a saved address resolves its text once per selection).
    if (!_didResolveLocation || selectedAddress != _coordinatesForAddress) {
      _didResolveLocation = true;
      _coordinatesForAddress = selectedAddress;
      _resolveLocationAndFetch(selectedAddress);
    }
  }

  /// Resolves "lat,lng" for [address], preferring its own stored
  /// coordinates (the exact pin saved for it) over re-geocoding its text —
  /// only falls back to forward-geocoding [SavedAddress.line] when the
  /// address has no stored coordinates (e.g. one saved before the map
  /// picker existed, or created without picking a map location). When no
  /// address is selected ("Use current location"), uses live GPS instead.
  /// Surfaces *why* it failed (permission/service/etc.) so the UI can
  /// prompt correctly rather than just showing an empty list. Never sends a
  /// fallback/default coordinate when location is unknown; the request is
  /// simply sent with no `coordinates` value, matching the backend's own
  /// "no location" handling.
  Future<void> _resolveLocationAndFetch(SavedAddress? address) async {
    String? coordinates;
    var status = LocationStatus.available;

    if (address != null) {
      coordinates = address.coordinates;
      coordinates ??= await DeviceInfoService.orderCoordinates(
        addressLine: address.line,
      );
      if (coordinates == null) status = LocationStatus.unavailable;
    } else {
      final (gpsStatus, gpsCoordinates) =
          await DeviceInfoService.currentLocationStatus();
      status = gpsStatus;
      coordinates = gpsCoordinates;
    }

    if (!mounted) return;
    setState(() => _coordinates = coordinates);
    await _fetchProviders(
      subCategoryId: _selectedSubCategoryId,
      filterId: _selectedFilterId,
      orderType: _orderType,
      coordinates: coordinates,
      fallbackLocationStatus: status,
    );
  }

  /// Re-resolves location from scratch (e.g. after the customer comes back
  /// from Settings, or taps "Try Again") and re-fetches.
  Future<void> _retryLocation() =>
      _resolveLocationAndFetch(_coordinatesForAddress);

  Future<void> _fetchProviders({
    int? subCategoryId,
    int? filterId,
    OrderType? orderType,
    String? coordinates,
    LocationStatus fallbackLocationStatus = LocationStatus.available,
  }) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        '/customer/services/${widget.categoryId}/providers',
        queryParameters: {
          'sub_category_id': ?subCategoryId,
          'filter_id': ?filterId,
          if (orderType != null) 'availability': orderType.apiValue,
          if (orderType == OrderType.instant)
            'availability_window_minutes': _instantWindowMinutes,
        },
        options: Options(
          headers: {'coordinates': ?coordinates ?? _coordinates},
        ),
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final result = ProvidersResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() {
          _subCategories = result.subCategories;
          _serviceFilters = result.serviceFilters;
          _providers = result.providers;
          _locationRequired = result.locationRequired;
          _radiusKm = result.radiusKm;
          if (result.locationRequired) {
            _locationStatus = fallbackLocationStatus;
            _locationMessage = response.data['message'] as String?;
          }
        });
      }
    } catch (e) {
      debugPrint('Providers API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!_hasPromptedSubCategory) {
      _hasPromptedSubCategory = true;
      await _promptSubCategoryIfNeeded();
    }
    if (!_hasPromptedOrderType) {
      _hasPromptedOrderType = true;
      await _promptOrderTypeIfNeeded();
    }
  }

  /// Shows the mandatory sub-category page once, right after the first
  /// fetch resolves — skipped entirely when there are no sub-categories to
  /// pick from. Backing out without choosing one pops this whole screen
  /// back to Home, matching the filter sheet's "mandatory or cancel"
  /// behaviour.
  Future<void> _promptSubCategoryIfNeeded() async {
    if (_subCategories.isEmpty) return;
    if (!mounted) return;
    final subCategory = await Navigator.of(context).push<ServiceSubCategory>(
      MaterialPageRoute(
        builder: (_) => SubCategoryScreen(subCategories: _subCategories),
      ),
    );
    if (!mounted) return;
    if (subCategory == null) {
      Navigator.of(context).pop();
      return;
    }
    _applySubCategory(subCategory);
  }

  /// Shows the mandatory Instant/Schedule sheet once a sub-category is
  /// known — skipped if one hasn't been resolved yet (it re-runs once the
  /// sub-category sheet above resolves and re-fetches). Backing out without
  /// choosing pops this whole screen back to Home, same "mandatory or
  /// cancel" treatment as the other two sheets.
  Future<void> _promptOrderTypeIfNeeded() async {
    if (_selectedSubCategoryId == null) return;
    if (!mounted) return;
    final orderType = await showOrderTypeSheet(context);
    if (!mounted) return;
    if (orderType == null) {
      Navigator.of(context).pop();
      return;
    }
    _applyOrderType(orderType);
  }

  void _applySubCategory(ServiceSubCategory subCategory) {
    AppStateScope.of(
      context,
    ).selectSub(subCategory.id, subCategory.categoryName);
    setState(() {
      _selectedSubCategoryId = subCategory.id;
      // A new sub-category means "how soon" is asked again, even if it was
      // already answered for whatever sub-category was selected before.
      _hasPromptedOrderType = false;
    });
    _fetchProviders(
      subCategoryId: subCategory.id,
      filterId: _selectedFilterId,
      orderType: _orderType,
    );
  }

  Future<void> _changeSubCategory() async {
    if (_subCategories.isEmpty) return;
    final subCategory = await Navigator.of(context).push<ServiceSubCategory>(
      MaterialPageRoute(
        builder: (_) => SubCategoryScreen(subCategories: _subCategories),
      ),
    );
    if (subCategory == null) return; // keep current selection
    _applySubCategory(subCategory);
  }

  void _applyOrderType(OrderType orderType) {
    setState(() => _orderType = orderType);
    _fetchProviders(
      subCategoryId: _selectedSubCategoryId,
      filterId: _selectedFilterId,
      orderType: orderType,
    );
  }

  Future<void> _changeOrderType() async {
    final orderType = await showOrderTypeSheet(context);
    if (orderType == null) return; // keep current selection
    _applyOrderType(orderType);
  }

  /// Short "Next: …" label for a provider's `next_available_at`, or `null`
  /// if it isn't known (the backend doesn't send it yet). Shows just the
  /// time for today, "Tomorrow <time>" for tomorrow, otherwise a short date.
  String? _availabilityLabel(ProviderListing provider) {
    final l10n = AppLocalizations.of(context);
    final next = provider.nextAvailableAt;
    if (next == null) return null;
    if (provider.isAvailableNow) return l10n.availableNowBadge;

    final local = next.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    final dayLabel = switch (target.difference(today).inDays) {
      0 => time,
      1 => 'Tomorrow $time',
      _ => '${local.day}/${local.month} $time',
    };
    return l10n.nextAvailableLabel(dayLabel);
  }

  void _selectFilter(ServiceFilter? filter) {
    setState(() => _selectedFilterId = filter?.id);
    _fetchProviders(
      subCategoryId: _selectedSubCategoryId,
      filterId: filter?.id,
      orderType: _orderType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      floatingActionButton: _subCategories.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _changeSubCategory,
              backgroundColor: AppColors.green,
              icon: const FaIcon(
                FontAwesomeIcons.filter,
                size: 14,
                color: Colors.white,
              ),
              label: Text(
                state.subCategoryName ?? l10n.selectSubCategoryTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            MiniHeader(
              title: state.categoryName ?? '',
              subtitle: state.subCategoryName != null
                  ? l10n.providersNearbyCount(
                      state.subCategoryName!,
                      _providers.length,
                    )
                  : l10n.providersCount(_providers.length),
              onBack: () => Navigator.of(context).pop(),
            ),
            if (_orderType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: _changeOrderType,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      border: Border.all(color: AppColors.mintBorder),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          _orderType == OrderType.instant
                              ? FontAwesomeIcons.bolt
                              : FontAwesomeIcons.calendarDays,
                          size: 11,
                          color: AppColors.greenDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _orderType == OrderType.instant
                              ? l10n.orderTypeInstant
                              : l10n.orderTypeSchedule,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: AppColors.greenDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_serviceFilters.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChipButton(
                      label: l10n.filterAll,
                      selected: _selectedFilterId == null,
                      onTap: () => _selectFilter(null),
                    ),
                    for (final filter in _serviceFilters)
                      FilterChipButton(
                        label: filter.name,
                        selected: _selectedFilterId == filter.id,
                        onTap: () => _selectFilter(filter),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_locationRequired)
              _LocationRequiredState(
                status: _locationStatus,
                message: _locationMessage,
                onRetry: _retryLocation,
              )
            else if (_providers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    _radiusKm != null
                        ? l10n.noProvidersWithinRadius(_radiusKm!)
                        : l10n.noProvidersFound,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              )
            else
              ..._providers.map(
                (p) => ProviderCard(
                  name: p.name,
                  role: p.serviceSubCategoryName ?? p.serviceCategoryName ?? '',
                  rating: p.rating.toString(),
                  price: p.displayPrice ?? '',
                  distance: p.displayDistance,
                  profileImage: p.profileImage,
                  isVerified: p.isVerifiedProvider,
                  jobs: l10n.jobsCount(p.completedJobs),
                  availabilityLabel: _availabilityLabel(p),
                  isAvailableNow: p.isAvailableNow,
                  onViewProfile: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(providerId: p.id),
                    ),
                  ),
                  onBook: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(
                        serviceId: p.serviceId,
                        isInstantOrder: _orderType == OrderType.instant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown in place of the providers list when the backend
/// couldn't resolve the customer's location (`location_required: true`) —
/// wording and the action button depend on exactly why, per [status].
class _LocationRequiredState extends StatelessWidget {
  const _LocationRequiredState({
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final LocationStatus status;

  /// Backend-provided `message`, used as the title when present —
  /// `null` falls back to the localized default title.
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (body, buttonLabel, action) = switch (status) {
      LocationStatus.serviceDisabled => (
        l10n.locationServiceDisabledBody,
        l10n.turnOnLocationButton,
        () async {
          await Geolocator.openLocationSettings();
          onRetry();
        },
      ),
      LocationStatus.permissionDeniedForever => (
        l10n.locationPermissionDeniedBody,
        l10n.openSettingsButton,
        () async {
          await Geolocator.openAppSettings();
          onRetry();
        },
      ),
      LocationStatus.permissionDenied => (
        l10n.locationPermissionDeniedBody,
        l10n.grantPermissionButton,
        onRetry,
      ),
      _ => (l10n.locationPermissionDeniedBody, l10n.tryAgainButton, onRetry),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          const FaIcon(
            FontAwesomeIcons.locationDot,
            size: 30,
            color: AppColors.muted,
          ),
          const SizedBox(height: 14),
          Text(
            message ?? l10n.turnOnLocationTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: buttonLabel, onTap: action),
          ),
        ],
      ),
    );
  }
}
