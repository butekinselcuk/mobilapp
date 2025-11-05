import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class AssistantScreen extends StatefulWidget {
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  final int userId = 2; // Kozmo kullanıcısı için sabit user_id
  String? _sessionToken;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('flutter_jwt_token') ?? '';
      
      if (token.isEmpty) {
        setState(() {
          _error = 'Oturum doğrulama hatası: JWT token bulunamadı.';
          _isLoadingHistory = false;
        });
        return;
      }

      // Session token'ı al veya oluştur
      _sessionToken = prefs.getString('chat_session_token');
      
      if (_sessionToken == null) {
        // Yeni session oluştur
        final response = await http.post(
          Uri.parse('$apiUrl/api/chat/session'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'session_token': null,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _sessionToken = data['session_token'];
          await prefs.setString('chat_session_token', _sessionToken!);
        }
      }
      
      // Sohbet geçmişini yükle
      if (_sessionToken != null) {
        await _loadChatHistory();
      }
      
    } catch (e) {
      setState(() {
        _error = 'Session başlatma hatası: $e';
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('flutter_jwt_token') ?? '';
      
      final response = await http.get(
        Uri.parse('$apiUrl/api/chat/session/$_sessionToken/messages'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = data['messages'] as List;
        
        setState(() {
          _messages.clear();
          for (var msg in messages) {
            _messages.add(_ChatMessage(
              text: msg['content'],
              isUser: msg['type'] == 'user',
              sources: msg['sources'],
            ));
          }
          _isLoadingHistory = false;
        });
      } else {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Geçmiş yükleme hatası: $e';
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sessionToken == null) return;
    
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _error = null;
      _controller.clear();
    });
    
    try {
      await dotenv.load(fileName: "assets/.env");
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('flutter_jwt_token') ?? '';
      
      if (token.isEmpty) {
        setState(() {
          _error = 'Oturum doğrulama hatası: JWT token bulunamadı.';
          _isLoading = false;
        });
        return;
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.post(
        Uri.parse('$apiUrl/api/ask'),
        headers: headers,
        body: json.encode({
          'question': text,
          'source_filter': 'all',
          'session_token': _sessionToken,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add(_ChatMessage(text: data['answer'], isUser: false, sources: data['sources']));
          _isLoading = false;
        });
      } else if (response.statusCode == 429) {
        final data = json.decode(response.body);
        final detail = data['detail'] ?? 'Günlük limitinizi doldurdunuz.';
        setState(() {
          _error = detail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Sunucu hatası: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asistan'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Sohbet geçmişi yükleniyor...', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.textHint)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                                SizedBox(width: 8),
                                Text('Yanıtlanıyor...', style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.textHint)),
                              ],
                            ),
                          ),
                        );
                      }
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: msg.isUser ? Colors.green : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg.text,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: msg.isUser ? Colors.white : Colors.black87),
                              ),
                            ),
                            if (!msg.isUser && msg.sources != null && msg.sources!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4, left: 8, right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.green.shade100),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kaynaklar:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ...msg.sources!.map((s) {
                                      final sourceType = s['type'] as String? ?? '';
                                      final sourceName = s['name'] as String? ?? '';
                                      
                                      // AI kaynak göstergesi
                                      if (sourceType == 'ai') {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            children: [
                                              Icon(Icons.smart_toy, size: 16, color: AppColors.info),
                                              SizedBox(width: 4),
                                              Text(
                                                'AI Asistan',
                                                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.info, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      
                                      // Hadis kaynakları
                                      final parts = sourceName.split(' - ');
                                      final source = parts.isNotEmpty ? parts[0] : '';
                                      final reference = parts.length > 1 ? parts[1] : '';
                                      final text = parts.length > 2 ? parts.sublist(2).join(' - ') : '';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.book, size: 16, color: AppColors.primary),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${source.isNotEmpty ? "Kaynak: $source" : ""}${reference.isNotEmpty ? " | Referans: $reference" : ""}${text.isNotEmpty ? "\n$text" : ""}',
                                                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: TextStyle(color: AppColors.error)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Yapay zekaya sor...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.primary),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<dynamic>? sources;
  _ChatMessage({required this.text, required this.isUser, this.sources});
}
