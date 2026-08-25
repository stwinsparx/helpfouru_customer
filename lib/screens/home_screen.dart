import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/provider_card.dart';
import '../widgets/promo_carousel.dart';
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
  Map<String, dynamic>? _homeData;
  bool _isLoading = true;

  static const _cats = <(FaIconData, String)>[
    (FontAwesomeIcons.bolt, 'Electrician'),
    (FontAwesomeIcons.wrench, 'Plumber'),
    (FontAwesomeIcons.snowflake, 'AC Repair'),
    (FontAwesomeIcons.broom, 'Cleaning'),
    (FontAwesomeIcons.hammer, 'Carpenter'),
    (FontAwesomeIcons.paintRoller, 'Painter'),
    (FontAwesomeIcons.car, 'Car Wash'),
    (FontAwesomeIcons.plug, 'Appliance'),
    (FontAwesomeIcons.key, 'Locksmith'),
    (FontAwesomeIcons.boxOpen, 'Packers'),
    (FontAwesomeIcons.scissors, 'Beauty'),
    (FontAwesomeIcons.ellipsis, 'View All'),
  ];

  static const _popular = {'AC Repair', 'Electrician', 'Cleaning', 'Plumber'};

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    try {
      final response = await _apiService.get('/customer/home');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        setState(() => _homeData = response.data['data']);
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
    return Container(
      color: AppColors.homeBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(onProviders: () => _openProviders(context)),
          const SizedBox(height: 16),

          // ── Explore Services ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHead(
                  title: 'Explore Services',
                  actionLabel: 'View all',
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
                    final (icon, label) = _cats[i];
                    return _CategoryTile(
                      icon: icon,
                      label: label,
                      popular: _popular.contains(label),
                      onTap: () {
                        state.selectCategory(label);
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
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: PromoCard(
                slide: PromoSlide(
                  eyebrow: 'LIMITED TIME OFFER',
                  title: 'Flat ₹100 off your first booking',
                  subtitle: 'Use code WELCOME100 at checkout on any service.',
                  gradient: AppGradients.banner,
                  icon: FontAwesomeIcons.tags,
                  onTap: () => _openProviders(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Why customers choose HelpFourU ──────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHead(title: 'Why customers choose HelpFourU'),
                _Recommendation(
                  icon: FontAwesomeIcons.circleCheck,
                  title: 'Verified professionals',
                  body:
                      'Identity and service experience checks before joining.',
                ),
                _Recommendation(
                  icon: FontAwesomeIcons.solidStar,
                  title: 'Real ratings & reviews',
                  body: 'Compare service quality before you book.',
                ),
                _Recommendation(
                  icon: FontAwesomeIcons.indianRupeeSign,
                  title: 'Transparent pricing',
                  body: 'See service price, add-ons and total before payment.',
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
                  title: 'Top Rated Near You',
                  actionLabel: 'See all',
                  onAction: () => _openProviders(context),
                ),
                ProviderCard(
                  name: 'Rajesh Kumar',
                  role: 'AC Specialist',
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
                  role: 'Electrician',
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Can't find the right professional?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Publish your requirement and let nearby providers send you offers.',
                          style: TextStyle(
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
                    child: const Text(
                      'Start Bidding',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide content for the promo carousel under the home search bar.
List<PromoSlide> _promoSlides(BuildContext context) {
  return [
    PromoSlide(
      eyebrow: 'NEW ON HELPFOURU',
      title: 'Deep home cleaning\nstarting at ₹499',
      subtitle: 'Book a verified cleaning expert in under 2 minutes.',
      gradient: AppGradients.hero,
      icon: FontAwesomeIcons.broom,
      onTap: () {
        AppStateScope.of(context).selectCategory('Cleaning');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProvidersScreen()));
      },
    ),
    PromoSlide(
      eyebrow: 'REFER & EARN',
      title: 'Give ₹150, get ₹150',
      subtitle: 'Invite friends to HelpFourU and earn wallet credit.',
      gradient: AppGradients.purpleBlue,
      icon: FontAwesomeIcons.gift,
      onTap: () => showAppToast(context, 'Referral screen opened'),
    ),
    PromoSlide(
      eyebrow: 'AC SEASON SPECIAL',
      title: 'AC service at flat ₹399',
      subtitle: 'Beat the heat with our top-rated technicians.',
      gradient: AppGradients.brand,
      icon: FontAwesomeIcons.snowflake,
      onTap: () {
        AppStateScope.of(context).selectCategory('AC Repair');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProvidersScreen()));
      },
    ),
  ];
}

class _Header extends StatelessWidget {
  const _Header({required this.onProviders});
  final VoidCallback onProviders;

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, Shubham',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'How can we help today?',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '⌖ Udaipur, Rajasthan · Home',
                          style: TextStyle(
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
                      child: const Text(
                        'SK',
                        style: TextStyle(
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
                child: const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 14,
                      color: Color(0xFF8391A3),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search services, providers or anything you need',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8391A3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Promo slider.
              PromoCarousel(slides: _promoSlides(context)),
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
                            const Text(
                              'HELPFOURU · TRUSTED HOME SERVICES',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Reliable help.\nRight when you need it.',
                              style: TextStyle(
                                fontSize: 21,
                                height: 1.18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Discover verified professionals near you, compare profiles and book in a few simple steps.',
                              style: TextStyle(
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
                                  label: 'Find a Professional',
                                  trailing: FontAwesomeIcons.arrowRight,
                                  onTap: onProviders,
                                ),
                                _HeroButton(
                                  label: 'Post a Job',
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
                    label: 'My Orders',
                    onTap: () => AppShell.goToTab(context, 1),
                  ),
                  _QuickAction(
                    icon: FontAwesomeIcons.locationCrosshairs,
                    label: 'Track Order',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrackingScreen()),
                    ),
                  ),
                  _QuickAction(
                    icon: FontAwesomeIcons.gavel,
                    label: 'Post Bid',
                    onTap: () => AppShell.goToTab(context, 2),
                  ),
                  _QuickAction(
                    icon: FontAwesomeIcons.bell,
                    label: 'Alerts',
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
    required this.icon,
    required this.label,
    required this.popular,
    this.onTap,
  });
  final FaIconData icon;
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
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: FaIcon(icon, size: 14, color: AppColors.greenDark),
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
                    child: const Text(
                      'Popular',
                      style: TextStyle(
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
