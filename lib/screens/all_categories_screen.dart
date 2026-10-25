import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Full-page listing of every top-level service category, styled like the
/// home screen's Explore Services grid. Pushed from Home's "More Services"
/// tile; tapping any category here runs the exact same category → filter →
/// providers flow as an Explore Services tile, via [onCategoryTap].
class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  final List<ServiceCategory> categories;
  final void Function(ServiceCategory category) onCategoryTap;

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceCategory> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.categories;
    return widget.categories
        .where((cat) => cat.categoryName.toLowerCase().contains(query))
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
              MiniHeader(title: l10n.allCategoriesTitle),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: appInputDecoration(l10n.searchCategoriesHint)
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
                          l10n.noCategoriesMatchSearch,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 9,
                              childAspectRatio: 0.95,
                            ),
                        itemBuilder: (context, i) {
                          final cat = filtered[i];
                          return CategoryTile(
                            iconUrl: cat.image,
                            localIconAsset: localCategoryIconFor(
                              cat.categoryName,
                            ),
                            label: cat.categoryName,
                            tint:
                                categoryTintPalette[i %
                                    categoryTintPalette.length],
                            onTap: () => widget.onCategoryTap(cat),
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
