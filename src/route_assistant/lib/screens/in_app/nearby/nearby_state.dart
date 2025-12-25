import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'nearby_models.dart';

class NearbyState {
  final bool loading;
  final String? error;

  final LatLng? me;
  final List<NearbyRoute> routes;

  final String? selectedRouteId;
  final NearbyRoute? selectedRoute;

  // Bottom sheet
  final bool sheetOpen;

  // Detail in sheet
  final bool sheetLoading;
  final String? sheetError;
  final String? sheetDescription;
  final List<String> sheetPhotos;

  const NearbyState({
    required this.loading,
    required this.error,
    required this.me,
    required this.routes,
    required this.selectedRouteId,
    required this.selectedRoute,
    required this.sheetOpen,
    required this.sheetLoading,
    required this.sheetError,
    required this.sheetDescription,
    required this.sheetPhotos,
  });

  factory NearbyState.initial() => const NearbyState(
    loading: true,
    error: null,
    me: null,
    routes: [],
    selectedRouteId: null,
    selectedRoute: null,
    sheetOpen: false,
    sheetLoading: false,
    sheetError: null,
    sheetDescription: null,
    sheetPhotos: [],
  );

  NearbyState copyWith({
    bool? loading,
    String? error,
    LatLng? me,
    List<NearbyRoute>? routes,
    String? selectedRouteId,
    NearbyRoute? selectedRoute,
    bool? sheetOpen,
    bool? sheetLoading,
    String? sheetError,
    String? sheetDescription,
    List<String>? sheetPhotos,
  }) {
    return NearbyState(
      loading: loading ?? this.loading,
      error: error,
      me: me ?? this.me,
      routes: routes ?? this.routes,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      sheetOpen: sheetOpen ?? this.sheetOpen,
      sheetLoading: sheetLoading ?? this.sheetLoading,
      sheetError: sheetError,
      sheetDescription: sheetDescription,
      sheetPhotos: sheetPhotos ?? this.sheetPhotos,
    );
  }
}
