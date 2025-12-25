// lib/screens/trail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:route_assistant/screens/in_app/trail_metadata_screen.dart';

class TrailScreen extends StatefulWidget {
  const TrailScreen({super.key});

  @override
  State<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends State<TrailScreen> {
  GoogleMapController? _mapCtrl;
  StreamSubscription<gl.Position>? _posSub;

  bool _initializing = true;
  String? _error;
  LatLng? _lastLatLng;

  // 📌 Trail kayıt durumları
  bool _isRecording = false;
  List<LatLng> _trailPoints = [];
  double _totalDistanceMeters = 0;

  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapCtrl?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Konum servisi kapalı. Lütfen açın.';
          _initializing = false;
        });
        return;
      }

      var perm = await gl.Geolocator.checkPermission();
      if (perm == gl.LocationPermission.denied) {
        perm = await gl.Geolocator.requestPermission();
      }
      if (perm == gl.LocationPermission.denied) {
        setState(() {
          _error = 'Konum izni reddedildi.';
          _initializing = false;
        });
        return;
      }
      if (perm == gl.LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Konum izni kalıcı reddedildi. Lütfen cihaz ayarlarından verin.';
          _initializing = false;
        });
        return;
      }

      // ilk konumu al
      final p = await gl.Geolocator.getCurrentPosition(
        desiredAccuracy: gl.LocationAccuracy.best,
      );
      _lastLatLng = LatLng(p.latitude, p.longitude);

      setState(() {
        _error = null;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'İzin/konum hatası: $e';
        _initializing = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapCtrl = controller;

    // İlk kamerayı kullanıcı konumuna götür
    if (_lastLatLng != null) {
      await _mapCtrl!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _lastLatLng!, zoom: 16),
        ),
      );
    }

    // Canlı takip (kamera + kayıt)
    _posSub?.cancel();
    _posSub =
        gl.Geolocator.getPositionStream(
          locationSettings: const gl.LocationSettings(
            accuracy: gl.LocationAccuracy.best,
            distanceFilter: 5, // 5m değişimde güncelle
          ),
        ).listen((pos) {
          final newLatLng = LatLng(pos.latitude, pos.longitude);
          _lastLatLng = newLatLng;

          // Kamerayı takip ettir
          _mapCtrl?.animateCamera(CameraUpdate.newLatLng(newLatLng));

          // Eğer kayıt açıksa rotaya ekle
          if (_isRecording) {
            _onNewTrailPoint(newLatLng);
          }
        });
  }

  // Yeni nokta geldiğinde trail listesine ekle + mesafe hesapla
  void _onNewTrailPoint(LatLng newPoint) {
    setState(() {
      if (_trailPoints.isNotEmpty) {
        final last = _trailPoints.last;
        _totalDistanceMeters += gl.Geolocator.distanceBetween(
          last.latitude,
          last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );
      }
      _trailPoints.add(newPoint);
    });
  }

  // Start / Stop butonu
  Future<void> _onStartTrail() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_lastLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum alınamadı, biraz bekleyin.')),
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _trailPoints = [_lastLatLng!];
      _totalDistanceMeters = 0;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });

    // Süre sayaç
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRecording || _startTime == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRecording = false;
    });

    final endedAt = DateTime.now();
    final startedAt = _startTime ?? endedAt;

    if (_trailPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trail kaydedilecek kadar veri yok.')),
      );
      return;
    }

    // 👉 Yeni ekrana git, verileri oraya gönder
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailMetadataScreen(
          points: _trailPoints,
          totalDistanceMeters: _totalDistanceMeters,
          elapsed: _elapsed,
          startedAt: startedAt,
          endedAt: endedAt,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final initialCam = CameraPosition(
      target:
          _lastLatLng ?? const LatLng(39.925533, 32.866287), // Ankara fallback
      zoom: _lastLatLng == null ? 5 : 16,
    );

    final distanceKm = _totalDistanceMeters / 1000;

    return Scaffold(
      appBar: AppBar(title: const Text('Trail')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (_error == null)
                  GoogleMap(
                    initialCameraPosition: initialCam,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: true, // mavi nokta
                    myLocationButtonEnabled: true, // sağ üstte konum butonu
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    polylines: {
                      if (_trailPoints.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('trail'),
                          width: 5,
                          points: _trailPoints,
                          color: Colors.blue, // istersen sil, default renk olur
                        ),
                    },
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  ),

                // Süre + Mesafe + Start/Stop butonu paneli
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoItem(
                              label: 'Süre',
                              value: _formatDuration(_elapsed),
                            ),
                            _buildInfoItem(
                              label: 'Mesafe',
                              value: '${distanceKm.toStringAsFixed(2)} km',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _error == null ? _onStartTrail : null,
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(
                              _isRecording ? 'Stop Trail' : 'Start Trail',
                            ),
                            style: FilledButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
