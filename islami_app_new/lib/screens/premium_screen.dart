import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // Added for json.decode

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isPremium = false;
  String? _premiumExpiry;
  bool _loading = true;
  bool _activating = false;
  String? _activationMsg;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() { _loading = true; });
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      print('API_URL: $apiUrl');
      print('JWT token: $token');
      final response = await http.get(
        Uri.parse('$apiUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('API yanıtı: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('is_premium:  [32m${data['is_premium']} [0m');
        setState(() {
          _isPremium = data['is_premium'] == true;
          _premiumExpiry = data['premium_expiry'];
          _loading = false;
        });
      } else {
        setState(() { _loading = false; });
      }
    } catch (e) {
      print('Hata: $e');
      setState(() { _loading = false; });
    }
  }

  Future<void> _activatePremium() async {
    setState(() { _activating = true; _activationMsg = null; });
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$apiUrl/user/activate_premium'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _activationMsg = 'Premium başarıyla etkinleştirildi!';
        });
        await _fetchUserInfo(); // Premium state'i güncelle
      } else {
        setState(() {
          _activationMsg = 'Aktivasyon başarısız.';
        });
      }
    } catch (e) {
      setState(() {
        _activationMsg = 'Bir hata oluştu.';
      });
    } finally {
      setState(() { _activating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Üyelik'),
        leading: BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isPremium ? Icons.verified : Icons.verified_outlined,
                  color: _isPremium ? Colors.amber : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  _isPremium ? 'Premium Üye' : 'Premium Değil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _isPremium ? Colors.amber[800] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (_isPremium && _premiumExpiry != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                child: Text(
                  'Premium bitiş: ${_premiumExpiry!.substring(0, 10)}',
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ),
            const SizedBox(height: 18),
            const Text(
              'Premium Avantajları:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...[
              'Sınırsız AI asistan sorgusu',
              'Reklamsız deneyim',
              'Premium koleksiyonlar ve özel içerikler',
              'Kişisel çalışma alanı ve bulut yedekleme',
              'Özel rozet ve profil görünümü',
            ].map((e) => Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 20),
                    const SizedBox(width: 6),
                    Text(e, style: const TextStyle(fontSize: 15)),
                  ],
                )),
            const SizedBox(height: 24),
            if (!_isPremium)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Abonelik Satın Al (Demo)'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo: Gerçek ödeme entegrasyonu ileride eklenecek.')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.verified),
                    label: _activating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Premiumu Etkinleştir (Demo)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _activating ? null : _activatePremium,
                  ),
                ],
              ),
            if (_activationMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _activationMsg!,
                  style: TextStyle(
                    color: _activationMsg!.contains('başarı') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_isPremium)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[800], size: 32),
                    const SizedBox(width: 10),
                    const Text(
                      'Premium avantajlarınız aktif!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 