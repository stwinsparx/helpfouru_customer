import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_more_services_screen.dart';
import 'edit_addons_screen.dart';

/// Fetches and renders `GET /customer/orders/:orderId` — the primary
/// order's full info and add-ons, plus every sub-order (additional services
/// added onto it after it was placed) with its own status/price/add-ons.
///
/// [orderId] must be a **primary** order's id — this is what both the order
/// list and this screen's own re-fetches (after adding a sub-order) already
/// pass; a sub-order never gets its own row anywhere in this app, so there's
/// no path that could reach this screen with a sub-order id instead.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  OrderDetailResult? _result;

  /// The server's own `message` from a non-success response, or a short
  /// description of what went wrong (network error, unexpected payload
  /// shape) — shown in the empty state instead of a generic string so a
  /// failed load is actually diagnosable instead of just "couldn't load".
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService.get(
        '/customer/orders/${widget.orderId}',
      );
      final isSuccess =
          response.data is Map &&
          (response.data['is_success'] == true ||
              response.data['is_success'] == 1);
      if (response.statusCode == 200 && isSuccess) {
        setState(
          () => _result = OrderDetailResult.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      } else {
        final message = response.data is Map
            ? response.data['message'] as String?
            : null;
        debugPrint(
          'Order detail API error: status=${response.statusCode} '
          'body=${response.data}',
        );
        setState(() => _errorMessage = message);
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? e.response?.data['message'] as String?
          : null;
      debugPrint(
        'Order detail API error: status=${e.response?.statusCode} '
        'body=${e.response?.data} type=${e.type}',
      );
      setState(() => _errorMessage = message);
    } catch (e, st) {
      debugPrint('Order detail API error: $e\n$st');
      setState(() => _errorMessage = null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addMoreServices() async {
    final result = _result;
    if (result == null) return;
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMoreServicesScreen(
          orderId: widget.orderId,
          primaryBookingDate: result.order.bookingDate,
        ),
      ),
    );
    if (added == true) _fetchOrderDetail();
  }

  /// Opens the add-on editor for [order] — the primary order or one of its
  /// sub-orders, whichever this was called for. [order.id] is the specific
  /// order/sub-order id the new add-on selection is saved against;
  /// [order.serviceId] is what its add-on catalog is fetched from.
  Future<void> _editAddons(OrderDetailInfo order) async {
    final serviceId = order.serviceId;
    if (serviceId == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditAddonsScreen(
          orderId: order.id,
          serviceId: serviceId,
          serviceLabel: order.displayService,
          initialAddOnIds: order.addOns
              .map((a) => a.addOnId)
              .whereType<int>()
              .toSet(),
        ),
      ),
    );
    if (saved == true) _fetchOrderDetail();
  }

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
                child: MiniHeader(title: l10n.orderDetailTitle),
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
              MiniHeader(title: l10n.orderDetailTitle),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _errorMessage ?? l10n.orderDetailUnavailable,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _fetchOrderDetail,
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
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _fetchOrderDetail,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              MiniHeader(title: l10n.orderDetailTitle),

              _OrderInfoCard(order: order),

              _AddOnsCard(
                title: l10n.orderAddonsLabel,
                addOns: order.addOns,
                onEdit: order.serviceId != null
                    ? () => _editAddons(order)
                    : null,
              ),

              if (provider != null) _ProviderCard(provider: provider),

              if (result.subOrders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 2),
                  child: Text(
                    l10n.additionalServicesTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                for (final subOrder in result.subOrders)
                  _SubOrderCard(
                    subOrder: subOrder,
                    onEditAddons: subOrder.serviceId != null
                        ? () => _editAddons(subOrder)
                        : null,
                  ),
              ],

              AppCard(
                child: Column(
                  children: [
                    if (result.subOrders.isNotEmpty)
                      TotalRow(
                        label: l10n.grandTotalLabel,
                        value: result.displayGrandTotal,
                      )
                    else
                      TotalRow(
                        label: l10n.totalLabel,
                        value: order.displayPrice,
                      ),
                  ],
                ),
              ),

              if (result.canAddMoreServices) ...[
                const SizedBox(height: 6),
                SecondaryButton(
                  label: l10n.addMoreServices,
                  onTap: _addMoreServices,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});

  final OrderDetailInfo order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.displayService,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (order.orderNumber != null)
                      Text(
                        l10n.orderNumberPrefix(order.orderNumber!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: order.status, label: order.statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          if (order.bookingDate != null)
            _InfoRow(label: l10n.bookingDateLabel, value: order.bookingDate!),
          if (order.bookingSlot != null)
            _InfoRow(label: l10n.bookingSlotLabel, value: order.bookingSlot!),
          _InfoRow(
            label: l10n.serviceLabel,
            value: order.displayPrice,
            emphasise: true,
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});

  final OrderDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
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
                    errorWidget: (context, url, error) => const FaIcon(
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
                  l10n.orderProviderLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (provider.phone != null && provider.phone!.isNotEmpty)
            GestureDetector(
              onTap: () => launchPhoneDialer(context, provider.phone!),
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
    );
  }
}

/// One card per sub-order under "Additional Services" — its own status
/// badge, price and add-ons, independent from the primary order's.
class _SubOrderCard extends StatelessWidget {
  const _SubOrderCard({required this.subOrder, this.onEditAddons});

  final OrderDetailInfo subOrder;

  /// Opens the add-on editor for this specific sub-order — `null` when its
  /// `service_id` isn't known, in which case no "Edit" action is shown.
  final VoidCallback? onEditAddons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  subOrder.displayService,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: subOrder.status, label: subOrder.statusLabel),
            ],
          ),
          const SizedBox(height: 8),
          if (subOrder.bookingSlot != null)
            _InfoRow(
              label: l10n.bookingSlotLabel,
              value: subOrder.bookingSlot!,
            ),
          _InfoRow(
            label: l10n.serviceLabel,
            value: subOrder.displayPrice,
            emphasise: true,
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEF2F5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.orderAddonsLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
              if (onEditAddons != null)
                GestureDetector(
                  onTap: onEditAddons,
                  child: Text(
                    l10n.editAddonsAction,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                ),
            ],
          ),
          if (subOrder.addOns.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final addOn in subOrder.addOns)
              _AddOnLineRow(
                addOn: addOn,
                isLast: addOn == subOrder.addOns.last,
              ),
          ],
        ],
      ),
    );
  }
}

class _AddOnsCard extends StatelessWidget {
  const _AddOnsCard({required this.title, required this.addOns, this.onEdit});

  final String title;
  final List<OrderAddOnLine> addOns;

  /// Opens the add-on editor for the primary order — `null` when its
  /// `service_id` isn't known, in which case no "Edit" action is shown.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Text(
                    l10n.editAddonsAction,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                ),
            ],
          ),
          if (addOns.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final addOn in addOns)
              _AddOnLineRow(addOn: addOn, isLast: addOn == addOns.last),
          ],
        ],
      ),
    );
  }
}

class _AddOnLineRow extends StatelessWidget {
  const _AddOnLineRow({required this.addOn, required this.isLast});

  final OrderAddOnLine addOn;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEDF1F4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              addOn.quantity != null && addOn.quantity! > 1
                  ? '${addOn.itemName} × ${addOn.quantity}'
                  : addOn.itemName,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
            ),
          ),
          Text(
            addOn.displayPrice,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasise ? 14 : 12,
              fontWeight: emphasise ? FontWeight.w900 : FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge — every sub-order carries its own status, independent from
/// the primary order's, so this is always driven by whichever
/// [OrderDetailInfo] (primary or sub-order) it's given.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.label});

  final String status;
  final String label;

  (Color, Color) _statusColors() => switch (status) {
    'completed' => (const Color(0xFFE7F8F1), AppColors.success),
    'cancelled' => (const Color(0xFFFDE9E9), AppColors.danger),
    _ => (AppColors.mint, AppColors.greenDark),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors();
    return Pill(label: label, background: bg, foreground: fg, fontSize: 9.5);
  }
}
