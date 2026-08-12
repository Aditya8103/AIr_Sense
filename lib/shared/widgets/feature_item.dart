import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FeatureItem extends StatelessWidget {
  final String title;
  final String description;
  final Widget icon;

  const FeatureItem({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border,
            ),
          ),

          child: Center(child: icon),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                description,

                style: const TextStyle(
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}