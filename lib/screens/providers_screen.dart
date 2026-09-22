import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/provider_card.dart';
import 'provider_profile_screen.dart';
import 'subcategory_screen.dart';
import 'booking_screen.dart';

/// Fetches `GET /customer/services/:categoryId/providers` for [categoryId],
/// re-fetching with `sub_category_id`/`filter_id` set whenever either
/// selection changes.
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
/// the filter sheet. A FAB lets the user reopen the sheet afterward to
/// change the selection, regardless of how the screen was entered.
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
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<ServiceSubCategory> _subCategories = [];
  List<ServiceFilter> _serviceFilters = [];
  List<ProviderListing> _providers = [];
  int? _selectedSubCategoryId;
  int? _selectedFilterId;

  /// Set once the initial fetch resolves, so the mandatory sub-category
  /// sheet is only ever auto-shown the first time — subsequent re-fetches
  /// (from picking a filter, or from the FAB) must not re-trigger it. Also
  /// pre-set to true when [ProvidersScreen.initialSubCategoryId] is given,
  /// since the caller already resolved sub-category selection for us.
  late bool _hasPromptedSubCategory = widget.initialSubCategoryId != null;

  @override
  void initState() {
    super.initState();
    _selectedFilterId = widget.initialFilterId;
    _selectedSubCategoryId = widget.initialSubCategoryId;
    _fetchProviders(
      subCategoryId: _selectedSubCategoryId,
      filterId: _selectedFilterId,
    );
  }

  Future<void> _fetchProviders({int? subCategoryId, int? filterId}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        '/customer/services/${widget.categoryId}/providers',
        queryParameters: {
          'sub_category_id': ?subCategoryId,
          'filter_id': ?filterId,
        },
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final result = ProvidersResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() {
          _subCategories = result.subCategories;
          _serviceFilters = result.serviceFilters;
          _providers = result.providers;
        });
      }
    } catch (e) {
      debugPrint('Providers API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!_hasPromptedSubCategory) {
      _hasPromptedSubCategory = true;
      _promptSubCategoryIfNeeded();
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

  void _applySubCategory(ServiceSubCategory subCategory) {
    AppStateScope.of(
      context,
    ).selectSub(subCategory.id, subCategory.categoryName);
    setState(() => _selectedSubCategoryId = subCategory.id);
    _fetchProviders(subCategoryId: subCategory.id, filterId: _selectedFilterId);
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

  void _selectFilter(ServiceFilter? filter) {
    setState(() => _selectedFilterId = filter?.id);
    _fetchProviders(
      subCategoryId: _selectedSubCategoryId,
      filterId: filter?.id,
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
            else if (_providers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    l10n.noProvidersFound,
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
                  profileImage: p.profileImage,
                  isVerified: p.isVerifiedProvider,
                  jobs: l10n.jobsCount(p.completedJobs),
                  onViewProfile: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(providerId: p.id),
                    ),
                  ),
                  onBook: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(serviceId: p.serviceId),
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
