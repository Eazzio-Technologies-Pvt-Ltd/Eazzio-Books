import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class FeatureLockedScreen extends ConsumerWidget {
  final String featureName;

  const FeatureLockedScreen({
    super.key,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        leading: IconButton(
          icon: const Icon(AppIcons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon with premium gradient circle background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.lock_outline_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Title
              Text(
                'Feature Locked',
                style: GoogleFonts.outfit(
                  textStyle: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),

              // Subtitle with feature name
              Text(
                featureName,
                style: GoogleFonts.inter(
                  textStyle: textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),

              // Explanation text
              Builder(
                builder: (context) {
                  final authState = ref.watch(authNotifierProvider);
                  final user = authState is AuthAuthenticated ? authState.user : null;
                  final isFreePlan = user == null || 
                      user.planId.toLowerCase() == 'free' || 
                      (user.planId.toLowerCase() == 'trial' && user.remainingTrialDays <= 0);

                  final message = isFreePlan 
                      ? 'You are currently on the Free Plan. $featureName is not available on the Free Plan. If you want this feature, please upgrade to one of our premium plans to get instant access.'
                      : 'This feature is not included in your current subscription plan. Upgrade your plan to get instant access to $featureName and other premium capabilities.';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    child: Text(
                      message,
                      style: textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // CTA: Upgrade Plan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/pricing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Upgrade Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // CTA: Back to safety
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
