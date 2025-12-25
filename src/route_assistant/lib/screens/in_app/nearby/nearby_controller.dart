import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:route_assistant/services/nearby_service.dart';
import 'nearby_models.dart';
import 'nearby_state.dart';

class NearbyController extends ChangeNotifier {
  final SupabaseClient _client;
  late final NearbyService _service;

  NearbyState _state = NearbyState.initial();
  NearbyState get state => _state;

  // config
  final int radiusM;

  // icons
  BitmapDescriptor? _iconMeBlue;
  BitmapDescriptor? _iconRouteOrange;
  BitmapDescriptor? _iconRouteGreen;

  int _detailReqToken = 0;

  NearbyController({required SupabaseClient client, this.radiusM = 2000000})
    : _client = client {
    _service = NearbyService(_client);
  }

  BitmapDescriptor routeIcon({required bool selected}) {
    if (selected) {
      return _iconRouteGreen ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return _iconRouteOrange ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  BitmapDescriptor meIcon() {
    return _iconMeBlue ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }

  Future<void> boot() async {
    try {
      _setState(_state.copyWith(loading: true, error: null));
      await _loadIconsSafe();
      final pos = await _getCurrentPosition();
      final me = LatLng(pos.latitude, pos.longitude);

      final routes = await _service.getNearbyRoutes(
        lat: me.latitude,
        lng: me.longitude,
        radiusM: radiusM,
      );

      _setState(
        _state.copyWith(loading: false, error: null, me: me, routes: routes),
      );
    } catch (e) {
      _setState(_state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _loadIconsSafe() async {
    try {
      const cfgRoute = ImageConfiguration(size: Size(72, 72));
      const cfgMe = ImageConfiguration(size: Size(48, 48));

      _iconRouteOrange = await BitmapDescriptor.fromAssetImage(
        cfgRoute,
        'lib/assets/icons/walking_orange.png',
      );
      _iconRouteGreen = await BitmapDescriptor.fromAssetImage(
        cfgRoute,
        'lib/assets/icons/walking_green.png',
      );
      _iconMeBlue = await BitmapDescriptor.fromAssetImage(
        cfgMe,
        'lib/assets/icons/walking_blue.png',
      );
    } catch (_) {
      _iconRouteOrange = null;
      _iconRouteGreen = null;
      _iconMeBlue = null;
    }
  }

  Future<Position> _getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception("GPS kapalı.");
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw Exception("Konum izni verilmedi.");
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception("Konum izni kalıcı kapalı. Ayarlardan açmalısın.");
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void selectRoute(NearbyRoute route) {
    _setState(
      _state.copyWith(
        selectedRouteId: route.id,
        selectedRoute: route,
        sheetOpen: true,
        sheetLoading: true,
        sheetError: null,
        sheetDescription: null,
        sheetPhotos: const [],
      ),
    );

    _loadSelectedRouteDetailSafe(route.id);
  }

  void clearSelection() {
    _setState(
      _state.copyWith(
        selectedRouteId: null,
        selectedRoute: null,
        sheetOpen: false,
        sheetLoading: false,
        sheetError: null,
        sheetDescription: null,
        sheetPhotos: const [],
      ),
    );
  }

  void onSheetClosed() {
    // sheet kapandı ama seçim kalmış olabilir, burada seçim temizleyelim
    // senin eski davranışına en yakın: sheet kapanınca state sheetOpen false
    _setState(_state.copyWith(sheetOpen: false));
  }

  Future<void> _loadSelectedRouteDetailSafe(String routeId) async {
    final token = ++_detailReqToken;

    try {
      final detail = await _service.getRouteDetail(routeId);

      // seçim değiştiyse / yeni istek geldiyse ignore
      if (_state.selectedRouteId != routeId) return;
      if (token != _detailReqToken) return;

      _setState(
        _state.copyWith(
          sheetLoading: false,
          sheetError: null,
          sheetDescription: detail.description,
          sheetPhotos: detail.photos,
        ),
      );
    } catch (e) {
      if (_state.selectedRouteId != routeId) return;
      if (token != _detailReqToken) return;

      _setState(_state.copyWith(sheetLoading: false, sheetError: e.toString()));
    }
  }

  void _setState(NearbyState next) {
    _state = next;
    notifyListeners();
  }
}
