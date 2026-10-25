import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import 'service_category.dart';

/// The two ways a booking can be made — mirrors `ProvidersScreen`'s Instant/
/// Schedule picker (`OrderType` in `widgets/service_selection_sheets.dart`),
/// but kept as its own type here since `GET /customer/platform-fee` and
/// `POST /customer/orders` both use `booking_type` with different string
/// values (`"instant"` / `"regular"`) than that picker's own `availability`
/// query param (`"instant"` / `"schedule"`).
enum BookingType {
  regular,
  instant;

  /// The `booking_type` value both `GET /customer/platform-fee` and
  /// `POST /customer/orders` expect.
  String get apiValue => switch (this) {
    BookingType.regular => 'regular',
    BookingType.instant => 'instant',
  };
}

/// A saved delivery address, as returned by `GET /addresses` — shared
/// between `SavedAddressesScreen` (the full address-book list) and the home
/// screen's location picker, so picking/adding/editing an address in either
/// place is reflected in both.
///
/// The backend's `city`/`state` fields are numeric ids sent as strings (e.g.
/// `"city": "134"`) — [cityName]/[stateName] hold the display names looked
/// up against `RegisterDetails` once that's fetched (see
/// `SavedAddressesScreen._resolveLocationNames`); they fall back to the raw
/// id string if no match is found (e.g. `RegisterDetails` hasn't loaded
/// yet), so the UI always has something to show rather than going blank.
class SavedAddress {
  SavedAddress({
    required this.id,
    required this.addressText,
    this.landmark,
    this.cityId,
    this.stateId,
    this.cityName,
    this.stateName,
    this.pincode,
    this.coordinates,
    required this.typeOfAddress,
    this.isDefault = false,
  });

  /// The backend's address record id — required once an address exists on
  /// the server; `GET /addresses/:addressId`, `PUT`, `DELETE`, and
  /// `PUT .../set-primary` all key off this.
  final int id;

  final String addressText;
  final String? landmark;
  final int? cityId;
  final int? stateId;
  final String? cityName;
  final String? stateName;
  final String? pincode;

  /// "lat,lng", when the backend has one for this address — `null` for any
  /// address saved before coordinates were captured (e.g. the pasted
  /// examples from the backend, which show `"coordinates": null`).
  final String? coordinates;

  /// Raw backend value, e.g. `"HOME"`, `"OFFICE"`, `"OTHER"` — compared
  /// case-insensitively via [typeKey] for display/icon lookups, since the
  /// backend sends it uppercase while the rest of the app's label-matching
  /// switches (`_labelFor`, icon pickers) use the `'Home'`/`'Office'` casing.
  final String typeOfAddress;
  bool isDefault;

  /// Canonical (non-localized) address label key — `'Home'`, `'Office'`, or
  /// `'Other'` — normalized from [typeOfAddress] for the existing
  /// label/icon-matching switches across the app.
  String get typeKey => switch (typeOfAddress.toUpperCase()) {
    'HOME' => 'Home',
    'OFFICE' => 'Office',
    _ => 'Other',
  };

  /// Canonical (non-localized) address label key — kept as an alias of
  /// [typeKey] so existing call sites (`_labelFor(l10n, address.label)`)
  /// don't need to change.
  String get label => typeKey;

  FaIconData get icon => switch (typeKey) {
    'Home' => FontAwesomeIcons.house,
    'Office' => FontAwesomeIcons.briefcase,
    _ => FontAwesomeIcons.locationDot,
  };

  /// Full display string — address, landmark, city/state (names when
  /// resolved, else the raw ids), and pincode, each on its own line where
  /// present.
  String get line {
    final cityState = [
      cityName ?? (cityId?.toString()),
      stateName ?? (stateId?.toString()),
    ].where((p) => p != null && p.isNotEmpty).join(', ');
    return [
      addressText,
      if (landmark != null && landmark!.isNotEmpty) landmark,
      [cityState, pincode].where((p) => p != null && p.isNotEmpty).join(' '),
    ].where((p) => p != null && p.isNotEmpty).join(',\n');
  }

  /// "lat,lng" parsed out of [coordinates] as `(lat, lng)`, or `null` if
  /// there's no coordinate string or it doesn't parse.
  (double, double)? get latLng {
    final raw = coordinates;
    if (raw == null) return null;
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as int,
    addressText: json['address'] as String? ?? '',
    landmark: json['landmark'] as String?,
    cityId: int.tryParse(json['city']?.toString() ?? ''),
    stateId: int.tryParse(json['state']?.toString() ?? ''),
    pincode: json['pincode'] as String?,
    coordinates: json['coordinates'] as String?,
    typeOfAddress: json['type_of_address'] as String? ?? 'OTHER',
    isDefault: json['is_primary'] == 1 || json['is_primary'] == true,
  );

  /// Request body for `POST /addresses` (create) and
  /// `PUT /addresses/:addressId` (update) — same shape either way.
  Map<String, dynamic> toRequestJson() => {
    'address': addressText,
    'landmark': landmark,
    'city_id': cityId,
    'state_id': stateId,
    'pincode': pincode,
    'coordinates': coordinates,
    'type_of_address': typeOfAddress,
  };
}

class Addon {
  const Addon(this.name, this.price, {this.id, this.source});
  final String name;
  final int price;

  /// The backend add-on record id, when known (real add-ons fetched from
  /// `GET /customer/service-detail/:serviceId` carry one; `null` for any
  /// legacy/local-only addon).
  final int? id;

  /// The full add-on record this was built from, when available — carries
  /// quantity/unit/warranty detail beyond just id/name/price, used to send
  /// a complete line-item breakdown on the place-order request.
  final ServiceAddOn? source;
}

/// An extra service bundled onto the order being booked, picked from the
/// "Add More Services" option on `BookingScreen` — from the same provider as
/// the primary service, before checkout. Distinct from a sub-order added
/// after the fact (see `AddMoreServicesScreen`): this one rides along with
/// the primary order's own Razorpay payment, and only becomes a real
/// sub-order (via `POST /customer/orders/:orderId/sub-orders`) once that
/// payment succeeds — see `PaymentScreen._placeOrder`.
class ExtraService {
  const ExtraService({
    required this.serviceId,
    required this.label,
    required this.servicePrice,
    this.addons = const [],
  });

  final int serviceId;

  /// `service_category_name [/ service_sub_category_name]`, for display.
  final String label;

  /// This service's own price, excluding its add-ons — see [addonsTotal]
  /// and [totalPrice] for the combined figures.
  final int servicePrice;

  /// The add-ons selected for this specific service, kept as full records
  /// (not just ids) so `BookingScreen` can list them the same way it lists
  /// the primary service's own add-ons.
  final List<Addon> addons;

  int get addonsTotal => addons.fold(0, (sum, a) => sum + a.price);

  /// This service's price plus its own selected add-ons — what it adds to
  /// the order's overall total.
  int get totalPrice => servicePrice + addonsTotal;

  List<int> get addonIds =>
      addons.where((a) => a.id != null).map((a) => a.id!).toList();
}

/// Mirrors the `state` object in the web prototype's app.js.
///
/// [category] and [sub] hold display strings for the currently selected
/// category/sub-category. Screens added before the API migration
/// (`booking_screen.dart`, `orders_screen.dart`, `tracking_screen.dart`,
/// `payment_screen.dart`) still read them as canonical English keys and pass
/// them through [localizedServiceName] for display — that lookup falls back
/// to returning the raw string for any key it doesn't recognise, so real
/// API-driven category/sub-category names (which aren't in the static
/// dictionary) still render correctly, just without translation.
///
/// [categoryId]/[categoryName] and [subCategoryId]/[subCategoryName] are the
/// real numeric ids + names from the backend (`/customer/services` and
/// `/customer/services/:categoryId/providers`), set via [selectCategory] and
/// [selectSub]. They are `null` until a category has been picked from Home.
class AppState extends ChangeNotifier {
  String category = 'AC Repair';
  String sub = 'AC Service';
  String provider = 'Rajesh Kumar';

  /// The selected slot's `label`, exactly as returned by
  /// `GET /customer/slots` — sent back verbatim as `slot` when creating an
  /// order/sub-order, since the backend matches it character for character.
  /// Empty until the customer picks one; never a hardcoded default, since
  /// the slot list itself is admin-configured per zone and can't be assumed.
  String slot = '';

  /// The booking date selected on the Review & Schedule screen. `null`
  /// until the user picks one; required (alongside [slot]) by
  /// `POST /customer/orders`.
  DateTime? bookingDate;

  /// The *effective* booking type for this order — set by `BookingScreen`
  /// once it's known. Defaults to [BookingType.regular]; only becomes
  /// [BookingType.instant] when an Instant pick on `ProvidersScreen`
  /// actually auto-selected a slot. If that Instant check found nothing
  /// bookable soon and fell back to manual date/slot picking, this stays
  /// [BookingType.regular] even though the screen was entered as Instant,
  /// since the customer ended up picking a slot manually either way.
  ///
  /// Drives `booking_type` on both `GET /customer/platform-fee` (so the fee
  /// shown matches the type of booking being made) and
  /// `POST /customer/orders` (so the two always agree).
  BookingType bookingType = BookingType.regular;

  int amount = 499;
  final List<Addon> addons = [];

  int? categoryId;
  String? categoryName;
  int? subCategoryId;
  String? subCategoryName;

  /// The service and provider currently being booked, set by
  /// `BookingScreen` once `GET /customer/service-detail/:serviceId`
  /// resolves. Read by `PaymentScreen` to build the place-order request.
  int? bookingServiceId;
  int? bookingProviderId;

  /// Extra services bundled onto this order from the same provider, picked
  /// via `BookingScreen`'s "Add More Services" option before checkout — see
  /// [ExtraService]. Cleared alongside [addons] whenever a new primary
  /// service's booking screen loads.
  final List<ExtraService> extraServices = [];

  /// The platform fee for the checkout summary, fetched by `PaymentScreen`
  /// from `GET /customer/platform-fee` — never hardcoded, since it can
  /// change server-side at any time. `null` until that fetch resolves;
  /// [payable] treats a `null` fee as `0` rather than blocking, but
  /// `PaymentScreen` itself keeps "Pay & Place Order" disabled until a real
  /// value is in hand, so the amount shown always matches what Razorpay
  /// will actually charge.
  int? platformFee;

  /// The zone id the current [platformFee] was calculated for, from the
  /// same response — echoed back as `zone_id` on `POST /customer/orders` so
  /// the order is created in the exact zone the fee matched, per the
  /// backend's own "same zone as order creation" contract.
  int? platformFeeZoneId;

  /// The customer's saved address book, from `GET /addresses` — see
  /// [SavedAddress]. Shared between `SavedAddressesScreen` and the home
  /// screen's location picker. Empty until [setAddresses] is called
  /// (`HomeScreen` fetches on load, same as it does categories/user/etc.).
  final List<SavedAddress> addresses = [];

  /// `null` means the home screen shows the device's live GPS location
  /// (`DeviceInfoService.currentAddress()`) — the Blinkit-style default.
  /// Set by the home screen's location picker when the customer picks a
  /// saved address instead; cleared by picking "Use current location"
  /// there again.
  SavedAddress? selectedAddress;

  /// Picks [address] as the active delivery location, or clears back to the
  /// live GPS location when `null` (the "Use current location" option).
  void selectAddress(SavedAddress? address) {
    selectedAddress = address;
    notifyListeners();
  }

  /// Replaces the whole address book — called after `GET /addresses`
  /// resolves. Keeps [selectedAddress] pointing at the same backend record
  /// (matched by id) if it's still present in the new list, since the old
  /// [SavedAddress] instance is no longer `==` to anything in [addresses]
  /// once the list has been refetched.
  void setAddresses(List<SavedAddress> newAddresses) {
    addresses
      ..clear()
      ..addAll(newAddresses);
    final selectedId = selectedAddress?.id;
    selectedAddress = selectedId == null
        ? null
        : addresses.where((a) => a.id == selectedId).firstOrNull;
    notifyListeners();
  }

  /// Appends a newly created [SavedAddress] — e.g. from
  /// [AddSavedAddressScreen] after `POST /addresses` succeeds — and
  /// notifies listeners so the address book and home screen's location
  /// picker both pick it up immediately.
  void addAddress(SavedAddress address) {
    addresses.add(address);
    notifyListeners();
  }

  /// Replaces the address with the same [SavedAddress.id] — e.g. after
  /// `PUT /addresses/:addressId` succeeds. Updates [selectedAddress] too if
  /// it was pointing at the old instance of this same address.
  void updateAddress(SavedAddress updated) {
    final i = addresses.indexWhere((a) => a.id == updated.id);
    if (i == -1) return;
    addresses[i] = updated;
    if (selectedAddress?.id == updated.id) selectedAddress = updated;
    notifyListeners();
  }

  /// Removes the address with [addressId] — e.g. after
  /// `DELETE /addresses/:addressId` succeeds. Falls back [selectedAddress]
  /// to live GPS if it was pointing at the address just removed.
  void removeAddress(int addressId) {
    addresses.removeWhere((a) => a.id == addressId);
    if (selectedAddress?.id == addressId) selectedAddress = null;
    notifyListeners();
  }

  int get addonsTotal => addons.fold(0, (sum, a) => sum + a.price);

  /// Every extra service's own price plus its own add-ons' total.
  int get extraServicesTotal =>
      extraServices.fold(0, (sum, s) => sum + s.totalPrice);

  int get subtotal => amount + addonsTotal + extraServicesTotal;
  int get payable => subtotal + (platformFee ?? 0);

  /// Records the platform fee + the zone it was calculated for. Called by
  /// `PaymentScreen` once `GET /customer/platform-fee` resolves.
  void setPlatformFee({required int fee, int? zoneId}) {
    platformFee = fee;
    platformFeeZoneId = zoneId;
    notifyListeners();
  }

  /// Adds [service], replacing any existing entry for the same
  /// `serviceId` (picking it again re-picks its add-ons from scratch).
  void addExtraService(ExtraService service) {
    extraServices.removeWhere((s) => s.serviceId == service.serviceId);
    extraServices.add(service);
    notifyListeners();
  }

  void removeExtraService(int serviceId) {
    extraServices.removeWhere((s) => s.serviceId == serviceId);
    notifyListeners();
  }

  /// Clears bundled extra services — called alongside [clearAddons] when a
  /// new primary service's booking screen loads, since they belonged to
  /// whatever service/provider was being booked before.
  void clearExtraServices() {
    if (extraServices.isEmpty) return;
    extraServices.clear();
    notifyListeners();
  }

  bool hasAddon(String name) => addons.any((a) => a.name == name);

  void toggleAddon(Addon addon) {
    final i = addons.indexWhere((a) => a.name == addon.name);
    i >= 0 ? addons.removeAt(i) : addons.add(addon);
    notifyListeners();
  }

  /// Clears selected add-ons — called when a new service's booking screen
  /// loads, since [addons] is a single shared list, not scoped per-service.
  void clearAddons() {
    if (addons.isEmpty) return;
    addons.clear();
    notifyListeners();
  }

  void selectSlot(String value) {
    slot = value;
    notifyListeners();
  }

  /// Records the booking date and clears the previously selected [slot],
  /// since each date has its own independent set of booked/available slots.
  void selectDate(DateTime date) {
    bookingDate = date;
    slot = '';
    notifyListeners();
  }

  /// Clears [bookingDate], [slot] and resets [bookingType] back to
  /// [BookingType.regular] — called when `BookingScreen` loads for a new
  /// service, since all three are single shared fields, not scoped per-
  /// service/provider. Without this, a date/slot (or an Instant booking
  /// type) from a previous booking would carry over to a different
  /// provider, and the slot grid would show `booked-slots` data that
  /// doesn't even belong to it.
  void clearBookingSchedule() {
    bookingDate = null;
    slot = '';
    bookingType = BookingType.regular;
    notifyListeners();
  }

  /// Records the effective booking type once `BookingScreen` knows it — see
  /// [bookingType] for when it does/doesn't end up [BookingType.instant].
  void setBookingType(BookingType type) {
    bookingType = type;
    notifyListeners();
  }

  /// `booking_date` formatted as `YYYY-MM-DD` for the API, or `null` if no
  /// date has been picked yet.
  String? get bookingDateApiValue {
    final date = bookingDate;
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Sets the base service price for the booking totals (add-ons and
  /// platform fee still apply on top). Called once a real service's price
  /// loads from `GET /customer/service-detail/:serviceId`.
  void setBookingAmount(int value) {
    amount = value;
    notifyListeners();
  }

  /// Records the real category selected from the API-driven Home grid.
  /// Clears any previously selected sub-category, since it belonged to the
  /// old category.
  void selectCategory(int id, String name) {
    categoryId = id;
    categoryName = name;
    category = name;
    subCategoryId = null;
    subCategoryName = null;
    notifyListeners();
  }

  /// Records the real sub-category selected from the providers screen rail.
  /// Pass `null` id/name to clear back to "All".
  void selectSub(int? id, String? name) {
    subCategoryId = id;
    subCategoryName = name;
    if (name != null) sub = name;
    notifyListeners();
  }
}

/// Translates a canonical category/sub-service key (as used by [AppState])
/// into the string for the active locale. Falls back to the key itself for
/// any value not in the lookup (e.g. `'Pipe Repair'`, which has no dedicated
/// screen surface today).
String localizedServiceName(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context);
  return <String, String>{
        'Electrician': l10n.catElectrician,
        'Plumber': l10n.catPlumber,
        'AC Repair': l10n.catAcRepair,
        'Cleaning': l10n.catCleaning,
        'Carpenter': l10n.catCarpenter,
        'Painter': l10n.catPainter,
        'Car Wash': l10n.catCarWash,
        'Appliance': l10n.catAppliance,
        'Locksmith': l10n.catLocksmith,
        'Packers': l10n.catPackers,
        'Beauty': l10n.catBeauty,
        'View All': l10n.catViewAll,
        'Painting': l10n.catPainting,
        'AC Service': l10n.subAcService,
        'AC Installation': l10n.subAcInstallation,
        'Gas Refill': l10n.subGasRefill,
        'AC Cleaning': l10n.subAcCleaning,
        'Wiring & Installation': l10n.subWiringInstallation,
        'Switch & Socket': l10n.subSwitchSocket,
        'Fan Repair': l10n.subFanRepair,
        'Lighting': l10n.subLighting,
        'MCB Repair': l10n.subMcbRepair,
        'General Service': l10n.subGeneralService,
        'Repair': l10n.subRepair,
        'Installation': l10n.subInstallation,
        'Maintenance': l10n.subMaintenance,
      }[key] ??
      key;
}

/// Simple InheritedNotifier so screens can read state without extra packages.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
