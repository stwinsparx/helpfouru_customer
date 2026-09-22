import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Full-page sub-category picker, styled like the home screen's Explore
/// Services grid (icon-on-tint-circle tiles), with a local search bar that
/// filters the tiles client-side. Pushed from [ProvidersScreen] in place of
/// a bottom sheet; pops with the selected [ServiceSubCategory], or `null`
/// if the user backed out without picking one.
class SubCategoryScreen extends StatefulWidget {
  const SubCategoryScreen({super.key, required this.subCategories});

  final List<ServiceSubCategory> subCategories;

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  /// Pastel tint backgrounds cycled across the tiles — matches the home
  /// screen's Explore Services palette.
  static const _tintPalette = [
    Color(0xFFE3F6E9),
    Color(0xFFFFF3D6),
    Color(0xFFDDEEFB),
    Color(0xFFFCE4E4),
    Color(0xFFE1EEFC),
    Color(0xFFFCE6F0),
    Color(0xFFEAE3FB),
    Color(0xFFE1F5EA),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceSubCategory> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.subCategories;
    return widget.subCategories
        .where((sub) => sub.categoryName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MiniHeader(title: l10n.selectSubCategoryTitle),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: appInputDecoration(l10n.searchSubCategoriesHint)
                    .copyWith(
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFF8391A3),
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: const Color(0xFF8391A3),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noSubCategoriesFound,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(top: 4),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 9,
                              childAspectRatio: 0.95,
                            ),
                        itemBuilder: (context, i) {
                          final sub = filtered[i];
                          return _SubCategoryTile(
                            label: sub.categoryName,
                            imageUrl: sub.image,
                            tint: _tintPalette[i % _tintPalette.length],
                            onTap: () => Navigator.of(context).pop(sub),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCategoryTile extends StatelessWidget {
  const _SubCategoryTile({
    required this.label,
    required this.imageUrl,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final Color tint;
  final VoidCallback onTap;

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
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.category_outlined,
                              size: 22,
                              color: AppColors.muted,
                            ),
                      )
                    : const Icon(
                        Icons.category_outlined,
                        size: 22,
                        color: AppColors.muted,
                      ),
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
}
