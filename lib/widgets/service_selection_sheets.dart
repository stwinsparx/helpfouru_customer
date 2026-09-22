import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import 'common.dart';

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
    this.centered = false,
    this.gridColumns,
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String? Function(T) iconUrlOf;

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
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.7,
                  ),
                  itemBuilder: (context, i) {
                    final item = widget.items[i];
                    return _OptionTile(
                      label: widget.labelOf(item),
                      iconUrl: widget.iconUrlOf(item),
                      selected: _selected == item,
                      onTap: () => setState(() => _selected = item),
                      showBottomMargin: false,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
    this.showBottomMargin = true,
  });

  final String label;
  final String? iconUrl;
  final bool selected;
  final VoidCallback onTap;

  /// False when laid out in a grid, where spacing already comes from the
  /// grid delegate's `mainAxisSpacing` — an extra margin would double it up.
  final bool showBottomMargin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: showBottomMargin
              ? const EdgeInsets.only(bottom: 8)
              : EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5FCF8) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.mintBorder : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    ? Image.network(
                        iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const FaIcon(
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.greenDark : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
