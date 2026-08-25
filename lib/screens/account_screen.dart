import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'personal_info_screen.dart';
import 'saved_addresses_screen.dart';
import 'help_support_screen.dart';
import 'settings_screen.dart';
import 'privacy_screen.dart';
import 'login_screen.dart';
import 'shell.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),

            AppCard(
              radius: 16,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppGradients.avatar,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'SK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shubham Kumar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '98765 43210 · shubham@example.com',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen(),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _AccountItem(
                    icon: FontAwesomeIcons.user,
                    title: 'Personal Information',
                    subtitle: 'Name, mobile, email, address',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen(),
                      ),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.locationDot,
                    title: 'Saved Addresses',
                    subtitle: 'Home · Office · 2 saved',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SavedAddressesScreen(),
                      ),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.bell,
                    title: 'Notifications',
                    subtitle: 'Manage booking and promotional alerts',
                    onTap: () => AppShell.goToTab(context, 3),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.gear,
                    title: 'Application Settings',
                    subtitle: 'Language, preferences, security',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.globe,
                    title: 'Language',
                    subtitle: 'English / हिन्दी',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.shieldHalved,
                    title: 'Privacy Policy',
                    subtitle: 'Data and privacy controls',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.heart,
                    title: 'Help & Support',
                    subtitle: 'Chat with HelpFourU support',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.rightFromBracket,
                    title: 'Logout',
                    subtitle: 'Sign out of this device',
                    isLast: true,
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountItem extends StatelessWidget {
  const _AccountItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLast = false,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFEDF1F4))),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FE),
                borderRadius: BorderRadius.circular(9),
              ),
              child: FaIcon(icon, size: 13, color: AppColors.blue),
            ),
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12,
              color: Color(0xFFA4B0BD),
            ),
          ],
        ),
      ),
    );
  }
}
