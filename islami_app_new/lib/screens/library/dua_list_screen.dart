import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- Yeni UI Bileşenleri ---
import '../../widgets/shared/app_card.dart';
import '../../widgets/shared/app_input.dart';
import '../../widgets/shared/app_button.dart';
import '../../widgets/modals/app_modal.dart';
import '../../widgets/loading/app_loading_state.dart';
import '../../widgets/animations/fade_in_animation.dart';
import '../../widgets/animations/slide_animation.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';

class Dua {
  final int id;
  final String title;
  final String text;
  final String? translation;
  Dua({required this.id, required this.title, required this.text, this.translation});
  factory Dua.fromJson(Map<String, dynamic> json) => Dua(
    id: json['id'],
    title: json['title'],
    text: json['text'],
    translation: json['translation'],
  );
}
Future<List<Dua>> fetchDuas() async {
  await dotenv.load(fileName: "assets/.env");
  final apiBaseUrl = dotenv.env['API_URL'] ?? '';
  final uri = Uri.parse('$apiBaseUrl/api/dua');
  final res = await http.get(uri);
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Dua.fromJson(e)).toList();
  } else {
    throw Exception('Dua verisi alınamadı');
  }
}
class DuaListScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DuaListScreen({Key? key, required this.onBack}) : super(key: key);
  @override
  State<DuaListScreen> createState() => _DuaListScreenState();
}
class _DuaListScreenState extends State<DuaListScreen> {
  late Future<List<Dua>> _future;
  final TextEditingController _searchController = TextEditingController();
  List<Dua> _allDuas = [];
  List<Dua> _filteredDuas = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _future = fetchDuas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDuas = _allDuas;
        _isSearching = false;
      } else {
        _filteredDuas = _allDuas.where((dua) {
          return dua.title.toLowerCase().contains(query) ||
                 dua.text.toLowerCase().contains(query);
        }).toList();
        _isSearching = true;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dualar',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: FutureBuilder<List<Dua>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadings.fullScreen(
              message: 'Dualar yükleniyor...',
            );
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // İlk yüklemede verileri ayarla
          if (_allDuas.isEmpty) {
            _allDuas = snapshot.data!;
            _filteredDuas = _allDuas;
          }

          return Column(
            children: [
              // Arama çubuğu
              _buildSearchBar(),
              
              // Liste
              Expanded(
                child: _buildDuaList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLgStatic),
      child: FadeInAnimation(
        child: AppInput(
          controller: _searchController,
          label: 'Dua ara...',
          prefixIcon: Icons.search,
          suffixIcon: _searchController.text.isNotEmpty
              ? Icons.clear
              : null,
        ),
      ),
    );
  }

  Widget _buildDuaList() {
    if (_filteredDuas.isEmpty && _isSearching) {
      return _buildNoResultsState();
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLgStatic,
          vertical: AppDimensions.paddingMdStatic,
      ),
      itemCount: _filteredDuas.length,
      separatorBuilder: (_, __) => SizedBox(height: AppDimensions.paddingMdStatic),
      itemBuilder: (context, index) {
        return SlideAnimation(
          delay: Duration(milliseconds: 50 * index),
          direction: SlideDirection.leftToRight,
          child: _buildDuaCard(_filteredDuas[index]),
        );
      },
    );
  }

  Widget _buildDuaCard(Dua dua) {
    return AppCard(
      onTap: () => _showDuaDetailModal(dua),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLgStatic),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmStatic),
                  ),
                  child: Icon(
                    Icons.self_improvement,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppDimensions.paddingMdStatic),
                Expanded(
                  child: Text(
                    dua.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            SizedBox(height: AppDimensions.paddingMdStatic),
            Text(
              dua.text.length > 120 
                  ? '${dua.text.substring(0, 120)}...'
                  : dua.text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          SizedBox(height: AppDimensions.paddingLgStatic),
          Text(
            'Bir hata oluştu',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          Text(
            'Dualar yüklenirken bir sorun oluştu',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.paddingLgStatic),
          AppButton(
            text: 'Tekrar Dene',
            icon: Icons.refresh,
            onPressed: () {
              setState(() {
                _future = fetchDuas();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppDimensions.paddingLgStatic),
          Text(
            'Henüz dua eklenmedi',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          Text(
            'Yakında dualar eklenecek',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppDimensions.paddingLgStatic),
          Text(
            'Sonuç bulunamadı',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          Text(
            'Arama kriterlerinizi değiştirip tekrar deneyin',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  void _showDuaDetailModal(Dua dua) {
    AppModal.show(
      context: context,
      title: dua.title,
      size: ModalSize.large,
      child: _DuaDetailContent(dua: dua),
    );
  }
}
// Modern dua detay content widget
class _DuaDetailContent extends StatefulWidget {
  final Dua dua;
  const _DuaDetailContent({required this.dua});
  
  @override
  State<_DuaDetailContent> createState() => _DuaDetailContentState();
}

class _DuaDetailContentState extends State<_DuaDetailContent> {
  late FlutterTts flutterTts;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _loadTtsSettings();
  }

  Future<void> _loadTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final speed = prefs.getDouble('ttsSpeed') ?? 1.0;
    final pitch = prefs.getDouble('ttsPitch') ?? 1.0;
    final lang = prefs.getString('ttsLanguage');
    final voice = prefs.getString('ttsVoice');
    
    await flutterTts.setSpeechRate(speed);
    await flutterTts.setPitch(pitch);
    if (lang != null) await flutterTts.setLanguage(lang);
    if (voice != null) {
      await flutterTts.setVoice({'name': voice, 'locale': lang ?? 'tr-TR'});
    }
  }

  Future<void> _speak() async {
    setState(() => _isPlaying = true);
    try {
      await flutterTts.speak(widget.dua.text);
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: widget.dua.text));
    if (mounted) {
      AppModals.showInfo(
        context: context,
        title: 'Başarılı',
        message: 'Dua metni kopyalandı',
      );
    }
  }

  void _shareText() {
    Share.share(
      widget.dua.text,
      subject: widget.dua.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dua = widget.dua;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dua metni
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppDimensions.paddingLgStatic),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            dua.text,
            style: AppTypography.bodyLarge.copyWith(
              height: 1.8,
              fontSize: 18,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        
        // Meal varsa göster
        if (dua.translation != null && dua.translation!.isNotEmpty) ...[
          SizedBox(height: AppDimensions.paddingLgStatic),
          Text(
            'Meali:',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppDimensions.paddingLgStatic),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
              border: Border.all(
                color: AppColors.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              dua.translation!,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
        
        SizedBox(height: AppDimensions.paddingLgStatic),
        
        // Aksiyon butonları
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Kopyala',
                icon: Icons.copy,
                type: AppButtonType.outline,
                onPressed: _copyText,
              ),
            ),
            SizedBox(width: AppDimensions.paddingMdStatic),
            Expanded(
              child: AppButton(
                text: _isPlaying ? 'Oynatılıyor...' : 'Sesli Oku',
                icon: _isPlaying ? Icons.volume_up : Icons.play_arrow,
                type: AppButtonType.outline,
                loading: _isPlaying,
                onPressed: _isPlaying ? null : _speak,
              ),
            ),
            SizedBox(width: AppDimensions.paddingMdStatic),
            Expanded(
              child: AppButton(
                text: 'Paylaş',
                icon: Icons.share,
                type: AppButtonType.primary,
                onPressed: _shareText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}