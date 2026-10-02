import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TrendCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String change;

  final List<double> chartData;

  final Color color;
  final Widget icon;

  final bool isGood;
  final bool isUp;

  const TrendCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.change,
    required this.chartData,
    required this.color,
    required this.icon,
    required this.isGood,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,

                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),

                      borderRadius:
                          BorderRadius.circular(8),
                    ),

                    child: Center(
                      child: icon,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,

                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        subtitle,

                        style: const TextStyle(
                          color:
                              AppColors.secondaryText,

                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: isGood
                      ? AppColors.primary
                          .withOpacity(0.15)
                      : Colors.orange
                          .withOpacity(0.15),

                  borderRadius:
                      BorderRadius.circular(6),
                ),

                child: Row(
                  children: [
                    Icon(
                      isUp
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,

                      size: 14,

                      color: isGood
                          ? AppColors.primary
                          : Colors.orange,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      change,

                      style: TextStyle(
                        color: isGood
                            ? AppColors.primary
                            : Colors.orange,

                        fontWeight:
                            FontWeight.bold,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            value,

            style: TextStyle(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 120,

            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: false,
                ),

                titlesData:
                    const FlTitlesData(
                  show: false,
                ),

                borderData:
                    FlBorderData(show: false),

                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      chartData.length,

                      (index) => FlSpot(
                        index.toDouble(),
                        chartData[index],
                      ),
                    ),

                    isCurved: true,

                    color: color,

                    barWidth: 3,

                    dotData: const FlDotData(
                      show: false,
                    ),

                    belowBarData:
                        BarAreaData(
                      show: true,

                      color: color
                          .withOpacity(0.08),
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
}