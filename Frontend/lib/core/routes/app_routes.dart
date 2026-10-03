import 'package:flutter/material.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const analytics = '/analytics';
  static const alerts = '/alerts';
  static const profile = '/profile';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    dashboard: (_) => const DashboardScreen(),
    analytics: (_) => const AnalyticsScreen(),
    alerts: (_) => const AlertsScreen(),
    profile: (_) => const ProfileScreen(),
    settings: (_) => const SettingsScreen(),
  };
}