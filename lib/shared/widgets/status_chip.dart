import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final Color bgColor;
  final Color textColor;
  final String label;

  const StatusChip({
    super.key,
    required this.bgColor,
    required this.textColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),

      child: Text(
        label,

        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}