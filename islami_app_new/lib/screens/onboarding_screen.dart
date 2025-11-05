import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../widgets/app_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/dimensions.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function() onDone;
  const OnboardingScreen({required this.onDone, Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  int _currentPage = 0;
  bool _animating = false;

  final List<_OnboardPageData> _pages = [
    _OnboardPageData(
      color: Color(0xFF00695C),
      illustration: Icons.mosque,
      title: 'İslami App ile İmanını Geliştir',
      subtitle: 'Kur’an, Hadis, Dua ve İlim Yolculukları tek uygulamada.',
    ),
    _OnboardPageData(
      color: Color(0xFFFFAB00),
      illustration: Icons.menu_book,
      title: 'Akıllı Asistan',
      subtitle: 'Sorularına Kur’an ve Sünnet kaynaklı cevaplar anında.',
    ),
    _OnboardPageData(
      color: Color(0xFF00695C),
      illustration: Icons.account_circle,
      title: 'Hesabını Oluştur',
      subtitle: 'Ücretsiz başla, premium ile limitsiz erişim sağla.',
      isLast: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onDone();
  }

  void _next() {
    if (_page < 2 && !_animating) {
      setState(() => _animating = true);
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut).then((_) {
        setState(() => _animating = false);
      });
    }
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return AnimatedOpacity(
                    opacity: _page == i ? 1 : 0,
                    duration: Duration(milliseconds: 300),
                    child: _OnboardPage(
                      data: p,
                      size: size,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppDimensions.paddingMdStatic),
            _DotsIndicator(count: 3, index: _page),
            SizedBox(height: AppDimensions.paddingMdStatic),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLgStatic, vertical: 8),
              child: Row(
                children: [
                  if (_page < 2)
                    TextButton(
                      onPressed: _skip,
                      child: Text('Atla', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  Spacer(),
                  if (_page < 2)
                    AppButton(
                      text: 'İleri',
                      onPressed: _next,
                      backgroundColor: AppColors.primary,
                      icon: Icons.arrow_forward,
                    ),
                  if (_page == 2)
                    Expanded(
                      child: AppButton(
                        text: 'Hesap Oluştur',
                        onPressed: _finish,
                        backgroundColor: AppColors.secondary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.paddingMdStatic),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final Color color;
  final IconData illustration;
  final String title;
  final String subtitle;
  final bool isLast;
  const _OnboardPageData({
    required this.color,
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });
}

class _OnboardPage extends StatelessWidget {
  final _OnboardPageData data;
  final Size size;
  const _OnboardPage({required this.data, required this.size});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: size.height * 0.28,
              width: size.height * 0.28,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  data.illustration,
                  size: size.height * 0.13,
                  color: data.color,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.06),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDimensions.paddingMdStatic),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 5),
          width: index == i ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == i ? AppColors.primary : AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}