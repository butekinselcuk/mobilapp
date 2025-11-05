import 'package:flutter/material.dart';
import 'quran_list_screen.dart';
import 'dua_list_screen.dart';
import 'zikr_list_screen.dart';
import 'tafsir_list_screen.dart';
// --- Yeni UI Bileşenleri ---
import '../../widgets/shared/app_card.dart';
import '../../widgets/animations/fade_in_animation.dart';
import '../../widgets/animations/slide_animation.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';

/// Kategori modeli
class LibraryCategory {
  final String title;
  final String description;
  final IconData icon;
  final String key;
  final Color color;
  final Color backgroundColor;

  const LibraryCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.key,
    required this.color,
    required this.backgroundColor,
  });
}

class LibraryScreen extends StatefulWidget {
  final String? initialCategory;
  final int? initialId;
  const LibraryScreen({Key? key, this.initialCategory, this.initialId}) : super(key: key);
  
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? selectedCategory;

  // Kategori listesi
  static const List<LibraryCategory> categories = [
    LibraryCategory(
      title: 'Kur\'an-ı Kerim',
      description: 'Ayetler ve sureler',
      icon: Icons.menu_book,
      key: 'quran',
      color: Color(0xFF2E7D32),
      backgroundColor: Color(0xFFE8F5E8),
    ),
    LibraryCategory(
      title: 'Dualar',
      description: 'Günlük dualar ve zikirler',
      icon: Icons.self_improvement,
      key: 'dua',
      color: Color(0xFF1565C0),
      backgroundColor: Color(0xFFE3F2FD),
    ),
    LibraryCategory(
      title: 'Zikir',
      description: 'Tesbih ve zikirler',
      icon: Icons.repeat,
      key: 'zikr',
      color: Color(0xFF7B1FA2),
      backgroundColor: Color(0xFFF3E5F5),
    ),
    LibraryCategory(
      title: 'Tefsir',
      description: 'Ayet açıklamaları',
      icon: Icons.library_books,
      key: 'tefsir',
      color: Color(0xFFE65100),
      backgroundColor: Color(0xFFFFF3E0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      selectedCategory = widget.initialCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedCategory == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Kitaplık',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLgStatic),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInAnimation(
                child: Text(
                  'Kategoriler',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.paddingMdStatic),
              FadeInAnimation(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'İslami kaynaklara kolayca erişin',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.paddingLgStatic),
              Expanded(
                child: _buildCategoriesGrid(),
              ),
            ],
          ),
        ),
      );
    }

    // Seçili kategoriye göre ekran göster
    switch (selectedCategory) {
      case 'quran':
        return QuranListScreen(onBack: () => setState(() => selectedCategory = null));
      case 'dua':
        return DuaListScreen(onBack: () => setState(() => selectedCategory = null));
      case 'zikr':
        return ZikrListScreen(onBack: () => setState(() => selectedCategory = null));
      case 'tefsir':
        return TafsirListScreen(onBack: () => setState(() => selectedCategory = null));
      default:
        return Container();
    }
  }

  Widget _buildCategoriesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid - mobil için 2 sütun
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppDimensions.paddingMdStatic,
            mainAxisSpacing: AppDimensions.paddingMdStatic,
            childAspectRatio: 0.85, // Kartları biraz daha uzun yap
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return SlideAnimation(
              delay: Duration(milliseconds: 100 * index),
              direction: SlideDirection.bottomToTop,
              child: _buildCategoryCard(categories[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(LibraryCategory category) {
    return GestureDetector(
      onTap: () {
        print('Card tapped: ${category.key}'); // Debug için
        setState(() {
          selectedCategory = category.key;
        });
      },
      child: AppCard(
        showRippleEffect: true,
      elevation: AppDimensions.elevationLg,
      child: Container(
        padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Flexible(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.backgroundColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  category.icon,
                  size: 24,
                  color: category.color,
                ),
              ),
            ),
            
            SizedBox(height: AppDimensions.paddingXsStatic),
            
            // Title
            Flexible(
              child: Text(
                category.title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(height: AppDimensions.paddingXsStatic / 2),
            
            // Description
            Flexible(
              child: Text(
                category.description,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(height: AppDimensions.paddingXsStatic),
            
            // Arrow indicator
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmStatic),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: category.color,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}