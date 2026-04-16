import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/run_data.dart';
import '../services/stats_service.dart';
import '../services/territory_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  Timer? followTimer;

  bool _isLoadingStats = true;
  String? _statsError;

  double _totalDistance = 0.0;
  int _totalRuns = 0;
  double _avgSpeed = 0.0;

  // --- Territory data ---
  List<Map<String, dynamic>> _territories = [];
  double _myTerritoryArea = 0.0;

  bool get hasLiveLocation =>
      RunDataStore.currentLatitude != null &&
      RunDataStore.currentLongitude != null;

  LatLng get currentLatLng => LatLng(
        RunDataStore.currentLatitude ?? 28.6139,
        RunDataStore.currentLongitude ?? 77.2090,
      );

  List<LatLng> get latestPathPoints {
    return RunDataStore.latestRunPath
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRuns();
    _loadTerritories();

    followTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (RunDataStore.isRunActive && hasLiveLocation) {
        mapController.move(currentLatLng, 17);
      }

      setState(() {});
    });
  }

  Future<void> _loadRuns() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    final result = await StatsService.getAllRuns();

    if (!mounted) return;

    if (result['success'] == true) {
      final runs = result['data'] as List<dynamic>;

      double totalDistance = 0.0;
      double totalSpeed = 0.0;

      for (final run in runs) {
        totalDistance += ((run['distance_km'] ?? 0) as num).toDouble();
        totalSpeed += ((run['avg_speed'] ?? 0) as num).toDouble();
      }

      setState(() {
        _totalRuns = runs.length;
        _totalDistance = totalDistance;
        _avgSpeed = runs.isEmpty ? 0.0 : totalSpeed / runs.length;
        _isLoadingStats = false;
      });
    } else {
      setState(() {
        _statsError = result['message']?.toString() ?? 'Failed to load stats';
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadTerritories() async {
    final result = await TerritoryService.getAllTerritories();

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final list = data['territories'] as List<dynamic>? ?? [];

      setState(() {
        _territories = list.cast<Map<String, dynamic>>();
      });
    }

    // Also fetch my territory area
    final myResult = await TerritoryService.getMyTerritory();
    if (!mounted) return;

    if (myResult['success'] == true) {
      final data = myResult['data'] as Map<String, dynamic>;
      setState(() {
        _myTerritoryArea = ((data['area_sq_m'] ?? 0) as num).toDouble();
      });
    }
  }

  /// Parse a GeoJSON geometry into a list of polygon point-lists.
  List<List<LatLng>> _parseGeoJsonPolygons(Map<String, dynamic>? geojson) {
    if (geojson == null) return [];

    final type = geojson['type'] as String? ?? '';
    final List<List<LatLng>> polygons = [];

    if (type == 'Polygon') {
      final coords = geojson['coordinates'] as List<dynamic>;
      if (coords.isNotEmpty) {
        final ring = coords[0] as List<dynamic>;
        polygons.add(
          ring
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList(),
        );
      }
    } else if (type == 'MultiPolygon') {
      final polys = geojson['coordinates'] as List<dynamic>;
      for (final poly in polys) {
        final ring = (poly as List<dynamic>)[0] as List<dynamic>;
        polygons.add(
          ring
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList(),
        );
      }
    }

    return polygons;
  }

  /// Generate a color for a given user_id (deterministic).
  Color _colorForUser(int userId, bool isMe) {
    if (isMe) return const Color(0xFF3B82F6);
    const palette = [
      Color(0xFFEF4444),
      Color(0xFF22C55E),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFFF97316),
    ];
    return palette[userId % palette.length];
  }

  @override
  void dispose() {
    followTimer?.cancel();
    super.dispose();
  }

  Widget topButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget stat(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatArea(double sqm) {
    if (sqm >= 1000000) {
      return '${(sqm / 1000000).toStringAsFixed(2)} km²';
    } else if (sqm >= 1000) {
      return '${(sqm / 1000).toStringAsFixed(1)}k m²';
    }
    return '${sqm.toStringAsFixed(0)} m²';
  }

  void _refreshAll() {
    _loadRuns();
    _loadTerritories();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3B82F6);

    // Build territory polygon layers
    final List<Polygon> territoryPolygons = [];

    // Get current user ID from territories to determine "isMe"
    // We'll use a simple heuristic: if user_name matches stored userName
    for (final t in _territories) {
      final geojson = t['geojson'] as Map<String, dynamic>?;
      final userId = (t['user_id'] as num?)?.toInt() ?? 0;
      final userName = t['user_name']?.toString() ?? '';
      final area = ((t['area_sq_m'] ?? 0) as num).toDouble();

      // Determine if this is the current user's territory
      // (we check if area matches our own territory area — simple approach)
      final isMe = area > 0 && (area - _myTerritoryArea).abs() < 1.0;

      final color = _colorForUser(userId, isMe);
      final polyPoints = _parseGeoJsonPolygons(geojson);

      for (final points in polyPoints) {
        if (points.length >= 3) {
          territoryPolygons.add(
            Polygon(
              points: points,
              color: color.withOpacity(0.25),
              borderColor: color.withOpacity(0.7),
              borderStrokeWidth: 2,
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLatLng,
              initialZoom: hasLiveLocation ? 16 : 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.fitness_game_app',
              ),
              // --- Territory polygons ---
              if (territoryPolygons.isNotEmpty)
                PolygonLayer(polygons: territoryPolygons),
              if (latestPathPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: latestPathPoints,
                      strokeWidth: 4,
                      color: accent,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLatLng,
                    width: 26,
                    height: 26,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      topButton(Icons.layers_rounded, () {}),
                      const Spacer(),
                      const Text(
                        'Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      topButton(Icons.refresh_rounded, _refreshAll),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.76),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _statsError != null
                          ? _statsError!
                          : RunDataStore.isRunActive
                              ? 'Live run tracking active'
                              : _totalRuns == 0
                                  ? 'No runs saved yet'
                                  : _myTerritoryArea > 0
                                      ? 'Your territory: ${_formatArea(_myTerritoryArea)}'
                                      : 'You have completed $_totalRuns runs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingStats)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(
                              color: accent,
                              strokeWidth: 2.2,
                            ),
                          )
                        else
                          Row(
                            children: [
                              stat('Runs', _totalRuns.toString()),
                              stat(
                                'Distance',
                                '${_totalDistance.toStringAsFixed(2)} km',
                              ),
                              stat(
                                'Territory',
                                _myTerritoryArea > 0
                                    ? _formatArea(_myTerritoryArea)
                                    : '—',
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag, color: accent, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _totalRuns == 0
                                      ? 'Start your first run to claim territory'
                                      : _myTerritoryArea > 0
                                          ? 'Territory: ${_formatArea(_myTerritoryArea)} • ${_territories.length} players'
                                          : 'Total distance covered: ${_totalDistance.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              topButton(Icons.my_location_rounded, () {
                                if (hasLiveLocation) {
                                  mapController.move(currentLatLng, 17);
                                }
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}