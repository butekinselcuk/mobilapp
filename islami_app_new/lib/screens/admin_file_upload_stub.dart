import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
typedef UploadCsvSetState = void Function(bool uploading, String? message);

Future<void> uploadCsvWeb(BuildContext context, {required UploadCsvSetState setStateCallback}) async {
  // Mobilde de çalışacak şekilde güncellendi
  setStateCallback(true, null);
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null || result.files.single.path == null) {
      setStateCallback(false, 'Dosya seçilmedi.');
      return;
    }
    String filePath = result.files.single.path!;
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    var uri = Uri.parse('$apiUrl/admin/upload_hadiths');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    var response = await request.send();
    if (response.statusCode == 200) {
      setStateCallback(false, 'Yükleme başarılı!');
    } else {
      setStateCallback(false, 'Hata: ${response.statusCode}');
    }
  } catch (e) {
    setStateCallback(false, 'Hata: $e');
  }
}

void downloadExampleCsv() {
  // Mobilde bir şey yapma
} 