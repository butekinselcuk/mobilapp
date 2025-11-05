import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math';
import '../theme/app_colors.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({Key? key}) : super(key: key);
  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double? _qiblaDirection;
  Position? _position;
  String? _error;
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _error = 'Konum servisi kapalı.'; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _error = 'Konum izni reddedildi.'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _error = 'Konum izni kalıcı olarak reddedildi.'; });
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _position = pos;
        _qiblaDirection = _calculateQiblaDirection(pos.latitude, pos.longitude);
        _error = null;
      });
    } catch (e) {
      setState(() { _error = 'Konum alınamadı: $e'; });
    }
  }

  double _calculateQiblaDirection(double lat, double lng) {
    double kaabaLatRad = kaabaLat * pi / 180;
    double kaabaLngRad = kaabaLng * pi / 180;
    double latRad = lat * pi / 180;
    double lngRad = lng * pi / 180;
    double dLng = kaabaLngRad - lngRad;
    double y = sin(dLng);
    double x = cos(latRad) * tan(kaabaLatRad) - sin(latRad) * cos(dLng);
    double angle = atan2(y, x) * 180 / pi;
    return (angle + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kıble Pusulası')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0f7fa), Color(0xFFb2dfdb)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _error != null
            ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
            : _position == null || _qiblaDirection == null
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      double heading = snapshot.data?.heading ?? 0;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pusula çerçevesi
                                  Container(
                                    width: 260,
                                    height: 260,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.surface,
                                      boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 16)],
                                    ),
                                  ),
                                  // Yön harfleri
                                  ..._buildDirections(),
                                  // Kuzey oku
                                  Transform.rotate(
                                    angle: (-heading) * (pi / 180),
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Icon(Icons.navigation, size: 60, color: AppColors.error),
                                    ),
                                  ),
                                  // Kıble oku
                                  Transform.rotate(
                                    angle: ((_qiblaDirection! - heading) * (pi / 180)),
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Column(
                                        children: [
                                          Icon(Icons.arrow_upward, size: 60, color: AppColors.primaryDark),
                                          SizedBox(height: 10),
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.green[700],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: Center(child: Icon(Icons.star, color: Theme.of(context).colorScheme.onSurface)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Merkezde Kâbe simgesi
                                  Positioned(
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.brown[700],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
                                        boxShadow: [BoxShadow(color: AppColors.shadowDark, blurRadius: 8)],
                                      ),
                                      child: Center(child: Icon(Icons.mosque, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 32),
                            Text('Kıble Açısı: ${_qiblaDirection!.toStringAsFixed(1)}°', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Konum: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}', style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(Icons.my_location),
                              label: Text('Konumu Yenile'),
                              onPressed: _initLocation,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  List<Widget> _buildDirections() {
    const directions = ['N', 'E', 'S', 'W'];
    final angleStep = 2 * pi / 4;
    return List.generate(4, (i) {
      final angle = -pi / 2 + i * angleStep;
      return Positioned(
        left: 150 + 110 * cos(angle) - 12,
        top: 150 + 110 * sin(angle) - 12,
        child: Text(
          directions[i],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: i == 0 ? AppColors.error : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkOnSurface : Theme.of(context).colorScheme.onSurface),
            shadows: [Shadow(color: Theme.of(context).brightness == Brightness.dark ? AppColors.shadowDark : AppColors.shadowLight, blurRadius: 4)],
          ),
        ),
      );
    });
  }
}