import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:flutter/foundation.dart' show kIsWeb;

class JourneyModule {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String? category; // Yeni eklendi
  final String? tags;    // Yeni eklendi
  final List<JourneyStep> steps;

  JourneyModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.category,
    this.tags,
    required this.steps,
  });

  factory JourneyModule.fromJson(Map<String, dynamic> json) {
    return JourneyModule(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      category: json['category'],
      tags: json['tags'],
      steps: (json['steps'] as List<dynamic>?)?.map((s) => JourneyStep.fromJson(s)).toList() ?? [],
    );
  }
}

class JourneyStep {
  final int id;
  final String title;
  final int order;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final String? source;

  JourneyStep({
    required this.id,
    required this.title,
    required this.order,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.source,
  });

  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    return JourneyStep(
      id: json['id'],
      title: json['title'],
      order: json['order'],
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      source: json['source'],
    );
  }
}

class JourneyScreen extends StatefulWidget {
  final int? initialModuleId;
  const JourneyScreen({Key? key, this.initialModuleId}) : super(key: key);
  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  List<JourneyModule> modules = [];
  Map<int, int> progressMap = {}; // module_id -> completed_step
  bool loading = true;
  String? error;
  String tagQuery = '';
  final TextEditingController tagController = TextEditingController();
  List<String> allTags = [];
  int? selectedModuleId;
  bool detailDialogShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialModuleId != null) {
      selectedModuleId = widget.initialModuleId;
      // initialModuleId varsa, detay modalını otomatik aç
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!detailDialogShown) {
          detailDialogShown = true;
          // Burada ilgili modül detayını bulup modal aç
        }
      });
    }
    fetchModulesAndProgress();
  }

  @override
  void dispose() {
    tagController.dispose();
    super.dispose();
  }

  Future<void> fetchModulesAndProgress() async {
    await dotenv.load(fileName: "assets/.env");
    setState(() { loading = true; error = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      // Filtre parametreleri
      String filter = '';
      if (tagQuery.isNotEmpty) {
        final tags = tagQuery.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
        for (final tag in tags) {
          filter += (filter.isEmpty ? '?' : '&') + 'tags=${Uri.encodeComponent(tag)}';
        }
      }
      final url = '$apiUrl/api/journey_modules$filter';
      print('API URL: ' + url);
      final response = await http.get(
        Uri.parse(url),
        headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
      );
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(response.body));
        final mods = data.map((m) => JourneyModule.fromJson(m)).toList();
        Map<int, int> progMap = {};
        // Kullanıcı ilerlemesini çek (sadece giriş yapmışsa)
        if (token != null && token.isNotEmpty) {
          final progResp = await http.get(
            Uri.parse('$apiUrl/user/journey_progress'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (progResp.statusCode == 200) {
            final progData = List<Map<String, dynamic>>.from(json.decode(progResp.body));
            for (final p in progData) {
              progMap[p['module_id']] = p['completed_step'] ?? 0;
            }
          }
        }
        // Etiket listesini topla (tekrarsız)
        final tagsSet = <String>{};
        for (final m in mods) {
          if (m.tags != null && m.tags!.isNotEmpty) {
            tagsSet.addAll(m.tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty));
          }
        }
        setState(() {
          modules = mods;
          progressMap = progMap;
          allTags = tagsSet.toList()..sort();
          loading = false;
        });
      } else {
        setState(() { error = 'Modüller alınamadı: ${response.body}'; loading = false; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İlim Yolculukları')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    // Filtre UI
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Etiket', style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: tagController,
                                  decoration: InputDecoration(
                                    labelText: 'Etiket ara...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() { tagQuery = tagController.text; });
                                  fetchModulesAndProgress();
                                },
                                child: Text('Ara'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: modules.length,
                        itemBuilder: (context, index) {
                          final module = modules[index];
                          final completedStep = progressMap[module.id] ?? 0;
                          final isCompleted = module.steps.isNotEmpty && completedStep >= module.steps.length;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              leading: Icon(_iconFromString(module.icon), size: 36, color: Colors.green),
                              title: Row(
                                children: [
                                  Expanded(child: Text(module.title, style: TextStyle(fontWeight: FontWeight.bold))),
                                  if (isCompleted)
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        SizedBox(width: 4),
                                        Text('Tamamlandı', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(module.description),
                                  if ((module.category != null && module.category!.isNotEmpty) || (module.tags != null && module.tags!.isNotEmpty))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          if (module.category != null && module.category!.isNotEmpty)
                                            Chip(
                                              label: Text(
                                                module.category!, 
                                                style: TextStyle(
                                                  fontSize: 12, 
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green[800]
                                                )
                                              ), 
                                              backgroundColor: Colors.green[100],
                                              side: BorderSide(color: Colors.green[300]!, width: 1),
                                            ),
                                          if (module.tags != null && module.tags!.isNotEmpty)
                                            ...List<Widget>.from(
                                              (module.tags as String)
                                                .split(',')
                                                .map((t) => t.trim())
                                                .where((t) => t.isNotEmpty)
                                                .map((t) => Chip(
                                                  label: Text(
                                                    t, 
                                                    style: TextStyle(
                                                      fontSize: 12, 
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.blue[800]
                                                    )
                                                  ), 
                                                  backgroundColor: Colors.blue[100],
                                                  side: BorderSide(color: Colors.blue[300]!, width: 1),
                                                ))
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JourneyDetailScreen(module: module),
                                  ),
                                ).then((_) => fetchModulesAndProgress());
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  IconData _iconFromString(String icon) {
    switch (icon) {
      case 'menu_book': return Icons.menu_book;
      case 'hiking': return Icons.hiking;
      case 'self_improvement': return Icons.self_improvement;
      default: return Icons.explore;
    }
  }
}

class JourneyDetailScreen extends StatefulWidget {
  final JourneyModule module;
  const JourneyDetailScreen({required this.module});

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  int completedStep = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    setState(() { loading = true; error = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/user/journey_progress'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(response.body));
        final progress = data.firstWhere(
          (p) => p['module_id'] == widget.module.id,
          orElse: () => {},
        );
        setState(() {
          completedStep = progress['completed_step'] ?? 0;
          loading = false;
        });
      } else {
        setState(() { error = 'İlerleme alınamadı: ${response.body}'; loading = false; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; loading = false; });
    }
  }

  Future<void> updateProgress(int newStep) async {
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/user/journey_progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'module_id': widget.module.id,
          'completed_step': newStep,
        }),
      );
      if (response.statusCode == 200) {
        setState(() { completedStep = newStep; });
      } else {
        // Hata yönetimi (isteğe bağlı)
      }
    } catch (e) {
      // Hata yönetimi (isteğe bağlı)
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.module.steps;
    final progress = steps.isEmpty ? 0.0 : (completedStep / steps.length).clamp(0.0, 1.0);
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.title)),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.title)),
        body: Center(child: Text(error!, style: TextStyle(color: Colors.red))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.module.description, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey[300], color: Colors.green),
              SizedBox(height: 10),
              Text('İlerleme: ${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              Text('Adımlar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ...steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
                    padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Row(
                          children: [
                            Icon(i < completedStep ? Icons.check_circle : Icons.radio_button_unchecked, color: i < completedStep ? Colors.green : Colors.grey),
                            SizedBox(width: 8),
                            Expanded(child: Text(step.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          ],
                        ),
                        if (step.content.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(step.content, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        ],
                        if (step.mediaUrl != null && step.mediaUrl!.isNotEmpty) ...[
            SizedBox(height: 12),
                          _buildStepMedia(step),
                        ],
                        if (step.source != null && step.source!.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.menu_book, size: 18, color: Colors.amber[800]),
                              SizedBox(width: 4),
                              Expanded(child: Text('Kaynak: ${step.source}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.amber[800]))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            SizedBox(height: 24),
              if (completedStep < steps.length)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await updateProgress(completedStep + 1);
                    },
                    child: Text('Adımı Tamamla'),
                  ),
                )
              else
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                      SizedBox(height: 8),
                      Text('Tebrikler! Modülü tamamladınız.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// JourneyDetailScreen'de adım kartında video gösterimini
dynamic _buildStepMedia(JourneyStep step) {
  if (step.mediaType == 'image' && step.mediaUrl != null && step.mediaUrl!.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(step.mediaUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.broken_image)),
    );
  } else if (step.mediaType == 'video' && step.mediaUrl != null && step.mediaUrl!.isNotEmpty) {
    final url = step.mediaUrl!;
    final isYoutube = url.contains('youtube.com') || url.contains('youtu.be');
    if (isYoutube) {
      final videoId = _extractYoutubeId(url);
      if (videoId != null) {
        if (kIsWeb) {
          // Web için youtube_player_iframe (güncel API)
          return ypi.YoutubePlayer(
            controller: ypi.YoutubePlayerController.fromVideoId(
              videoId: videoId,
              autoPlay: false,
              params: const ypi.YoutubePlayerParams(
                showControls: true,
                mute: false,
              ),
            ),
            aspectRatio: 16 / 9,
          );
        } else {
          // Mobil için youtube_player_flutter
          return ypf.YoutubePlayer(
            controller: ypf.YoutubePlayerController(
              initialVideoId: videoId,
              flags: ypf.YoutubePlayerFlags(
                autoPlay: false,
                mute: false,
              ),
            ),
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
          );
        }
      } else {
        return Text('YouTube video ID bulunamadı.', style: TextStyle(color: Colors.red));
      }
    } else if (url.endsWith('.mp4') || url.endsWith('.webm') || url.endsWith('.mov')) {
      return _VideoPlayerWidget(url: url);
    } else {
      return Text('Bu video türü desteklenmiyor.', style: TextStyle(color: Colors.red));
    }
  } else if (step.mediaUrl != null && step.mediaUrl!.isNotEmpty) {
    return Text('Medya: ${step.mediaUrl}', style: TextStyle(color: Colors.blue));
  } else {
    return SizedBox.shrink();
  }
}

// Video oynatıcı widget'ı ekle:
class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});
  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}
class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() { _initialized = true; });
      });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(height: 200, color: Colors.black12, child: Center(child: CircularProgressIndicator()));
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(_controller, allowScrubbing: true),
          Align(
            alignment: Alignment.center,
            child: IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              ),
            ),
          ],
      ),
    );
  }
}

// YouTube video ID ayıklama fonksiyonu
String? _extractYoutubeId(String url) {
  final regExp = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11}).*');
  final match = regExp.firstMatch(url);
  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }
  return null;
}