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
    final cardColor = AppColors.getCard(context);
    final borderColor = AppColors.getBorder(context);
    final secondaryTextColor = AppColors.getSecondaryText(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : borderColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : secondaryTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}