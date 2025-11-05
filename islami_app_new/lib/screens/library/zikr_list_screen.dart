import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Zikr {
  final int id;
  final String title;
  final String text;
  final int? count;
  Zikr({required this.id, required this.title, required this.text, this.count});
  factory Zikr.fromJson(Map<String, dynamic> json) => Zikr(
    id: json['id'],
    title: json['title'],
    text: json['text'],
    count: json['count'],
  );
}
Future<List<Zikr>> fetchZikrs() async {
  await dotenv.load(fileName: "assets/.env");
  final apiBaseUrl = dotenv.env['API_URL'] ?? '';
  final uri = Uri.parse('$apiBaseUrl/api/zikr');
  final res = await http.get(uri);
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Zikr.fromJson(e)).toList();
  } else {
    throw Exception('Zikir verisi alınamadı');
  }
}
class ZikrListScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ZikrListScreen({Key? key, required this.onBack}) : super(key: key);
  @override
  State<ZikrListScreen> createState() => _ZikrListScreenState();
}
class _ZikrListScreenState extends State<ZikrListScreen> {
  late Future<List<Zikr>> _future;
  @override
  void initState() {
    super.initState();
    _future = fetchZikrs();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zikirler'), leading: BackButton(onPressed: widget.onBack)),
      body: FutureBuilder<List<Zikr>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Henüz içerik eklenmedi.'));
          }
          final zikrs = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: zikrs.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, i) {
              final z = zikrs[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.repeat, color: Theme.of(context).primaryColor),
                  title: Text(z.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(z.text.length > 60 ? z.text.substring(0, 60) + '...' : z.text),
                  trailing: z.count != null ? Text('x${z.count}', style: TextStyle(fontWeight: FontWeight.bold)) : null,
                  onTap: () => _showZikrDetailDialog(context, z),
                ),
              );
            },
          );
        },
      ),
    );
  }
  void _showZikrDetailDialog(BuildContext context, Zikr z) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ZikrDetailDialog(zikr: z),
    );
  }
}
// Yeni: Zikr detay dialog widget
class _ZikrDetailDialog extends StatefulWidget {
  final Zikr zikr;
  const _ZikrDetailDialog({required this.zikr});
  @override
  State<_ZikrDetailDialog> createState() => _ZikrDetailDialogState();
}
class _ZikrDetailDialogState extends State<_ZikrDetailDialog> {
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
    await flutterTts.speak(widget.zikr.text);
    setState(() => ttsLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    final z = widget.zikr;
    return AlertDialog(
      title: Text(z.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(z.text, style: TextStyle(fontSize: 16)),
            if (z.count != null) ...[
              SizedBox(height: 16),
              Text('Tekrar:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${z.count} kez', style: TextStyle(fontSize: 15, color: Colors.grey[700])),
            ],
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Kopyala',
          icon: Icon(Icons.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: z.text));
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
          onPressed: () => Share.share(z.text, subject: z.title),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Kapat'),
        ),
      ],
    );
  }
} 