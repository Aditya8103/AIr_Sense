import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ProfileOption extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.danger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,

      child: Container(
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
                child: icon,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: TextStyle(
                      color: danger
                          ? AppColors.danger
                          : Colors.white,

                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                  if (subtitle != 'empty')
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 4),

                      child: Text(
                        subtitle,

                        style: const TextStyle(
                          color:
                              AppColors.secondaryText,

                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (!danger)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
              )
          ],
        ),
      ),
    );
  }
}