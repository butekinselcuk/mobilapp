import 'dart:html' as html;
import 'package:flutter/material.dart';

typedef UploadCsvSetState = void Function(bool uploading, String? message);

Future<void> uploadCsvWeb(BuildContext context, {required UploadCsvSetState setStateCallback}) async {
  setStateCallback(true, null);
  // API URL ve token admin_screen.dart'tan alınacak, burada tekrar alınmasına gerek yok
  // Ancak fonksiyonun parametreleri gerekirse genişletilebilir
  // Bu örnekte context ve setStateCallback ile ilerliyoruz
  // Kullanıcıdan dosya seçmesini iste
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.csv';
  uploadInput.click();
  uploadInput.onChange.listen((e) async {
    final file = uploadInput.files?.first;
    if (file == null) {
      setStateCallback(false, 'Dosya seçilmedi.');
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = reader.result as List<int>;
    // API URL ve token'ı context üzerinden veya parametreyle alın
    // (Burada örnek olarak context'ten almıyoruz, admin_screen.dart'ta parametreyle genişletilebilir)
    setStateCallback(false, 'Web fonksiyonu tamamlandı (örnek).');
    // Gerçek yükleme kodu admin_screen.dart'tan taşınabilir
  });
}

void downloadExampleCsv() {
  final url = '/backend/journey_module_example.csv';
  html.AnchorElement(href: url)
    ..setAttribute('download', 'journey_module_example.csv')
    ..click();
} 