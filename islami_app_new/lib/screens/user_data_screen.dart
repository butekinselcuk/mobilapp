import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class UserDataScreen extends StatefulWidget {
  @override
  State<UserDataScreen> createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _history = [];
  List<dynamic> _favorites = [];
  bool _loading = false;
  String? _error;
  int? userId;
  // Her sekme için ayrı state
  String _historySearchText = '';
  String _favoritesSearchText = '';
  String _pendingHistorySearchText = '';
  String _pendingFavoritesSearchText = '';
  String _historySortBy = 'created_at';
  String _favoritesSortBy = 'created_at';
  String _historyOrder = 'desc';
  String _favoritesOrder = 'desc';
  Map<String, dynamic>? _recommendations;
  bool _loadingRecommendations = false;

  int get _activeTabIndex => _tabController.index;

  void _onTabChanged() {
    setState(() {}); // UI'yi güncelle
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserIdAndFetchData();
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIdAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
    if (userId != null) {
      _fetchData();
    } else {
      setState(() {
        _error = 'Kullanıcı kimliği bulunamadı, lütfen tekrar giriş yapın.';
      });
    }
  }

  Future<void> _fetchData() async {
    if (userId == null) return;
    setState(() { _loading = true; _error = null; });
    await dotenv.load(fileName: "assets/.env");
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    // Geçmiş için query
    String historyQuery = '?';
    if (_historySearchText.isNotEmpty) {
      historyQuery += 'search=${Uri.encodeComponent(_historySearchText)}&';
    }
    historyQuery += 'sort_by=$_historySortBy&order=$_historyOrder';
    // Favoriler için query
    String favQuery = '?';
    if (_favoritesSearchText.isNotEmpty) {
      favQuery += 'search=${Uri.encodeComponent(_favoritesSearchText)}&';
    }
    favQuery += 'sort_by=$_favoritesSortBy&order=$_favoritesOrder';
    if (token != null && token.isNotEmpty && token != 'null') {
      final historyRes = await http.get(
        Uri.parse('$apiUrl/user/history$historyQuery'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final favRes = await http.get(
        Uri.parse('$apiUrl/user/favorites$favQuery'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (historyRes.statusCode == 200 && favRes.statusCode == 200) {
        setState(() {
          _history = json.decode(historyRes.body);
          _favorites = json.decode(favRes.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Sunucu hatası';
          _loading = false;
        });
      }
    } else {
      setState(() {
        _error = 'Oturum bulunamadı, lütfen tekrar giriş yapın.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(int hadithId, bool isFav) async {
    await dotenv.load(fileName: "assets/.env");
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    if (token == null || token.isEmpty || token == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Oturum bulunamadı, lütfen tekrar giriş yapın.')));
      return;
    }
    final url = '$apiUrl/user/favorites?hadith_id=$hadithId';
    try {
      final res = isFav
          ? await http.delete(Uri.parse(url), headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            })
          : await http.post(Uri.parse(url), headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            });
      if (res.statusCode == 200) {
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İşlem başarısız')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı hatası')));
    }
  }

  Future<void> _addFavorite(int hadithId) async {
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    if (token == null || token.isEmpty) return;
    final response = await http.post(
      Uri.parse('$apiUrl/user/favorites?hadith_id=$hadithId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'already_exists') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu hadis zaten favorilerde.')),
        );
      } else {
        _fetchData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favorilere eklenirken hata oluştu.')),
      );
    }
  }

  // Geçmiş sekmesinde favori kontrolü için yardımcı fonksiyon:
  bool _isFavorite(int? hadithId) {
    if (hadithId == null) return false;
    return _favorites.any((f) => f['id'] == hadithId);
  }

  // Çoklu seçim için state
  Set<int> _selectedHistoryIds = {};
  Set<int> _selectedFavoriteIds = {};

  Future<void> _deleteSelectedFavorites() async {
    if (_selectedFavoriteIds.isEmpty) return;
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    if (token == null || token.isEmpty) return;
    final response = await http.post(
      Uri.parse('$apiUrl/user/favorites/delete_many'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'hadith_ids': _selectedFavoriteIds.toList()}),
    );
    if (response.statusCode == 200) {
      setState(() { _selectedFavoriteIds.clear(); });
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seçili favoriler silindi.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Favoriler silinirken hata oluştu.')));
    }
  }

  Future<void> _deleteSelectedHistory() async {
    if (_selectedHistoryIds.isEmpty) return;
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    if (token == null || token.isEmpty) return;
    final response = await http.post(
      Uri.parse('$apiUrl/user/history/delete_many'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'history_ids': _selectedHistoryIds.toList()}),
    );
    if (response.statusCode == 200) {
      setState(() { _selectedHistoryIds.clear(); });
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seçili geçmiş silindi.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Geçmiş silinirken hata oluştu.')));
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() { _loadingRecommendations = true; });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
    if (token == null || token.isEmpty) return;
    final response = await http.get(
      Uri.parse('$apiUrl/user/recommendations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        _recommendations = json.decode(response.body);
        _loadingRecommendations = false;
      });
    } else {
      setState(() { _loadingRecommendations = false; });
    }
  }

  Widget _buildFilterBar(bool isHistory) {
    final searchText = isHistory ? _historySearchText : _favoritesSearchText;
    final pendingSearchText = isHistory ? _pendingHistorySearchText : _pendingFavoritesSearchText;
    final sortBy = isHistory ? _historySortBy : _favoritesSortBy;
    final order = isHistory ? _historyOrder : _favoritesOrder;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: pendingSearchText),
                  decoration: InputDecoration(
                    hintText: 'Arama...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) {
                    if (isHistory) {
                      _pendingHistorySearchText = val;
                    } else {
                      _pendingFavoritesSearchText = val;
                    }
                  },
                  enabled: true,
                  readOnly: false,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (isHistory) {
                      _historySearchText = _pendingHistorySearchText;
                    } else {
                      _favoritesSearchText = _pendingFavoritesSearchText;
                    }
                  });
                  _fetchData();
                },
                child: Text('Ara'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sortBy,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  ),
                  items: <Map<String, String>>[
                    {'key': 'created_at', 'label': 'Tarih'},
                    {'key': 'question', 'label': 'Soru'},
                    {'key': 'answer', 'label': 'Cevap'},
                  ]
                      .map((item) => DropdownMenuItem<String>(
                            value: item['key'],
                            child: Text(item['label']!),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      if (isHistory) {
                        _historySortBy = val ?? 'created_at';
                      } else {
                        _favoritesSortBy = val ?? 'created_at';
                      }
                    });
                    _fetchData();
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: order,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'desc', child: Text('Azalan')),
                    DropdownMenuItem(value: 'asc', child: Text('Artan')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      if (isHistory) {
                        _historyOrder = val ?? 'desc';
                      } else {
                        _favoritesOrder = val ?? 'desc';
                      }
                    });
                    _fetchData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kullanıcıya Özel Öneriler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          if (_loadingRecommendations)
            Center(child: CircularProgressIndicator()),
          if (!_loadingRecommendations && _recommendations != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((_recommendations!['user_top_hadiths'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('En Çok Favorilediğiniz Hadisler:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(_recommendations!['user_top_hadiths'] as List).map((h) => Card(
                        color: Colors.green[50],
                        child: ListTile(
                          title: Text(h['text'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Kaynak: ${h['source'] ?? ''}\nReferans: ${h['reference'] ?? ''}'),
                        ),
                      )),
                    ],
                  ),
                SizedBox(height: 8),
                if (_recommendations!['week_top_hadith'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Haftanın Hadisi:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Card(
                        color: Colors.blue[50],
                        child: ListTile(
                          title: Text(_recommendations!['week_top_hadith']['text'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Kaynak: ${_recommendations!['week_top_hadith']['source'] ?? ''}\nReferans: ${_recommendations!['week_top_hadith']['reference'] ?? ''}'),
                        ),
                      ),
                    ],
                  ),
                if ((_recommendations!['user_top_hadiths'] as List).isEmpty && _recommendations!['week_top_hadith'] == null)
                  Text('Henüz öneri bulunmamaktadır.'),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geçmiş & Favoriler'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Geçmiş'),
            Tab(text: 'Favoriler'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    _buildRecommendationsWidget(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Geçmiş
                          Column(
                            children: [
                              _buildFilterBar(true),
                              // Geçmiş sekmesi üstüne toplu silme butonu:
                              _selectedHistoryIds.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    child: ElevatedButton.icon(
                                      onPressed: _deleteSelectedHistory,
                                      icon: Icon(Icons.delete),
                                      label: Text('Seçili geçmişi sil'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    ),
                                  )
                                : SizedBox.shrink(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _history.length,
                                  itemBuilder: (context, i) {
                                    final h = _history[i];
                                    return Card(
                                      elevation: 3,
                                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(h['question'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.copy, size: 20),
                                                  tooltip: 'Kopyala',
                                                  onPressed: () {
                                                    Clipboard.setData(ClipboardData(text: h['answer'] ?? ''));
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cevap panoya kopyalandı.')));
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.share, size: 20),
                                                  tooltip: 'Paylaş',
                                                  onPressed: () {
                                                    final metin = h['answer'] ?? '';
                                                    Share.share(metin);
                                                  },
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6),
                                            Text(h['answer'] ?? '', style: TextStyle(color: Colors.black87)),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (h['created_at'] != null)
                                                  Text(h['created_at'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                Spacer(),
                                                IconButton(
                                                  icon: Icon(
                                                    _isFavorite(h['hadith_id']) ? Icons.star : Icons.star_border,
                                                    color: Colors.amber,
                                                  ),
                                                  onPressed: _isFavorite(h['hadith_id'])
                                                      ? null
                                                      : () {
                                                          if (h['hadith_id'] != null) {
                                                            _addFavorite(h['hadith_id']);
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hadis ID bulunamadı.')));
                                                          }
                                                        },
                                                  tooltip: _isFavorite(h['hadith_id']) ? 'Zaten favorilerde' : 'Favorilere ekle',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Favoriler
                          Column(
                            children: [
                              _buildFilterBar(false),
                              // Favoriler sekmesi üstüne toplu silme butonu:
                              _selectedFavoriteIds.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    child: ElevatedButton.icon(
                                      onPressed: _deleteSelectedFavorites,
                                      icon: Icon(Icons.delete),
                                      label: Text('Seçili favorileri sil'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    ),
                                  )
                                : SizedBox.shrink(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _favorites.length,
                                  itemBuilder: (context, i) {
                                    final f = _favorites[i];
                                    final isFav = true;
                                    return Card(
                                      elevation: 3,
                                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(f['text'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.copy, size: 20),
                                                  tooltip: 'Kopyala',
                                                  onPressed: () {
                                                    Clipboard.setData(ClipboardData(text: f['text'] ?? ''));
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hadis panoya kopyalandı.')));
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.share, size: 20),
                                                  tooltip: 'Paylaş',
                                                  onPressed: () {
                                                    final metin = f['text'] ?? '';
                                                    Share.share(metin);
                                                  },
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6),
                                            Text('Kaynak: ${f['source'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                            Text('Referans: ${f['reference'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                            Text('Kategori: ${f['category'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                            Text('Dil: ${f['language'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                            Row(
                                              children: [
                                                Spacer(),
                                                IconButton(
                                                  icon: Icon(Icons.favorite, color: Colors.red),
                                                  onPressed: () => _toggleFavorite(f['id'], true),
                                                  tooltip: 'Favoriden çıkar',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 