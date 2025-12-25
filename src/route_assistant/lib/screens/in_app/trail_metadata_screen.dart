// lib/screens/trail_metadata_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:route_assistant/services/trail_service.dart';

class TrailMetadataScreen extends StatefulWidget {
  final List<LatLng> points;
  final double totalDistanceMeters;
  final Duration elapsed;
  final DateTime startedAt;
  final DateTime endedAt;

  const TrailMetadataScreen({
    super.key,
    required this.points,
    required this.totalDistanceMeters,
    required this.elapsed,
    required this.startedAt,
    required this.endedAt,
  });

  @override
  State<TrailMetadataScreen> createState() => _TrailMetadataScreenState();
}

class _TrailMetadataScreenState extends State<TrailMetadataScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _difficulty = 'easy'; // easy / medium / hard
  bool _isPublic = true;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (images == null || images.isEmpty) return;

      setState(() {
        _selectedImages = images;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fotoğraf seçilemedi: $e')));
    }
  }

  Future<void> _saveTrail() async {
    if (widget.points.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yeterli nokta yok.')));
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim().isEmpty
          ? 'Trail ${widget.startedAt.toLocal().toString().substring(0, 16)}'
          : _nameCtrl.text.trim();

      // 1) Fotoğrafları upload et -> URL listesi
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        photoUrls = await TrailService.uploadPhotos(_selectedImages);
      }

      // 2) Trail kaydını DB'ye yaz
      final routeId = await TrailService.insertTrailWithPoints(
        name: name,
        description: _descCtrl.text.trim(),
        difficulty: _difficulty,
        isPublic: _isPublic,
        totalDistanceMeters: widget.totalDistanceMeters,
        duration: widget.elapsed,
        startedAt: widget.startedAt.toUtc(),
        endedAt: widget.endedAt.toUtc(),
        points: widget.points,
        photoUrls: photoUrls,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trail kaydedildi ✅ (ID: $routeId)')),
      );

      if (!mounted) return;

      // 🔥 Burada gerçekten "showcase / explore" ekranına gidiyoruz
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = widget.totalDistanceMeters / 1000;

    return Scaffold(
      appBar: AppBar(title: const Text('Trail Detayları')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kutusu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoItem('Süre', _formatDuration(widget.elapsed)),
                    _infoItem('Mesafe', '${distanceKm.toStringAsFixed(2)} km'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Rota adı',
                hintText: 'Örn: Köy içi yürüyüş rotası',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Kısa bir açıklama yaz...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Zorluk seviyesi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'easy', label: Text('Kolay')),
                ButtonSegment(value: 'medium', label: Text('Orta')),
                ButtonSegment(value: 'hard', label: Text('Zor')),
              ],
              selected: {_difficulty},
              onSelectionChanged: (values) {
                setState(() {
                  _difficulty = values.first;
                });
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bu rotayı diğer kullanıcılara açık yap (public)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('Fotoğraflar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Fotoğraf Ekle'),
                ),
                const SizedBox(width: 12),
                if (_selectedImages.isNotEmpty)
                  Text('${_selectedImages.length} foto seçildi'),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final img = _selectedImages[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(img.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveTrail,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Kaydediliyor...' : 'Trail\'i Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
