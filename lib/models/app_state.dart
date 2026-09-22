import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'service_category.dart';

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
  String slot = '10:00 AM - 11:00 AM';

  /// The booking date selected on the Review & Schedule screen. `null`
  /// until the user picks one; required (alongside [slot]) by
  /// `POST /customer/orders`.
  DateTime? bookingDate;

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

  static const platformFee = 49;

  int get addonsTotal => addons.fold(0, (sum, a) => sum + a.price);
  int get subtotal => amount + addonsTotal;
  int get payable => subtotal + platformFee;

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
  }[key] ?? key;
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
