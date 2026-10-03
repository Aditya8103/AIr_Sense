import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/services/api_service.dart';
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

  final List<Widget> pages = const [
    DashboardHome(),
    AnalyticsScreen(),
    AlertsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.getCard(context);
    final secondaryTextColor = AppColors.getSecondaryText(context);

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.getBorder(context),
              width: 0.8,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: cardColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: secondaryTextColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
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
  // ================= URBAN ZONE MODEL =================
  final List<Map<String, dynamic>> urbanZones = [
    {
      'name': '🚦 Silk Board Traffic Junction',
      'source': 'Vehicular Emissions & Idling Exhaust (CO + NOx + PM2.5)',
      'baseAqi': 235,
      'baseCo2': 680,
      'baseSmoke': 1.85,
      'basePm25': 118.0,
      'basePm10': 142.0,
      'temp': 28.5,
      'hum': 48.0,
      'recommendedAction': 'Extend Traffic Signal Green-Time (+25s)',
    },
    {
      'name': '🏗️ Metro Line Construction Corridor',
      'source': 'Unpaved Excavation & Heavy Dust (PM10 Spike)',
      'baseAqi': 192,
      'baseCo2': 490,
      'baseSmoke': 0.95,
      'basePm25': 74.0,
      'basePm10': 225.0,
      'temp': 29.8,
      'hum': 42.0,
      'recommendedAction': 'Trigger Anti-Smog Mist Cannons & Water Sprinklers',
    },
    {
      'name': '🏭 Peenya Industrial Complex',
      'source': 'Industrial Boiler & Chemical Exhaust (Smoke + VOC)',
      'baseAqi': 268,
      'baseCo2': 780,
      'baseSmoke': 2.90,
      'basePm25': 135.0,
      'basePm10': 180.0,
      'temp': 31.0,
      'hum': 40.0,
      'recommendedAction': 'Issue Industrial Emission Reduction Audit Alert',
    },
    {
      'name': '🌳 Central Eco-Park & Residential Belt',
      'source': 'Clean Air Ambient Baseline (Vegetative Buffer)',
      'baseAqi': 42,
      'baseCo2': 395,
      'baseSmoke': 0.20,
      'basePm25': 14.0,
      'basePm10': 28.0,
      'temp': 24.5,
      'hum': 64.0,
      'recommendedAction': 'Air Quality Optimal - Maintain Current Status',
    },
  ];

  int selectedZoneIndex = 0;

  // ================= SENSOR VALUES =================
  int aqi = 235;
  int co2 = 680;
  double smoke = 1.85;
  double pm25 = 118.0;
  double pm10 = 142.0;
  double temperature = 28.5;
  double humidity = 48.0;

  // Intervention State
  bool isInterventionActive = false;
  String activeInterventionName = '';
  int reductionPercent = 0;

  StreamSubscription? _subscription;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _applyZoneData(selectedZoneIndex);
    fetchRealtimeData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _applyZoneData(int index) {
    final zone = urbanZones[index];
    setState(() {
      selectedZoneIndex = index;
      aqi = isInterventionActive
          ? (zone['baseAqi'] * (1 - reductionPercent / 100)).round()
          : zone['baseAqi'];
      co2 = zone['baseCo2'];
      smoke = zone['baseSmoke'];
      pm25 = isInterventionActive
          ? (zone['basePm25'] * (1 - reductionPercent / 100))
          : zone['basePm25'];
      pm10 = isInterventionActive
          ? (zone['basePm10'] * (1 - reductionPercent / 100))
          : zone['basePm10'];
      temperature = zone['temp'];
      humidity = zone['hum'];
    });
  }

  // ================= FETCH LIVE DATA VIA API SERVICE =================
  void fetchRealtimeData() {
    _subscription = ApiService().getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
          // If in first zone and live hardware is streaming, use live hardware stream
          if (selectedZoneIndex == 0 && data.aqi > 0) {
            aqi = isInterventionActive
                ? (data.aqi * (1 - reductionPercent / 100)).round()
                : data.aqi;
            co2 = data.co2.toInt();
            smoke = data.smoke;
            pm25 = isInterventionActive
                ? (data.pm25 * (1 - reductionPercent / 100))
                : data.pm25;
            pm10 = isInterventionActive
                ? (data.pm10 * (1 - reductionPercent / 100))
                : data.pm10;
            temperature = data.temperature;
            humidity = data.humidity;
          }
        });
      }
    });
  }

  Color _getAqiColor(int value) {
    if (value <= 50) return const Color(0xFF00D26A);
    if (value <= 100) return const Color(0xFF52C41A);
    if (value <= 200) return const Color(0xFFFAAD14);
    if (value <= 300) return const Color(0xFFFF7A45);
    return const Color(0xFFFF4D4F);
  }

  String _getAqiStatus(int value) {
    if (value <= 50) return 'GOOD';
    if (value <= 100) return 'MODERATE';
    if (value <= 200) return 'POOR';
    if (value <= 300) return 'VERY POOR';
    return 'HAZARDOUS';
  }

  void _triggerIntervention(String title, int simulatedDrop) {
    setState(() {
      isInterventionActive = true;
      activeInterventionName = title;
      reductionPercent = simulatedDrop;
      _applyZoneData(selectedZoneIndex);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00D26A),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Intervention Deployed: $title. Localized emissions dropped by ~$simulatedDrop%!',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetIntervention() {
    setState(() {
      isInterventionActive = false;
      activeInterventionName = '';
      reductionPercent = 0;
      _applyZoneData(selectedZoneIndex);
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
    final aqiColor = _getAqiColor(aqi);
    final currentZone = urbanZones[selectedZoneIndex];

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AirSense Smart Urban Platform',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Theme 2: Urban AQI Mitigation',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. URBAN ZONE SELECTOR =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_city_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SPECIFIC URBAN POLLUTION HOTSPOT',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedZoneIndex,
                    dropdownColor: cardColor,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: AppColors.getBackground(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items: List.generate(urbanZones.length, (i) {
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text(
                          urbanZones[i]['name'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        _applyZoneData(val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Source: ${currentZone['source']}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= 2. OVERALL AQI LIVE GAUGE =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AIR QUALITY INDEX',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isInterventionActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D26A).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00D26A),
                            ),
                          ),
                          child: Text(
                            '-$reductionPercent% CURBED',
                            style: const TextStyle(
                              color: Color(0xFF00D26A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    aqi.toString(),
                    style: TextStyle(
                      fontSize: 66,
                      fontWeight: FontWeight.bold,
                      color: aqiColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: aqiColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: aqiColor.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          _getAqiStatus(aqi),
                          style: TextStyle(
                            color: aqiColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MONITORING',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= 3. MULTI-POLLUTANT SENSOR GRID (6 GAUGES) =================
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // PM2.5 (Vehicular fine soot)
                SensorCard(
                  label: 'PM2.5 (VEHICULAR)',
                  value: pm25.toStringAsFixed(1),
                  unit: 'µg/m³',
                  color: pm25 > 60 ? Colors.redAccent : Colors.green,
                  icon: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: Colors.redAccent,
                    size: 26,
                  ),
                ),

                // PM10 (Construction dust)
                SensorCard(
                  label: 'PM10 (ROAD DUST)',
                  value: pm10.toStringAsFixed(1),
                  unit: 'µg/m³',
                  color: pm10 > 100 ? Colors.orangeAccent : Colors.green,
                  icon: const Icon(
                    Icons.construction_rounded,
                    color: Colors.orangeAccent,
                    size: 26,
                  ),
                ),

                // CO2 Level
                SensorCard(
                  label: 'CO2 (IDLING EXHAUST)',
                  value: co2.toString(),
                  unit: 'ppm',
                  color: AppColors.primary,
                  icon: const Icon(
                    Icons.co2_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),

                // Smoke / VOC
                SensorCard(
                  label: 'SMOKE & TOXIC GAS',
                  value: smoke.toStringAsFixed(2),
                  unit: 'mg/m³',
                  color: Colors.deepOrange,
                  icon: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.deepOrange,
                    size: 26,
                  ),
                ),

                // Temperature
                SensorCard(
                  label: 'TEMPERATURE',
                  value: temperature.toStringAsFixed(1),
                  unit: '°C',
                  color: Colors.redAccent,
                  icon: const Icon(
                    Icons.thermostat_rounded,
                    color: Colors.redAccent,
                    size: 26,
                  ),
                ),

                // Humidity
                SensorCard(
                  label: 'HUMIDITY',
                  value: humidity.toStringAsFixed(1),
                  unit: '%',
                  color: Colors.blueAccent,
                  icon: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.blueAccent,
                    size: 26,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ================= 4. AI PREDICTIVE FORECAST CARD (PREDICT PILLAR) =================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1890FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Color(0xFF1890FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AI PREDICTIVE FORECAST (NEXT 6 HOURS)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI Traffic Congestion Warning: Evening peak rush expected at 18:30 (Forecasted AQI: ${(aqi * 1.25).round().clamp(50, 420)})',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, (aqi * 0.95)),
                              FlSpot(1, (aqi * 1.05)),
                              FlSpot(2, (aqi * 1.18)),
                              FlSpot(3, (aqi * 1.28)),
                              FlSpot(4, (aqi * 1.20)),
                              FlSpot(5, (aqi * 1.08)),
                            ],
                            isCurved: true,
                            color: const Color(0xFF1890FF),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF1890FF).withOpacity(0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ================= 5. SMART CITY INTERVENTIONS (REDUCE PILLAR) =================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SMART CITY INTERVENTIONS (REDUCE)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      if (isInterventionActive)
                        TextButton(
                          onPressed: _resetIntervention,
                          child: const Text('Reset', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action 1: Adaptive Traffic Signals
                  _buildInterventionButton(
                    context: context,
                    icon: Icons.traffic_rounded,
                    title: 'Adaptive Signal: Extend Green Time (+25s)',
                    subtitle: 'Flushes junction queue, drops vehicle idling by 22%',
                    color: const Color(0xFF00D26A),
                    onTap: () => _triggerIntervention(
                        'Adaptive Signal Extension (+25s)', 22),
                  ),
                  const SizedBox(height: 10),

                  // Action 2: Anti-Smog Mist Cannons
                  _buildInterventionButton(
                    context: context,
                    icon: Icons.shower_rounded,
                    title: 'Trigger Anti-Smog Mist Cannons',
                    subtitle: 'Suppresses PM10 & PM2.5 dust particles by 26%',
                    color: const Color(0xFF1890FF),
                    onTap: () => _triggerIntervention(
                        'Anti-Smog Mist Cannon Deployment', 26),
                  ),
                  const SizedBox(height: 10),

                  // Action 3: Heavy Truck Reroute
                  _buildInterventionButton(
                    context: context,
                    icon: Icons.alt_route_rounded,
                    title: 'Heavy Commercial Vehicle Reroute Advisory',
                    subtitle: 'Diverts diesel trucks away from residential corridors',
                    color: Colors.deepPurpleAccent,
                    onTap: () => _triggerIntervention(
                        'Heavy Vehicle Reroute Advisory', 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ================= 6. QUANTIFIED IMPACT COUNTER =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF132F20), const Color(0xFF161B22)]
                      : [const Color(0xFFE6F8ED), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Environmental ROI',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '-22.4% Idling Emissions | 140K+ Citizens Protected',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final borderColor = AppColors.getBorder(context);
    final textColor = AppColors.getText(context);
    final secondaryTextColor = AppColors.getSecondaryText(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill_rounded,
              color: color,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
