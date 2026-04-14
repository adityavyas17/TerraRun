import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/run_data.dart';
import '../services/stats_service.dart';

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

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3B82F6);

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
                      topButton(Icons.refresh_rounded, _loadRuns),
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
                                'Avg Speed',
                                _avgSpeed.toStringAsFixed(1),
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
                                      ? 'Start your first run to build your map history'
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