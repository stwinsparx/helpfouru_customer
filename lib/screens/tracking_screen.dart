import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Fetches and renders `GET /customer/orders/:orderId/track`.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  OrderTrackingResult? _result;

  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    try {
      final response = await _apiService.get(
        '/customer/orders/${widget.orderId}/track',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        setState(
          () => _result = OrderTrackingResult.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
    } catch (e) {
      debugPrint('Order tracking API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static FaIconData _stepIcon(TrackingStep step) =>
      step.completed && !step.current
      ? FontAwesomeIcons.check
      : FontAwesomeIcons.circle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.screenBg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: MiniHeader(title: l10n.trackOrderTitle),
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.screenBg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              MiniHeader(title: l10n.trackOrderTitle),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    l10n.orderTrackingUnavailable,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final order = result.order;
    final provider = result.provider;

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.trackOrderTitle),

            AppCard(
              radius: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.displayService,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pill(label: order.statusLabel, fontSize: 9.5),
                ],
              ),
            ),

            if (provider != null) ...[
              const _MapArt(),
              const SizedBox(height: 10),
              AppCard(
                radius: 14,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.providerAvatar,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          provider.profileImage != null &&
                              provider.profileImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: provider.profileImage!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const FaIcon(
                                    FontAwesomeIcons.userGear,
                                    size: 16,
                                    color: AppColors.blueDark,
                                  ),
                            )
                          : const FaIcon(
                              FontAwesomeIcons.userGear,
                              size: 16,
                              color: AppColors.blueDark,
                            ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.statusLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider.phone != null && provider.phone!.isNotEmpty)
                      GestureDetector(
                        onTap: () =>
                            launchPhoneDialer(context, provider.phone!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7EF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.phone,
                                size: 12,
                                color: AppColors.greenDark,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.call,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 8),

            ...List.generate(result.timeline.length, (i) {
              final step = result.timeline[i];
              return _TimelineStep(
                title: step.label,
                subtitle: step.timestamp != null
                    ? _formatTimestamp(step.timestamp!)
                    : (step.current ? l10n.inProgressLabel : l10n.pendingLabel),
                kind: step.completed && !step.current
                    ? 0
                    : (step.current ? 1 : 2),
                icon: _stepIcon(step),
                isLast: i == result.timeline.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _MapArt extends StatelessWidget {
  const _MapArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFFDFE9E4), Color(0xFFEDF3F7)],
        ),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // Two crossing "roads".
            Positioned(
              left: -40,
              right: -40,
              top: 90,
              child: Transform.rotate(
                angle: -0.384, // -22deg
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD6E0E8)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              right: -40,
              top: 120,
              child: Transform.rotate(
                angle: 0.436, // 25deg
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD6E0E8)),
                  ),
                ),
              ),
            ),
            // Location pin.
            const Positioned(
              left: 0,
              right: 0,
              top: 62,
              child: Align(
                alignment: Alignment(0.32, 0),
                child: FaIcon(
                  FontAwesomeIcons.locationDot,
                  size: 34,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.icon,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final int kind; // 0 done, 1 current, 2 pending
  final FaIconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final active = kind != 2;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.mint : const Color(0xFFDCE5EC),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  icon,
                  size: kind == 0 ? 11 : 9,
                  color: active ? AppColors.greenDark : AppColors.muted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: active
                        ? AppColors.mintBorder
                        : const Color(0xFFDCE5EC),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
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
