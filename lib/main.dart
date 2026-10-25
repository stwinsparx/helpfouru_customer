import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'models/app_state.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HelpFourUApp());
}

class HelpFourUApp extends StatefulWidget {
  const HelpFourUApp({super.key});

  @override
  State<HelpFourUApp> createState() => _HelpFourUAppState();
}

class _HelpFourUAppState extends State<HelpFourUApp> {
  final _state = AppState();
  final _localeController = LocaleController();

  @override
  void initState() {
    super.initState();
    _localeController.addListener(_onLocaleChanged);
    _localeController.load();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  void dispose() {
    _localeController.removeListener(_onLocaleChanged);
    _localeController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: LocaleControllerScope(
        controller: _localeController,
        child: MaterialApp(
          title: 'HelpFourU',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: _localeController.locale,
          supportedLocales: LocaleController.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // The app's layouts are hand-tuned to specific font sizes
          // throughout (cards, chips, grids) — honoring the device's own
          // text-scale setting would overflow/clip many of them, so the
          // app always renders at a fixed scale regardless of what the
          // user has set under their phone's display/accessibility
          // settings. This only clamps text scaling; everything else
          // (bold text, dark mode, reduced motion) still passes through
          // from the platform as normal.
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

/// Lets any screen read the active [LocaleController] and call
/// `setLocale()` without prop-drilling it through every route.
class LocaleControllerScope extends InheritedWidget {
  const LocaleControllerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final LocaleController controller;

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleControllerScope>();
    assert(scope != null, 'No LocaleControllerScope found in context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(LocaleControllerScope oldWidget) =>
      controller != oldWidget.controller;
}
