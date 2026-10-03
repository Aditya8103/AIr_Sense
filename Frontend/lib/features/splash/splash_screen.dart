import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_gjmecwii.json',
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.air_rounded,
                      size: 120,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Text(
                'Air Sense',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Precision Air Monitoring',
                style: TextStyle(
                  color: AppColors.getSecondaryText(context),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                title: 'Get Started',
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.login,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
