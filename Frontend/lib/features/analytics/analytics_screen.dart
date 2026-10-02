import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/filter_chip.dart';
import '../../shared/widgets/trend_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int selectedTab = 1;

  final List<String> tabs = [
    '1H',
    '24H',
    '7D',
    '30D',
    'CUSTOM',
  ];

  // ================= LIVE VALUES =================
  int aqi = 0;
  int co2 = 0;
  double smoke = 0;
  double temperature = 0;
  double humidity = 0;

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

  // ================= FETCH REALTIME DATA VIA API SERVICE =================
  void fetchRealtimeData() {
    _subscription = ApiService().getSensorStream().listen((data) {
      if (mounted) {
        setState(() {
          aqi = data.aqi;
          co2 = data.co2.toInt();
          smoke = data.smoke;
          temperature = data.temperature;
          humidity = data.humidity;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ANALYTICS & TRENDS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.ios_share_rounded,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FILTER TABS =================
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  tabs.length,
                  (index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = index;
                          });
                        },
                        child: FilterChipWidget(
                          label: tabs[index],
                          selected: selectedTab == index,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= METRIC CARDS =================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'LIVE AQI',
                    value: '$aqi',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'LIVE CO2',
                    value: '$co2',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= AQI TREND =================
            TrendCard(
              title: 'Air Quality Index',
              subtitle: 'Realtime atmospheric health',
              value: '$aqi AQI',
              change: 'LIVE',
              chartData: [
                (aqi - 20).toDouble(),
                (aqi - 10).toDouble(),
                aqi.toDouble(),
                (aqi + 5).toDouble(),
                aqi.toDouble(),
              ],
              color: AppColors.primary,
              icon: const Icon(
                Icons.air_rounded,
                color: AppColors.primary,
              ),
              isGood: true,
              isUp: false,
            ),

            const SizedBox(height: 24),

            // ================= CO2 TREND =================
            TrendCard(
              title: 'Carbon Dioxide',
              subtitle: 'Realtime CO2 concentration',
              value: '$co2 ppm',
              change: 'LIVE',
              chartData: [
                (co2 - 100).toDouble(),
                (co2 - 50).toDouble(),
                co2.toDouble(),
                (co2 + 40).toDouble(),
                co2.toDouble(),
              ],
              color: Colors.orange,
              icon: const Icon(
                Icons.co2_rounded,
                color: Colors.orange,
              ),
              isGood: false,
              isUp: true,
            ),

            const SizedBox(height: 24),

            // ================= TEMP & HUMIDITY GRAPH =================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Temp & Humidity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _legend(
                            Colors.pink,
                            'Temp',
                          ),
                          const SizedBox(width: 16),
                          _legend(
                            Colors.blue,
                            'Hum',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(
                          show: false,
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        titlesData: const FlTitlesData(
                          show: false,
                        ),
                        lineBarsData: [
                          // TEMPERATURE
                          LineChartBarData(
                            spots: [
                              FlSpot(0, temperature - 2),
                              FlSpot(1, temperature - 1),
                              FlSpot(2, temperature),
                              FlSpot(3, temperature + 1),
                              FlSpot(4, temperature),
                            ],
                            color: Colors.pink,
                            isCurved: true,
                            barWidth: 3,
                            dotData: const FlDotData(
                              show: false,
                            ),
                          ),

                          // HUMIDITY
                          LineChartBarData(
                            spots: [
                              FlSpot(0, humidity - 3),
                              FlSpot(1, humidity - 1),
                              FlSpot(2, humidity),
                              FlSpot(3, humidity + 2),
                              FlSpot(4, humidity),
                            ],
                            color: Colors.blue,
                            isCurved: true,
                            barWidth: 3,
                            dotData: const FlDotData(
                              show: false,
                            ),
                          ),
                        ],
                      ),
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

  // ================= METRIC CARD =================
  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= LEGEND =================
  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
