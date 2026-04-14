import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _error;

  double _totalDistanceKm = 0.0;
  int _totalRuns = 0;
  double _avgSpeed = 0.0;
  String _userName = 'Runner';

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userName = await AuthService.getUserName();
    final result = await StatsService.getProfileStats();

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;

      setState(() {
        _userName = (userName == null || userName.isEmpty) ? 'Runner' : userName;
        _totalDistanceKm = (data['total_distance_km'] ?? 0).toDouble();
        _totalRuns = (data['total_runs'] ?? 0) as int;
        _avgSpeed = (data['avg_speed'] ?? 0).toDouble();
        _isLoading = false;
      });
    } else {
      setState(() {
        _userName = (userName == null || userName.isEmpty) ? 'Runner' : userName;
        _error = result['message']?.toString() ?? 'Failed to load stats';
        _isLoading = false;
      });
    }
  }

  Widget buildSmallStat({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
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
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget buildActivityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF1A1A1A);
    const bgBody = Color(0xFF050505);
    const accent = Color(0xFF3B82F6);
    const accentLight = Color(0xFF60A5FA);
    const green = Color(0xFF22C55E);
    const red = Color(0xFFEF4444);

    final missionProgress = _totalRuns == 0
        ? 0.0
        : _totalRuns >= 5
            ? 1.0
            : _totalRuns / 5.0;

    final territoryText = _totalRuns == 0
        ? 'Start your first run today'
        : '${_totalRuns} runs completed';

    final territorySubtext = _totalRuns == 0
        ? 'Complete your first run to start building your zone.'
        : 'You covered ${_totalDistanceKm.toStringAsFixed(2)} km overall.';

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
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadHomeData,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHomeData,
                color: accent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              accent,
                              accentLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Territory',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    territoryText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    territorySubtext,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      if (_isLoading)
                        Row(
                          children: [
                            buildSmallStat(label: 'This Week', value: '--'),
                            const SizedBox(width: 8),
                            buildSmallStat(label: 'Runs', value: '--'),
                            const SizedBox(width: 8),
                            buildSmallStat(label: 'Avg Speed', value: '--'),
                          ],
                        )
                      else
                        Row(
                          children: [
                            buildSmallStat(
                              label: 'Distance',
                              value: '${_totalDistanceKm.toStringAsFixed(2)} km',
                            ),
                            const SizedBox(width: 8),
                            buildSmallStat(
                              label: 'Runs',
                              value: _totalRuns.toString(),
                            ),
                            const SizedBox(width: 8),
                            buildSmallStat(
                              label: 'Avg Speed',
                              value: _avgSpeed.toStringAsFixed(1),
                            ),
                          ],
                        ),
                      const SizedBox(height: 18),
                      buildSectionTitle('Today’s mission'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  color: accent,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Secure Main Loop',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _totalRuns == 0
                                  ? 'Complete your first run to activate your mission.'
                                  : 'Keep running to improve your total distance and control.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: missionProgress,
                                minHeight: 6,
                                backgroundColor: Colors.white12,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      buildSectionTitle('Recent activity'),
                      const SizedBox(height: 10),
                      buildActivityTile(
                        icon: Icons.route_rounded,
                        color: accent,
                        title: 'Total distance',
                        subtitle:
                            '${_totalDistanceKm.toStringAsFixed(2)} km covered so far',
                        trailing: 'Live',
                      ),
                      buildActivityTile(
                        icon: Icons.directions_run,
                        color: green,
                        title: 'Runs completed',
                        subtitle: 'You have finished $_totalRuns runs',
                        trailing: 'Now',
                      ),
                      buildActivityTile(
                        icon: Icons.speed_rounded,
                        color: red,
                        title: 'Average speed',
                        subtitle: 'Current average speed is ${_avgSpeed.toStringAsFixed(1)}',
                        trailing: 'Stats',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}