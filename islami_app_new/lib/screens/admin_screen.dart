import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'admin_file_upload.dart';

// --- Yeni: Her başlık için ayrı widget ---
class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}
class _SettingsTabState extends State<SettingsTab> {
  List<Map<String, dynamic>> settings = [];
  bool loadingSettings = false;
  String? errorSettings;
  bool saving = false;
  String? saveMessage;
  Future<void> fetchSettings() async {
    setState(() { loadingSettings = true; errorSettings = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/admin/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() { settings = data; });
      } else {
        setState(() { errorSettings = 'Ayarlar alınamadı: ${response.body}'; });
      }
    } catch (e) {
      setState(() { errorSettings = 'Hata: $e'; });
    } finally {
      setState(() { loadingSettings = false; });
    }
  }
  Future<void> saveSetting(int index) async {
    setState(() { saving = true; saveMessage = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/admin/settings'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'key': settings[index]['key'],
          'value': settings[index]['value'],
        }),
      );
      if (response.statusCode == 200) {
        setState(() { saveMessage = 'Ayar kaydedildi.'; });
      } else {
        setState(() { saveMessage = 'Kaydedilemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { saveMessage = 'Hata: $e'; });
    } finally {
      setState(() { saving = false; });
    }
  }
  @override
  void initState() {
    super.initState();
    fetchSettings();
  }
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Ayar Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        loadingSettings
            ? Center(child: CircularProgressIndicator())
            : errorSettings != null
                ? Text(errorSettings!, style: TextStyle(color: Colors.red))
                : Column(
                    children: [
                      ...settings.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(s['key'] ?? ''),
                            subtitle: TextField(
                              controller: TextEditingController(text: s['value'] ?? '')
                                ..selection = TextSelection.collapsed(offset: (s['value'] ?? '').length),
                              onChanged: (v) => settings[i]['value'] = v,
                              decoration: InputDecoration(labelText: 'Değer'),
                            ),
                            trailing: saving
                                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(
                                    icon: Icon(Icons.save),
                                    onPressed: () => saveSetting(i),
                                  ),
                          ),
                        );
                      }).toList(),
                      if (saveMessage != null) ...[
                        SizedBox(height: 8),
                        Text(saveMessage!, style: TextStyle(color: saveMessage!.contains('kaydedildi') ? Colors.green : Colors.red)),
                      ]
                    ],
                  ),
      ],
    );
  }
}

// --- Hadis Yükleme Tab ---
class HadisYuklemeTab extends StatefulWidget {
  const HadisYuklemeTab({Key? key}) : super(key: key);
  @override
  State<HadisYuklemeTab> createState() => _HadisYuklemeTabState();
}
class _HadisYuklemeTabState extends State<HadisYuklemeTab> {
  bool uploading = false;
  String? uploadMessage;
  Future<void> uploadCsv() async {
    setState(() { uploadMessage = null; });
    await uploadCsvWeb(context, setStateCallback: (bool uploading, String? message) {
      setState(() { this.uploading = uploading; this.uploadMessage = message; });
    });
  }
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Toplu Hadis Yükleme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        uploading
            ? Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text('CSV ile Hadis Yükle'),
                onPressed: uploadCsv,
              ),
        if (uploadMessage != null) ...[
          SizedBox(height: 8),
          Text(uploadMessage!, style: TextStyle(color: uploadMessage!.contains('başarılı') ? Colors.green : Colors.red)),
        ],
      ],
    );
  }
}

// --- Embedding Tab ---
class EmbeddingTab extends StatefulWidget {
  const EmbeddingTab({Key? key}) : super(key: key);
  @override
  State<EmbeddingTab> createState() => _EmbeddingTabState();
}
class _EmbeddingTabState extends State<EmbeddingTab> {
  bool embeddingUpdating = false;
  String? embeddingMessage;
  Future<void> updateEmbeddings() async {
    setState(() { embeddingUpdating = true; embeddingMessage = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/admin/update_embeddings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() { embeddingMessage = 'Embedding güncellendi.'; });
      } else {
        setState(() { embeddingMessage = 'Hata: ${response.body}'; });
      }
    } catch (e) {
      setState(() { embeddingMessage = 'Hata: $e'; });
    } finally {
      setState(() { embeddingUpdating = false; });
    }
  }
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Embedding Güncelleme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        embeddingUpdating
            ? Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Tüm Embeddingleri Güncelle'),
                onPressed: updateEmbeddings,
              ),
        if (embeddingMessage != null) ...[
          SizedBox(height: 8),
          Text(embeddingMessage!, style: TextStyle(color: embeddingMessage!.contains('güncellendi') ? Colors.green : Colors.red)),
        ],
      ],
    );
  }
}

// --- Kullanıcılar Tab ---
class KullaniciTab extends StatefulWidget {
  const KullaniciTab({Key? key}) : super(key: key);
  @override
  State<KullaniciTab> createState() => _KullaniciTabState();
}
class _KullaniciTabState extends State<KullaniciTab> {
  List<Map<String, dynamic>> users = [];
  bool loadingUsers = false;
  String? errorUsers;
  String? userActionMessage;
  Future<void> fetchUsers() async {
    setState(() { loadingUsers = true; errorUsers = null; userActionMessage = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() { users = data; });
      } else {
        setState(() { errorUsers = 'Kullanıcılar alınamadı: ${response.body}'; });
      }
    } catch (e) {
      setState(() { errorUsers = 'Hata: $e'; });
    } finally {
      setState(() { loadingUsers = false; });
    }
  }
  Future<void> deleteUser(int userId) async {
    setState(() { userActionMessage = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/admin/user/delete?user_id=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() { userActionMessage = 'Kullanıcı silindi.'; users.removeWhere((u) => u['id'] == userId); });
      } else {
        setState(() { userActionMessage = 'Silinemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { userActionMessage = 'Hata: $e'; });
    }
  }
  Future<void> makeUserPremium(int userId, {required bool activate}) async {
    setState(() { userActionMessage = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/admin/user/premium?user_id=$userId&action=${activate ? 'activate' : 'deactivate'}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() { userActionMessage = activate ? 'Kullanıcı premium yapıldı.' : 'Premium kaldırıldı.'; });
        fetchUsers();
      } else {
        setState(() { userActionMessage = 'İşlem başarısız: ${response.body}'; });
      }
    } catch (e) {
      setState(() { userActionMessage = 'Hata: $e'; });
    }
  }
  Future<void> deleteUserWithConfirm(int userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kullanıcıyı Sil'),
        content: Text('"$username" adlı kullanıcıyı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Hayır')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Evet')),
        ],
      ),
    );
    if (confirmed == true) {
      await deleteUser(userId);
    }
  }
  Future<void> confirmPremiumAction(int userId, bool isPremium, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPremium ? 'Premiumu Kaldır' : 'Premium Yap'),
        content: Text(isPremium
            ? '"$username" adlı kullanıcının premium üyeliğini kaldırmak istiyor musunuz?'
            : '"$username" adlı kullanıcıyı premium yapmak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Hayır')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Evet')),
        ],
      ),
    );
    if (confirmed == true) {
      await makeUserPremium(userId, activate: !isPremium);
    }
  }
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Kullanıcı Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ElevatedButton.icon(
          icon: Icon(Icons.people),
          label: Text('Kullanıcıları Listele'),
          onPressed: fetchUsers,
        ),
        if (loadingUsers) ...[
          Center(child: CircularProgressIndicator()),
        ],
        if (errorUsers != null) ...[
          Text(errorUsers!, style: TextStyle(color: Colors.red)),
        ],
        if (users.isNotEmpty) ...[
          SizedBox(height: 12),
          ...users.map((u) => Card(
            child: ListTile(
              title: Text('${u['username']} (${u['email']})'),
              subtitle: Text('Admin: ${u['is_admin']} | Premium: ${u['is_premium']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      u['is_premium'] == true ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    tooltip: u['is_premium'] == true ? 'Premiumu Kaldır' : 'Premium Yap',
                    onPressed: () => confirmPremiumAction(u['id'], u['is_premium'] == true, u['username']),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Sil',
                    onPressed: () => deleteUserWithConfirm(u['id'], u['username']),
                  ),
                ],
              ),
            ),
          )),
        ],
        if (userActionMessage != null) ...[
          SizedBox(height: 8),
          Text(userActionMessage!, style: TextStyle(color: userActionMessage!.contains('silindi') || userActionMessage!.contains('premium') ? Colors.green : Colors.red)),
        ],
      ],
    );
  }
}

// --- İlim Yolculukları Tab ---
class JourneyTab extends StatefulWidget {
  const JourneyTab({Key? key}) : super(key: key);
  @override
  State<JourneyTab> createState() => _JourneyTabState();
}

class _JourneyTabState extends State<JourneyTab> {
  bool uploadingJourney = false;
  String? uploadJourneyMessage;
  List<Map<String, dynamic>> modules = [];
  bool loading = false;
  String? error;

  Future<void> fetchModules() async {
    setState(() { loading = true; error = null; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/admin/journey_modules'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() { modules = data; });
      } else {
        setState(() { error = 'Modüller alınamadı: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> deleteModule(int moduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modülü Sil'),
        content: Text('Bu modülü ve tüm adımlarını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Hayır')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Evet')),
        ],
      ),
    );
    if (confirmed != true) return;
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    setState(() { loading = true; });
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/admin/journey_module?module_id=$moduleId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        fetchModules();
      } else {
        setState(() { error = 'Modül silinemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> deleteStep(int stepId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adımı Sil'),
        content: Text('Bu adımı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Hayır')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Evet')),
        ],
      ),
    );
    if (confirmed != true) return;
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    setState(() { loading = true; });
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/admin/journey_step?step_id=$stepId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        fetchModules();
      } else {
        setState(() { error = 'Adım silinemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> addModuleDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final iconController = TextEditingController(text: 'explore');
    final categoryController = TextEditingController();
    final tagsController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modül Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Başlık')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Açıklama')),
            TextField(controller: iconController, decoration: InputDecoration(labelText: 'İkon (örn: explore)')),
            TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Kategori')),
            TextField(controller: tagsController, decoration: InputDecoration(labelText: 'Etiketler (virgül ile)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Ekle')),
        ],
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty) {
      await addModule(
        titleController.text.trim(),
        descController.text.trim(),
        iconController.text.trim(),
        categoryController.text.trim(),
        tagsController.text.trim(),
      );
    }
  }

  Future<void> addModule(String title, String desc, String icon, String category, String tags) async {
    setState(() { loading = true; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/admin/journey_module'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'title': title, 'description': desc, 'icon': icon, 'category': category, 'tags': tags}),
      );
      if (response.statusCode == 200) {
        fetchModules();
      } else {
        setState(() { error = 'Modül eklenemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> addStepDialog() async {
    if (modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Önce bir modül ekleyin.')));
      return;
    }
    int selectedModuleId = modules.first['id'];
    final titleController = TextEditingController();
    final orderController = TextEditingController();
    final contentController = TextEditingController();
    final mediaUrlController = TextEditingController();
    final sourceController = TextEditingController();
    String mediaType = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adım Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedModuleId,
              items: modules.map((m) => DropdownMenuItem<int>(value: m['id'] as int, child: Text(m['title']))).toList(),
              onChanged: (v) { if (v != null) selectedModuleId = v; },
              decoration: InputDecoration(labelText: 'Modül'),
            ),
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Başlık')),
            TextField(controller: orderController, decoration: InputDecoration(labelText: 'Sıra (sayı)')),
            TextField(controller: contentController, decoration: InputDecoration(labelText: 'İçerik')),
            DropdownButtonFormField<String>(
              value: mediaType.isEmpty ? null : mediaType,
              items: [DropdownMenuItem(value: '', child: Text('Yok')), DropdownMenuItem(value: 'image', child: Text('Resim')), DropdownMenuItem(value: 'video', child: Text('Video')), DropdownMenuItem(value: 'link', child: Text('Link'))],
              onChanged: (v) { if (v != null) mediaType = v; },
              decoration: InputDecoration(labelText: 'Medya Türü'),
            ),
            TextField(controller: mediaUrlController, decoration: InputDecoration(labelText: 'Medya URL')),
            TextField(controller: sourceController, decoration: InputDecoration(labelText: 'Kaynak/Referans')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Ekle')),
        ],
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty && int.tryParse(orderController.text.trim()) != null) {
      await addStep(
        selectedModuleId,
        titleController.text.trim(),
        int.parse(orderController.text.trim()),
        contentController.text.trim(),
        mediaUrlController.text.trim(),
        mediaType,
        sourceController.text.trim(),
      );
    }
  }

  Future<void> addStep(int moduleId, String title, int order, String content, String mediaUrl, String mediaType, String source) async {
    setState(() { loading = true; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/admin/journey_step'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'module_id': moduleId,
          'title': title,
          'order': order,
          'content': content,
          'media_url': mediaUrl,
          'media_type': mediaType,
          'source': source,
        }),
      );
      if (response.statusCode == 200) {
        fetchModules();
      } else {
        setState(() { error = 'Adım eklenemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> reorderSteps(int moduleId, List<Map<String, dynamic>> newSteps) async {
    setState(() { loading = true; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final payload = newSteps.map((s) => {'id': s['id'], 'order': s['order']}).toList();
      final response = await http.post(
        Uri.parse('$apiUrl/admin/journey_step/reorder'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'module_id': moduleId, 'steps': payload}),
      );
      if (response.statusCode == 200) {
        fetchModules();
      } else {
        setState(() { error = 'Sıralama güncellenemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchModules();
  }

  // Modül düzenleme dialog fonksiyonu
  Future<void> editModuleDialog(Map<String, dynamic> module) async {
    final titleController = TextEditingController(text: module['title'] ?? '');
    final descController = TextEditingController(text: module['description'] ?? '');
    final iconController = TextEditingController(text: module['icon'] ?? 'explore');
    final categoryController = TextEditingController(text: module['category'] ?? '');
    final tagsController = TextEditingController(text: module['tags'] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modülü Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Başlık')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Açıklama')),
            TextField(controller: iconController, decoration: InputDecoration(labelText: 'İkon (örn: explore)')),
            TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Kategori')),
            TextField(controller: tagsController, decoration: InputDecoration(labelText: 'Etiketler (virgül ile)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Kaydet')),
        ],
      ),
    );
    if (result == true) {
      await updateModule(
        module['id'],
        titleController.text.trim(),
        descController.text.trim(),
        iconController.text.trim(),
        categoryController.text.trim(),
        tagsController.text.trim(),
      );
    }
  }

  Future<void> updateModule(int id, String title, String desc, String icon, String category, String tags) async {
    setState(() { loading = true; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/admin/journey_module/update'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'title': title, 'description': desc, 'icon': icon, 'category': category, 'tags': tags}),
      );
      if (response.statusCode == 200) {
        fetchModules();
      } else {
        setState(() { error = 'Modül güncellenemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  // Adım düzenleme dialog fonksiyonu
  Future<void> editStepDialog(Map<String, dynamic> step) async {
    final titleController = TextEditingController(text: step['title'] ?? '');
    final orderController = TextEditingController(text: step['order']?.toString() ?? '');
    final contentController = TextEditingController(text: step['content'] ?? '');
    final mediaUrlController = TextEditingController(text: step['media_url'] ?? '');
    final sourceController = TextEditingController(text: step['source'] ?? '');
    String mediaType = step['media_type'] ?? '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adımı Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Başlık')),
            TextField(controller: orderController, decoration: InputDecoration(labelText: 'Sıra (sayı)')),
            TextField(controller: contentController, decoration: InputDecoration(labelText: 'İçerik')),
            DropdownButtonFormField<String>(
              value: mediaType.isEmpty ? null : mediaType,
              items: [DropdownMenuItem(value: '', child: Text('Yok')), DropdownMenuItem(value: 'image', child: Text('Resim')), DropdownMenuItem(value: 'video', child: Text('Video')), DropdownMenuItem(value: 'link', child: Text('Link'))],
              onChanged: (v) { if (v != null) mediaType = v; },
              decoration: InputDecoration(labelText: 'Medya Türü'),
            ),
            TextField(controller: mediaUrlController, decoration: InputDecoration(labelText: 'Medya URL')),
            TextField(controller: sourceController, decoration: InputDecoration(labelText: 'Kaynak/Referans')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Kaydet')),
        ],
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty && int.tryParse(orderController.text.trim()) != null) {
      await updateStep(
        step['id'],
        titleController.text.trim(),
        int.parse(orderController.text.trim()),
        contentController.text.trim(),
        mediaUrlController.text.trim(),
        mediaType,
        sourceController.text.trim(),
      );
    }
  }

  Future<void> updateStep(int id, String title, int order, String content, String mediaUrl, String mediaType, String source) async {
    setState(() { loading = true; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/admin/journey_step/update'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'title': title, 'order': order, 'content': content, 'media_url': mediaUrl, 'media_type': mediaType, 'source': source}),
      );
      if (response.statusCode == 200) {
        fetchModules();
      } else {
        setState(() { error = 'Adım güncellenemedi: ${response.body}'; });
      }
    } catch (e) {
      setState(() { error = 'Hata: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İlim Yolculukları Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text('Journey modüllerini ve adımlarını CSV ile toplu yükleyebilir, ekleyebilir veya sıralayabilirsiniz.', style: TextStyle(fontSize: 14, color: Colors.black87)),
                SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.upload_file),
                      label: Text('CSV ile Journey Yükle'),
                      onPressed: kIsWeb ? () async {
                        await uploadCsvWeb(context, setStateCallback: (bool uploading, String? message) {
                          setState(() { uploadingJourney = uploading; uploadJourneyMessage = message; });
                        });
                      } : () {
                        setState(() { uploadJourneyMessage = 'Dosya yükleme sadece webde desteklenir.'; });
                      },
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.download),
                      label: Text('Örnek CSV İndir'),
                      onPressed: kIsWeb ? () {
                        downloadExampleCsv();
                      } : null,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('Not: Journey CSV formatı ve örnek dosya backend klasöründe mevcuttur.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Modül Ekle'),
                      onPressed: addModuleDialog,
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Adım Ekle'),
                      onPressed: addStepDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!loading && error == null && modules.isNotEmpty)
          ...modules.map((m) => Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.explore),
                      SizedBox(width: 8),
                      Text(m['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Modülü Düzenle',
                        onPressed: () => editModuleDialog(m),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Modülü Sil',
                        onPressed: () => deleteModule(m['id']),
                      ),
                    ],
                  ),
                  if ((m['description'] ?? '').isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(m['description'] ?? '', style: TextStyle(color: Colors.grey[700])),
                  ],
                  if ((m['category'] ?? '').isNotEmpty || (m['tags'] ?? '').isNotEmpty) ...[
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if ((m['category'] ?? '').isNotEmpty)
                          Chip(label: Text(m['category'], style: TextStyle(fontSize: 12)), backgroundColor: Colors.green[50]),
                        if ((m['tags'] ?? '').isNotEmpty)
                          ...List<Widget>.from(
                            (m['tags'] as String)
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .map((t) => Chip(label: Text(t, style: TextStyle(fontSize: 12)), backgroundColor: Colors.blue[50]))
                          ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8),
                  if ((m['steps'] as List).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Adımlar:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 48.0 * (m['steps'] as List).length,
                          child: ReorderableListView(
                            buildDefaultDragHandles: true,
                            onReorder: (oldIndex, newIndex) async {
                              var steps = List<Map<String, dynamic>>.from(m['steps']);
                              if (newIndex > oldIndex) newIndex--;
                              final item = steps.removeAt(oldIndex);
                              steps.insert(newIndex, item);
                              // Yeni order değerlerini ata
                              for (int i = 0; i < steps.length; i++) {
                                steps[i]['order'] = i + 1;
                              }
                              await reorderSteps(m['id'], steps);
                            },
                            children: [
                              for (final s in m['steps'])
                                ListTile(
                                  key: ValueKey(s['id']),
                                  title: Row(
                                    children: [
                                      Text('${s['order']}. ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(s['title'] ?? ''),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Adımı Düzenle',
                                        onPressed: () => editStepDialog(s),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Adımı Sil',
                                        onPressed: () => deleteStep(s['id']),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )),
        if (!loading && error == null && modules.isEmpty)
          Text('Henüz journey modülü eklenmemiş.', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Tab> _tabs = const [
    Tab(text: 'Ayar Yönetimi', icon: Icon(Icons.settings)),
    Tab(text: 'Hadis Yükleme', icon: Icon(Icons.upload_file)),
    Tab(text: 'Embedding', icon: Icon(Icons.refresh)),
    Tab(text: 'Kullanıcılar', icon: Icon(Icons.people)),
    Tab(text: 'İlim Yolculukları', icon: Icon(Icons.explore)),
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SettingsTab(),
          HadisYuklemeTab(),
          EmbeddingTab(),
          KullaniciTab(),
          JourneyTab(),
        ],
      ),
    );
  }
} 