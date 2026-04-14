class RunPoint {
  final double latitude;
  final double longitude;

  RunPoint({
    required this.latitude,
    required this.longitude,
  });
}

class CapturedArea {
  final String name;
  final List<RunPoint> points;
  final int progress;
  final bool isMine;

  CapturedArea({
    required this.name,
    required this.points,
    required this.progress,
    required this.isMine,
  });
}

class RunDataStore {
  static List<RunPoint> latestRunPath = [];

  static double? currentLatitude;
  static double? currentLongitude;
  static bool isRunActive = false;

  static List<CapturedArea> capturedAreas = [
    CapturedArea(
      name: 'Rival North Zone',
      points: [],
      progress: 64,
      isMine: false,
    ),
    CapturedArea(
      name: 'Rival Market Zone',
      points: [],
      progress: 41,
      isMine: false,
    ),
  ];
}