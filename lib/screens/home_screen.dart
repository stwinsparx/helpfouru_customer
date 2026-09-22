import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../core/services/device_info_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/current_user.dart';
import '../models/home_data.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/home_image_carousel.dart';
import '../widgets/service_selection_sheets.dart';
import 'providers_screen.dart';
import 'shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  HomeData? _homeData;
  bool _isLoading = true;
  CurrentUser? _currentUser;
  String? _currentAddress;

  List<ServiceCategory> _categories = [];
  bool _isLoadingCategories = true;

  List<PopularService> _popularServices = [];
  bool _isLoadingPopularServices = true;

  /// Local SVG fallback icons for known category names, used only when the
  /// API doesn't provide an `image` for that category. Matched via
  /// substring against the lowercased `category_name`, so variants like
  /// "AC Repair & Service" or "Home Cleaning" still resolve — see
  /// [_localIconFor].
  static const _localIcons = <String, String>{
    'electric': 'assets/icons/categories/electrician.svg',
    'plumb': 'assets/icons/categories/plumber.svg',
    'ac repair': 'assets/icons/categories/ac_repair.svg',
    'ac service': 'assets/icons/categories/ac_repair.svg',
    'clean': 'assets/icons/categories/cleaning.svg',
    'carpen': 'assets/icons/categories/carpenter.svg',
    'paint': 'assets/icons/categories/painter.svg',
    'car wash': 'assets/icons/categories/car_wash.svg',
    'appliance': 'assets/icons/categories/appliance.svg',
    'locksmith': 'assets/icons/categories/locksmith.svg',
    'packers': 'assets/icons/categories/packers.svg',
    'beaut': 'assets/icons/categories/beauty.svg',
  };

  static const _defaultIcon = 'assets/icons/categories/view_all.svg';

  /// Finds the local SVG asset whose key is a substring of [categoryName]
  /// (case-insensitive), falling back to [_defaultIcon] when nothing
  /// matches — so near-miss category names from the API (e.g. "AC Repair &
  /// Service", "Home Cleaning") still get a category-specific icon instead
  /// of the generic placeholder.
  static String _localIconFor(String categoryName) {
    final name = categoryName.toLowerCase();
    for (final entry in _localIcons.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return _defaultIcon;
  }

  /// Pastel tint backgrounds cycled across the Explore Services tiles.
  static const _tintPalette = [
    Color(0xFFE3F6E9),
    Color(0xFFFFF3D6),
    Color(0xFFDDEEFB),
    Color(0xFFFCE4E4),
    Color(0xFFE1EEFC),
    Color(0xFFFCE6F0),
    Color(0xFFEAE3FB),
    Color(0xFFE1F5EA),
  ];

  /// How many category tiles to show before collapsing the rest behind a
  /// "More Services" tile.
  static const _maxVisibleCategories = 7;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    _fetchCategories();
    _fetchPopularServices();
    _loadCurrentUser();
    _loadCurrentAddress();
  }

  /// Reloads every dashboard data source in parallel — bound to the pull-to-
  /// refresh gesture so a single pull refreshes the whole screen, not just
  /// the home banner/slider data.
  Future<void> _refreshDashboard() => Future.wait([
    _fetchHomeData(),
    _fetchCategories(),
    _fetchPopularServices(),
    _loadCurrentUser(),
    _loadCurrentAddress(),
  ]);

  Future<void> _loadCurrentUser() async {
    final user = await CurrentUser.load();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _loadCurrentAddress() async {
    final address = await DeviceInfoService.currentAddress();
    if (mounted) setState(() => _currentAddress = address);
  }

  Future<void> _fetchHomeData() async {
    try {
      final response = await _apiService.get('/customer/home');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        setState(
          () => _homeData = HomeData.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
    } catch (e) {
      debugPrint('Home API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _apiService.get('/customer/services');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final categories = (data['categories'] as List<dynamic>? ?? [])
            .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() => _categories = categories);
      }
    } catch (e) {
      debugPrint('Services API error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchPopularServices() async {
    try {
      final response = await _apiService.get('/customer/services/popular');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final popularServices =
            (data['popularServices'] as List<dynamic>? ?? [])
                .map((e) => PopularService.fromJson(e as Map<String, dynamic>))
                .toList();
        setState(() => _popularServices = popularServices);
      }
    } catch (e) {
      debugPrint('Popular services API error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPopularServices = false);
    }
  }

  /// Opens the providers list. The providers endpoint is scoped to a single
  /// category, so generic "browse everything" entry points (hero button,
  /// "view all", promo banner, the CTA card) default to the first fetched
  /// category. If categories haven't loaded yet (or none exist), this
  /// no-ops with a toast rather than opening a screen with no category to
  /// fetch against.
  void _openProviders(BuildContext context) {
    if (_categories.isEmpty) {
      showAppToast(context, AppLocalizations.of(context).noCategoriesFound);
      return;
    }
    _openCategory(context, _categories.first);
  }

  /// Tapping a category runs a mandatory filter-selection step before
  /// landing on the provider list:
  ///  1. Fetch `/customer/services/:categoryId/providers` once, unfiltered,
  ///     to get `serviceFilters` (and an initial provider list, which is
  ///     discarded here — [ProvidersScreen] re-fetches with whatever filter
  ///     ends up chosen).
  ///  2. Show the filter sheet, if any filters exist. Dismissing it without
  ///     picking one (X, tap-outside, back) cancels the whole flow — the
  ///     user stays on Home, no provider list opens. Skipped entirely (not
  ///     shown, not required) when there are no filters to choose from.
  ///  3. Push [ProvidersScreen], which itself shows the (also mandatory)
  ///     sub-category sheet once it has loaded — see that screen for why
  ///     sub-category selection happens there rather than here.
  Future<void> _openCategory(
    BuildContext context,
    ServiceCategory category,
  ) async {
    final state = AppStateScope.of(context);
    state.selectCategory(category.id, category.categoryName);

    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    ProvidersResult? result;
    try {
      final response = await _apiService.get(
        '/customer/services/${category.id}/providers',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        result = ProvidersResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Providers API error: $e');
    }
    if (!context.mounted) return;
    navigator.pop(); // dismiss the loading dialog

    int? filterId;
    final filters = result?.serviceFilters ?? const [];
    if (filters.isNotEmpty) {
      if (!context.mounted) return;
      final filter = await showFilterSheet(context, filters: filters);
      if (filter == null) return; // dismissed without picking — cancel
      filterId = filter.id;
    }

    if (!context.mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            ProvidersScreen(categoryId: category.id, initialFilterId: filterId),
      ),
    );
  }

  /// Popular Services entries are either a top-level category or a
  /// sub-category (`parentId` tells which) — see [PopularService.isTopLevel].
  /// A top-level entry runs the exact same filter → providers flow as an
  /// Explore Services tile. A sub-category entry already names both its
  /// owning category (`parentId`) and itself, so it skips category-level
  /// browsing (and the mandatory sub-category prompt) entirely and lands
  /// straight on that sub-category's provider list.
  void _openPopularService(BuildContext context, PopularService service) {
    if (service.isTopLevel) {
      _openCategory(
        context,
        ServiceCategory(id: service.id, categoryName: service.categoryName),
      );
      return;
    }
    final state = AppStateScope.of(context);
    state.selectCategory(service.parentId!, service.categoryName);
    state.selectSub(service.id, service.categoryName);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProvidersScreen(
          categoryId: service.parentId!,
          initialSubCategoryId: service.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: AppColors.homeBg,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _refreshDashboard,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(
              user: _currentUser,
              address: _currentAddress,
              sliders: _homeData?.homeSliders ?? const [],
              isLoadingSliders: _isLoading,
              onTapSearch: () => _openProviders(context),
            ),
            const SizedBox(height: 20),

            // ── Quick Actions ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHead(
                    title: l10n.quickActions,
                    actionLabel: l10n.viewAll,
                    onAction: () => AppShell.goToTab(context, 1),
                  ),
                  Row(
                    children: [
                      _QuickAction(
                        icon: FontAwesomeIcons.receipt,
                        label: l10n.myOrders,
                        onTap: () => AppShell.goToTab(context, 1),
                      ),
                      _QuickAction(
                        icon: FontAwesomeIcons.locationCrosshairs,
                        label: l10n.trackOrder,
                        onTap: () => AppShell.goToTab(context, 1),
                      ),
                      _QuickAction(
                        icon: FontAwesomeIcons.gavel,
                        label: l10n.postBid,
                        onTap: () => AppShell.goToTab(context, 2),
                      ),
                      _QuickAction(
                        icon: FontAwesomeIcons.bell,
                        label: l10n.alerts,
                        onTap: () => AppShell.goToTab(context, 3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Explore Services ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHead(
                    title: l10n.exploreServices,
                    actionLabel: l10n.viewAll,
                    onAction: () => _openProviders(context),
                  ),
                  if (_isLoadingCategories)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.noCategoriesFound,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final showMoreTile =
                            _categories.length > _maxVisibleCategories;
                        final visibleCount = showMoreTile
                            ? _maxVisibleCategories
                            : _categories.length;
                        final itemCount = visibleCount + (showMoreTile ? 1 : 0);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: itemCount,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 9,
                                childAspectRatio: 0.95,
                              ),
                          itemBuilder: (_, i) {
                            if (showMoreTile && i == visibleCount) {
                              return _CategoryTile(
                                label: l10n.moreServices,
                                tint: const Color(0xFFEFF2F6),
                                iconWidget: const Icon(
                                  Icons.grid_view_rounded,
                                  size: 20,
                                  color: AppColors.muted,
                                ),
                                onTap: () => _openProviders(context),
                              );
                            }
                            final cat = _categories[i];
                            return _CategoryTile(
                              iconUrl: cat.image,
                              localIconAsset: _localIconFor(cat.categoryName),
                              label: cat.categoryName,
                              tint: _tintPalette[i % _tintPalette.length],
                              onTap: () => _openCategory(context, cat),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Popular Services ─────────────────────────────────────────
            if (_isLoadingPopularServices || _popularServices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHead(title: l10n.popularServices),
                    if (_isLoadingPopularServices)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _popularServices.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 9,
                              childAspectRatio: 0.95,
                            ),
                        itemBuilder: (_, i) {
                          final service = _popularServices[i];
                          return _CategoryTile(
                            iconUrl: service.image,
                            localIconAsset: _localIconFor(service.categoryName),
                            label: service.categoryName,
                            tint: _tintPalette[i % _tintPalette.length],
                            onTap: () => _openPopularService(context, service),
                          );
                        },
                      ),
                  ],
                ),
              ),
            if (_isLoadingPopularServices || _popularServices.isNotEmpty)
              const SizedBox(height: 14),

            // ── Special offer banner ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: _homeData?.homeBanner != null
                  ? HomeBannerCard(
                      banner: _homeData!.homeBanner!,
                      onTap: () =>
                          _openHomeImage(context, _homeData!.homeBanner!),
                    )
                  : _SpecialOfferBanner(onTap: () => _openProviders(context)),
            ),
            const SizedBox(height: 20),

            // ── Why customers choose HelpFourU ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHead(title: l10n.whyChooseHelpFourU),
                  _Recommendation(
                    icon: FontAwesomeIcons.circleCheck,
                    title: l10n.verifiedProfessionalsTitle,
                    body: l10n.verifiedProfessionalsBody,
                  ),
                  _Recommendation(
                    icon: FontAwesomeIcons.solidStar,
                    title: l10n.realRatingsTitle,
                    body: l10n.realRatingsBody,
                  ),
                  _Recommendation(
                    icon: FontAwesomeIcons.indianRupeeSign,
                    title: l10n.transparentPricingTitle,
                    body: l10n.transparentPricingBody,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Browse providers CTA ─────────────────────────────────────
            // There is no "top rated near you" endpoint yet (no geo-matching
            // on the backend), so rather than ship fake provider names/data
            // this section is a simple CTA into the full providers list.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _openProviders(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.iceBlue,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.userGroup,
                            size: 17,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.browseAllProviders,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n.browseProvidersBody,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const FaIcon(
                          FontAwesomeIcons.chevronRight,
                          size: 13,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Bidding banner ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppGradients.banner,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cantFindProfessional,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            l10n.publishRequirementBanner,
                            style: const TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => AppShell.goToTab(context, 2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.blueDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(
                        l10n.startBidding,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Gallery ──────────────────────────────────────────────────
            if ((_homeData?.gallery.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHead(title: l10n.gallery),
                    HomeGalleryGrid(
                      images: _homeData!.gallery,
                      onTap: (image) => _openHomeImage(context, image),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Handles a tap on an API-driven home image (slider, banner or gallery
/// item) — surfaces the redirect URL if one is set, otherwise no-ops.
void _openHomeImage(BuildContext context, HomeImage image) {
  if (image.redirectUrl == null || image.redirectUrl!.isEmpty) return;
  showAppToast(
    context,
    AppLocalizations.of(context).openingLink(image.redirectUrl!),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    this.user,
    this.address,
    this.sliders = const [],
    this.isLoadingSliders = false,
    this.onTapSearch,
  });

  final CurrentUser? user;
  final String? address;
  final List<HomeImage> sliders;
  final bool isLoadingSliders;
  final VoidCallback? onTapSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.yourLocation,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xD9FFFFFF),
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                address ?? l10n.locationNotAvailable,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AppShell.goToTab(context, 3),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(left: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x24FFFFFF),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AppShell.goToTab(context, 4),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(left: 8),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search bar (visual, matching the prototype's static field).
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onTapSearch,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          size: 19,
                          color: Color(0xFF8391A3),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            l10n.searchServicesHint,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8391A3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Promo slider — API-driven images, with a skeleton shown
              // while loading, and a static fallback hero card otherwise.
              if (isLoadingSliders)
                const HomeSliderSkeleton()
              else if (sliders.isNotEmpty)
                HomeImageCarousel(
                  slides: sliders,
                  onTap: (slide) => _openHomeImage(context, slide),
                )
              else
                _FallbackHeroCard(onTap: onTapSearch),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static hero card shown in place of the API slider when there are no home
/// sliders to display.
class _FallbackHeroCard extends StatelessWidget {
  const _FallbackHeroCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: const BoxDecoration(color: Color(0x1AFFFFFF)),
        child: Stack(
          children: [
            Positioned(
              right: -55,
              top: -55,
              child: Container(
                width: 145,
                height: 145,
                decoration: const BoxDecoration(
                  color: Color(0x1AFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.heroEyebrow,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    l10n.heroTitle,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    l10n.heroBody,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: Color(0xDBFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HeroButton(
                    label: l10n.findAProfessional,
                    trailing: FontAwesomeIcons.arrowRight,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, this.onTap, this.trailing});
  final String label;
  final VoidCallback? onTap;
  final FaIconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                FaIcon(trailing, size: 10, color: AppColors.blueDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});
  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.5),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A143250),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  FaIcon(icon, size: 16, color: AppColors.blueDark),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF53667C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    this.iconUrl,
    this.localIconAsset,
    this.iconWidget,
    required this.label,
    required this.tint,
    this.onTap,
  });

  /// Remote category photo from the API. When present, fills the tile's
  /// circle as a cover photo instead of the small centered SVG glyph.
  final String? iconUrl;
  final String? localIconAsset;

  /// Overrides [iconUrl]/[localIconAsset] entirely — used for the "More
  /// Services" tile, which has no category icon to render.
  final Widget? iconWidget;
  final String label;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipOval(
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                color: tint,
                child: _buildIcon(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (iconWidget != null) return iconWidget!;
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return Image.network(
        iconUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: 24,
          height: 24,
          child: SvgPicture.asset(localIconAsset!, fit: BoxFit.contain),
        ),
      );
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: SvgPicture.asset(localIconAsset!, fit: BoxFit.contain),
    );
  }
}

class _SpecialOfferBanner extends StatelessWidget {
  const _SpecialOfferBanner({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppGradients.banner,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.specialOfferLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xE6FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.flatOffFirstBooking,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HeroButton(
                      label: l10n.bookNow,
                      trailing: FontAwesomeIcons.arrowRight,
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const FaIcon(
                FontAwesomeIcons.sprayCanSparkles,
                size: 44,
                color: Color(0x59FFFFFF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({
    required this.icon,
    required this.title,
    required this.body,
  });
  final FaIconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(11),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.iceBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: FaIcon(icon, size: 17, color: AppColors.blue),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
