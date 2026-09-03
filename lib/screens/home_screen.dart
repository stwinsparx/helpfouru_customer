import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/current_user.dart';
import '../models/home_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/provider_card.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/home_image_carousel.dart';
import 'providers_screen.dart';
import 'provider_profile_screen.dart';
import 'booking_screen.dart';
import 'tracking_screen.dart';
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

  /// (icon asset, canonical category key). The key drives [AppState]
  /// matching and is localized for display via [localizedServiceName].
  static const _cats = <(String, String)>[
    ('assets/icons/categories/electrician.svg', 'Electrician'),
    ('assets/icons/categories/plumber.svg', 'Plumber'),
    ('assets/icons/categories/ac_repair.svg', 'AC Repair'),
    ('assets/icons/categories/cleaning.svg', 'Cleaning'),
    ('assets/icons/categories/carpenter.svg', 'Carpenter'),
    ('assets/icons/categories/painter.svg', 'Painter'),
    ('assets/icons/categories/car_wash.svg', 'Car Wash'),
    ('assets/icons/categories/appliance.svg', 'Appliance'),
    ('assets/icons/categories/locksmith.svg', 'Locksmith'),
    ('assets/icons/categories/packers.svg', 'Packers'),
    ('assets/icons/categories/beauty.svg', 'Beauty'),
    ('assets/icons/categories/view_all.svg', 'View All'),
  ];

  static const _popular = {'AC Repair', 'Electrician', 'Cleaning', 'Plumber'};

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await CurrentUser.load();
    if (mounted) setState(() => _currentUser = user);
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

  void _openProviders(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ProvidersScreen()));

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      color: AppColors.homeBg,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _fetchHomeData,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
          _Header(
            onProviders: () => _openProviders(context),
            sliders: _homeData?.homeSliders ?? const [],
            isLoadingSliders: _isLoading,
            user: _currentUser,
          ),
          const SizedBox(height: 16),

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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cats.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 0.80,
                  ),
                  itemBuilder: (_, i) {
                    final (iconAsset, key) = _cats[i];
                    return _CategoryTile(
                      iconAsset: iconAsset,
                      label: localizedServiceName(context, key),
                      popular: _popular.contains(key),
                      onTap: () {
                        state.selectCategory(key);
                        _openProviders(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Promo banner ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: _homeData?.homeBanner != null
                ? HomeBannerCard(
                    banner: _homeData!.homeBanner!,
                    onTap: () => _openHomeImage(context, _homeData!.homeBanner!),
                  )
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PromoCard(
                      slide: PromoSlide(
                        eyebrow: l10n.limitedTimeOffer,
                        title: l10n.flatOffFirstBooking,
                        subtitle: l10n.useCodeWelcome100,
                        gradient: AppGradients.banner,
                        icon: FontAwesomeIcons.tags,
                        onTap: () => _openProviders(context),
                      ),
                    ),
                  ),
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

          // ── Top Rated Near You ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHead(
                  title: l10n.topRatedNearYou,
                  actionLabel: l10n.seeAll,
                  onAction: () => _openProviders(context),
                ),
                ProviderCard(
                  name: 'Rajesh Kumar',
                  role: localizedServiceName(context, 'AC Repair'),
                  rating: '4.9',
                  price: '₹499 onwards',
                  distance: '2.1 km',
                  onViewProfile: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProviderProfileScreen(),
                    ),
                  ),
                  onBook: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BookingScreen()),
                  ),
                ),
                ProviderCard(
                  name: 'Amit Sharma',
                  role: localizedServiceName(context, 'Electrician'),
                  rating: '4.8',
                  price: '₹299 onwards',
                  distance: '1.4 km',
                  onViewProfile: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProviderProfileScreen(),
                    ),
                  ),
                  onBook: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BookingScreen()),
                  ),
                ),
              ],
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
    required this.onProviders,
    this.sliders = const [],
    this.isLoadingSliders = false,
    this.user,
  });
  final VoidCallback onProviders;
  final List<HomeImage> sliders;
  final bool isLoadingSliders;
  final CurrentUser? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null
                              ? l10n.goodMorningWithName(user!.name.split(' ').first)
                              : l10n.goodMorning,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.howCanWeHelpToday,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.homeLocationLine,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AppShell.goToTab(context, 4),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.avatar,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search bar (visual, matching the prototype's static field).
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F9),
                  border: Border.all(color: const Color(0xFFE6EDF3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 14,
                      color: Color(0xFF8391A3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.searchServicesHint,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8391A3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Promo slider — API-driven images, with a skeleton shown
              // while loading instead of any static placeholder content.
              if (isLoadingSliders)
                const HomeSliderSkeleton()
              else if (sliders.isNotEmpty)
                HomeImageCarousel(
                  slides: sliders,
                  onTap: (slide) => _openHomeImage(context, slide),
                ),
              const SizedBox(height: 14),

              // Hero card.
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: const BoxDecoration(gradient: AppGradients.hero),
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
                            // Wrap (not Row) so the pair reflows instead of
                            // overflowing on narrow screens.
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _HeroButton(
                                  label: l10n.findAProfessional,
                                  trailing: FontAwesomeIcons.arrowRight,
                                  onTap: onProviders,
                                ),
                                _HeroButton(
                                  label: l10n.postAJob,
                                  ghost: true,
                                  onTap: () => AppShell.goToTab(context, 2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick actions.
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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrackingScreen()),
                    ),
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
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    this.onTap,
    this.ghost = false,
    this.trailing,
  });
  final String label;
  final VoidCallback? onTap;
  final bool ghost;
  final FaIconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ghost ? const Color(0x24FFFFFF) : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: ghost ? Border.all(color: const Color(0x33FFFFFF)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ghost ? Colors.white : AppColors.blueDark,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                FaIcon(
                  trailing,
                  size: 10,
                  color: ghost ? Colors.white : AppColors.blueDark,
                ),
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
    required this.iconAsset,
    required this.label,
    required this.popular,
    this.onTap,
  });
  final String iconAsset;
  final String label;
  final bool popular;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A143250),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sized to fill the tile so the column centres against the
              // tile itself, not against its widest child.
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top inset leaves room for the "Popular" badge so it
                    // never crowds the icon on featured tiles.
                    const SizedBox(height: 10),
                    SvgPicture.asset(
                      iconAsset,
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (popular)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppLocalizations.of(context).popularBadge,
                      style: const TextStyle(
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ),
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
