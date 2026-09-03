import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class Addon {
  const Addon(this.name, this.price);
  final String name;
  final int price;
}

/// Mirrors the `state` object in the web prototype's app.js.
///
/// [category] and [sub] hold canonical (non-localized) English keys used to
/// drive matching logic (`selectCategory`'s switch, [subServices]). Screens
/// that display them to the user must go through [localizedServiceName] to
/// render the string in the active app language.
class AppState extends ChangeNotifier {
  String category = 'AC Repair';
  String sub = 'AC Service';
  String provider = 'Rajesh Kumar';
  String slot = '10:00 AM - 11:00 AM';
  int amount = 499;
  final List<Addon> addons = [];

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

  void selectSlot(String value) {
    slot = value;
    notifyListeners();
  }

  void selectCategory(String value) {
    category = value;
    sub = switch (value) {
      'Electrician' => 'Wiring & Installation',
      'Plumber' => 'Pipe Repair',
      _ => 'AC Service',
    };
    notifyListeners();
  }

  void selectSub(String value) {
    sub = value;
    notifyListeners();
  }

  /// Sub-services shown on the left rail of the providers screen. Canonical
  /// English keys — localize each entry with [localizedSub] before display.
  List<String> get subServices => switch (category) {
    'AC Repair' => const [
      'AC Service',
      'AC Installation',
      'Gas Refill',
      'AC Cleaning',
      'AC Repair',
    ],
    'Electrician' => const [
      'Wiring & Installation',
      'Switch & Socket',
      'Fan Repair',
      'Lighting',
      'MCB Repair',
    ],
    _ => const ['General Service', 'Repair', 'Installation', 'Maintenance'],
  };
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
