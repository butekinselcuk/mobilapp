import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class QuranVerse {
  final int id;
  final String surah;
  final int ayah;
  final String text;
  final String? translation;
  final String language;
  final String? audioUrl;
  QuranVerse({required this.id, required this.surah, required this.ayah, required this.text, this.translation, required this.language, this.audioUrl});
  factory QuranVerse.fromJson(Map<String, dynamic> json) => QuranVerse(
    id: json['id'],
    surah: json['surah'],
    ayah: json['ayah'],
    text: json['text'],
    translation: json['translation'],
    language: json['language'],
    audioUrl: json['audio_url'],
  );
}
class Reciter {
  final String id;
  final String name;
  Reciter({required this.id, required this.name});
  factory Reciter.fromJson(Map<String, dynamic> json) => Reciter(
    id: json['id'],
    name: json['name'],
  );
}
Future<List<Reciter>> fetchReciters() async {
  await dotenv.load(fileName: "assets/.env");
  final apiBaseUrl = dotenv.env['API_URL'] ?? '';
  final uri = Uri.parse('$apiBaseUrl/api/reciters');
  final res = await http.get(uri);
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Reciter.fromJson(e)).toList();
  } else {
    throw Exception('Reciter verisi alınamadı');
  }
}
Future<List<QuranVerse>> fetchQuran({String? surah, String? reciter}) async {
  await dotenv.load(fileName: "assets/.env");
  final apiBaseUrl = dotenv.env['API_URL'] ?? '';
  final uri = Uri.parse('$apiBaseUrl/api/quran').replace(queryParameters: {
    if (surah != null) 'surah': surah,
    'language': 'ar',
    if (reciter != null) 'reciter': reciter,
  });
  final res = await http.get(uri);
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => QuranVerse.fromJson(e)).toList();
  } else {
    throw Exception('Kur\'an verisi alınamadı');
  }
}
class QuranListScreen extends StatefulWidget {
  final VoidCallback onBack;
  const QuranListScreen({Key? key, required this.onBack}) : super(key: key);
  @override
  State<QuranListScreen> createState() => _QuranListScreenState();
}
class _QuranListScreenState extends State<QuranListScreen> {
  String? _selectedReciterId;
  List<Reciter> _reciters = [];
  late Future<List<QuranVerse>> _future;
  List<QuranVerse> _allVerses = [];
  List<QuranVerse> _filteredVerses = [];
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  int? _currentPlayingIndex;
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSequentialPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadReciters();
  }
  void _loadReciters() async {
    final reciters = await fetchReciters();
    setState(() {
      _reciters = reciters;
      _selectedReciterId = reciters.isNotEmpty ? reciters.first.id : null;
      _future = fetchQuran(reciter: _selectedReciterId);
    });
  }
  void _onReciterChanged(String? reciterId) {
    setState(() {
      _selectedReciterId = reciterId;
      _future = fetchQuran(reciter: _selectedReciterId);
    });
  }
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _filteredVerses = _allVerses.where((v) =>
        v.surah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        v.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        v.ayah.toString().contains(_searchQuery)
      ).toList();
    });
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Tek ayet oynatma
  void _playSingleAyah(int index) async {
    final ayah = _filteredVerses[index];
    if (ayah.audioUrl == null || ayah.audioUrl!.isEmpty) {
      print('DEBUG: audioUrl boş veya null, oynatma yapılmadı.');
      return;
    }
    print('DEBUG: Playing audio url: \'${ayah.audioUrl}\'');
    setState(() { _currentPlayingIndex = index; });
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(ayah.audioUrl!);
      await _audioPlayer.play();
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() { _currentPlayingIndex = null; });
        }
      });
    } catch (e) {
      print('Audio error: $e');
      if (mounted) setState(() { _currentPlayingIndex = null; });
    }
  }
  // Tüm sureyi sırayla oku ile ilgili fonksiyonlar, butonlar ve state değişkenleri kaldırıldı.
  // Ayet kartında hoparlör butonu:
  // IconButton(
  //   icon: Icon(Icons.volume_up),
  //   onPressed: () => _playSingleAyah(index),
  // )
  void _playSurahSequentially(int startIndex) async {
    if (_isSequentialPlaying) return;
    setState(() { _isSequentialPlaying = true; });
    for (int i = startIndex; i < _filteredVerses.length; i++) {
      if (!_isSequentialPlaying) break;
      final ayah = _filteredVerses[i];
      if (ayah.audioUrl == null || ayah.audioUrl!.isEmpty) {
        print('DEBUG: audioUrl boş veya null, oynatma yapılmadı.');
        continue;
      }
      print('DEBUG: Sequential playing audio url: \'${ayah.audioUrl}\'');
      setState(() { _currentPlayingIndex = i; });
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(ayah.audioUrl!);
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere((state) => state.processingState == ProcessingState.completed);
      // Otomatik scroll
      _scrollController.animateTo(
        i * 90.0, // Kart yüksekliği tahmini
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    if (mounted) setState(() { _isSequentialPlaying = false; _currentPlayingIndex = null; });
  }
  void _stopSequentialPlayback() {
    setState(() { _isSequentialPlaying = false; _currentPlayingIndex = null; });
    _audioPlayer.stop();
  }
  @override
  Widget build(BuildContext context) {
    if (_reciters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Kur'an-ı Kerim"), leading: BackButton(onPressed: widget.onBack)),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Kur'an-ı Kerim"), leading: BackButton(onPressed: widget.onBack)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _selectedReciterId != null
                          ? Text(
                              _reciters.firstWhere((r) => r.id == _selectedReciterId, orElse: () => _reciters.first).name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            )
                          : SizedBox.shrink(),
                      SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedReciterId,
                        isExpanded: true,
                        items: _reciters.map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _onReciterChanged,
                        underline: Container(),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Eğer bir görsel ekleniyorsa, sabit genişlikte ekle:
                // Container(
                //   width: 40,
                //   height: 40,
                //   child: Image.asset('assets/your_image.png', fit: BoxFit.contain),
                // ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ara: sure, ayet veya metin',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          //   child: ElevatedButton.icon(
          //     icon: Icon(Icons.queue_music),
          //     label: Text('Tüm sureyi sırayla oku'),
          //     onPressed: _isSequentialPlaying
          //         ? null
          //         : () {
          //             if (_filteredVerses.isNotEmpty) {
          //               _playSurahSequentially(0);
          //             }
          //           },
          //     style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40)),
          //   ),
          // ),
          Expanded(
            child: FutureBuilder<List<QuranVerse>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Bir hata oluştu.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Henüz içerik eklenmedi.'));
                }
                _allVerses = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  _filteredVerses = _allVerses.where((v) =>
                    v.surah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    v.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    v.ayah.toString().contains(_searchQuery)
                  ).toList();
                } else {
                  _filteredVerses = _allVerses;
                }
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVerses.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final v = _filteredVerses[i];
                    final isPlaying = _currentPlayingIndex == i;
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: isPlaying ? Colors.amber[100] : null,
                      child: ListTile(
                        leading: Icon(Icons.menu_book, color: Theme.of(context).primaryColor),
                        title: Text('${v.surah} - ${v.ayah}', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(v.text.length > 60 ? v.text.substring(0, 60) + '...' : v.text),
                        onTap: () => _showQuranDetailDialog(context, v),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.volume_up),
                              tooltip: 'Sadece bu ayeti oku',
                              onPressed: () => _playSingleAyah(i),
                            ),
                            IconButton(
                              icon: Icon(_isSequentialPlaying && _currentPlayingIndex == i ? Icons.stop : Icons.queue_music),
                              tooltip: _isSequentialPlaying && _currentPlayingIndex == i ? 'Durdur' : 'Buradan sırayla oku',
                              onPressed: _isSequentialPlaying && _currentPlayingIndex == i ? _stopSequentialPlayback : () => _playSurahSequentially(i),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void _showQuranDetailDialog(BuildContext context, QuranVerse v) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => QuranDetailModal(verse: v),
    );
  }
}
class QuranDetailModal extends StatefulWidget {
  final QuranVerse verse;
  const QuranDetailModal({required this.verse});
  @override
  State<QuranDetailModal> createState() => _QuranDetailModalState();
}
class _QuranDetailModalState extends State<QuranDetailModal> {
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  void _playAudio() async {
    if (widget.verse.audioUrl == null || widget.verse.audioUrl!.isEmpty) {
      print('DEBUG: audioUrl boş veya null, oynatma yapılmadı.');
      return;
    }
    print('DEBUG: Playing audio url: \'${widget.verse.audioUrl}\'');
    setState(() => _isPlaying = true);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(widget.verse.audioUrl!);
      await _audioPlayer.play();
    } catch (e) {
      print('Audio error: $e');
    }
    setState(() => _isPlaying = false);
  }
  void _stopAudio() async {
    await _audioPlayer.stop();
    setState(() => _isPlaying = false);
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.verse.surah} - ${widget.verse.ayah}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.verse.text, style: TextStyle(fontSize: 16)),
            if (widget.verse.translation != null && widget.verse.translation!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Meali:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.verse.translation!, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
            ],
            SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Durdur' : 'Sesli Dinle'),
                  onPressed: _isPlaying ? _stopAudio : _playAudio,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.copy),
                  label: Text('Kopyala'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.verse.text));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Metin kopyalandı!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Kapat'),
        ),
      ],
    );
  }
} 