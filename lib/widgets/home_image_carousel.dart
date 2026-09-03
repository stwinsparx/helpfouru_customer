import 'dart:async';
import 'package:flutter/material.dart';
import '../models/home_data.dart';
import '../theme/app_theme.dart';

/// Pulsing placeholder shown in place of [HomeImageCarousel] while the
/// home sliders are still loading.
class HomeSliderSkeleton extends StatefulWidget {
  const HomeSliderSkeleton({super.key});

  @override
  State<HomeSliderSkeleton> createState() => _HomeSliderSkeletonState();
}

class _HomeSliderSkeletonState extends State<HomeSliderSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: FadeTransition(
              opacity: _opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF1F5),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: i == 0 ? 16 : 10,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EBF0),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Auto-advancing, swipeable image carousel for API-driven home sliders.
class HomeImageCarousel extends StatefulWidget {
  const HomeImageCarousel({super.key, required this.slides, this.onTap});

  final List<HomeImage> slides;
  final ValueChanged<HomeImage>? onTap;

  @override
  State<HomeImageCarousel> createState() => _HomeImageCarouselState();
}

class _HomeImageCarouselState extends State<HomeImageCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  static const double _viewportFraction = 0.86;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
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
          aspectRatio: 16 / 8,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final slide = widget.slides[i];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double page = i.toDouble();
                  if (_controller.position.haveDimensions) {
                    page = _controller.page ?? _page.toDouble();
                  }
                  final delta = (page - i).clamp(-1.0, 1.0).abs();
                  final scale = 1 - (delta * 0.06);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: _HomeImageCard(
                  slide: slide,
                  onTap: widget.onTap == null
                      ? null
                      : () => widget.onTap!(slide),
                ),
              );
            },
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.slides.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: active ? 16 : 10,
                height: 3,
                decoration: BoxDecoration(
                  color: active ? AppColors.green : const Color(0xFFD5DEE6),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _HomeImageCard extends StatelessWidget {
  const _HomeImageCard({required this.slide, this.onTap});
  final HomeImage slide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEDF1F5),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Image.network(
          slide.image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}

/// Single full-width promotional banner image.
class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({super.key, required this.banner, this.onTap});
  final HomeImage banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Material(
        color: const Color(0xFFEDF1F5),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Image.network(
            banner.image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid of gallery images shown at the bottom of the home screen.
class HomeGalleryGrid extends StatelessWidget {
  const HomeGalleryGrid({super.key, required this.images, this.onTap});
  final List<HomeImage> images;
  final ValueChanged<HomeImage>? onTap;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (_, i) {
        final image = images[i];
        return Material(
          color: const Color(0xFFEDF1F5),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null ? null : () => onTap!(image),
            child: Image.network(
              image.image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
