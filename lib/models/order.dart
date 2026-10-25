import 'service_category.dart' show formatPrice;

/// Parses a JSON value that's supposed to be an int, but has been observed
/// sent as a decimal-formatted string (e.g. `"500.00"`) by some of the
/// order-detail endpoints below — a raw `as int` cast throws on that shape.
/// Returns `null` if [value] is `null` or not parseable as a number.
int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return num.tryParse(value.toString())?.round();
}

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
    this.providerPhone,
    this.totalPrice,
    this.bookingSlot,
    this.bookingDate,
    this.bookingType,
    this.jobStartTime,
    this.jobEndTime,
    this.assignedTime,
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
  final String? providerPhone;
  final String? totalPrice;
  final String? bookingSlot;
  final DateTime? bookingDate;
  final String? bookingType;
  final DateTime? jobStartTime;
  final DateTime? jobEndTime;
  final DateTime? assignedTime;
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
    providerPhone: json['provider_phone'] as String?,
    totalPrice: json['total_price']?.toString(),
    bookingSlot: json['booking_slot'] as String?,
    bookingDate: DateTime.tryParse(json['booking_date'] as String? ?? ''),
    bookingType: json['booking_type'] as String?,
    jobStartTime: DateTime.tryParse(json['job_start_time'] as String? ?? ''),
    jobEndTime: DateTime.tryParse(json['job_end_time'] as String? ?? ''),
    assignedTime: DateTime.tryParse(json['assigned_time'] as String? ?? ''),
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

  factory OrderTrackingResult.fromJson(
    Map<String, dynamic> json,
  ) => OrderTrackingResult(
    order: OrderTrackingInfo.fromJson(json['order'] as Map<String, dynamic>),
    provider: json['provider'] != null
        ? TrackingProvider.fromJson(json['provider'] as Map<String, dynamic>)
        : null,
    timeline: (json['timeline'] as List<dynamic>? ?? [])
        .map((e) => TrackingStep.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// A single row of an order's (or sub-order's) `add_ons` array, as returned
/// by `GET /customer/orders/:orderId`.
class OrderAddOnLine {
  const OrderAddOnLine({
    required this.id,
    required this.orderId,
    this.addOnId,
    required this.itemName,
    required this.itemPrice,
    this.quantity,
  });

  final int id;
  final int orderId;
  final int? addOnId;
  final String itemName;
  final String itemPrice;

  /// `quantity` has been observed sent as a decimal-formatted string (e.g.
  /// `"500.00"`) rather than a bare int, so this parses leniently instead of
  /// casting — a raw `as int?` throws on that shape.
  final int? quantity;

  String get displayPrice => formatPrice(itemPrice);

  factory OrderAddOnLine.fromJson(Map<String, dynamic> json) => OrderAddOnLine(
    id: _asInt(json['id']) ?? 0,
    orderId: _asInt(json['order_id']) ?? 0,
    addOnId: _asInt(json['add_on_id']),
    itemName: json['item_name'] as String? ?? '',
    itemPrice: json['item_price']?.toString() ?? '0',
    quantity: _asInt(json['quantity']),
  );
}

/// Shared fields between the primary `order` object and each entry of
/// `sub_orders` in `GET /customer/orders/:orderId` — every sub-order is a
/// full order in its own right (own price, own status lifecycle, own
/// add-ons), just linked back to its primary order.
class OrderDetailInfo {
  const OrderDetailInfo({
    required this.id,
    this.orderNumber,
    required this.status,
    required this.statusLabel,
    this.totalPrice,
    this.settlementAmount,
    this.platformCommissionPrice,
    this.bookingSlot,
    this.bookingDate,
    this.paymentMethod,
    this.serviceId,
    this.serviceCategoryName,
    this.serviceSubCategoryName,
    this.jobStartTime,
    this.jobEndTime,
    this.assignedTime,
    this.creationDt,
    required this.addOns,
  });

  final int id;
  final String? orderNumber;
  final String status;
  final String statusLabel;
  final String? totalPrice;
  final String? settlementAmount;
  final String? platformCommissionPrice;
  final String? bookingSlot;
  final String? bookingDate;
  final String? paymentMethod;
  final int? serviceId;
  final String? serviceCategoryName;
  final String? serviceSubCategoryName;
  final DateTime? jobStartTime;
  final DateTime? jobEndTime;
  final DateTime? assignedTime;
  final DateTime? creationDt;
  final List<OrderAddOnLine> addOns;

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

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isFinished => isCompleted || isCancelled;

  factory OrderDetailInfo.fromJson(Map<String, dynamic> json) =>
      OrderDetailInfo(
        id: _asInt(json['id']) ?? 0,
        orderNumber: json['order_number'] as String?,
        status: json['status'] as String? ?? '',
        statusLabel: json['status_label'] as String? ?? '',
        totalPrice: json['total_price']?.toString(),
        settlementAmount: json['settlement_amount']?.toString(),
        platformCommissionPrice: json['platform_commission_price']?.toString(),
        bookingSlot: json['booking_slot'] as String?,
        bookingDate: json['booking_date'] as String?,
        paymentMethod: json['payment_method'] as String?,
        serviceId: _asInt(json['service_id']),
        serviceCategoryName: json['service_category_name'] as String?,
        serviceSubCategoryName: json['service_sub_category_name'] as String?,
        jobStartTime: DateTime.tryParse(
          json['job_start_time'] as String? ?? '',
        ),
        jobEndTime: DateTime.tryParse(json['job_end_time'] as String? ?? ''),
        assignedTime: DateTime.tryParse(json['assigned_time'] as String? ?? ''),
        creationDt: DateTime.tryParse(json['creation_dt'] as String? ?? ''),
        addOns: (json['add_ons'] as List<dynamic>? ?? [])
            .map((e) => OrderAddOnLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// The `provider` object of `GET /customer/orders/:orderId`.
class OrderDetailProvider {
  const OrderDetailProvider({
    required this.id,
    required this.name,
    this.phone,
    this.profileImage,
  });

  final int id;
  final String name;
  final String? phone;
  final String? profileImage;

  factory OrderDetailProvider.fromJson(Map<String, dynamic> json) =>
      OrderDetailProvider(
        id: _asInt(json['id']) ?? 0,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        profileImage: json['profile_image'] as String?,
      );
}

/// Response payload of `GET /customer/orders/:orderId` — the primary
/// order's own info + add-ons, plus every sub-order (each a full order with
/// its own status/price/add-ons) added onto it after it was placed.
/// [subOrders] is `[]` when none have been added yet.
class OrderDetailResult {
  const OrderDetailResult({
    required this.order,
    this.provider,
    required this.subOrders,
    this.grandTotal,
  });

  final OrderDetailInfo order;
  final OrderDetailProvider? provider;
  final List<OrderDetailInfo> subOrders;

  /// Primary `total_price` plus every sub-order's `total_price`. Equals
  /// `order.totalPrice` when there are no sub-orders.
  final String? grandTotal;

  String get displayGrandTotal {
    final total = grandTotal;
    if (total == null || total.isEmpty) return order.displayPrice;
    return formatPrice(total);
  }

  /// "Add More Services" should only be offered while there's an assigned
  /// provider to add onto and the order hasn't reached a terminal state —
  /// mirrors the same condition the backend enforces on both
  /// `available-services` and `sub-orders`.
  bool get canAddMoreServices => provider != null && !order.isFinished;

  factory OrderDetailResult.fromJson(Map<String, dynamic> json) =>
      OrderDetailResult(
        order: OrderDetailInfo.fromJson(json['order'] as Map<String, dynamic>),
        provider: json['provider'] != null
            ? OrderDetailProvider.fromJson(
                json['provider'] as Map<String, dynamic>,
              )
            : null,
        subOrders: (json['sub_orders'] as List<dynamic>? ?? [])
            .map((e) => OrderDetailInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        grandTotal: json['grand_total']?.toString(),
      );
}

/// A single row of `GET /customer/orders/:orderId/available-services` — a
/// service from the primary order's own provider that isn't already on the
/// order (as the primary service or an existing sub-order), offered for
/// "Add More Services".
class AvailableService {
  const AvailableService({
    required this.id,
    this.serviceCategory,
    this.serviceSubCategory,
    this.serviceCategoryName,
    this.serviceSubCategoryName,
    this.serviceStartPrice,
    this.serviceOfferPrice,
    this.warranty,
  });

  final int id;
  final int? serviceCategory;
  final int? serviceSubCategory;
  final String? serviceCategoryName;
  final String? serviceSubCategoryName;
  final String? serviceStartPrice;
  final String? serviceOfferPrice;
  final int? warranty;

  /// `service_category_name` plus ` / service_sub_category_name` when the
  /// sub-category is present.
  String get displayLabel {
    final sub = serviceSubCategoryName;
    final base = serviceCategoryName ?? '';
    if (sub != null && sub.isNotEmpty) return '$base / $sub';
    return base;
  }

  /// Prefers the offer price when present, else falls back to the start
  /// price. Returns `null` when neither is available.
  String? get displayPrice {
    final offer = serviceOfferPrice;
    if (offer != null && offer.isNotEmpty) return formatPrice(offer);
    final start = serviceStartPrice;
    if (start != null && start.isNotEmpty) return formatPrice(start);
    return null;
  }

  factory AvailableService.fromJson(Map<String, dynamic> json) =>
      AvailableService(
        id: _asInt(json['id']) ?? 0,
        serviceCategory: _asInt(json['service_category']),
        serviceSubCategory: _asInt(json['service_sub_category']),
        serviceCategoryName: json['service_category_name'] as String?,
        serviceSubCategoryName: json['service_sub_category_name'] as String?,
        serviceStartPrice: json['service_start_price']?.toString(),
        serviceOfferPrice: json['service_offer_price']?.toString(),
        warranty: _asInt(json['warranty']),
      );
}

/// Response payload of
/// `GET /customer/orders/:orderId/available-services`.
class AvailableServicesResult {
  const AvailableServicesResult({required this.services});

  final List<AvailableService> services;

  factory AvailableServicesResult.fromJson(Map<String, dynamic> json) =>
      AvailableServicesResult(
        services: (json['services'] as List<dynamic>? ?? [])
            .map((e) => AvailableService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Success response of `POST /customer/orders/:orderId/sub-orders`.
class SubOrderCreateResult {
  const SubOrderCreateResult({
    required this.subOrderId,
    required this.primaryOrderId,
    this.transactionId,
    this.totalPrice,
    this.platformCommissionPrice,
    this.settlementAmount,
  });

  final int subOrderId;
  final int primaryOrderId;
  final int? transactionId;
  final String? totalPrice;
  final String? platformCommissionPrice;
  final String? settlementAmount;

  factory SubOrderCreateResult.fromJson(Map<String, dynamic> json) =>
      SubOrderCreateResult(
        subOrderId: _asInt(json['subOrderId']) ?? 0,
        primaryOrderId: _asInt(json['primaryOrderId']) ?? 0,
        transactionId: _asInt(json['transactionId']),
        totalPrice: json['total_price']?.toString(),
        platformCommissionPrice: json['platform_commission_price']?.toString(),
        settlementAmount: json['settlement_amount']?.toString(),
      );
}
