import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _leaders = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await LeaderboardService.getLeaderboard();

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() {
        _leaders = result["data"] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result["message"]?.toString() ?? "Failed to fetch leaderboard";
        _isLoading = false;
      });
    }
  }

  Widget buildTopIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
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
          size: 22,
        ),
      ),
    );
  }

  Widget buildPodiumCard({
    required String rank,
    required String name,
    required String score,
    required Color color,
    required double height,
    required bool highlighted,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: highlighted ? 22 : 19,
            backgroundColor: color.withOpacity(0.20),
            child: Text(
              rank,
              style: TextStyle(
                color: color,
                fontSize: highlighted ? 15 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: highlighted ? 13 : 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            score,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: highlighted ? color : color.withOpacity(0.80),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRankTile({
    required String rank,
    required String name,
    required String subtitle,
    required String score,
    required Color accent,
    bool isTop = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop
            ? accent.withOpacity(0.12)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop
              ? accent.withOpacity(0.45)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Text(
              rank,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withOpacity(0.22),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: TextStyle(
              color: isTop ? accent : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMiniStat({
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

  String _distanceText(dynamic leader) {
    final distance = ((leader['total_distance'] ?? 0) as num).toDouble();
    return '${distance.toStringAsFixed(2)} km';
  }

  String _territoryText(dynamic leader) {
    final area = ((leader['territory_area'] ?? 0) as num).toDouble();
    if (area <= 0) return '';
    if (area >= 1000000) {
      return '${(area / 1000000).toStringAsFixed(2)} km²';
    } else if (area >= 1000) {
      return '${(area / 1000).toStringAsFixed(1)}k m²';
    }
    return '${area.toStringAsFixed(0)} m²';
  }

  String _subtitleText(dynamic leader) {
    final runs = leader['total_runs'] ?? 0;
    final avg = ((leader['avg_speed'] ?? 0) as num).toDouble();
    final territory = _territoryText(leader);
    final base = '$runs runs • avg ${avg.toStringAsFixed(1)}';
    return territory.isNotEmpty ? '$base • $territory' : base;
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF1A1A1A);
    const bgBody = Color(0xFF050505);
    const accent = Color(0xFF3B82F6);
    const silver = Color(0xFFC0C0C0);
    const bronze = Color(0xFFCD7F32);

    final top1 = _leaders.isNotEmpty ? _leaders[0] : null;
    final top2 = _leaders.length > 1 ? _leaders[1] : null;
    final top3 = _leaders.length > 2 ? _leaders[2] : null;

    final topDistance = top1 != null
        ? ((top1['total_distance'] ?? 0) as num).toDouble()
        : 0.0;
    final secondDistance = top2 != null
        ? ((top2['total_distance'] ?? 0) as num).toDouble()
        : 0.0;
    final gap = (topDistance - secondDistance).abs();

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
                  buildTopIconButton(Icons.emoji_events_outlined),
                  const Spacer(),
                  const Text(
                    'Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  buildTopIconButton(Icons.refresh_rounded, onTap: _loadLeaderboard),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLeaderboard,
                color: accent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        )
                      : _error != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : _leaders.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 80),
                                  child: Center(
                                    child: Text(
                                      'No leaderboard data yet',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accent.withOpacity(0.95),
                                            const Color(0xFF60A5FA),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Live Rankings',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${top1['name']} is ranked #1',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _leaders.length > 1
                                                ? 'Top spot lead: ${gap.toStringAsFixed(2)} km'
                                                : 'Only one runner on the board right now.',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        buildMiniStat(
                                          label: 'Top Distance',
                                          value: '${topDistance.toStringAsFixed(2)} km',
                                        ),
                                        const SizedBox(width: 8),
                                        buildMiniStat(
                                          label: 'Players',
                                          value: _leaders.length.toString(),
                                        ),
                                        const SizedBox(width: 8),
                                        buildMiniStat(
                                          label: 'Top Territory',
                                          value: _territoryText(top1).isNotEmpty
                                              ? _territoryText(top1)
                                              : '${top1['total_runs'] ?? 0} runs',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    buildSectionTitle('Top players'),
                                    const SizedBox(height: 14),
                                    if (_leaders.length == 1)
                                      SizedBox(
                                        height: 155,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Spacer(),
                                            buildPodiumCard(
                                              rank: '1',
                                              name: top1['name'].toString(),
                                              score: _distanceText(top1),
                                              color: accent,
                                              height: 62,
                                              highlighted: true,
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      )
                                    else if (_leaders.length == 2)
                                      SizedBox(
                                        height: 155,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            buildPodiumCard(
                                              rank: '2',
                                              name: top2!['name'].toString(),
                                              score: _distanceText(top2),
                                              color: silver,
                                              height: 54,
                                              highlighted: false,
                                            ),
                                            buildPodiumCard(
                                              rank: '1',
                                              name: top1['name'].toString(),
                                              score: _distanceText(top1),
                                              color: accent,
                                              height: 62,
                                              highlighted: true,
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 155,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            buildPodiumCard(
                                              rank: '2',
                                              name: top2!['name'].toString(),
                                              score: _distanceText(top2),
                                              color: silver,
                                              height: 54,
                                              highlighted: false,
                                            ),
                                            buildPodiumCard(
                                              rank: '1',
                                              name: top1['name'].toString(),
                                              score: _distanceText(top1),
                                              color: accent,
                                              height: 62,
                                              highlighted: true,
                                            ),
                                            buildPodiumCard(
                                              rank: '3',
                                              name: top3!['name'].toString(),
                                              score: _distanceText(top3),
                                              color: bronze,
                                              height: 42,
                                              highlighted: false,
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 18),
                                    buildSectionTitle('Full rankings'),
                                    const SizedBox(height: 10),
                                    ...List.generate(_leaders.length, (index) {
                                      final leader = _leaders[index];
                                      return buildRankTile(
                                        rank: '${index + 1}',
                                        name: leader['name'].toString(),
                                        subtitle: _subtitleText(leader),
                                        score: _distanceText(leader),
                                        accent: index == 0
                                            ? accent
                                            : index == 1
                                                ? silver
                                                : index == 2
                                                    ? bronze
                                                    : const Color(0xFF22C55E),
                                        isTop: index == 0,
                                      );
                                    }),
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