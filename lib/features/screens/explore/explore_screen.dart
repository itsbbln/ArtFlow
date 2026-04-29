import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/editorial_colors.dart';
import '../../shared/data/app_data_state.dart';
import '../../shared/widgets/artwork_card.dart';
import '../screen_utils.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  String _query = '';
  String _selectedCategory = 'all';
  bool _showFilters = false;
  String _sortBy = 'newest';
  final _artistController = TextEditingController();
  final _styleController = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 6000);

  late AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fade.forward();
    });
  }

  @override
  void dispose() {
    _artistController.dispose();
    _styleController.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataState>();
    var artworks = data.artworks.where((item) {
      final categoryMatch =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      final artistMatch = _artistController.text.trim().isEmpty ||
          item.artistName.toLowerCase().contains(
                _artistController.text.toLowerCase(),
              );
      final styleMatch = _styleController.text.trim().isEmpty ||
          (item.medium?.toLowerCase().contains(_styleController.text.toLowerCase()) ?? false);
      final priceMatch = item.price >= _priceRange.start && item.price <= _priceRange.end;
      final queryMatch = item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.artistName.toLowerCase().contains(_query.toLowerCase()) ||
          item.tags.any((tag) => tag.toLowerCase().contains(_query.toLowerCase()));
      return categoryMatch && queryMatch && artistMatch && styleMatch && priceMatch;
    }).toList();

    if (_sortBy == 'price_low') {
      artworks.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_high') {
      artworks.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'rating') {
      artworks.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    } else if (_sortBy == 'featured') {
      artworks.sort(
        (a, b) => data.isBoosted(b.id).toString().compareTo(data.isBoosted(a.id).toString()),
      );
    }

    return ColoredBox(
      color: EditorialColors.pageCream,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          children: [
            Text(
              'Explore',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: EditorialColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search the gallery · refine by medium and price',
              style: GoogleFonts.inter(fontSize: 13.5, color: EditorialColors.muted),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon:
                          Icon(Icons.search_rounded, color: EditorialColors.muted.withValues(alpha: 0.85)),
                      hintText: 'Search artworks, artists…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: EditorialColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: EditorialColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: EditorialColors.tribalRed, width: 1.35),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              onPressed: () => setState(() => _query = ''),
                              icon: Icon(Icons.close_rounded, color: EditorialColors.muted.withValues(alpha: 0.7)),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EditorialColors.border),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _showFilters ? EditorialColors.tribalRed : EditorialColors.charcoal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showFilters) ...[
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.circularXl(),
                  border: Border.all(color: EditorialColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: EditorialColors.tribalRed.withValues(alpha: 0.9)),
                        const SizedBox(width: 8),
                        Text(
                          'Refine results',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: EditorialColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: EditorialColors.parchment.withValues(alpha: 0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                        DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                        DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                        DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
                        DropdownMenuItem(value: 'featured', child: Text('Featured Priority')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _artistController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Artist',
                        filled: true,
                        fillColor: EditorialColors.parchment.withValues(alpha: 0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _styleController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Style / Medium',
                        filled: true,
                        fillColor: EditorialColors.parchment.withValues(alpha: 0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Price (₱)',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EditorialColors.muted),
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 10000,
                      divisions: 20,
                      activeColor: EditorialColors.tribalRed,
                      inactiveColor: EditorialColors.border,
                      labels: RangeLabels(
                        '₱${_priceRange.start.toStringAsFixed(0)}',
                        '₱${_priceRange.end.toStringAsFixed(0)}',
                      ),
                      onChanged: (value) => setState(() => _priceRange = value),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: data.categories.map((item) {
                  final selected = item == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(categoryLabel(item)),
                      selected: selected,
                      selectedColor: EditorialColors.tribalRed,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected ? EditorialColors.tribalRed : EditorialColors.border,
                      ),
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: selected ? Colors.white : EditorialColors.charcoal,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = item),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${artworks.length} artworks found',
              style: GoogleFonts.inter(fontSize: 13, color: EditorialColors.muted),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: artworks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 252,
              ),
              itemBuilder: (context, index) {
                final item = artworks[index];
                return ArtworkCard(
                  artwork: item,
                  onTap: () => context.push('/artwork/${item.id}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
