import 'service_category.dart' show formatPrice;

/// Formats a raw `bid_end_date` value — either a plain `"2026-09-16"` date
/// or a full ISO datetime like `"2026-09-16T00:00:00.000Z"` — as
/// `dd/MM/yyyy` for display. Returns the raw string unchanged if it can't
/// be parsed as a date.
String formatBidDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

/// A single row of `GET /customer/bids`.
class BidSummary {
  const BidSummary({
    required this.id,
    required this.title,
    this.description,
    this.estimateBidPrice,
    this.estimatedWorkingDays,
    this.bidEndDate,
    this.city,
    this.bidLocation,
    required this.status,
    this.creationDt,
    required this.totalBids,
  });

  final int id;
  final String title;
  final String? description;
  final String? estimateBidPrice;
  final int? estimatedWorkingDays;
  final String? bidEndDate;
  final String? city;
  final String? bidLocation;

  /// Raw numeric status code from the API (no string enum documented yet).
  final int status;
  final DateTime? creationDt;

  /// How many providers have responded with a quote.
  final int totalBids;

  String get displayBudget {
    final price = estimateBidPrice;
    if (price == null || price.isEmpty) return '—';
    return formatPrice(price);
  }

  factory BidSummary.fromJson(Map<String, dynamic> json) => BidSummary(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    estimateBidPrice: json['estimate_bid_price']?.toString(),
    estimatedWorkingDays: json['estimated_working_days'] as int?,
    bidEndDate: json['bid_end_date'] as String?,
    city: json['city'] as String?,
    bidLocation: json['bid_location'] as String?,
    status: json['status'] as int? ?? 0,
    creationDt: DateTime.tryParse(json['creation_dt'] as String? ?? ''),
    totalBids: json['total_bids'] as int? ?? 0,
  );
}

/// Response payload of `GET /customer/bids`.
class BidsPage {
  const BidsPage({
    required this.bids,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<BidSummary> bids;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory BidsPage.fromJson(Map<String, dynamic> json) => BidsPage(
    bids: (json['bids'] as List<dynamic>? ?? [])
        .map((e) => BidSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int? ?? 0,
    page: json['page'] as int? ?? 1,
    limit: json['limit'] as int? ?? 10,
    totalPages: json['total_pages'] as int? ?? 1,
  );
}

/// Full bid detail, the `bid` object of `GET /customer/bids/:id`.
class BidDetail {
  const BidDetail({
    required this.id,
    required this.title,
    this.description,
    this.serviceCategoryId,
    this.estimateBidPrice,
    this.estimatedWorkingDays,
    this.bidRegistrationFees,
    required this.isFeesRefundable,
    required this.isPenalty,
    this.penaltyRulesNotes,
    this.bidEndDate,
    this.city,
    this.bidLocation,
    required this.images,
    required this.documents,
    required this.status,
    this.creationDt,
  });

  final int id;
  final String title;
  final String? description;
  final int? serviceCategoryId;
  final String? estimateBidPrice;
  final int? estimatedWorkingDays;
  final String? bidRegistrationFees;
  final bool isFeesRefundable;
  final bool isPenalty;
  final String? penaltyRulesNotes;
  final String? bidEndDate;
  final String? city;
  final String? bidLocation;
  final List<String> images;
  final List<String> documents;
  final int status;
  final DateTime? creationDt;

  String get displayBudget {
    final price = estimateBidPrice;
    if (price == null || price.isEmpty) return '—';
    return formatPrice(price);
  }

  String get displayRegistrationFee {
    final fee = bidRegistrationFees;
    if (fee == null || fee.isEmpty) return '—';
    return formatPrice(fee);
  }

  factory BidDetail.fromJson(Map<String, dynamic> json) => BidDetail(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    serviceCategoryId: json['service_category_id'] as int?,
    estimateBidPrice: json['estimate_bid_price']?.toString(),
    estimatedWorkingDays: json['estimated_working_days'] as int?,
    bidRegistrationFees: json['bid_registration_fees']?.toString(),
    isFeesRefundable:
        json['is_fees_refundable'] == 1 || json['is_fees_refundable'] == true,
    isPenalty: json['is_penalty'] == 1 || json['is_penalty'] == true,
    penaltyRulesNotes: json['penalty_rules_notes'] as String?,
    bidEndDate: json['bid_end_date'] as String?,
    city: json['city'] as String?,
    bidLocation: json['bid_location'] as String?,
    images: (json['images'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    documents: (json['documents'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    status: json['status'] as int? ?? 0,
    creationDt: DateTime.tryParse(json['creation_dt'] as String? ?? ''),
  );
}

/// A single row of `providerBids` in `GET /customer/bids/:id` — one
/// provider's quote against the bid request.
class ProviderBid {
  const ProviderBid({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerPhone,
    this.providerEmail,
    this.bidAmount,
    this.bidCompletionDay,
    required this.isAgreed,
    this.creationDt,
  });

  final int id;
  final int providerId;
  final String providerName;
  final String? providerPhone;
  final String? providerEmail;
  final String? bidAmount;
  final int? bidCompletionDay;
  final bool isAgreed;
  final DateTime? creationDt;

  String get displayAmount {
    final amount = bidAmount;
    if (amount == null || amount.isEmpty) return '—';
    return formatPrice(amount);
  }

  factory ProviderBid.fromJson(Map<String, dynamic> json) => ProviderBid(
    id: json['id'] as int,
    providerId: json['provider_id'] as int? ?? 0,
    providerName: json['provider_name'] as String? ?? '',
    providerPhone: json['provider_phone'] as String?,
    providerEmail: json['provider_email'] as String?,
    bidAmount: json['bid_amount']?.toString(),
    bidCompletionDay: json['bid_completion_day'] as int?,
    isAgreed: json['is_agreed'] == 1 || json['is_agreed'] == true,
    creationDt: DateTime.tryParse(json['creation_dt'] as String? ?? ''),
  );
}

/// A row of `eligibleProviders` in `GET /customer/bids/:id`.
class EligibleProvider {
  const EligibleProvider({required this.id, required this.name, this.phone});

  final int id;
  final String name;
  final String? phone;

  factory EligibleProvider.fromJson(Map<String, dynamic> json) =>
      EligibleProvider(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
      );
}

/// Response payload of `GET /customer/bids/:id`.
class BidDetailResult {
  const BidDetailResult({
    required this.bid,
    required this.providerBids,
    required this.totalBids,
    required this.eligibleProviders,
  });

  final BidDetail bid;
  final List<ProviderBid> providerBids;
  final int totalBids;
  final List<EligibleProvider> eligibleProviders;

  /// Lowest quote among [providerBids] — the API returns this list sorted
  /// lowest amount first — or null if none have responded yet.
  ProviderBid? get lowestBid =>
      providerBids.isEmpty ? null : providerBids.first;

  factory BidDetailResult.fromJson(Map<String, dynamic> json) =>
      BidDetailResult(
        bid: BidDetail.fromJson(json['bid'] as Map<String, dynamic>),
        providerBids: (json['providerBids'] as List<dynamic>? ?? [])
            .map((e) => ProviderBid.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalBids: json['total_bids'] as int? ?? 0,
        eligibleProviders: (json['eligibleProviders'] as List<dynamic>? ?? [])
            .map((e) => EligibleProvider.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
