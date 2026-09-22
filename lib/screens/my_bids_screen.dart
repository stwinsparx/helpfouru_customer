import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/bid.dart';
import '../models/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'bid_detail_screen.dart';
import 'bidding_screen.dart';
import 'shell.dart';

/// Bid tab root — fetches and renders `GET /customer/bids`, with a "New
/// Bid" entry point into [BiddingScreen].
class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<BidSummary> _bids = const [];
  CurrentUser? _currentUser;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _fetchBids();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await CurrentUser.load();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _fetchBids() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        '/customer/bids',
        queryParameters: const {'page': 1, 'limit': 20},
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final page = BidsPage.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() => _bids = page.bids);
      }
    } catch (e) {
      debugPrint('My bids API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Status `1` means the bid is still active/accepting offers — see
  /// [BidSummary.status].
  List<BidSummary> get _openBids => _bids.where((b) => b.status == 1).toList();

  List<BidSummary> get _visibleBids => _tab == 1 ? _openBids : _bids;

  Future<void> _openBid(int id) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => BidDetailScreen(bidId: id)));
    if (changed == true) _fetchBids();
  }

  Future<void> _createBid() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const BiddingScreen()));
    if (created == true) _fetchBids();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visibleBids = _visibleBids;
    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _fetchBids,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => AppShell.goToTab(context, 4),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: AppGradients.avatar,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _currentUser?.initials ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.myBidsTitle,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => AppShell.goToTab(context, 3),
                      child: const FaIcon(
                        FontAwesomeIcons.bell,
                        size: 20,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: _createBid,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.plus,
                          size: 14,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _BidsTabButton(
                        label: l10n.bidsTabAll,
                        count: _bids.length,
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BidsTabButton(
                        label: l10n.bidsTabOpen,
                        count: _openBids.length,
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : visibleBids.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            l10n.noBidsFound,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: visibleBids
                            .map(
                              (bid) => _BidCard(
                                bid: bid,
                                onViewDetails: () => _openBid(bid.id),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BidsTabButton extends StatelessWidget {
  const _BidsTabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.green : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? const Color(0x33FFFFFF) : AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.greenDark,
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

class _BidCard extends StatelessWidget {
  const _BidCard({required this.bid, required this.onViewDetails});

  final BidSummary bid;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.briefcase,
                  size: 17,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (bid.bidEndDate != null &&
                        bid.bidEndDate!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.endsOnLabel(formatBidDate(bid.bidEndDate!)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bid.displayBudget,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.bidAmountLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: FontAwesomeIcons.calendarDays,
                  label: l10n.workingDaysLabel,
                  value: bid.estimatedWorkingDays != null
                      ? l10n.completionDaysLabel(bid.estimatedWorkingDays!)
                      : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  icon: FontAwesomeIcons.calendarXmark,
                  label: l10n.bidEndsLabel,
                  value: bid.bidEndDate != null && bid.bidEndDate!.isNotEmpty
                      ? formatBidDate(bid.bidEndDate!)
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.greenDark,
                side: const BorderSide(color: AppColors.mintBorder),
                backgroundColor: AppColors.mint,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(l10n.viewDetails),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 11, color: AppColors.greenDark),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
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
