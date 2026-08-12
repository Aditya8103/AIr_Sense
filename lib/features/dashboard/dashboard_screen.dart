import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:firebase_core/firebase_core.dart';

import '../../core/theme/app_colors.dart';

import '../../shared/widgets/sensor_card.dart';

import '../analytics/analytics_screen.dart';

import '../alerts/alerts_screen.dart';

import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const DashboardHome(),
    AnalyticsScreen(),
    AlertsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  // ================= FIREBASE DATABASE =================
  final DatabaseReference database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://air-sense-cb4e2-default-rtdb.firebaseio.com/",
  ).ref("air_quality");

  // ================= SENSOR VALUES =================
  int aqi = 0;

  int co2 = 0;

  double smoke = 0;

  double temperature = 0;

  double humidity = 0;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    fetchRealtimeData();
  }

  // ================= FETCH LIVE DATA =================
  void fetchRealtimeData() {
    database.onValue.listen((event) {
      final data = event.snapshot.value as Map?;

      if (data != null) {
        setState(() {
          aqi = data['aqi'] ?? 0;

          co2 = data['co2'] ?? 0;

          smoke = (data['smoke'] ?? 0).toDouble();

          temperature = (data['temperature'] ?? 0).toDouble();

          humidity = (data['humidity'] ?? 0).toDouble();
        });
      }
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Live Dashboard',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ================= AQI CARD =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'AIR QUALITY INDEX',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    aqi.toString(),
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= SENSOR GRID =================
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  // CO2
                  SensorCard(
                    label: 'CO2 LEVEL',
                    value: co2.toString(),
                    unit: 'ppm',
                    color: AppColors.primary,
                    icon: const Icon(
                      Icons.co2,
                      color: AppColors.primary,
                    ),
                  ),

                  // SMOKE
                  SensorCard(
                    label: 'SMOKE',
                    value: smoke.toStringAsFixed(2),
                    unit: 'mg/m³',
                    color: Colors.orange,
                    icon: const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),

                  // TEMPERATURE
                  SensorCard(
                    label: 'TEMPERATURE',
                    value: temperature.toStringAsFixed(1),
                    unit: '°C',
                    color: Colors.red,
                    icon: const Icon(
                      Icons.thermostat,
                      color: Colors.red,
                    ),
                  ),

                  // HUMIDITY
                  SensorCard(
                    label: 'HUMIDITY',
                    value: humidity.toStringAsFixed(1),
                    unit: '%',
                    color: Colors.blue,
                    icon: const Icon(
                      Icons.water_drop,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
