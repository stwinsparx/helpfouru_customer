import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/bid.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'bidding_screen.dart';

/// Fetches and renders `GET /customer/bids/:id`.
class BidDetailScreen extends StatefulWidget {
  const BidDetailScreen({super.key, required this.bidId});

  final int bidId;

  @override
  State<BidDetailScreen> createState() => _BidDetailScreenState();
}

class _BidDetailScreenState extends State<BidDetailScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  BidDetailResult? _result;

  /// True once this screen has caused a change (an edit was saved) that the
  /// list screen should refresh for — returned to the caller on pop.
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final response = await _apiService.get('/customer/bids/${widget.bidId}');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        setState(
          () => _result = BidDetailResult.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
    } catch (e) {
      debugPrint('Bid detail API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editBid() async {
    final bid = _result?.bid;
    if (bid == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BiddingScreen(editingBid: bid)),
    );
    if (updated == true) {
      _didChange = true;
      _fetchDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didChange);
      },
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: SafeArea(
          child: _isLoading
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: MiniHeader(
                        title: l10n.bidDetailTitle,
                        onBack: () => Navigator.of(context).pop(_didChange),
                      ),
                    ),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                )
              : _result == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    MiniHeader(
                      title: l10n.bidDetailTitle,
                      onBack: () => Navigator.of(context).pop(_didChange),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          l10n.bidDetailUnavailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : _buildContent(context, l10n, _result!),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    BidDetailResult result,
  ) {
    final bid = result.bid;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: MiniHeader(
                title: l10n.bidDetailTitle,
                onBack: () => Navigator.of(context).pop(_didChange),
              ),
            ),
          ],
        ),

        if (bid.images.isNotEmpty) ...[
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bid.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => showImagePreview(context, imageUrl: bid.images[i]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    bid.images[i],
                    width: 240,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 240,
                      height: 160,
                      color: const Color(0xFFEDF1F5),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (result.totalBids > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mint,
              border: Border.all(color: AppColors.mintBorder),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleCheck,
                  size: 18,
                  color: AppColors.greenDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.youHaveOffersLabel(result.totalBids),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                bid.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            GestureDetector(
              onTap: _editBid,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.iceBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 11,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.editBid,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: FontAwesomeIcons.indianRupeeSign,
                label: l10n.expectedBudgetLabel,
                value: bid.displayBudget,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                icon: FontAwesomeIcons.calendarDays,
                label: l10n.workingDaysLabel,
                value: bid.estimatedWorkingDays != null
                    ? l10n.completionDaysLabel(bid.estimatedWorkingDays!)
                    : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: FontAwesomeIcons.calendarXmark,
                label: l10n.bidEndsLabel,
                value: bid.bidEndDate != null && bid.bidEndDate!.isNotEmpty
                    ? formatBidDate(bid.bidEndDate!)
                    : '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                icon: FontAwesomeIcons.userGroup,
                label: l10n.totalBidsLabel,
                value: '${result.totalBids}',
              ),
            ),
          ],
        ),
        if (bid.bidRegistrationFees != null &&
            bid.bidRegistrationFees != '0' &&
            bid.bidRegistrationFees!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoTile(
            icon: FontAwesomeIcons.receipt,
            label: l10n.registrationFeeLabel,
            value:
                '${bid.displayRegistrationFee} ${bid.isFeesRefundable ? l10n.refundableSuffix : l10n.nonRefundableSuffix}',
            fullWidth: true,
          ),
        ],

        if (bid.city != null && bid.city!.isNotEmpty ||
            bid.bidLocation != null && bid.bidLocation!.isNotEmpty) ...[
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bid.city != null && bid.city!.isNotEmpty)
                  DetailRow(label: l10n.cityLabel, value: bid.city!),
                if (bid.bidLocation != null && bid.bidLocation!.isNotEmpty)
                  DetailRow(
                    label: l10n.locationLabel,
                    value: bid.bidLocation!,
                    showDivider: false,
                  ),
              ],
            ),
          ),
        ],

        if (bid.description != null && bid.description!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            l10n.descriptionLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Text(
              bid.description!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ),
        ],

        if (bid.documents.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            l10n.documentsLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          ...bid.documents.map((doc) => _DocumentRow(url: doc)),
        ],

        const SizedBox(height: 18),
        SectionHead(title: l10n.quotesReceivedTitle),

        if (result.providerBids.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                l10n.noQuotesYet,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ),
          )
        else
          ...result.providerBids.map(
            (quote) => _ProviderQuoteCard(
              quote: quote,
              isLowest: result.lowestBid?.id == quote.id,
            ),
          ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 14, color: AppColors.greenDark),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.fileLines,
            size: 15,
            color: AppColors.greenDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
            ),
          ),
          const FaIcon(
            FontAwesomeIcons.arrowUpRightFromSquare,
            size: 12,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _ProviderQuoteCard extends StatelessWidget {
  const _ProviderQuoteCard({required this.quote, required this.isLowest});

  final ProviderBid quote;
  final bool isLowest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.providerAvatar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
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
                  quote.providerName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (quote.bidCompletionDay != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.completionDaysLabel(quote.bidCompletionDay!),
                    style: const TextStyle(
                      fontSize: 11.5,
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
                quote.displayAmount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isLowest) ...[
                const SizedBox(height: 4),
                Pill(label: l10n.lowestOfferLabel, fontSize: 8.5),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
