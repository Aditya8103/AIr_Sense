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
  State<SettingSwitch> createState() =>
      _SettingSwitchState();
}

class _SettingSwitchState
    extends State<SettingSwitch> {
  late bool enabled;

  @override
  void initState() {
    super.initState();
    enabled = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),

      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),

            child: Center(
              child: widget.icon,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  widget.title,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.subtitle,

                  style: const TextStyle(
                    color: AppColors.secondaryText,
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