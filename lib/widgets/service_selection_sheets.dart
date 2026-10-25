import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// The two ways to browse providers for a chosen sub-category — see
/// [showOrderTypeSheet]. Mirrors the `availability` query param on
/// `GET /customer/services/:categoryId/providers`.
enum OrderType {
  /// Only providers with an opening in the next 30 minutes.
  instant,

  /// Every provider, same as today's unfiltered list.
  schedule;

  /// The `availability` query param value for this choice.
  String get apiValue => switch (this) {
    OrderType.instant => 'instant',
    OrderType.schedule => 'schedule',
  };
}

/// Shows a mandatory Instant-vs-Schedule picker as a centered modal popup,
/// right after a sub-category has been chosen — mirrors [showFilterSheet]'s
/// presentation (centered, 2-column grid) for a consistent feel across the
/// browse flow. Returns the chosen [OrderType], or `null` if the user
/// dismissed it (X, tap-outside, back) without picking one — callers must
/// treat a `null` result the same as the filter/sub-category sheets do:
/// cancel the flow rather than silently defaulting to one or the other.
Future<OrderType?> showOrderTypeSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<OrderType?>(
    context: context,
    barrierColor: const Color(0xCC12243B),
    builder: (context) => _SelectionSheet<OrderType>(
      title: l10n.selectOrderTypeTitle,
      items: OrderType.values,
      labelOf: (type) => switch (type) {
        OrderType.instant => l10n.orderTypeInstant,
        OrderType.schedule => l10n.orderTypeSchedule,
      },
      iconUrlOf: (_) => null,
      iconDataOf: (type) => switch (type) {
        OrderType.instant => FontAwesomeIcons.bolt,
        OrderType.schedule => FontAwesomeIcons.calendarDays,
      },
      subtitleOf: (type) => switch (type) {
        OrderType.instant => l10n.orderTypeInstantSubtitle,
        OrderType.schedule => l10n.orderTypeScheduleSubtitle,
      },
      centered: true,
      gridColumns: 2,
    ),
  );
}

/// Shows the service-filter picker as a mandatory modal popup, centered on
/// screen with filter options laid out in a 2-column grid. Returns the
/// selected [ServiceFilter], or `null` if the user dismissed it (tapped the
/// X, tapped outside, or pressed back) without picking one — callers must
/// treat a `null` result as "cancel the whole flow", not as "no filter".
/// Callers should not invoke this at all when `filters` is empty — there is
/// nothing to choose from.
Future<ServiceFilter?> showFilterSheet(
  BuildContext context, {
  required List<ServiceFilter> filters,
}) {
  return showDialog<ServiceFilter?>(
    context: context,
    barrierColor: const Color(0xCC12243B),
    builder: (context) => _SelectionSheet<ServiceFilter>(
      title: AppLocalizations.of(context).selectFilterTitle,
      items: filters,
      labelOf: (f) => f.name,
      iconUrlOf: (f) => f.icon,
      centered: true,
      gridColumns: 2,
    ),
  );
}

/// Shows the sub-category picker as a mandatory modal bottom sheet. Returns
/// the selected [ServiceSubCategory], or `null` if the user dismissed it
/// without picking one — callers must treat a `null` result as "cancel the
/// whole flow", not as "all sub-categories". Callers should not invoke this
/// at all when `subCategories` is empty.
Future<ServiceSubCategory?> showSubCategorySheet(
  BuildContext context, {
  required List<ServiceSubCategory> subCategories,
}) {
  return showModalBottomSheet<ServiceSubCategory?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xCC12243B),
    builder: (context) => _SelectionSheet<ServiceSubCategory>(
      title: AppLocalizations.of(context).selectSubCategoryTitle,
      items: subCategories,
      labelOf: (s) => s.categoryName,
      iconUrlOf: (s) => s.image,
    ),
  );
}

/// Shared single-select sheet used by [showFilterSheet] and
/// [showSubCategorySheet] — a title row, a list (or, when [gridColumns] is
/// set, a grid) of tappable option rows/tiles (icon/photo + name, mint
/// highlight when selected), and a single Continue action that's disabled
/// until an option is picked. By default it's a rounded-top sheet anchored
/// to the bottom with a drag handle; passing [centered] shows it instead as
/// a rounded modal card centered on screen, used for [showFilterSheet].
/// There is no "skip" affordance: the sheet's own X button, tapping outside,
/// and the back gesture all dismiss with `null`, which the caller treats as
/// cancelling the flow rather than proceeding unfiltered.
class _SelectionSheet<T> extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.iconUrlOf,
    this.iconDataOf,
    this.subtitleOf,
    this.centered = false,
    this.gridColumns,
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String? Function(T) iconUrlOf;

  /// Overrides the generic sliders glyph with a specific icon per item —
  /// used by [showOrderTypeSheet], whose two options (Instant/Schedule) each
  /// need a distinct icon rather than a shared fallback.
  final FaIconData Function(T)? iconDataOf;

  /// An optional one-line description shown under the label in grid mode —
  /// used by [showOrderTypeSheet] to explain what each option means, since
  /// "Instant"/"Schedule" alone isn't self-explanatory the way a filter or
  /// sub-category name is.
  final String Function(T)? subtitleOf;

  /// Shows the sheet as a centered modal card instead of a bottom-anchored
  /// sheet.
  final bool centered;

  /// When set, lays out [items] as a grid with this many columns instead of
  /// a single-column list.
  final int? gridColumns;

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  T? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.centered) ...[
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8EF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(20, widget.centered ? 18 : 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
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
        ),
        Flexible(
          child: widget.gridColumns == null
              ? ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final item in widget.items)
                      _OptionTile(
                        label: widget.labelOf(item),
                        iconUrl: widget.iconUrlOf(item),
                        selected: _selected == item,
                        onTap: () => setState(() => _selected = item),
                      ),
                  ],
                )
              : GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: widget.items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.gridColumns!,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // A subtitle needs more vertical room than the plain
                    // icon+label grid (e.g. the filter picker) does.
                    childAspectRatio: widget.subtitleOf == null ? 1.05 : 0.85,
                  ),
                  itemBuilder: (context, i) {
                    final item = widget.items[i];
                    return _GridOptionTile(
                      label: widget.labelOf(item),
                      iconUrl: widget.iconUrlOf(item),
                      iconData: widget.iconDataOf?.call(item),
                      subtitle: widget.subtitleOf?.call(item),
                      selected: _selected == item,
                      onTap: () => setState(() => _selected = item),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Opacity(
            opacity: _selected == null ? 0.5 : 1,
            child: PrimaryButton(
              label: l10n.continueLabel,
              onTap: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
            ),
          ),
        ),
      ],
    );

    if (widget.centered) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: content,
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: content,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.iconUrl,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? iconUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5FCF8) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.mintBorder : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.iceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: iconUrl != null && iconUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: iconUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const FaIcon(
                          FontAwesomeIcons.sliders,
                          size: 14,
                          color: AppColors.blue,
                        ),
                      )
                    : const FaIcon(
                        FontAwesomeIcons.sliders,
                        size: 14,
                        color: AppColors.blue,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.greenDark : AppColors.ink,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? AppColors.green : const Color(0xFFA3AFBD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid-layout counterpart to [_OptionTile] — a square-ish card with a large
/// centered icon on top, a wrapped 2-line label below, and a small check
/// badge in the top-right corner instead of a full-width radio row. Used by
/// [showFilterSheet]'s 2-column grid, where [_OptionTile]'s single
/// icon+label+radio row reads too cramped at half the sheet's width.
class _GridOptionTile extends StatelessWidget {
  const _GridOptionTile({
    required this.label,
    required this.iconUrl,
    this.iconData,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? iconUrl;

  /// Overrides the generic sliders glyph used when [iconUrl] is absent —
  /// see [_SelectionSheet.iconDataOf].
  final FaIconData? iconData;

  /// An optional one-line description under the label — see
  /// [_SelectionSheet.subtitleOf].
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5FCF8) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.mintBorder : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: iconUrl != null && iconUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: iconUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => FaIcon(
                              iconData ?? FontAwesomeIcons.sliders,
                              size: 17,
                              color: AppColors.blue,
                            ),
                          )
                        : FaIcon(
                            iconData ?? FontAwesomeIcons.sliders,
                            size: 17,
                            color: AppColors.blue,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.greenDark : AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.25,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: selected ? AppColors.green : const Color(0xFFC3CCD8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
