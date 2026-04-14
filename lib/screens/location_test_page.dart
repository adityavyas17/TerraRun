import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationTestPage extends StatefulWidget {
  const LocationTestPage({super.key});

  @override
  State<LocationTestPage> createState() => _LocationTestPageState();
}

class _LocationTestPageState extends State<LocationTestPage> {
  String statusText = 'Location not fetched yet';
  String latitudeText = '--';
  String longitudeText = '--';

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        statusText = 'Location services are disabled. Please enable GPS.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          statusText = 'Location permission denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        statusText =
            'Location permission permanently denied. Change it from phone settings.';
      });
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition();

      setState(() {
        statusText = 'Location fetched successfully';
        latitudeText = position.latitude.toString();
        longitudeText = position.longitude.toString();
      });
    } catch (e) {
      setState(() {
        statusText = 'Error getting location: $e';
      });
    }
  }

  Widget buildInfoCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(12, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Icon(icon, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        centerTitle: true,
        title: const Text(
          'Location Access',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Location Test',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fetch your current GPS coordinates from the phone.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            buildInfoCard('Status', statusText, Icons.info_outline),
            buildInfoCard('Latitude', latitudeText, Icons.my_location),
            buildInfoCard('Longitude', longitudeText, Icons.explore),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Get Current Location',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}