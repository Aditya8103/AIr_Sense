import 'dart:async';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/routes/app_routes.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.getCard(context);
    final borderColor = AppColors.getBorder(context);
    final textColor = AppColors.getText(context);
    final secondaryTextColor = AppColors.getSecondaryText(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
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
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: SingleChildScrollView(
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
                      color: cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      deviceOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 42,
                      color: deviceOnline ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AirSense Urban Node',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceOnline ? 'ESP32 Connected' : 'Device Offline (Standby)',
                    style: TextStyle(
                      color: deviceOnline ? Colors.green : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================= APPEARANCE / THEME =================
            Text(
              'APPEARANCE & THEME',
              style: TextStyle(
                color: secondaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: SwitchListTile(
                value: isDark,
                onChanged: (value) {
                  AeroGuardApp.of(context)?.toggleTheme(value);
                },
                activeColor: AppColors.primary,
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? AppColors.primary : Colors.amber,
                ),
                title: Text(
                  'Dark Theme',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  isDark ? 'Dark Mode Active' : 'Light Mode Active',
                  style: TextStyle(color: secondaryTextColor),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ================= LIVE SENSOR STATUS =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE SENSOR STATUS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _sensorRow(context, 'AQI', '$aqi'),
                  _sensorRow(context, 'CO2', '$co2 ppm'),
                  _sensorRow(context, 'Smoke', '${smoke.toStringAsFixed(2)} mg/m³'),
                  _sensorRow(context, 'Temperature',
                      '${temperature.toStringAsFixed(1)} °C'),
                  _sensorRow(
                      context, 'Humidity', '${humidity.toStringAsFixed(1)}%'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================= NOTIFICATIONS =================
            Text(
              'NOTIFICATIONS',
              style: TextStyle(
                color: secondaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            const SettingSwitch(
              icon: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
              ),
              title: 'Critical Alerts',
              subtitle: 'Receive dangerous gas and spike alerts',
              initialValue: true,
            ),
            const SizedBox(height: 8),

            SettingSwitch(
              icon: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
              ),
              title: 'Realtime Notifications',
              subtitle: 'Live sensor telemetry notifications',
              initialValue: notificationsEnabled,
            ),

            const SizedBox(height: 32),

            // ================= DEVICE SETTINGS =================
            Text(
              'PREFERENCES & DEVICE',
              style: TextStyle(
                color: secondaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            ProfileOption(
              icon: const Icon(
                Icons.memory_rounded,
                color: AppColors.primary,
              ),
              title: 'Device Settings',
              subtitle: 'ESP32 Wi-Fi & Sensor calibration',
              danger: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Device Settings'),
                      content: const Text(
                        'Node ID: ESP32_AIR_01\nProtocol: HTTP/REST\nFirmware: v2.1.0-urban',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            ProfileOption(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
              ),
              title: 'About App',
              subtitle: 'AirSense Smart Urban Platform v1.2',
              danger: false,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Air Sense',
                  applicationVersion: '1.2.0',
                  applicationLegalese:
                      'Urban Air Quality Monitoring & Pollution Mitigation System.',
                );
              },
            ),

            ProfileOption(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
              ),
              title: 'Logout',
              subtitle: 'Sign out to Login Screen',
              danger: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.login);
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
        ),
      ),
    );
  }

  Widget _sensorRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.getSecondaryText(context),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.getText(context),
            ),
          ),
        ],
      ),
    );
  }
}
