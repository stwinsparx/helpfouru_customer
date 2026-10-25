import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../theme/app_theme.dart';

/// Local SVG fallback icons for known category names, used only when the
/// API doesn't provide an `image` for that category. Matched via substring
/// against the lowercased `category_name`, so variants like "AC Repair &
/// Service" or "Home Cleaning" still resolve — see [localCategoryIconFor].
/// Shared between the Home screen's Explore Services grid and
/// [AllCategoriesScreen]-style full category lists.
const _localCategoryIcons = <String, String>{
  'electric': 'assets/icons/categories/electrician.svg',
  'plumb': 'assets/icons/categories/plumber.svg',
  'ac repair': 'assets/icons/categories/ac_repair.svg',
  'ac service': 'assets/icons/categories/ac_repair.svg',
  'clean': 'assets/icons/categories/cleaning.svg',
  'carpen': 'assets/icons/categories/carpenter.svg',
  'paint': 'assets/icons/categories/painter.svg',
  'car wash': 'assets/icons/categories/car_wash.svg',
  'appliance': 'assets/icons/categories/appliance.svg',
  'locksmith': 'assets/icons/categories/locksmith.svg',
  'packers': 'assets/icons/categories/packers.svg',
  'beaut': 'assets/icons/categories/beauty.svg',
};

const _defaultCategoryIcon = 'assets/icons/categories/view_all.svg';

/// Finds the local SVG asset whose key is a substring of [categoryName]
/// (case-insensitive), falling back to [_defaultCategoryIcon] when nothing
/// matches — so near-miss category names from the API (e.g. "AC Repair &
/// Service", "Home Cleaning") still get a category-specific icon instead of
/// the generic placeholder.
String localCategoryIconFor(String categoryName) {
  final name = categoryName.toLowerCase();
  for (final entry in _localCategoryIcons.entries) {
    if (name.contains(entry.key)) return entry.value;
  }
  return _defaultCategoryIcon;
}

/// Pastel tint backgrounds cycled across category tiles — shared by the
/// Home screen's Explore Services grid and [AllCategoriesScreen]-style
/// full category lists.
const categoryTintPalette = [
  Color(0xFFE3F6E9),
  Color(0xFFFFF3D6),
  Color(0xFFDDEEFB),
  Color(0xFFFCE4E4),
  Color(0xFFE1EEFC),
  Color(0xFFFCE6F0),
  Color(0xFFEAE3FB),
  Color(0xFFE1F5EA),
];

/// A single circular category glyph + label — the Explore Services tile
/// look, reused wherever a category grid is shown.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    this.iconUrl,
    this.localIconAsset,
    this.iconWidget,
    required this.label,
    required this.tint,
    this.onTap,
  });

  /// Remote category photo from the API. When present, fills the tile's
  /// circle as a cover photo instead of the small centered SVG glyph.
  final String? iconUrl;
  final String? localIconAsset;

  /// Overrides [iconUrl]/[localIconAsset] entirely — used for tiles with no
  /// category icon to render (e.g. a "More Services" tile).
  final Widget? iconWidget;
  final String label;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipOval(
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                color: tint,
                child: _buildIcon(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (iconWidget != null) return iconWidget!;
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: iconUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => SizedBox(
          width: 24,
          height: 24,
          child: SvgPicture.asset(localIconAsset!, fit: BoxFit.contain),
        ),
      );
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: SvgPicture.asset(localIconAsset!, fit: BoxFit.contain),
    );
  }
}

/// Full-width gradient CTA — the prototype's `.primary`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E0BA360),
              blurRadius: 20,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined white CTA — the prototype's `.secondary`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.blueDark,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        child: Text(label),
      ),
    );
  }
}

/// White rounded container used for nearly every content block.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.radius = 15,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Back-chevron + title row — the prototype's `.mini-head`.
class MiniHeader extends StatelessWidget {
  const MiniHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.chevronLeft,
                  size: 13,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with an optional trailing text action.
class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill badge — statuses, "VERIFIED", chips.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.background = AppColors.mint,
    this.foreground = AppColors.greenDark,
    this.fontSize = 10,
    this.icon,
  });
  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;

  /// Optional leading glyph — e.g. a status pill showing a small clock or
  /// spinner icon before the label.
  final FaIconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            FaIcon(icon, size: fontSize, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable chip used for filters and order tabs.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : Colors.white,
          border: Border.all(
            color: selected ? AppColors.mintBorder : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.greenDark : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

/// Label + row used inside pricing/summary cards.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFEEF2F5)))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Emphasised total row at the bottom of a summary card.
class TotalRow extends StatelessWidget {
  const TotalRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// Opens the device's dialer pre-filled with [phoneNumber] via a `tel:`
/// deep link — used by every "Call" action (order detail, tracking) that
/// has a real provider/support phone number to call. Shows [l10n]'s
/// `couldNotOpenDialerToast` if the platform refuses to launch it (no
/// dialer app, simulator, malformed number) rather than failing silently.
Future<void> launchPhoneDialer(BuildContext context, String phoneNumber) async {
  final l10n = AppLocalizations.of(context);
  final uri = Uri(scheme: 'tel', path: phoneNumber);
  try {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      showAppToast(context, l10n.couldNotOpenDialerToast);
    }
  } catch (_) {
    if (context.mounted) {
      showAppToast(context, l10n.couldNotOpenDialerToast);
    }
  }
}

/// The prototype's `toast()` — a dark pill sliding in from the top.
void showAppToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 12.5, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF10253B),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2600),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Labelled input matching the prototype's `.field`.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF63758B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Shows a simple English/Hindi picker and applies the choice via the
/// nearest [LocaleControllerScope]. Used by both the Account screen's
/// "Language" menu item and the Settings screen's language row.
void showLanguagePicker(BuildContext context) {
  final controller = LocaleControllerScope.of(context);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => _LanguagePickerDialog(controller: controller),
  );
}

class _LanguagePickerDialog extends StatelessWidget {
  const _LanguagePickerDialog({required this.controller});
  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <(Locale, String)>[
      (const Locale('en'), l10n.englishLanguageOption),
      (const Locale('hi'), l10n.hindiLanguageOption),
    ];
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.selectLanguageTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
                for (final (locale, label) in options)
                  _LanguageOptionTile(
                    label: label,
                    selected: controller.locale == locale,
                    onTap: () {
                      controller.setLocale(locale);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.mintBorder : AppColors.line,
            ),
            color: selected ? const Color(0xFFF5FCF8) : Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? AppColors.green : const Color(0xFFA3AFBD),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.greenDark : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration appInputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFA3AFBD), fontSize: 14),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFDCE5ED)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFDCE5ED)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.green, width: 1.4),
  ),
);

/// Opens a full-screen, pinch-to-zoom preview of a single image — either a
/// hosted [imageUrl] or a not-yet-uploaded [localPath]. Exactly one of the
/// two should be provided.
void showImagePreview(
  BuildContext context, {
  String? imageUrl,
  String? localPath,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: _ImagePreviewScreen(imageUrl: imageUrl, localPath: localPath),
      ),
    ),
  );
}

class _ImagePreviewScreen extends StatelessWidget {
  const _ImagePreviewScreen({this.imageUrl, this.localPath});
  final String? imageUrl;
  final String? localPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      )
                    : Image.file(File(localPath!)),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
