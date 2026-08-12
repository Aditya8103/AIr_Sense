import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_database/firebase_database.dart';

import '../../core/theme/app_colors.dart';

import '../../shared/widgets/alert_item.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // ================= FIREBASE =================
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

  // ================= ALERT LIST =================
  List<Widget> alerts = [];

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    fetchRealtimeData();
  }

  // ================= FETCH DATA =================
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

          generateAlerts();
        });
      }
    });
  }

  // ================= GENERATE ALERTS =================
  void generateAlerts() {
    alerts = [];

    // HIGH AQI
    if (aqi > 150) {
      alerts.add(
        AlertItem(
          title: 'Poor Air Quality Detected',
          message: 'AQI level has crossed safe limits.',
          time: 'LIVE',
          sensorValue: '$aqi AQI',
          warning: true,
        ),
      );
    }

    // HIGH CO2
    if (co2 > 1000) {
      alerts.add(
        AlertItem(
          title: 'High CO2 Detected',
          message: 'Carbon dioxide concentration is high.',
          time: 'LIVE',
          sensorValue: '$co2 ppm',
          warning: true,
        ),
      );
    }

    // SMOKE ALERT
    if (smoke > 2.5) {
      alerts.add(
        AlertItem(
          title: 'Smoke Detected',
          message: 'Smoke concentration increased significantly.',
          time: 'LIVE',
          sensorValue: smoke.toStringAsFixed(2),
          warning: true,
        ),
      );
    }

    // HIGH TEMPERATURE
    if (temperature > 35) {
      alerts.add(
        AlertItem(
          title: 'Temperature Spike',
          message: 'Temperature exceeded safe range.',
          time: 'LIVE',
          sensorValue: '${temperature.toStringAsFixed(1)}°C',
          warning: true,
        ),
      );
    }

    // LOW HUMIDITY
    if (humidity < 25) {
      alerts.add(
        AlertItem(
          title: 'Low Humidity Warning',
          message: 'Humidity dropped below recommended level.',
          time: 'LIVE',
          sensorValue: '${humidity.toStringAsFixed(1)}%',
          warning: false,
        ),
      );
    }

    // NO ALERTS
    if (alerts.isEmpty) {
      alerts.add(
        const AlertItem(
          title: 'Environment Safe',
          message: 'All air quality values are normal.',
          time: 'LIVE',
          sensorValue: 'SAFE',
          warning: false,
        ),
      );
    }
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
          'LIVE ALERTS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: alerts,
      ),
    );
  }
}
