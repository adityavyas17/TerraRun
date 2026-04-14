import 'package:flutter/material.dart';
import '../services/run_service.dart';

class RunHistoryPage extends StatefulWidget {
  const RunHistoryPage({super.key});

  @override
  State<RunHistoryPage> createState() => _RunHistoryPageState();
}

class _RunHistoryPageState extends State<RunHistoryPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _runs = [];

  static const bgTop = Color(0xFF1A1A1A);
  static const bgBody = Color(0xFF050505);
  static const accent = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await RunService.getRuns();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _runs = result['runs'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message']?.toString() ?? 'Failed to load runs';
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    String two(int n) => n.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(secs)}';
    }
    return '${two(minutes)}:${two(secs)}';
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  Widget _topIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _runCard(dynamic run) {
    final distance = (run['distance_km'] ?? 0).toDouble();
    final duration = (run['duration_seconds'] ?? 0) as int;
    final avgSpeed = (run['avg_speed'] ?? 0).toDouble();
    final createdAt = run['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(createdAt),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _stat('Distance', '${distance.toStringAsFixed(2)} km'),
              ),
              Expanded(
                child: _stat('Time', _formatDuration(duration)),
              ),
              Expanded(
                child: _stat('Avg speed', avgSpeed.toStringAsFixed(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _topIconButton(Icons.arrow_back_rounded, () {
                    Navigator.pop(context);
                  }),
                  const Spacer(),
                  const Text(
                    'Run History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _topIconButton(Icons.refresh_rounded, _loadRuns),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: accent),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _runs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No runs saved yet',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _runs.length,
                                itemBuilder: (context, index) {
                                  return _runCard(_runs[index]);
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}