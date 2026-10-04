import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ai_prediction.dart';
import '../../data/models/hotspot_node.dart';
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

  // AI Prediction & Hotspot Models
  AIPrediction? aiPrediction;
  List<HotspotNode> hotspotNodes = [];

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
    _loadAiIntelligence();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAiIntelligence() async {
    final pred = await ApiService().fetchLatestPrediction(currentPm25: pm25);
    final hotspots = await ApiService().fetchHotspots();
    if (mounted) {
      setState(() {
        aiPrediction = pred;
        hotspotNodes = hotspots;
      });
    }
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
    _loadAiIntelligence();
  }

  // ================= FETCH LIVE STREAM =================
  void fetchRealtimeData() {
    _subscription = ApiService().getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
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

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFFF4D4F);
      case 'HIGH':
        return const Color(0xFFFF7A45);
      case 'MODERATE':
        return const Color(0xFFFAAD14);
      case 'LOW':
      default:
        return const Color(0xFF00D26A);
    }
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
              'Theme 2: Rising AQI Mitigation',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 14,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(
                        context,
                        cardColor,
                        borderColor,
                        textColor,
                        secondaryTextColor,
                        aqiColor,
                        currentZone,
                        isDark,
                      )
                    : _buildMobileLayout(
                        context,
                        cardColor,
                        borderColor,
                        textColor,
                        secondaryTextColor,
                        aqiColor,
                        currentZone,
                        isDark,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= LAPTOP / DESKTOP WIDE LAYOUT =================
  Widget _buildDesktopLayout(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    Color aqiColor,
    Map<String, dynamic> currentZone,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildHotspotSelector(cardColor, borderColor, textColor, secondaryTextColor, currentZone),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (AQI + AI Forecast + Impact)
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildAqiCard(cardColor, borderColor, aqiColor, secondaryTextColor, isDark),
                  const SizedBox(height: 18),
                  _buildAiForecastCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
                  const SizedBox(height: 18),
                  _buildImpactBanner(textColor, secondaryTextColor, isDark),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Right Column (Sensors + Interventions + Hotspot Intelligence)
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  _buildSensorGrid(crossAxisCount: 3),
                  const SizedBox(height: 18),
                  _buildInterventionsCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
                  const SizedBox(height: 18),
                  _buildCitywideHotspotsCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= MOBILE VERTICAL LAYOUT =================
  Widget _buildMobileLayout(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    Color aqiColor,
    Map<String, dynamic> currentZone,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHotspotSelector(cardColor, borderColor, textColor, secondaryTextColor, currentZone),
        const SizedBox(height: 16),
        _buildAqiCard(cardColor, borderColor, aqiColor, secondaryTextColor, isDark),
        const SizedBox(height: 16),
        _buildSensorGrid(crossAxisCount: 2),
        const SizedBox(height: 16),
        _buildAiForecastCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
        const SizedBox(height: 16),
        _buildInterventionsCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
        const SizedBox(height: 16),
        _buildCitywideHotspotsCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
        const SizedBox(height: 16),
        _buildImpactBanner(textColor, secondaryTextColor, isDark),
        const SizedBox(height: 16),
      ],
    );
  }

  // ================= 1. HOTSPOT SELECTOR =================
  Widget _buildHotspotSelector(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    Map<String, dynamic> currentZone,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 20),
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
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                child: Text(urbanZones[i]['name'], overflow: TextOverflow.ellipsis),
              );
            }),
            onChanged: (val) {
              if (val != null) _applyZoneData(val);
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Source: ${currentZone['source']}',
                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. AQI CARD =================
  Widget _buildAqiCard(
    Color cardColor,
    Color borderColor,
    Color aqiColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D26A).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00D26A)),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: aqiColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: aqiColor.withOpacity(0.4)),
                ),
                child: Text(
                  _getAqiStatus(aqi),
                  style: TextStyle(color: aqiColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MONITORING',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. SENSOR GRID =================
  Widget _buildSensorGrid({required int crossAxisCount}) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: crossAxisCount == 3 ? 1.08 : 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        SensorCard(
          label: 'PM2.5 (VEHICULAR)',
          value: pm25.toStringAsFixed(1),
          unit: 'µg/m³',
          color: pm25 > 60 ? Colors.redAccent : Colors.green,
          icon: const Icon(Icons.directions_car_filled_rounded, color: Colors.redAccent, size: 26),
        ),
        SensorCard(
          label: 'PM10 (ROAD DUST)',
          value: pm10.toStringAsFixed(1),
          unit: 'µg/m³',
          color: pm10 > 100 ? Colors.orangeAccent : Colors.green,
          icon: const Icon(Icons.construction_rounded, color: Colors.orangeAccent, size: 26),
        ),
        SensorCard(
          label: 'CO2 (IDLING EXHAUST)',
          value: co2.toString(),
          unit: 'ppm',
          color: AppColors.primary,
          icon: const Icon(Icons.co2_rounded, color: AppColors.primary, size: 26),
        ),
        SensorCard(
          label: 'SMOKE & TOXIC GAS',
          value: smoke.toStringAsFixed(2),
          unit: 'mg/m³',
          color: Colors.deepOrange,
          icon: const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 26),
        ),
        SensorCard(
          label: 'TEMPERATURE',
          value: temperature.toStringAsFixed(1),
          unit: '°C',
          color: Colors.redAccent,
          icon: const Icon(Icons.thermostat_rounded, color: Colors.redAccent, size: 26),
        ),
        SensorCard(
          label: 'HUMIDITY',
          value: humidity.toStringAsFixed(1),
          unit: '%',
          color: Colors.blueAccent,
          icon: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 26),
        ),
      ],
    );
  }

  // ================= 4. AI 1-HOUR FORECAST CARD =================
  Widget _buildAiForecastCard(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final pred = aiPrediction ??
        AIPrediction(
          deviceId: 'ESP32_AIR_01',
          location: 'Junction Central Corridor',
          currentPm25: pm25,
          predictedPm25: (pm25 * 1.18).clamp(15.0, 350.0),
          predictionHorizon: '1 hour',
          trend: 'RISING',
          riskLevel: 'HIGH',
          recommendedAction: 'Extend green traffic cycle (+25s) & deploy zone misting cannons.',
          modelVersion: 'v1.0-uci-trained',
          algorithm: 'Ridge Regressor',
        );

    final riskColor = _getRiskColor(pred.riskLevel);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(isDark ? 0.15 : 0.05),
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
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.psychology_rounded, color: riskColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI 1-HOUR POLLUTION FORECAST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              _buildTrendBadge(pred.trend),
            ],
          ),
          const SizedBox(height: 14),

          // Now vs Next Hour PM2.5 Comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current PM2.5', style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    '${pred.currentPm25} µg/m³',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_rounded, color: secondaryTextColor),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Next 1-Hour Forecast', style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    '${pred.predictedPm25} µg/m³',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: riskColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Risk Badge
          Row(
            children: [
              Text('Health Risk Tier: ', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskColor.withOpacity(0.4)),
                ),
                child: Text(
                  '${pred.riskLevel} RISK',
                  style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actionable Intervention Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: riskColor.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt_rounded, color: riskColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIONABLE INTERVENTION RECOMMENDED:',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pred.recommendedAction,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(String trend) {
    Color badgeColor = trend == 'RISING'
        ? const Color(0xFFFF4D4F)
        : (trend == 'FALLING' ? const Color(0xFF00D26A) : const Color(0xFFFAAD14));
    IconData badgeIcon = trend == 'RISING'
        ? Icons.trending_up_rounded
        : (trend == 'FALLING' ? Icons.trending_down_rounded : Icons.trending_flat_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            trend,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ================= 5. SMART CITY INTERVENTIONS =================
  Widget _buildInterventionsCard(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
                    child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
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
          _buildInterventionButton(
            icon: Icons.traffic_rounded,
            title: 'Adaptive Signal: Extend Green Time (+25s)',
            subtitle: 'Flushes junction queue, drops vehicle idling by 22%',
            color: const Color(0xFF00D26A),
            onTap: () => _triggerIntervention('Adaptive Signal Extension (+25s)', 22),
          ),
          const SizedBox(height: 10),
          _buildInterventionButton(
            icon: Icons.shower_rounded,
            title: 'Trigger Anti-Smog Mist Cannons',
            subtitle: 'Suppresses PM10 & PM2.5 dust particles by 26%',
            color: const Color(0xFF1890FF),
            onTap: () => _triggerIntervention('Anti-Smog Mist Cannon Deployment', 26),
          ),
          const SizedBox(height: 10),
          _buildInterventionButton(
            icon: Icons.alt_route_rounded,
            title: 'Heavy Commercial Vehicle Reroute Advisory',
            subtitle: 'Diverts diesel trucks away from residential corridors',
            color: Colors.deepPurpleAccent,
            onTap: () => _triggerIntervention('Heavy Vehicle Reroute Advisory', 18),
          ),
        ],
      ),
    );
  }

  // ================= 6. CITYWIDE HOTSPOT INTELLIGENCE =================
  Widget _buildCitywideHotspotsCard(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final nodes = hotspotNodes.isNotEmpty
        ? hotspotNodes
        : [
            HotspotNode(
              deviceId: 'ESP32_NODE_04',
              location: 'Industrial Bypass Route',
              currentPm25: 142.9,
              predictedPm25: 165.4,
              riskLevel: 'CRITICAL',
              trend: 'RISING',
              recommendedAction: '🚨 Restrict heavy diesel transit & activate misting cannons.',
            ),
            HotspotNode(
              deviceId: 'ESP32_NODE_03',
              location: 'Junction B (Bus Terminal)',
              currentPm25: 118.2,
              predictedPm25: 126.0,
              riskLevel: 'HIGH',
              trend: 'RISING',
              recommendedAction: '⚠️ Extend green light intervals to flush idling buses.',
            ),
            HotspotNode(
              deviceId: 'ESP32_NODE_02',
              location: 'Junction A (Suburban Entry)',
              currentPm25: 54.3,
              predictedPm25: 52.0,
              riskLevel: 'MODERATE',
              trend: 'STABLE',
              recommendedAction: 'Normal traffic flow. Telemetry stable.',
            ),
            HotspotNode(
              deviceId: 'ESP32_NODE_01',
              location: 'School Corridor & Eco Park',
              currentPm25: 22.5,
              predictedPm25: 24.1,
              riskLevel: 'LOW',
              trend: 'STABLE',
              recommendedAction: '🌿 Vegetative buffer active. Air quality optimal.',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'CITYWIDE POLLUTION HOTSPOT DETECTION',
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
          ...nodes.map((node) {
            final riskColor = _getRiskColor(node.riskLevel);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getBackground(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          node.location,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${node.currentPm25} µg/m³ [${node.riskLevel}]',
                          style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node.recommendedAction,
                    style: TextStyle(color: secondaryTextColor, fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= 7. QUANTIFIED IMPACT BANNER =================
  Widget _buildImpactBanner(Color textColor, Color secondaryTextColor, bool isDark) {
    return Container(
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
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
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
    );
  }

  Widget _buildInterventionButton({
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
                    style: TextStyle(color: secondaryTextColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded, color: color, size: 26),
          ],
        ),
      ),
    );
  }
}
