/// Top-level service category as returned by `GET /customer/services`.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.categoryName,
    this.image,
    this.serviceDesc,
  });

  final int id;
  final String categoryName;
  final String? image;
  final String? serviceDesc;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        id: json['id'] as int,
        categoryName: json['category_name'] as String? ?? '',
        image: json['image'] as String?,
        serviceDesc: json['service_desc'] as String?,
      );
}

/// A row of `GET /customer/services/popular` — either a top-level category
/// ([parentId] is `null`) or a sub-category ([parentId] holds the owning
/// category's id).
class PopularService {
  const PopularService({
    required this.id,
    required this.categoryName,
    this.parentId,
    this.image,
  });

  final int id;
  final String categoryName;
  final int? parentId;
  final String? image;

  /// True for a top-level category entry — tapping it should behave like an
  /// Explore Services tile. False means this is a sub-category, and tapping
  /// it should jump straight to that sub-category's provider list.
  bool get isTopLevel => parentId == null;

  factory PopularService.fromJson(Map<String, dynamic> json) => PopularService(
    id: json['id'] as int,
    categoryName: json['category_name'] as String? ?? '',
    parentId: json['parent_id'] as int?,
    image: json['image'] as String?,
  );
}

/// Sub-category rail entry as returned alongside providers by
/// `GET /customer/services/:categoryId/providers`.
class ServiceSubCategory {
  const ServiceSubCategory({
    required this.id,
    required this.categoryName,
    this.image,
  });

  final int id;
  final String categoryName;
  final String? image;

  factory ServiceSubCategory.fromJson(Map<String, dynamic> json) =>
      ServiceSubCategory(
        id: json['id'] as int,
        categoryName: json['category_name'] as String? ?? '',
        image: json['image'] as String?,
      );
}

/// Parses a backend price string (e.g. `"499.00"`) into a `₹`-formatted
/// display string, dropping a trailing `.00` and keeping decimals only when
/// the value has a non-zero fractional part (e.g. `"449.50"` -> `₹449.50`).
String formatPrice(String raw) {
  final value = num.tryParse(raw) ?? 0;
  final isWhole = value == value.roundToDouble();
  final text = isWhole
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return '₹$text';
}

/// A selectable filter option as returned alongside providers by
/// `GET /customer/services/:categoryId/providers`.
class ServiceFilter {
  const ServiceFilter({required this.id, required this.name, this.icon});

  final int id;
  final String name;
  final String? icon;

  factory ServiceFilter.fromJson(Map<String, dynamic> json) => ServiceFilter(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    icon: json['icon'] as String?,
  );
}

/// A provider listing row as returned by
/// `GET /customer/services/:categoryId/providers`.
class ProviderListing {
  const ProviderListing({
    required this.id,
    required this.name,
    this.profileImage,
    required this.isVerified,
    required this.serviceId,
    required this.serviceCategory,
    this.serviceSubCategory,
    this.serviceCategoryName,
    this.serviceSubCategoryName,
    this.serviceStartPrice,
    this.serviceOfferPrice,
    this.warranty,
    required this.rating,
    required this.totalReviews,
    required this.completedJobs,
    this.nextAvailableAt,
    this.distanceKm,
  });

  final int id;
  final String name;
  final String? profileImage;
  final int isVerified;
  final int serviceId;
  final int serviceCategory;
  final int? serviceSubCategory;
  final String? serviceCategoryName;
  final String? serviceSubCategoryName;
  final String? serviceStartPrice;
  final String? serviceOfferPrice;
  final int? warranty;
  final num rating;
  final int totalReviews;
  final int completedJobs;

  /// This provider's next open slot, per the `next_available_at` field on
  /// `GET /customer/services/:categoryId/providers` — `null` if the backend
  /// doesn't send it yet (not confirmed live as of this writing) or if the
  /// provider has no opening in whatever lookahead window it considers.
  /// Used to show an "Available now" / "Next: …" badge on provider cards,
  /// and to drive the Instant filter upstream of this model.
  final DateTime? nextAvailableAt;

  /// Distance in km from the customer's location sent via the `coordinates`
  /// request, per this row's `distance_km` — `null` if the backend doesn't
  /// send it (e.g. an older backend, or `location_required` was true and
  /// this list is empty anyway).
  final num? distanceKm;

  bool get isVerifiedProvider => isVerified == 1;

  /// True when [nextAvailableAt] is known and is within the next 30 minutes
  /// — mirrors the "instant" window the providers list filter uses server-
  /// side, so a provider already included in an instant-filtered response
  /// still renders its badge consistently if re-derived client-side.
  bool get isAvailableNow {
    final next = nextAvailableAt;
    if (next == null) return false;
    return next.difference(DateTime.now()) <= const Duration(minutes: 30);
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

  /// "0.7 km" rounded to one decimal, or "< 1 km" for anything under 1 km —
  /// `null` when [distanceKm] isn't known.
  String? get displayDistance {
    final km = distanceKm;
    if (km == null) return null;
    if (km < 1) return '< 1 km';
    return '${km.toStringAsFixed(1)} km';
  }

  factory ProviderListing.fromJson(Map<String, dynamic> json) =>
      ProviderListing(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        profileImage: json['profile_image'] as String?,
        isVerified: json['is_verified'] as int? ?? 0,
        serviceId: json['service_id'] as int? ?? 0,
        serviceCategory: json['service_category'] as int? ?? 0,
        serviceSubCategory: json['service_sub_category'] as int?,
        serviceCategoryName: json['service_category_name'] as String?,
        serviceSubCategoryName: json['service_sub_category_name'] as String?,
        serviceStartPrice: json['service_start_price']?.toString(),
        serviceOfferPrice: json['service_offer_price']?.toString(),
        warranty: json['warranty'] as int?,
        rating: num.tryParse(json['rating']?.toString() ?? '') ?? 0,
        totalReviews: json['total_reviews'] as int? ?? 0,
        completedJobs: json['completed_jobs'] as int? ?? 0,
        nextAvailableAt: DateTime.tryParse(
          json['next_available_at'] as String? ?? '',
        ),
        distanceKm: num.tryParse(json['distance_km']?.toString() ?? ''),
      );
}

/// Response payload of `GET /customer/services/:categoryId/providers`.
class ProvidersResult {
  const ProvidersResult({
    required this.subCategories,
    required this.serviceFilters,
    required this.providers,
    this.locationRequired = false,
    this.radiusKm,
  });

  final List<ServiceSubCategory> subCategories;
  final List<ServiceFilter> serviceFilters;
  final List<ProviderListing> providers;

  /// True when the backend couldn't resolve a usable customer location
  /// (missing/malformed/out-of-range `coordinates`) — `providers` is empty
  /// in this case, and the UI should prompt to enable location rather than
  /// show a generic "no providers" message. `false` for an older backend
  /// that doesn't send this field at all.
  final bool locationRequired;

  /// The radius (km) the backend filtered providers within, when known —
  /// `null` for an older backend that doesn't send it. Used to word the
  /// empty state ("No providers within {radiusKm} km of you") instead of
  /// hardcoding 30.
  final num? radiusKm;

  factory ProvidersResult.fromJson(Map<String, dynamic> json) =>
      ProvidersResult(
        subCategories: (json['subCategories'] as List<dynamic>? ?? [])
            .map((e) => ServiceSubCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        serviceFilters: (json['serviceFilters'] as List<dynamic>? ?? [])
            .map((e) => ServiceFilter.fromJson(e as Map<String, dynamic>))
            .toList(),
        providers: (json['providers'] as List<dynamic>? ?? [])
            .map((e) => ProviderListing.fromJson(e as Map<String, dynamic>))
            .toList(),
        locationRequired: json['location_required'] as bool? ?? false,
        radiusKm: num.tryParse(json['radius_km']?.toString() ?? ''),
      );
}

/// Provider detail as returned by `GET /customer/providers/:providerId`.
class ProviderDetail {
  const ProviderDetail({
    required this.id,
    required this.name,
    this.phone,
    this.profileImage,
    required this.isVerified,
    required this.rating,
    required this.totalReviews,
    required this.completedJobs,
    this.about,
    this.yearsOfExperience,
  });

  final int id;
  final String name;
  final String? phone;
  final String? profileImage;
  final int isVerified;
  final num rating;
  final int totalReviews;
  final int completedJobs;
  final String? about;
  final int? yearsOfExperience;

  bool get isVerifiedProvider => isVerified == 1;

  factory ProviderDetail.fromJson(Map<String, dynamic> json) => ProviderDetail(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String?,
    profileImage: json['profile_image'] as String?,
    isVerified: json['is_verified'] as int? ?? 0,
    rating: num.tryParse(json['rating']?.toString() ?? '') ?? 0,
    totalReviews: json['total_reviews'] as int? ?? 0,
    completedJobs: json['completed_jobs'] as int? ?? 0,
    about: json['about'] as String?,
    yearsOfExperience: json['years_of_experience'] as int?,
  );
}

/// A single row of the provider's "Services & Pricing" list, as returned by
/// `GET /customer/providers/:providerId`.
class ProviderService {
  const ProviderService({
    required this.id,
    required this.serviceCategory,
    this.serviceCategoryName,
    this.serviceSubCategory,
    this.serviceSubCategoryName,
    this.serviceStartPrice,
    this.serviceOfferPrice,
    this.warranty,
    this.additionalDetail,
  });

  final int id;
  final int serviceCategory;
  final String? serviceCategoryName;
  final int? serviceSubCategory;
  final String? serviceSubCategoryName;
  final String? serviceStartPrice;
  final String? serviceOfferPrice;
  final int? warranty;
  final String? additionalDetail;

  /// `service_category_name` plus ` / service_sub_category_name` when the
  /// sub-category fields are present.
  String get displayLabel {
    final sub = serviceSubCategoryName;
    final base = serviceCategoryName ?? '';
    if (sub != null && sub.isNotEmpty) return '$base / $sub';
    return base;
  }

  String? get displayPrice {
    final offer = serviceOfferPrice;
    if (offer != null && offer.isNotEmpty) return formatPrice(offer);
    final start = serviceStartPrice;
    if (start != null && start.isNotEmpty) return formatPrice(start);
    return null;
  }

  factory ProviderService.fromJson(Map<String, dynamic> json) =>
      ProviderService(
        id: json['id'] as int,
        serviceCategory: json['service_category'] as int? ?? 0,
        serviceCategoryName: json['service_category_name'] as String?,
        serviceSubCategory: json['service_sub_category'] as int?,
        serviceSubCategoryName: json['service_sub_category_name'] as String?,
        serviceStartPrice: json['service_start_price']?.toString(),
        serviceOfferPrice: json['service_offer_price']?.toString(),
        warranty: json['warranty'] as int?,
        additionalDetail: json['additional_detail'] as String?,
      );
}

/// A single booking-eligible service, as returned by the `service` object of
/// `GET /customer/service-detail/:serviceId`. Powers the "Review & Schedule"
/// (booking) screen's summary card.
class ServiceDetail {
  const ServiceDetail({
    required this.id,
    this.serviceCategoryName,
    this.serviceSubCategoryName,
    this.serviceStartPrice,
    this.serviceOfferPrice,
    this.warranty,
    this.additionalDetail,
    required this.providerId,
    this.providerName,
    this.providerProfileImage,
    required this.isVerified,
  });

  final int id;
  final String? serviceCategoryName;
  final String? serviceSubCategoryName;
  final String? serviceStartPrice;
  final String? serviceOfferPrice;
  final int? warranty;
  final String? additionalDetail;
  final int providerId;
  final String? providerName;
  final String? providerProfileImage;
  final int isVerified;

  bool get isVerifiedProvider => isVerified == 1;

  /// `service_category_name` plus ` / service_sub_category_name` when the
  /// sub-category fields are present.
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

  /// The numeric amount used for booking totals — prefers the offer price,
  /// else the start price, else `0`.
  int get amount {
    final offer = serviceOfferPrice;
    if (offer != null && offer.isNotEmpty) {
      return num.tryParse(offer)?.round() ?? 0;
    }
    final start = serviceStartPrice;
    if (start != null && start.isNotEmpty) {
      return num.tryParse(start)?.round() ?? 0;
    }
    return 0;
  }

  factory ServiceDetail.fromJson(Map<String, dynamic> json) => ServiceDetail(
    id: json['id'] as int,
    serviceCategoryName: json['service_category_name'] as String?,
    serviceSubCategoryName: json['service_sub_category_name'] as String?,
    serviceStartPrice: json['service_start_price']?.toString(),
    serviceOfferPrice: json['service_offer_price']?.toString(),
    warranty: json['warranty'] as int?,
    additionalDetail: json['additional_detail'] as String?,
    providerId: json['provider_id'] as int? ?? 0,
    providerName: json['provider_name'] as String?,
    providerProfileImage: json['provider_profile_image'] as String?,
    isVerified: json['provider_is_verified'] as int? ?? 0,
  );
}

/// A single optional add-on/item offered alongside a service, as returned in
/// the `addOns` array of `GET /customer/service-detail/:serviceId`.
class ServiceAddOn {
  const ServiceAddOn({
    required this.id,
    required this.itemName,
    this.itemDesc,
    required this.itemPrice,
    this.quantity,
    this.unitLabel,
    this.warranty,
    this.warrantyUnitLabel,
  });

  final int id;
  final String itemName;
  final String? itemDesc;
  final String itemPrice;
  final String? quantity;
  final String? unitLabel;
  final int? warranty;
  final String? warrantyUnitLabel;

  /// Numeric price, for totals math.
  int get price => num.tryParse(itemPrice)?.round() ?? 0;

  String get displayPrice => formatPrice(itemPrice);

  /// e.g. "500 Millilitre" when both a quantity and unit label are present.
  String? get displayQuantity {
    final raw = quantity;
    if (raw == null || raw.isEmpty) return null;
    final qty = num.tryParse(raw);
    final qtyText = qty != null
        ? (qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toString())
        : raw;
    return unitLabel != null && unitLabel!.isNotEmpty
        ? '$qtyText $unitLabel'
        : qtyText;
  }

  /// e.g. "6 Month" when both a warranty period and unit label are present.
  String? get displayWarranty {
    if (warranty == null) return null;
    return warrantyUnitLabel != null && warrantyUnitLabel!.isNotEmpty
        ? '$warranty $warrantyUnitLabel'
        : '$warranty';
  }

  factory ServiceAddOn.fromJson(Map<String, dynamic> json) => ServiceAddOn(
    id: json['id'] as int,
    itemName: json['item_name'] as String? ?? '',
    itemDesc: json['item_desc'] as String?,
    itemPrice: json['item_price']?.toString() ?? '0',
    quantity: json['quantity']?.toString(),
    unitLabel: json['unit_label'] as String?,
    warranty: json['warranty'] as int?,
    warrantyUnitLabel: json['warranty_unit_label'] as String?,
  );
}

/// Response payload of `GET /customer/service-detail/:serviceId`.
class ServiceDetailResult {
  const ServiceDetailResult({required this.service, required this.addOns});

  final ServiceDetail service;
  final List<ServiceAddOn> addOns;

  factory ServiceDetailResult.fromJson(Map<String, dynamic> json) =>
      ServiceDetailResult(
        service: ServiceDetail.fromJson(
          json['service'] as Map<String, dynamic>,
        ),
        addOns: (json['addOns'] as List<dynamic>? ?? [])
            .map((e) => ServiceAddOn.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response payload of `GET /customer/providers/:providerId`.
class ProviderProfileResult {
  const ProviderProfileResult({required this.provider, required this.services});

  final ProviderDetail provider;
  final List<ProviderService> services;

  factory ProviderProfileResult.fromJson(Map<String, dynamic> json) =>
      ProviderProfileResult(
        provider: ProviderDetail.fromJson(
          json['provider'] as Map<String, dynamic>,
        ),
        services: (json['services'] as List<dynamic>? ?? [])
            .map((e) => ProviderService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response payload of
/// `GET /customer/providers/:providerId/booked-slots?booking_date=...` —
/// the slot labels already booked for that provider on that date.
class BookedSlots {
  const BookedSlots({
    required this.providerId,
    required this.bookingDate,
    required this.slots,
  });

  final int providerId;
  final String bookingDate;

  /// Slot labels exactly matching the app's slot chip strings (e.g.
  /// `"10:00 AM - 11:00 AM"`) that are already booked for this provider on
  /// this date.
  final List<String> slots;

  factory BookedSlots.fromJson(Map<String, dynamic> json) => BookedSlots(
    providerId: json['provider_id'] as int? ?? 0,
    bookingDate: json['booking_date'] as String? ?? '',
    slots: (json['booked_slots'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}

/// A single bookable slot as returned by
/// `GET /customer/slots?booking_date=&zone_id=` — admin-configured per zone,
/// so the set of slots (and their count) varies and can change at any time;
/// never hardcode a slot list client-side.
class BookingSlot {
  const BookingSlot({
    required this.label,
    this.startAt,
    this.endAt,
    required this.isPast,
  });

  /// Shown as-is and sent back verbatim as `slot` when creating an order or
  /// sub-order — the backend matches it character for character, so this is
  /// never reformatted or derived from [startAt]/[endAt] client-side.
  final String label;

  /// ISO UTC timestamps, used only for sorting/comparisons — [label] is
  /// what's displayed, never a format derived from these.
  final DateTime? startAt;
  final DateTime? endAt;

  /// True when this slot's start time has already passed — can only happen
  /// for today's date.
  final bool isPast;

  factory BookingSlot.fromJson(Map<String, dynamic> json) => BookingSlot(
    label: json['label'] as String? ?? '',
    startAt: DateTime.tryParse(json['start_at'] as String? ?? ''),
    endAt: DateTime.tryParse(json['end_at'] as String? ?? ''),
    isPast: json['is_past'] as bool? ?? false,
  );
}

/// Response payload of `GET /customer/slots?booking_date=&zone_id=`.
class BookingSlotsResult {
  const BookingSlotsResult({
    required this.bookingDate,
    this.zoneId,
    required this.slots,
  });

  final String bookingDate;
  final int? zoneId;

  /// Can be empty — a zone may have no slots configured for a given date.
  final List<BookingSlot> slots;

  factory BookingSlotsResult.fromJson(Map<String, dynamic> json) =>
      BookingSlotsResult(
        bookingDate: json['booking_date'] as String? ?? '',
        zoneId: json['zone_id'] as int?,
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((e) => BookingSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response payload of `GET /customer/providers/:providerId/availability` —
/// replaces the old client-side "Instant Booking" guesswork on
/// `BookingScreen` with a server answer on whether this provider can be
/// booked right now, and when their next real opening is otherwise.
///
/// NOTE: no confirmed backend contract yet — this endpoint doesn't exist as
/// of this writing (see the "Instant vs Schedule API" spec). `BookingScreen`
/// treats any failure to reach it (404, network error) as "unknown" and
/// falls back to today's manual date/slot picking with no availability
/// banner shown, rather than blocking the screen.
class ProviderAvailability {
  const ProviderAvailability({
    required this.providerId,
    required this.availableNow,
    this.nextAvailableAt,
    this.nextAvailableSlot,
  });

  final int providerId;

  /// True when this provider has an opening within the "instant" window
  /// (30 minutes from now) — see [ProviderListing.isAvailableNow] for the
  /// same rule applied client-side to a providers-list row.
  final bool availableNow;

  /// This provider's actual next opening, regardless of [availableNow] —
  /// `null` only when nothing is bookable in the server's lookahead window.
  final DateTime? nextAvailableAt;

  /// Same moment as [nextAvailableAt], as a slot label string. Not
  /// guaranteed to match a [BookingSlot.label] from `GET /customer/slots`
  /// character for character (separate, unconfirmed contracts) — callers
  /// should re-validate it against that list before selecting it rather
  /// than trusting it as pre-formatted/ready-to-use.
  final String? nextAvailableSlot;

  factory ProviderAvailability.fromJson(Map<String, dynamic> json) =>
      ProviderAvailability(
        providerId: json['provider_id'] as int? ?? 0,
        availableNow: json['available_now'] as bool? ?? false,
        nextAvailableAt: DateTime.tryParse(
          json['next_available_at'] as String? ?? '',
        ),
        nextAvailableSlot: json['next_available_slot'] as String?,
      );
}
