import 'package:flutter/material.dart';

class Addon {
  const Addon(this.name, this.price);
  final String name;
  final int price;
}

/// Mirrors the `state` object in the web prototype's app.js.
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

  /// Sub-services shown on the left rail of the providers screen.
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
