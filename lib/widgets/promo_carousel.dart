import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class PromoSlide {
  const PromoSlide({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final FaIconData icon;
  final VoidCallback? onTap;
}

/// Auto-advancing, swipeable promo carousel for the home dashboard.
///
/// Renders gradient cards rather than photos: the app ships no promo
/// imagery, and this keeps the slider visually consistent with the
/// existing hero/banner cards instead of needing placeholder assets.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.slides});

  final List<PromoSlide> slides;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    final next = (_page + 1) % widget.slides.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: PromoCard(slide: widget.slides[i]),
            ),
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.slides.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.green : const Color(0xFFD5DEE6),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class PromoCard extends StatelessWidget {
  const PromoCard({super.key, required this.slide});
  final PromoSlide slide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: slide.onTap,
        child: Ink(
          decoration: BoxDecoration(gradient: slide.gradient),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -34,
                child: FaIcon(
                  slide.icon,
                  size: 150,
                  color: const Color(0x1FFFFFFF),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      slide.eyebrow,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xDBFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
