import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tafsir {
  final int id;
  final String surah;
  final int ayah;
  final String text;
  Tafsir({required this.id, required this.surah, required this.ayah, required this.text});
  factory Tafsir.fromJson(Map<String, dynamic> json) => Tafsir(
    id: json['id'],
    surah: json['surah'],
    ayah: json['ayah'],
    text: json['text'],
  );
}
Future<List<Tafsir>> fetchTafsirs() async {
  await dotenv.load(fileName: "assets/.env");
  final apiBaseUrl = dotenv.env['API_URL'] ?? '';
  final uri = Uri.parse('$apiBaseUrl/api/tefsir');
  final res = await http.get(uri);
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Tafsir.fromJson(e)).toList();
  } else {
    throw Exception('Tefsir verisi alınamadı');
  }
}
class TafsirListScreen extends StatefulWidget {
  final VoidCallback onBack;
  const TafsirListScreen({Key? key, required this.onBack}) : super(key: key);
  @override
  State<TafsirListScreen> createState() => _TafsirListScreenState();
}
class _TafsirListScreenState extends State<TafsirListScreen> {
  late Future<List<Tafsir>> _future;
  @override
  void initState() {
    super.initState();
    _future = fetchTafsirs();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tefsirler'), leading: BackButton(onPressed: widget.onBack)),
      body: FutureBuilder<List<Tafsir>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Henüz içerik eklenmedi.'));
          }
          final tafsirs = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tafsirs.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, i) {
              final t = tafsirs[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.library_books, color: Theme.of(context).primaryColor),
                  title: Text('${t.surah} - ${t.ayah}', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(t.text.length > 60 ? t.text.substring(0, 60) + '...' : t.text),
                  onTap: () => _showTafsirDetailDialog(context, t),
                ),
              );
            },
          );
        },
      ),
    );
  }
  void _showTafsirDetailDialog(BuildContext context, Tafsir t) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _TafsirDetailDialog(tafsir: t),
    );
  }
}
// Yeni: Tafsir detay dialog widget
class _TafsirDetailDialog extends StatefulWidget {
  final Tafsir tafsir;
  const _TafsirDetailDialog({required this.tafsir});
  @override
  State<_TafsirDetailDialog> createState() => _TafsirDetailDialogState();
}
class _TafsirDetailDialogState extends State<_TafsirDetailDialog> {
  late FlutterTts flutterTts;
  bool ttsLoading = false;
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
    if (voice != null) await flutterTts.setVoice({'name': voice, 'locale': lang ?? 'tr-TR'});
  }
  Future<void> _speak() async {
    setState(() => ttsLoading = true);
    await flutterTts.speak(widget.tafsir.text);
    setState(() => ttsLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    final t = widget.tafsir;
    return AlertDialog(
      title: Text('${t.surah} - ${t.ayah}'),
      content: SingleChildScrollView(
        child: Text(t.text, style: TextStyle(fontSize: 16)),
      ),
      actions: [
        IconButton(
          tooltip: 'Kopyala',
          icon: Icon(Icons.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: t.text));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kopyalandı!')));
          },
        ),
        IconButton(
          tooltip: 'Sesli Oynat',
          icon: ttsLoading ? CircularProgressIndicator() : Icon(Icons.volume_up),
          onPressed: ttsLoading ? null : _speak,
        ),
        IconButton(
          tooltip: 'Paylaş',
          icon: Icon(Icons.share),
          onPressed: () => Share.share(t.text, subject: '${t.surah} - ${t.ayah}'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Kapat'),
        ),
      ],
    );
  }
} 