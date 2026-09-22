import 'service_category.dart' show formatPrice;

/// A single row of `GET /customer/orders`.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    this.serviceCategoryName,
    this.serviceSubCategoryName,
    this.providerId,
    this.providerName,
    this.providerProfileImage,
    this.totalPrice,
    this.bookingSlot,
    this.creationDt,
  });

  final int id;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final String? serviceCategoryName;
  final String? serviceSubCategoryName;
  final int? providerId;
  final String? providerName;
  final String? providerProfileImage;
  final String? totalPrice;
  final String? bookingSlot;
  final DateTime? creationDt;

  /// `service_category_name` plus ` / service_sub_category_name` when the
  /// sub-category is present.
  String get displayService {
    final sub = serviceSubCategoryName;
    final base = serviceCategoryName ?? '';
    if (sub != null && sub.isNotEmpty) return '$base / $sub';
    return base;
  }

  String get displayPrice {
    final price = totalPrice;
    if (price == null || price.isEmpty) return '—';
    return formatPrice(price);
  }

  /// True once the order has reached its terminal "completed" step.
  bool get isCompleted => status == 'completed';

  /// True once the order is no longer active (completed or cancelled) —
  /// used to drive the Orders screen's tab filters.
  bool get isFinished => status == 'completed' || status == 'cancelled';

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: json['id'] as int,
    orderNumber: json['order_number'] as String? ?? '',
    status: json['status'] as String? ?? '',
    statusLabel: json['status_label'] as String? ?? '',
    serviceCategoryName: json['service_category_name'] as String?,
    serviceSubCategoryName: json['service_sub_category_name'] as String?,
    providerId: json['provider_id'] as int?,
    providerName: json['provider_name'] as String?,
    providerProfileImage: json['provider_profile_image'] as String?,
    totalPrice: json['total_price']?.toString(),
    bookingSlot: json['booking_slot'] as String?,
    creationDt: DateTime.tryParse(json['creation_dt'] as String? ?? ''),
  );
}

/// Response payload of `GET /customer/orders`.
class OrdersPage {
  const OrdersPage({
    required this.orders,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<OrderSummary> orders;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory OrdersPage.fromJson(Map<String, dynamic> json) => OrdersPage(
    orders: (json['orders'] as List<dynamic>? ?? [])
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int? ?? 0,
    page: json['page'] as int? ?? 1,
    limit: json['limit'] as int? ?? 20,
    totalPages: json['total_pages'] as int? ?? 1,
  );
}

/// The `order` object of `GET /customer/orders/:orderId/track`.
class OrderTrackingInfo {
  const OrderTrackingInfo({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    this.serviceCategoryName,
    this.serviceSubCategoryName,
  });

  final int id;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final String? serviceCategoryName;
  final String? serviceSubCategoryName;

  String get displayService {
    final sub = serviceSubCategoryName;
    final base = serviceCategoryName ?? '';
    if (sub != null && sub.isNotEmpty) return '$base / $sub';
    return base;
  }

  factory OrderTrackingInfo.fromJson(Map<String, dynamic> json) =>
      OrderTrackingInfo(
        id: json['id'] as int,
        orderNumber: json['order_number'] as String? ?? '',
        status: json['status'] as String? ?? '',
        statusLabel: json['status_label'] as String? ?? '',
        serviceCategoryName: json['service_category_name'] as String?,
        serviceSubCategoryName: json['service_sub_category_name'] as String?,
      );
}

/// The `provider` object of `GET /customer/orders/:orderId/track`.
class TrackingProvider {
  const TrackingProvider({
    required this.id,
    required this.name,
    this.phone,
    this.profileImage,
    this.location,
    this.locationCapturedAt,
  });

  final int id;
  final String name;
  final String? phone;
  final String? profileImage;

  /// Raw "lat,lng" string, when the provider's live location is known.
  final String? location;
  final DateTime? locationCapturedAt;

  /// Parsed (lat, lng), or null if [location] is missing/malformed.
  (double, double)? get coordinates {
    final raw = location;
    if (raw == null) return null;
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  factory TrackingProvider.fromJson(Map<String, dynamic> json) =>
      TrackingProvider(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        profileImage: json['profile_image'] as String?,
        location: json['location'] as String?,
        locationCapturedAt: DateTime.tryParse(
          json['location_captured_at'] as String? ?? '',
        ),
      );
}

/// A single row of the `timeline` array in
/// `GET /customer/orders/:orderId/track`.
class TrackingStep {
  const TrackingStep({
    required this.step,
    required this.label,
    required this.completed,
    required this.current,
    this.timestamp,
  });

  final String step;
  final String label;
  final bool completed;
  final bool current;
  final DateTime? timestamp;

  factory TrackingStep.fromJson(Map<String, dynamic> json) => TrackingStep(
    step: json['step'] as String? ?? '',
    label: json['label'] as String? ?? '',
    completed: json['completed'] as bool? ?? false,
    current: json['current'] as bool? ?? false,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
  );
}

/// Response payload of `GET /customer/orders/:orderId/track`.
class OrderTrackingResult {
  const OrderTrackingResult({
    required this.order,
    required this.provider,
    required this.timeline,
  });

  final OrderTrackingInfo order;
  final TrackingProvider? provider;
  final List<TrackingStep> timeline;

  factory OrderTrackingResult.fromJson(Map<String, dynamic> json) =>
      OrderTrackingResult(
        order: OrderTrackingInfo.fromJson(
          json['order'] as Map<String, dynamic>,
        ),
        provider: json['provider'] != null
            ? TrackingProvider.fromJson(json['provider'] as Map<String, dynamic>)
            : null,
        timeline: (json['timeline'] as List<dynamic>? ?? [])
            .map((e) => TrackingStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
