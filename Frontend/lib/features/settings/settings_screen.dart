import 'package:flutter/material.dart';
import '../../app.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings & Themes',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
          // Section header
          Text(
            'CHOOSE COLOR THEME',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),

          // Theme Selector Cards (Light & Dark)
          Row(
            children: [
              // Dark Mode Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AeroGuardApp.of(context)?.toggleTheme(true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.primary : const Color(0xFF30363D),
                        width: isDark ? 2.5 : 1,
                      ),
                      boxShadow: [
                        if (isDark)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: const Icon(
                            Icons.dark_mode_rounded,
                            color: Color(0xFF00D26A),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Dark Theme',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sleek Cyber-Dark',
                          style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isDark)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Light Mode Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AeroGuardApp.of(context)?.toggleTheme(false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !isDark
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: !isDark ? 2.5 : 1,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Icon(
                            Icons.light_mode_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Light Theme',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Clean Daylight',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!isDark)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Additional preferences section
          Text(
            'GENERAL SETTINGS',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.speed_rounded,
                      color: AppColors.primary),
                  title: Text(
                    'Telemetry Polling Rate',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '3 seconds (ESP32 stream)',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: secondaryTextColor),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_rounded,
                      color: AppColors.primary),
                  title: Text(
                    'Cloud Backend Endpoint',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Render Cloud / Aiven MySQL',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  trailing: Icon(Icons.check_circle_rounded,
                      size: 20, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}