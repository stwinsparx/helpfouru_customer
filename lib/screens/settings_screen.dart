import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _push = true;
  bool _promos = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = LocaleControllerScope.of(context).locale;
    final languageSubtitle = locale.languageCode == 'hi'
        ? l10n.languageSettingSubtitleHindi
        : l10n.languageSettingSubtitleEnglish;
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.applicationSettingsHeader),

            _GroupLabel(l10n.preferencesGroup),
            _SettingsGroup(
              children: [
                _SettingRow(
                  icon: FontAwesomeIcons.globe,
                  title: l10n.languageTitle,
                  subtitle: languageSubtitle,
                  trailing: TextButton(
                    onPressed: () => showLanguagePicker(context),
                    child: Text(
                      l10n.change,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.bell,
                  title: l10n.pushNotificationsTitle,
                  subtitle: l10n.pushNotificationsSubtitle,
                  trailing: Switch(
                    value: _push,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.green,
                    onChanged: (v) => setState(() => _push = v),
                  ),
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.bullhorn,
                  title: l10n.promotionalOffersTitle,
                  subtitle: l10n.promotionalOffersSubtitle,
                  trailing: Switch(
                    value: _promos,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.green,
                    onChanged: (v) => setState(() => _promos = v),
                  ),
                ),
              ],
            ),

            _GroupLabel(l10n.securityGroup),
            _SettingsGroup(
              children: [
                _SettingRow(
                  icon: FontAwesomeIcons.lock,
                  title: l10n.loginAndSecurityTitle,
                  subtitle: l10n.loginAndSecuritySubtitle,
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.fileInvoice,
                  title: l10n.paymentPreferencesTitle,
                  subtitle: l10n.paymentPreferencesSubtitle,
                ),
              ],
            ),

            _GroupLabel(l10n.appGroup),
            _SettingsGroup(
              children: [
                _SettingRow(
                  icon: FontAwesomeIcons.solidStar,
                  title: l10n.rateHelpFourUTitle,
                  subtitle: l10n.rateHelpFourUSubtitle,
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.circleInfo,
                  title: l10n.appVersionTitle,
                  subtitle: l10n.appVersionSubtitle,
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 16, 3, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
          color: Color(0xFF8190A1),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(13),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDF1F4))),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 14, color: AppColors.blue),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          trailing ??
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 12,
                color: Color(0xFFA4B0BD),
              ),
        ],
      ),
    );
  }
}
