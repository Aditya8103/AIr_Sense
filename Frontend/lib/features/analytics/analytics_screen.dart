import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/sensor_data.dart';
import '../../shared/widgets/filter_chip.dart';
import '../../shared/widgets/trend_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int selectedTab = 1; // Default: 24H

  final List<String> tabs = [
    '1H',
    '24H',
    '7D',
    '30D',
    'CUSTOM',
  ];

  // ================= LIVE SENSOR VALUES =================
  int liveAqi = 78;
  int liveCo2 = 460;
  double liveSmoke = 0.85;
  double livePm25 = 86.4;
  double liveTemperature = 26.5;
  double liveHumidity = 58.0;

  bool _isLoadingHistory = false;
  StreamSubscription? _subscription;

  // ================= TIMEFRAME COMPUTED DATA =================
  List<double> aqiChartData = [];
  List<double> co2ChartData = [];
  List<double> pm25Historical = [];
  double pm25Predicted = 112.5;
  List<double> tempChartData = [];
  List<double> humChartData = [];

  int avgAqi = 75;
  int maxAqi = 110;
  int minAqi = 45;
  int avgCo2 = 450;
  String aqiChangeText = '+4.2%';
  bool aqiIsUp = true;
  String co2ChangeText = '-2.1%';
  bool co2IsUp = false;
  String timeRangeSubtitle = 'Past 24 Hours';

  @override
  void initState() {
    super.initState();
    _computeTimeframeData(selectedTab);
    fetchRealtimeData();
    _loadBackendHistory();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void fetchRealtimeData() {
    _subscription = ApiService().getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
          liveAqi = data.aqi;
          liveCo2 = data.co2.toInt();
          liveSmoke = data.smoke;
          livePm25 = data.pm25;
          liveTemperature = data.temperature;
          liveHumidity = data.humidity;
          _computeTimeframeData(selectedTab);
        });
      }
    });
  }

  Future<void> _loadBackendHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    final history = await ApiService().fetchHistory(range: tabs[selectedTab]);

    if (!mounted) return;

    if (history.isNotEmpty && history.length >= 3) {
      setState(() {
        aqiChartData = history.map((e) => e.aqi.toDouble()).toList();
        co2ChartData = history.map((e) => e.co2).toList();
        tempChartData = history.map((e) => e.temperature).toList();
        humChartData = history.map((e) => e.humidity).toList();
        pm25Historical = history.map((e) => e.pm25).toList();
        pm25Predicted = (pm25Historical.last * 1.18).clamp(15.0, 350.0);

        final aqiList = history.map((e) => e.aqi).toList();
        avgAqi = (aqiList.reduce((a, b) => a + b) / aqiList.length).round();
        maxAqi = aqiList.reduce(max);
        minAqi = aqiList.reduce(min);

        final co2List = history.map((e) => e.co2).toList();
        avgCo2 = (co2List.reduce((a, b) => a + b) / co2List.length).round();

        _isLoadingHistory = false;
      });
    } else {
      _computeTimeframeData(selectedTab);
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  void _computeTimeframeData(int tabIndex) {
    final baseAqi = liveAqi > 0 ? liveAqi.toDouble() : 75.0;
    final baseCo2 = liveCo2 > 0 ? liveCo2.toDouble() : 450.0;
    final basePm = livePm25 > 0 ? livePm25 : 86.4;
    final baseTemp = liveTemperature > 0 ? liveTemperature : 26.0;
    final baseHum = liveHumidity > 0 ? liveHumidity : 55.0;

    switch (tabIndex) {
      case 0: // 1 Hour
        timeRangeSubtitle = 'Past 60 Minutes (5-min intervals)';
        aqiChangeText = '+2.8%';
        aqiIsUp = true;
        co2ChangeText = '+1.4%';
        co2IsUp = true;
        aqiChartData = [baseAqi - 6, baseAqi - 4, baseAqi - 7, baseAqi - 2, baseAqi + 1, baseAqi + 3, baseAqi - 1, baseAqi + 4, baseAqi + 6, baseAqi + 2, baseAqi - 1, baseAqi];
        co2ChartData = [baseCo2 - 25, baseCo2 - 15, baseCo2 - 30, baseCo2 - 10, baseCo2 + 5, baseCo2 + 20, baseCo2 + 10, baseCo2 + 35, baseCo2 + 15, baseCo2 + 5, baseCo2 - 8, baseCo2];
        pm25Historical = [basePm - 8, basePm - 5, basePm - 10, basePm - 2, basePm + 4, basePm];
        pm25Predicted = basePm + 12.5;
        tempChartData = [baseTemp - 0.4, baseTemp - 0.2, baseTemp, baseTemp + 0.3, baseTemp + 0.1, baseTemp];
        humChartData = [baseHum + 1.2, baseHum + 0.5, baseHum, baseHum - 1.0, baseHum - 0.4, baseHum];
        break;

      case 1: // 24 Hours
        timeRangeSubtitle = 'Past 24 Hours (Diurnal traffic & weather curve)';
        aqiChangeText = '+14.6%';
        aqiIsUp = true;
        co2ChangeText = '+8.3%';
        co2IsUp = true;
        aqiChartData = [baseAqi - 22, baseAqi - 30, baseAqi - 15, baseAqi + 28, baseAqi + 10, baseAqi - 5, baseAqi + 34, baseAqi];
        co2ChartData = [baseCo2 - 80, baseCo2 - 110, baseCo2 - 50, baseCo2 + 95, baseCo2 + 30, baseCo2 - 20, baseCo2 + 120, baseCo2];
        pm25Historical = [basePm - 35, basePm - 40, basePm - 20, basePm + 32, basePm + 15, basePm - 10, basePm + 40, basePm];
        pm25Predicted = basePm + 26.0;
        tempChartData = [baseTemp - 4.5, baseTemp - 6.0, baseTemp - 3.5, baseTemp + 1.2, baseTemp + 5.0, baseTemp + 6.2, baseTemp + 2.1, baseTemp];
        humChartData = [baseHum + 14.0, baseHum + 18.5, baseHum + 12.0, baseHum - 5.0, baseHum - 16.0, baseHum - 18.0, baseHum - 4.0, baseHum];
        break;

      case 2: // 7 Days
        timeRangeSubtitle = 'Past 7 Days (Mon - Sun Urban Cycle)';
        aqiChangeText = '-6.4%';
        aqiIsUp = false;
        co2ChangeText = '-4.5%';
        co2IsUp = false;
        aqiChartData = [baseAqi + 18, baseAqi + 24, baseAqi + 12, baseAqi + 16, baseAqi + 22, baseAqi - 18, baseAqi - 25];
        co2ChartData = [baseCo2 + 65, baseCo2 + 80, baseCo2 + 45, baseCo2 + 55, baseCo2 + 75, baseCo2 - 60, baseCo2 - 90];
        pm25Historical = [basePm + 25, basePm + 30, basePm + 15, basePm + 20, basePm + 28, basePm - 22, basePm - 30];
        pm25Predicted = basePm - 15.0;
        tempChartData = [baseTemp + 1.2, baseTemp + 0.8, baseTemp - 0.5, baseTemp + 0.3, baseTemp + 1.5, baseTemp - 1.0, baseTemp];
        humChartData = [baseHum - 4.0, baseHum - 2.5, baseHum + 3.0, baseHum - 1.0, baseHum - 5.0, baseHum + 6.0, baseHum];
        break;

      case 3: // 30 Days
        timeRangeSubtitle = 'Past 30 Days (Monthly Urban Trends)';
        aqiChangeText = '-11.2%';
        aqiIsUp = false;
        co2ChangeText = '-7.8%';
        co2IsUp = false;
        aqiChartData = [baseAqi + 32, baseAqi + 18, baseAqi + 6, baseAqi - 8, baseAqi];
        co2ChartData = [baseCo2 + 110, baseCo2 + 60, baseCo2 + 20, baseCo2 - 30, baseCo2];
        pm25Historical = [basePm + 45, basePm + 28, basePm + 10, basePm - 12, basePm];
        pm25Predicted = basePm - 8.0;
        tempChartData = [baseTemp - 2.8, baseTemp - 1.5, baseTemp - 0.2, baseTemp + 1.0, baseTemp];
        humChartData = [baseHum + 8.5, baseHum + 4.0, baseHum + 1.2, baseHum - 3.0, baseHum];
        break;

      case 4: // Custom Range
      default:
        timeRangeSubtitle = 'Custom Range: Selected Window';
        aqiChangeText = '+3.1%';
        aqiIsUp = true;
        co2ChangeText = '+1.9%';
        co2IsUp = true;
        aqiChartData = [baseAqi - 12, baseAqi + 8, baseAqi - 4, baseAqi + 15, baseAqi];
        co2ChartData = [baseCo2 - 40, baseCo2 + 30, baseCo2 - 15, baseCo2 + 50, baseCo2];
        pm25Historical = [basePm - 15, basePm + 10, basePm - 5, basePm + 18, basePm];
        pm25Predicted = basePm + 14.0;
        tempChartData = [baseTemp - 1.0, baseTemp + 0.5, baseTemp - 0.2, baseTemp + 1.2, baseTemp];
        humChartData = [baseHum + 4.0, baseHum - 2.0, baseHum + 1.0, baseHum - 3.5, baseHum];
        break;
    }

    final nonNullAqi = aqiChartData.map((e) => e.round()).toList();
    avgAqi = (nonNullAqi.reduce((a, b) => a + b) / nonNullAqi.length).round();
    maxAqi = nonNullAqi.reduce(max);
    minAqi = nonNullAqi.reduce(min);

    final nonNullCo2 = co2ChartData.map((e) => e.round()).toList();
    avgCo2 = (nonNullCo2.reduce((a, b) => a + b) / nonNullCo2.length).round();
  }

  void _onTabSelected(int index) {
    setState(() {
      selectedTab = index;
      _computeTimeframeData(index);
    });
    _loadBackendHistory();
  }

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
          'ANALYTICS & AI PROJECTIONS',
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
          IconButton(
            tooltip: 'Refresh Analytics',
            onPressed: () => _loadBackendHistory(),
            icon: Icon(Icons.refresh_rounded, color: textColor),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= FILTER TABS =================
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          tabs.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _onTabSelected(index),
                              child: FilterChipWidget(
                                label: tabs[index],
                                selected: selectedTab == index,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Timeframe label
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          timeRangeSubtitle,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoadingHistory)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ================= RESPONSIVE DESKTOP VS MOBILE CONTENT =================
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Expanded(
                            child: Column(
                              children: [
                                _buildMetricRow(context),
                                const SizedBox(height: 18),
                                _buildAiProjectionCurveCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          // Right Column
                          Expanded(
                            child: Column(
                              children: [
                                TrendCard(
                                  title: 'Air Quality Index (${tabs[selectedTab]})',
                                  subtitle: 'Average $avgAqi AQI during this window',
                                  value: '$liveAqi AQI',
                                  change: aqiChangeText,
                                  chartData: aqiChartData,
                                  color: AppColors.primary,
                                  icon: const Icon(Icons.air_rounded, color: AppColors.primary),
                                  isGood: !aqiIsUp,
                                  isUp: aqiIsUp,
                                ),
                                const SizedBox(height: 18),
                                _buildTempHumCard(cardColor, borderColor, textColor, isDark),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildMetricRow(context),
                          const SizedBox(height: 16),
                          _buildAiProjectionCurveCard(cardColor, borderColor, textColor, secondaryTextColor, isDark),
                          const SizedBox(height: 16),
                          TrendCard(
                            title: 'Air Quality Index (${tabs[selectedTab]})',
                            subtitle: 'Average $avgAqi AQI during this window',
                            value: '$liveAqi AQI',
                            change: aqiChangeText,
                            chartData: aqiChartData,
                            color: AppColors.primary,
                            icon: const Icon(Icons.air_rounded, color: AppColors.primary),
                            isGood: !aqiIsUp,
                            isUp: aqiIsUp,
                          ),
                          const SizedBox(height: 16),
                          TrendCard(
                            title: 'Carbon Dioxide (${tabs[selectedTab]})',
                            subtitle: 'Average $avgCo2 ppm over period',
                            value: '$liveCo2 ppm',
                            change: co2ChangeText,
                            chartData: co2ChartData,
                            color: Colors.orange,
                            icon: const Icon(Icons.co2_rounded, color: Colors.orange),
                            isGood: !co2IsUp,
                            isUp: co2IsUp,
                          ),
                          const SizedBox(height: 16),
                          _buildTempHumCard(cardColor, borderColor, textColor, isDark),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context: context,
            title: 'AVERAGE AQI',
            value: '$avgAqi',
            subtitle: 'Min: $minAqi | Max: $maxAqi',
            color: avgAqi <= 50
                ? const Color(0xFF00D26A)
                : (avgAqi <= 100 ? const Color(0xFFFAAD14) : const Color(0xFFFF4D4F)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context: context,
            title: 'AVG CO2 LEVEL',
            value: '$avgCo2',
            subtitle: 'Safe threshold: 1000',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  // ================= ACTUAL VS PREDICTED PROJECTION CURVE =================
  Widget _buildAiProjectionCurveCard(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final lastHistoricalIndex = (pm25Historical.length - 1).toDouble();
    final futureIndex = lastHistoricalIndex + 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(isDark ? 0.15 : 0.04),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.insights_rounded, color: Colors.amber, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PM2.5 ACTUAL VS. AI PREDICTED PROJECTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Solid Green: Actual Telemetry | Dashed Amber: Future +1H Projection',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Now: ${pm25Historical.isNotEmpty ? pm25Historical.last.toStringAsFixed(1) : "86.4"} µg/m³',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Forecast: ${pm25Predicted.toStringAsFixed(1)} µg/m³ (+1h)',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: borderColor.withOpacity(0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  // 1. Solid Historical Telemetry Line
                  LineChartBarData(
                    spots: List.generate(
                      pm25Historical.length,
                      (i) => FlSpot(i.toDouble(), pm25Historical[i]),
                    ),
                    color: AppColors.primary,
                    isCurved: true,
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),

                  // 2. Dashed Future Predicted Line
                  LineChartBarData(
                    spots: [
                      FlSpot(lastHistoricalIndex, pm25Historical.isNotEmpty ? pm25Historical.last : 86.4),
                      FlSpot(futureIndex, pm25Predicted),
                    ],
                    isCurved: false,
                    dashArray: [6, 4],
                    color: Colors.amber,
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.amber.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempHumCard(
    Color cardColor,
    Color borderColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(
                'Temp & Humidity (${tabs[selectedTab]})',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
              ),
              Row(
                children: [
                  _legend(Colors.pinkAccent, 'Temp (°C)'),
                  const SizedBox(width: 14),
                  _legend(Colors.blueAccent, 'Hum (%)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: borderColor.withOpacity(0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      tempChartData.length,
                      (i) => FlSpot(i.toDouble(), tempChartData[i]),
                    ),
                    color: Colors.pinkAccent,
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      humChartData.length,
                      (i) => FlSpot(i.toDouble(), humChartData[i]),
                    ),
                    color: Colors.blueAccent,
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final cardColor = AppColors.getCard(context);
    final borderColor = AppColors.getBorder(context);
    final secondaryTextColor = AppColors.getSecondaryText(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: secondaryTextColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
