import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'my_bids_screen.dart';
import 'notifications_screen.dart';
import 'account_screen.dart';

/// Tab host for the five bottom-nav destinations.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Switch the shell's active tab from anywhere below it, popping any
  /// pushed routes on the way.
  static void goToTab(BuildContext context, int index) {
    final shell = context.findAncestorStateOfType<_AppShellState>();
    if (shell == null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    shell.setTab(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void setTab(int index) {
    if (!mounted) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          OrdersScreen(),
          MyBidsScreen(),
          NotificationsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        active: NavTab.values[_index],
        onSelect: (tab) => setTab(NavTab.values.indexOf(tab)),
      ),
    );
  }
}
