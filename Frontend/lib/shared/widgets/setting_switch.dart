import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SettingSwitch extends StatefulWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final bool initialValue;

  const SettingSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.initialValue,
  });

  @override
  State<SettingSwitch> createState() => _SettingSwitchState();
}

class _SettingSwitchState extends State<SettingSwitch> {
  late bool enabled;

  @override
  void initState() {
    super.initState();
    enabled = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.getCard(context);
    final borderColor = AppColors.getBorder(context);
    final textColor = AppColors.getText(context);
    final secondaryTextColor = AppColors.getSecondaryText(context);
    final bgColor = AppColors.getBackground(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: widget.icon,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                enabled = value;
              });
            },
          ),
        ],
      ),
    );
  }
}