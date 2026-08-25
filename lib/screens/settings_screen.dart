import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const MiniHeader(title: 'Application Settings'),

            const _GroupLabel('Preferences'),
            _SettingsGroup(
              children: [
                _SettingRow(
                  icon: FontAwesomeIcons.globe,
                  title: 'Language',
                  subtitle: 'English',
                  trailing: TextButton(
                    onPressed: () =>
                        showAppToast(context, 'Language selector opened'),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.bell,
                  title: 'Push Notifications',
                  subtitle: 'Booking updates and alerts',
                  trailing: Switch(
                    value: _push,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.green,
                    onChanged: (v) => setState(() => _push = v),
                  ),
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.bullhorn,
                  title: 'Promotional Offers',
                  subtitle: 'Deals and service recommendations',
                  trailing: Switch(
                    value: _promos,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.green,
                    onChanged: (v) => setState(() => _promos = v),
                  ),
                ),
              ],
            ),

            const _GroupLabel('Security'),
            const _SettingsGroup(
              children: [
                _SettingRow(
                  icon: FontAwesomeIcons.lock,
                  title: 'Login & Security',
                  subtitle: 'OTP and account security',
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.fileInvoice,
                  title: 'Payment Preferences',
                  subtitle: 'Saved methods and invoices',
                ),
              ],
            ),

            const _GroupLabel('App'),
            const _SettingsGroup(
              children: [
                _SettingRow(
                  icon: FontAwesomeIcons.solidStar,
                  title: 'Rate HelpFourU',
                  subtitle: 'Help us improve',
                ),
                _SettingRow(
                  icon: FontAwesomeIcons.circleInfo,
                  title: 'App Version',
                  subtitle: 'Customer v1.0.0',
                  trailing: SizedBox.shrink(),
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
