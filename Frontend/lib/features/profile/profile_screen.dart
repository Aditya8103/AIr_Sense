import 'dart:async';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/profile_option.dart';
import '../../shared/widgets/setting_switch.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ================= SENSOR VALUES =================
  int aqi = 0;
  int co2 = 0;
  double smoke = 0;
  double temperature = 0;
  double humidity = 0;
  bool deviceOnline = false;
  bool darkTheme = true;
  bool notificationsEnabled = true;

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
          deviceOnline = true;
          aqi = data.aqi;
          co2 = data.co2.toInt();
          smoke = data.smoke;
          temperature = data.temperature;
          humidity = data.humidity;
        });
      }
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= USER INFO =================
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Icon(
                      deviceOnline ? Icons.wifi : Icons.wifi_off,
                      size: 42,
                      color: deviceOnline ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Air Sense Device',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceOnline ? 'ESP32 Connected' : 'Device Offline',
                    style: TextStyle(
                      color: deviceOnline ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================= THEME =================
            const Text(
              'APPEARANCE',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              value: darkTheme,
              onChanged: (value) {
                setState(() {
                  darkTheme = value;
                });

                AeroGuardApp.of(context)?.toggleTheme(value);
              },
              activeColor: AppColors.primary,
              title: const Text(
                'Dark Theme',
              ),
              subtitle: Text(
                darkTheme ? 'Dark Mode Enabled' : 'Light Mode Enabled',
              ),
            ),

            const SizedBox(height: 32),

            // ================= LIVE SENSOR STATUS =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE SENSOR STATUS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sensorRow(
                    'AQI',
                    '$aqi',
                  ),
                  _sensorRow(
                    'CO2',
                    '$co2 ppm',
                  ),
                  _sensorRow(
                    'Smoke',
                    smoke.toStringAsFixed(2),
                  ),
                  _sensorRow(
                    'Temperature',
                    '${temperature.toStringAsFixed(1)} °C',
                  ),
                  _sensorRow(
                    'Humidity',
                    '${humidity.toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================= NOTIFICATIONS =================
            const Text(
              'NOTIFICATIONS',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            const SettingSwitch(
              icon: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
              ),
              title: 'Critical Alerts',
              subtitle: 'Receive dangerous gas alerts',
              initialValue: true,
            ),

            SettingSwitch(
              icon: const Icon(
                Icons.notifications_active,
                color: AppColors.primary,
              ),
              title: 'Realtime Notifications',
              subtitle: 'Live ESP32 updates',
              initialValue: notificationsEnabled,
            ),

            const SizedBox(height: 32),

            // ================= DEVICE SETTINGS =================
            const Text(
              'DEVICE SETTINGS',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            ProfileOption(
              icon: const Icon(
                Icons.memory_rounded,
                color: AppColors.primary,
              ),
              title: 'Device Settings',
              subtitle: 'ESP32 Configuration',
              danger: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        'Device Settings',
                      ),
                      content: const Text(
                        'Configure ESP32 WiFi, sensor calibration, and update interval settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // ================= ABOUT APP =================
            ProfileOption(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
              ),
              title: 'About App',
              subtitle: 'Air Sense v1.0',
              danger: false,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Air Sense',
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      'Realtime Air Quality Monitoring System using ESP32 + Spring Boot + MySQL + Flutter.',
                );
              },
            ),

            // ================= LOGOUT =================
            ProfileOption(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
              ),
              title: 'Logout',
              subtitle: 'Exit application',
              danger: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        'Logout',
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= SENSOR ROW =================
  Widget _sensorRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
