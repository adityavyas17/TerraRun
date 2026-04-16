import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/run_data.dart';
import '../services/run_service.dart';

class RunPage extends StatefulWidget {
  const RunPage({super.key});

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  final MapController mapController = MapController();

  bool isRunning = false;
  bool isSavingRun = false;
  int secondsElapsed = 0;
  double distanceKm = 0.0;
  double avgSpeed = 0.0;
  String statusText = 'Ready to run';

  Timer? timer;
  StreamSubscription<Position>? positionStream;
  Position? lastPosition;

  final List<RunPoint> runPath = [];

  LatLng get currentLatLng => LatLng(
        RunDataStore.currentLatitude ?? 28.6139,
        RunDataStore.currentLongitude ?? 77.2090,
      );

  List<LatLng> get latestPathPoints {
    return runPath.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  bool _isLoopClosed(List<RunPoint> path) {
    if (path.length < 4) return false;

    final start = path.first;
    final end = path.last;

    const threshold = 0.0003;

    final latDiff = (start.latitude - end.latitude).abs();
    final lngDiff = (start.longitude - end.longitude).abs();

    return latDiff < threshold && lngDiff < threshold;
  }

  void _recalculateAvgSpeed() {
    if (secondsElapsed < 15 || distanceKm < 0.03) {
      avgSpeed = 0.0;
      return;
    }

    final hours = secondsElapsed / 3600;
    avgSpeed = hours > 0 ? distanceKm / hours : 0.0;
  }

  Future<void> startRun() async {
    if (isRunning) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        statusText = 'Enable location services';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          statusText = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        statusText = 'Allow location from settings';
      });
      return;
    }

    timer?.cancel();
    await positionStream?.cancel();

    if (!mounted) return;
    setState(() {
      isRunning = true;
      statusText = 'GPS tracking live';
      runPath.clear();
      RunDataStore.latestRunPath = [];
      RunDataStore.isRunActive = true;
      lastPosition = null;
      secondsElapsed = 0;
      distanceKm = 0.0;
      avgSpeed = 0.0;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        secondsElapsed++;
        _recalculateAvgSpeed();
      });
    });

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((Position position) {
      if (!mounted) return;

      final point = RunPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      double addedKm = 0.0;

      if (lastPosition != null) {
        final meters = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Ignore clearly bad GPS jumps and tiny noise
        if (meters >= 2 && meters <= 50) {
          addedKm = meters / 1000;
        }
      }

      lastPosition = position;

      setState(() {
        runPath.add(point);
        RunDataStore.latestRunPath = List.from(runPath);
        RunDataStore.currentLatitude = position.latitude;
        RunDataStore.currentLongitude = position.longitude;

        distanceKm += addedKm;
        _recalculateAvgSpeed();
      });

      mapController.move(
        LatLng(position.latitude, position.longitude),
        17,
      );
    });
  }

  Future<void> stopRun() async {
    if (isSavingRun) return;

    timer?.cancel();
    await positionStream?.cancel();

    final closedLoop = _isLoopClosed(runPath);

    if (closedLoop) {
      RunDataStore.capturedAreas.insert(
        0,
        CapturedArea(
          name:
              'My Loop ${RunDataStore.capturedAreas.where((a) => a.isMine).length + 1}',
          points: List.from(runPath),
          progress: 100,
          isMine: true,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      isRunning = false;
      RunDataStore.isRunActive = false;
      isSavingRun = true;
      statusText = 'Saving run...';
    });

    // Convert tracked GPS points to [[lat, lng], …] for territory capture
    final List<List<double>> routeCoords = runPath
        .map((p) => [p.latitude, p.longitude])
        .toList();

    final result = await RunService.saveRun(
      distanceKm: distanceKm,
      durationSeconds: secondsElapsed,
      avgSpeed: avgSpeed,
      routeCoordinates: routeCoords.length >= 2 ? routeCoords : null,
    );

    if (!mounted) return;

    final hasTerritoryData = result['success'] == true &&
        result['data'] is Map &&
        result['data']['territory_geojson'] != null;

    setState(() {
      isSavingRun = false;
      statusText = result['success'] == true
          ? (hasTerritoryData
              ? 'Territory claimed! Run saved'
              : closedLoop
                  ? 'Loop captured and run saved'
                  : 'Run saved')
          : 'Run stopped, but save failed';
    });

    final message = result['success'] == true
        ? (hasTerritoryData
            ? 'Run saved — territory captured!'
            : 'Run saved successfully')
        : (result['message']?.toString() ?? 'Failed to save run');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> resetRun() async {
    timer?.cancel();
    await positionStream?.cancel();

    if (!mounted) return;
    setState(() {
      isRunning = false;
      RunDataStore.isRunActive = false;
      secondsElapsed = 0;
      distanceKm = 0.0;
      avgSpeed = 0.0;
      statusText = 'Ready to run';
      lastPosition = null;
      runPath.clear();
      RunDataStore.latestRunPath = [];
    });
  }

  String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Widget buildTopBanner() {
    const blue = Color(0xFF3B82F6);
    const blueDark = Color(0xFF1D4ED8);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRunning
              ? blueDark.withOpacity(0.8)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isRunning
                  ? blueDark.withOpacity(0.45)
                  : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRunning ? Icons.gps_fixed : Icons.location_searching,
              color: isRunning ? blue : Colors.white70,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRunning ? 'GPS Acquired' : statusText,
              style: TextStyle(
                color: isRunning ? blue : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              mapController.move(currentLatLng, 17);
            },
            icon: const Icon(Icons.my_location, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.84),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metricBlock(
              formatTime(secondsElapsed),
              'Time',
            ),
          ),
          Expanded(
            child: _metricBlock(
              avgSpeed.toStringAsFixed(1),
              'Avg speed',
              centerBig: true,
            ),
          ),
          Expanded(
            child: _metricBlock(
              distanceKm.toStringAsFixed(2),
              'Distance',
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(
    String value,
    String label, {
    bool centerBig = false,
    bool alignEnd = false,
  }) {
    CrossAxisAlignment align = CrossAxisAlignment.start;
    TextAlign textAlign = TextAlign.left;

    if (centerBig) {
      align = CrossAxisAlignment.center;
      textAlign = TextAlign.center;
    } else if (alignEnd) {
      align = CrossAxisAlignment.end;
      textAlign = TextAlign.right;
    }

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          value,
          textAlign: textAlign,
          style: TextStyle(
            color: Colors.white,
            fontSize: centerBig ? 30 : 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: textAlign,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget buildBottomPanel() {
    const blue = Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
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
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSavingRun
                    ? null
                    : (isRunning ? stopRun : startRun),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: isSavingRun
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isRunning ? 'Stop Run' : 'Run'),
              ),
            ),
            const SizedBox(height: 8),
            if (!isRunning && !isSavingRun)
              TextButton(
                onPressed: resetRun,
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3B82F6);

    final hasLocation = RunDataStore.currentLatitude != null &&
        RunDataStore.currentLongitude != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLatLng,
              initialZoom: hasLocation ? 17 : 15,
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
                      color: blue,
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
                        color: blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            color: Colors.black.withOpacity(0.08),
          ),
          SafeArea(
            child: Column(
              children: [
                buildTopBanner(),
                const Spacer(),
                buildStatsCard(),
                const SizedBox(height: 12),
                buildBottomPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}