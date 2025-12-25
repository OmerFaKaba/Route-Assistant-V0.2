import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nearby_controller.dart';
import 'nearby_state.dart';
import 'widgets/nearby_map_view.dart';
import 'widgets/route_bottom_sheet.dart';

class MapNearbyScreen extends StatefulWidget {
  const MapNearbyScreen({super.key});

  @override
  State<MapNearbyScreen> createState() => _MapNearbyScreenState();
}

class _MapNearbyScreenState extends State<MapNearbyScreen> {
  late final NearbyController _c;
  String? _lastSheetRouteId;

  @override
  void initState() {
    super.initState();
    _c = NearbyController(client: Supabase.instance.client, radiusM: 2000000);
    _c.addListener(_onControllerChanged);
    _c.boot();
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    _c.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final s = _c.state;

    // Sheet açma tetikleyicisi (seçim değişince)
    final rid = s.selectedRouteId;
    if (s.sheetOpen &&
        rid != null &&
        rid.isNotEmpty &&
        rid != _lastSheetRouteId) {
      _lastSheetRouteId = rid;
      _openSheet();
    }

    // Sheet kapatılacaksa (clearSelection vb.)
    if (!s.sheetOpen && _lastSheetRouteId != null) {
      _lastSheetRouteId = null;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).maybePop();
      }
    }
  }

  Future<void> _openSheet() async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black26,
      builder: (_) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, __) {
            final s = _c.state;

            return RouteBottomSheet(
              state: s,
              onDetail: _goToDetail,
              onDirections: _openDirections,
            );
          },
        );
      },
    ).whenComplete(() {
      // kullanıcı sheet’i kapattı
      _c.onSheetClosed();
      _lastSheetRouteId = null;
      _c.clearSelection();
    });
  }

  void _goToDetail() {
    final id = _c.state.selectedRouteId;
    if (id == null || id.isEmpty) return;
    Navigator.pushNamed(context, '/trailDetail', arguments: id);
  }

  Future<void> _openDirections() async {
    final dest = _c.state.selectedRoute?.start;
    if (dest == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${dest.latitude},${dest.longitude}'
      '&travelmode=walking',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final NearbyState s = _c.state;

        if (s.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (s.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Yakındaki Rotalar")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.error!),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Yakındaki Rotalar")),
          body: NearbyMapView(
            controller: _c,
            state: s,
            onMapTap: () {
              // Haritaya tıklayınca seçim temizle + sheet kapansın
              _c.clearSelection();
            },
          ),
        );
      },
    );
  }
}
