import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AlertItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String sensorValue;
  final bool warning;

  const AlertItem({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.sensorValue,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,

            decoration: BoxDecoration(
              color: warning
                  ? Colors.orange
                  : AppColors.danger,

              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(
                      time,

                      style: const TextStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  message,

                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,

                      color: warning
                          ? Colors.orange
                          : AppColors.danger,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      sensorValue,

                      style: TextStyle(
                        color: warning
                            ? Colors.orange
                            : AppColors.danger,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}