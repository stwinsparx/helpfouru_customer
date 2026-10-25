import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'order_detail_screen.dart';
import 'tracking_screen.dart';

/// Fetches and renders `GET /customer/orders`.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _apiService = ApiService();
  int _tab = 0;
  bool _isLoading = true;
  List<OrderSummary> _orders = const [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/customer/orders');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final page = OrdersPage.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() => _orders = page.orders);
      }
    } catch (e) {
      debugPrint('Orders API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrderSummary> _filteredOrders() => switch (_tab) {
    1 => _orders.where((o) => !o.isFinished).toList(),
    2 => _orders.where((o) => o.status == 'completed').toList(),
    3 => _orders.where((o) => o.status == 'cancelled').toList(),
    _ => _orders,
  };

  void _trackOrder(int orderId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TrackingScreen(orderId: orderId)));
  }

  void _openOrderDetail(int orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      l10n.orderTabAll,
      l10n.orderTabUpcoming,
      l10n.orderTabCompleted,
      l10n.orderTabCancelled,
    ];
    final orders = _filteredOrders();

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _fetchOrders,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.myOrdersTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (i) => FilterChipButton(
                      label: tabs[i],
                      selected: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      l10n.noOrdersFound,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                )
              else
                ...orders.map(
                  (order) => _OrderCard(
                    order: order,
                    onTrack: () => _trackOrder(order.id),
                    onTap: () => _openOrderDetail(order.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTrack,
    required this.onTap,
  });

  final OrderSummary order;
  final VoidCallback onTrack;

  /// Opens the order detail screen — tapping anywhere on the card except
  /// the "Track Status" action, which has its own distinct tap target.
  final VoidCallback onTap;

  (Color, Color, FaIconData) _statusStyle() => switch (order.status) {
    'completed' => (
      const Color(0xFFE7F8F1),
      AppColors.success,
      FontAwesomeIcons.circleCheck,
    ),
    'cancelled' => (
      const Color(0xFFFDE9E9),
      AppColors.danger,
      FontAwesomeIcons.circleXmark,
    ),
    _ => (
      AppColors.mint,
      AppColors.greenDark,
      FontAwesomeIcons.clockRotateLeft,
    ),
  };

  String _initials() {
    final name = order.providerName?.trim();
    if (name == null || name.isEmpty) return '';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toLowerCase();
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour24 = dt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month - 1]}, $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (statusBg, statusFg, statusIcon) = _statusStyle();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
            // Matches the Explore Services category tiles' lifted look on
            // Home.
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A143250),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pill(
                    label: order.statusLabel,
                    background: statusBg,
                    foreground: statusFg,
                    fontSize: 9.5,
                    icon: statusIcon,
                  ),
                  const Spacer(),
                  Text(
                    order.displayPrice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.serviceSubCategoryName?.isNotEmpty == true
                    ? order.serviceSubCategoryName!
                    : (order.serviceCategoryName ?? '#${order.orderNumber}'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (order.serviceCategoryName != null &&
                  order.serviceCategoryName !=
                      order.serviceSubCategoryName) ...[
                const SizedBox(height: 2),
                Text(
                  order.serviceCategoryName!,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              if (order.providerName != null ||
                  order.providerPhone != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.user,
                      size: 11,
                      color: AppColors.muted,
                    ),
                    if (_initials().isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Text(
                        _initials(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    if (order.providerPhone != null) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () =>
                            launchPhoneDialer(context, order.providerPhone!),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.phone,
                              size: 11,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              order.providerPhone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: FontAwesomeIcons.circlePlay,
                      label: l10n.startedAtLabel,
                      value: order.jobStartTime != null
                          ? _formatDateTime(order.jobStartTime!)
                          : l10n.notStartedPlaceholder,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                      icon: FontAwesomeIcons.clipboard,
                      label: l10n.assignedAtLabel,
                      value: order.assignedTime != null
                          ? _formatDateTime(order.assignedTime!)
                          : l10n.notStartedPlaceholder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(label: l10n.trackStatus, onTap: onTrack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final FaIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 10, color: AppColors.muted),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
