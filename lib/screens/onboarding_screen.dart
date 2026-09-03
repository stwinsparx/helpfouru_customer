import 'package:flutter/material.dart';
import '../core/services/token_storage.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _gifs = <String>[
    'assets/onboarding/page_1.gif',
    'assets/onboarding/page_2.gif',
    'assets/onboarding/page_3.gif',
  ];

  List<(String, String, String)> _pages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      (_gifs[0], l10n.onboardTitle1, l10n.onboardBody1),
      (_gifs[1], l10n.onboardTitle2, l10n.onboardBody2),
      (_gifs[2], l10n.onboardTitle3, l10n.onboardBody3),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    TokenStorage.markOnboardingSeen();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (_index < _gifs.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _gifs.length - 1;
    final pages = _pages(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.onboardBg),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _OnboardPage(
                    gif: pages[i].$1,
                    title: pages[i].$2,
                    body: pages[i].$3,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? AppColors.green : const Color(0xFFCCD7E3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 20),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: isLast
                          ? AppLocalizations.of(context).getStarted
                          : AppLocalizations.of(context).continueLabel,
                      onTap: _next,
                    ),
                    SizedBox(
                      height: 42,
                      child: isLast
                          ? null
                          : TextButton(
                              onPressed: _goToLogin,
                              child: Text(
                                AppLocalizations.of(context).skip,
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.gif,
    required this.title,
    required this.body,
  });
  final String gif;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient art panel with the two soft circles from the CSS.
          Container(
            width: 250,
            height: 240,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(35),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33105968),
                  blurRadius: 35,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Stack(
                children: [
                  Positioned(right: -70, top: -50, child: _Blob(size: 180)),
                  Positioned(left: -45, bottom: -35, child: _Blob(size: 120)),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        gif,
                        width: 220,
                        height: 210,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 34),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0x1AFFFFFF),
        shape: BoxShape.circle,
      ),
    );
  }
}
