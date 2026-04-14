import 'package:flutter/material.dart';
import 'location_test_page.dart';
import 'run_history_page.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String? _error;

  double _totalDistanceKm = 0.0;
  int _totalRuns = 0;
  double _avgSpeed = 0.0;

  List<dynamic> _runs = [];
  Map<String, int> _runsPerDay = {};
  List<double> _weeklyDistances = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final statsResult = await StatsService.getProfileStats();
    final runsResult = await StatsService.getAllRuns();

    if (!mounted) return;

    if (statsResult['success'] == true && runsResult['success'] == true) {
      final stats = statsResult['data'] as Map<String, dynamic>;
      final runs = runsResult['data'] as List<dynamic>;

      final Map<String, int> runsPerDay = {};
      final List<double> weeklyDistances = List.filled(7, 0.0);

      final now = DateTime.now();

      for (final run in runs) {
        final createdAtString = run['created_at']?.toString();
        if (createdAtString == null) continue;

        DateTime? createdAt;
        try {
          createdAt = DateTime.parse(createdAtString).toLocal();
        } catch (_) {
          createdAt = null;
        }

        if (createdAt == null) continue;

        final dateKey =
            '${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

        runsPerDay[dateKey] = (runsPerDay[dateKey] ?? 0) + 1;

        final difference = now.difference(
          DateTime(createdAt.year, createdAt.month, createdAt.day),
        ).inDays;

        if (difference >= 0 && difference < 7) {
          final index = 6 - difference;
          weeklyDistances[index] += ((run['distance_km'] ?? 0) as num).toDouble();
        }
      }

      setState(() {
        _totalDistanceKm = (stats['total_distance_km'] ?? 0).toDouble();
        _totalRuns = (stats['total_runs'] ?? 0) as int;
        _avgSpeed = (stats['avg_speed'] ?? 0).toDouble();
        _runs = runs;
        _runsPerDay = runsPerDay;
        _weeklyDistances = weeklyDistances;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = statsResult['message']?.toString() ??
            runsResult['message']?.toString() ??
            'Failed to load profile data';
        _isLoading = false;
      });
    }
  }

  Widget buildTopIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget buildWeeklyStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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

  Widget buildMonthLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
      ),
    );
  }

  Widget buildCalendarDay(String text, String dateKey) {
  final hasRun = _runsPerDay.containsKey(dateKey);

  final today = DateTime.now();
  final todayKey =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final isToday = dateKey == todayKey;

  return Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: isToday
          ? const Color(0xFF3B82F6) // 🔵 today highlight
          : hasRun
              ? const Color(0xFF3B82F6).withOpacity(0.6)
              : Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(
        color: isToday
            ? const Color(0xFF3B82F6)
            : hasRun
                ? const Color(0xFF3B82F6)
                : Colors.white24,
        width: isToday ? 2 : 1.2,
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight:
            isToday ? FontWeight.w900 : FontWeight.w500, // ⭐ bold today
      ),
    ),
  );
}

  Widget buildWeekRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }

  Widget buildLocationAccessCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LocationTestPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Color(0xFF3B82F6),
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Location Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRunHistoryCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RunHistoryPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: Color(0xFF3B82F6),
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Run History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLogoutCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AuthService.logout();

        if (!context.mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.red.withOpacity(0.25),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProgressView(BuildContext context) {
    const accent = Color(0xFF3B82F6);

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(
                  color: accent,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_run,
                    color: accent,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Run',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your stats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(
                    color: accent,
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Row(
                children: [
                  buildWeeklyStat(
                    'Distance',
                    '${_totalDistanceKm.toStringAsFixed(2)} km',
                  ),
                  buildWeeklyStat(
                    'Avg speed',
                    _avgSpeed.toStringAsFixed(1),
                  ),
                  buildWeeklyStat(
                    'Runs',
                    _totalRuns.toString(),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Text(
              'Past 7 days',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white24),
                              bottom: BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ProgressGraphPainter(_weeklyDistances),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 24,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Text('6d', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('5d', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('4d', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('3d', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('2d', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('1d', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('Now', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'This month',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                    color: Colors.white.withOpacity(0.03),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.ios_share, color: Colors.white38, size: 12),
                      SizedBox(width: 5),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                buildWeeklyStat(
                  'Total runs',
                  _totalRuns.toString(),
                ),
                buildWeeklyStat(
                  'Distance',
                  '${_totalDistanceKm.toStringAsFixed(2)} km',
                ),
                buildWeeklyStat(
                  'Avg speed',
                  _avgSpeed.toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('M', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('T', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('W', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('T', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('F', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('S', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('S', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            buildWeekRow([
              buildCalendarDay('1', '2026-04-01'),
              buildCalendarDay('2', '2026-04-02'),
              buildCalendarDay('3', '2026-04-03'),
              buildCalendarDay('4', '2026-04-04'),
              buildCalendarDay('5', '2026-04-05'),
              buildCalendarDay('6', '2026-04-06'),
              buildCalendarDay('7', '2026-04-07'),
            ]),
            buildWeekRow([
              buildCalendarDay('8', '2026-04-08'),
              buildCalendarDay('9', '2026-04-09'),
              buildCalendarDay('10', '2026-04-10'),
              buildCalendarDay('11', '2026-04-11'),
              buildCalendarDay('12', '2026-04-12'),
              buildCalendarDay('13', '2026-04-13'),
              buildCalendarDay('14', '2026-04-14'),
            ]),
            buildWeekRow([
              buildCalendarDay('15', '2026-04-15'),
              buildCalendarDay('16', '2026-04-16'),
              buildCalendarDay('17', '2026-04-17'),
              buildCalendarDay('18', '2026-04-18'),
              buildCalendarDay('19', '2026-04-19'),
              buildCalendarDay('20', '2026-04-20'),
              buildCalendarDay('21', '2026-04-21'),
            ]),
            buildWeekRow([
              buildCalendarDay('22', '2026-04-22'),
              buildCalendarDay('23', '2026-04-23'),
              buildCalendarDay('24', '2026-04-24'),
              buildCalendarDay('25', '2026-04-25'),
              buildCalendarDay('26', '2026-04-26'),
              buildCalendarDay('27', '2026-04-27'),
              buildCalendarDay('28', '2026-04-28'),
            ]),
            buildWeekRow([
              buildCalendarDay('29', '2026-04-29'),
              buildCalendarDay('30', '2026-04-30'),
              buildCalendarDay('1', '2026-05-01'),
              buildCalendarDay('2', '2026-05-02'),
              buildCalendarDay('3', '2026-05-03'),
              buildCalendarDay('4', '2026-05-04'),
              buildCalendarDay('5', '2026-05-05'),
            ]),
            const SizedBox(height: 16),
            buildRunHistoryCard(context),
            buildLocationAccessCard(context),
            const SizedBox(height: 12),
            buildLogoutCard(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF1A1A1A);
    const bgBody = Color(0xFF050505);

    return Scaffold(
      backgroundColor: bgBody,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: bgTop,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  buildTopIconButton(Icons.person_outline),
                  const Spacer(),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadProfileData,
                    child: buildTopIconButton(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: bgBody,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: buildProgressView(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressGraphPainter extends CustomPainter {
  final List<double> weeklyDistances;

  ProgressGraphPainter(this.weeklyDistances);

  @override
  void paint(Canvas canvas, Size size) {
    const accent = Color(0xFF3B82F6);

    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = accent.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final maxValue = weeklyDistances.isEmpty
        ? 1.0
        : weeklyDistances.reduce((a, b) => a > b ? a : b) == 0
            ? 1.0
            : weeklyDistances.reduce((a, b) => a > b ? a : b);

    final List<Offset> points = [];

    for (int i = 0; i < weeklyDistances.length; i++) {
      final x = size.width * (i / (weeklyDistances.length - 1));
      final normalized = weeklyDistances[i] / maxValue;
      final y = size.height * (0.80 - (normalized * 0.45));
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 3.5, dotPaint);
    }

    canvas.drawCircle(points.last, 10, glowPaint);
    canvas.drawCircle(points.last, 5.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}