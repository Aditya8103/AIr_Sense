import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : AppColors.card,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.border,
        ),
      ),

      child: Text(
        label,

        style: TextStyle(
          color: selected
              ? Colors.black
              : AppColors.secondaryText,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}