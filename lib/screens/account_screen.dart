import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/token_storage.dart';
import '../l10n/app_localizations.dart';
import '../models/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'personal_info_screen.dart';
import 'saved_addresses_screen.dart';
import 'help_support_screen.dart';
import 'settings_screen.dart';
import 'privacy_screen.dart';
import 'login_screen.dart';
import 'shell.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  CurrentUser? _user;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await CurrentUser.load();
    if (mounted) setState(() => _user = user);
  }

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.logOutQuestion,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.logOutConfirmBody,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await TokenStorage.clearToken();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              l10n.logOut,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              l10n.myProfileTitle,
              style: const TextStyle(
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
                    child: Text(
                      _user?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.name ?? l10n.guestName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (_user?.phone.isNotEmpty ?? false) _user!.phone,
                            if (_user?.email.isNotEmpty ?? false) _user!.email,
                          ].join(' · '),
                          style: const TextStyle(
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
                    child: Text(
                      l10n.edit,
                      style: const TextStyle(
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
                    title: l10n.personalInformationTitle,
                    subtitle: l10n.personalInformationSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen(),
                      ),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.locationDot,
                    title: l10n.savedAddressesTitle,
                    subtitle: l10n.savedAddressesSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SavedAddressesScreen(),
                      ),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.bell,
                    title: l10n.notificationsTitle,
                    subtitle: l10n.notificationsSubtitle,
                    onTap: () => AppShell.goToTab(context, 3),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.gear,
                    title: l10n.applicationSettingsTitle,
                    subtitle: l10n.applicationSettingsSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.globe,
                    title: l10n.languageTitle,
                    subtitle: l10n.languageSubtitleBoth,
                    onTap: () => showLanguagePicker(context),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.shieldHalved,
                    title: l10n.privacyPolicyTitle,
                    subtitle: l10n.privacyPolicySubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.heart,
                    title: l10n.helpAndSupportTitle,
                    subtitle: l10n.helpAndSupportSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                  _AccountItem(
                    icon: FontAwesomeIcons.rightFromBracket,
                    title: l10n.logoutTitle,
                    subtitle: l10n.logoutSubtitle,
                    isLast: true,
                    onTap: () => _confirmLogout(context),
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
