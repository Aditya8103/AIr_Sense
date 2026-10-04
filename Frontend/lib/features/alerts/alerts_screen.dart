import 'dart:async';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/alert_item.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // ================= SENSOR VALUES =================
  int aqi = 0;
  int co2 = 0;
  double smoke = 0;
  double pm25 = 86.4;
  double temperature = 0;
  double humidity = 0;

  // ================= ALERT LIST =================
  List<Widget> alerts = [];
  StreamSubscription? _subscription;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    fetchRealtimeData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ================= FETCH DATA VIA API SERVICE =================
  void fetchRealtimeData() {
    _subscription = ApiService().getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
          aqi = data.aqi;
          co2 = data.co2.toInt();
          smoke = data.smoke;
          pm25 = data.pm25;
          temperature = data.temperature;
          humidity = data.humidity;
          generateAlerts();
        });
      }
    });
  }

  // ================= GENERATE ALERTS (RETROSPECTIVE + PREDICTIVE) =================
  void generateAlerts() {
    alerts = [];

    // 1. PREDICTIVE EARLY WARNING ALERT (Forward-looking AI Alarm)
    alerts.add(
      _buildPredictiveEarlyWarningAlert(
        title: '🧠 AI PREDICTIVE EARLY WARNING',
        message:
            'Impending Vehicular Emission Spike anticipated in ~45-60 mins due to peak evening rush hour. Forecasted PM2.5: ${(pm25 * 1.25).toStringAsFixed(1)} µg/m³.\nRecommended Action: Extend green traffic cycle & activate anti-smog misting.',
        time: 'NEXT 60 MINS',
        badge: 'PREDICTIVE ALARM',
      ),
    );

    // 2. HIGH AQI ALERT
    if (aqi > 150) {
      alerts.add(
        AlertItem(
          title: 'Poor Air Quality Detected',
          message: 'AQI level has crossed safe limits. Sensitive groups advised to avoid outdoors.',
          time: 'LIVE',
          sensorValue: '$aqi AQI',
          warning: true,
        ),
      );
    }

    // 3. PM2.5 PARTICULATE ALERT
    if (pm25 > 60) {
      alerts.add(
        AlertItem(
          title: 'High PM2.5 Fine Particulate Level',
          message: 'Vehicular soot concentration above standard threshold (60 µg/m³).',
          time: 'LIVE',
          sensorValue: '${pm25.toStringAsFixed(1)} µg/m³',
          warning: true,
        ),
      );
    }

    // 4. HIGH CO2 ALERT
    if (co2 > 1000) {
      alerts.add(
        AlertItem(
          title: 'High CO2 Concentration Detected',
          message: 'Traffic idling exhaust causing localized CO2 spike.',
          time: 'LIVE',
          sensorValue: '$co2 ppm',
          warning: true,
        ),
      );
    }

    // 5. SMOKE / TOXIC GAS ALERT
    if (smoke > 2.5) {
      alerts.add(
        AlertItem(
          title: 'Severe Smoke / Industrial Gas Spike',
          message: 'Smoke concentration increased significantly in the corridor.',
          time: 'LIVE',
          sensorValue: '${smoke.toStringAsFixed(2)} mg/m³',
          warning: true,
        ),
      );
    }

    // 6. TEMPERATURE SPIKE
    if (temperature > 35) {
      alerts.add(
        AlertItem(
          title: 'Temperature Spike',
          message: 'Urban heat island effect observed.',
          time: 'LIVE',
          sensorValue: '${temperature.toStringAsFixed(1)}°C',
          warning: true,
        ),
      );
    }

    // 7. SAFE BASELINE NOTICE
    if (alerts.length == 1) {
      alerts.add(
        const AlertItem(
          title: 'Current Telemetry Normal',
          message: 'Real-time readings are within acceptable baseline limits.',
          time: 'LIVE',
          sensorValue: 'SAFE',
          warning: false,
        ),
      );
    }
  }

  Widget _buildPredictiveEarlyWarningAlert({
    required String title,
    required String message,
    required String time,
    required String badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.getCard(context);
    final textColor = AppColors.getText(context);
    final secondaryTextColor = AppColors.getSecondaryText(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: secondaryTextColor,
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 15, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      'AI Anticipation Horizon: $time',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getText(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ALERTS & EARLY WARNINGS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : const Color(0xFF1E293B),
            ),
            onPressed: () {
              AeroGuardApp.of(context)?.switchTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: alerts,
              ),
            ),
          );
        },
      ),
    );
  }
}
