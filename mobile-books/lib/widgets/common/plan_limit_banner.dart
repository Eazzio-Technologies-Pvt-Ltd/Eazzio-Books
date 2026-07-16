import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/permissions/plan_gate_service.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class PlanLimitBanner extends ConsumerWidget {
  final String resourceType;
  final String resourceName;

  const PlanLimitBanner({
    super.key,
    required this.resourceType,
    required this.resourceName,
  });

  String _getPlanName(String planId) {
    switch (planId.toLowerCase()) {
      case 'free': return 'Free';
      case 'standard': return 'Standard Premium';
      case 'premium': return 'Standard Premium';
      case 'professional': return 'Professional';
      case 'enterprise': return 'Enterprise';
      case 'trial': return 'Trial';
      default: return planId;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planGate = ref.watch(planGateProvider);
    final limit = planGate.getMaxLimit(resourceType);
    if (limit == null) return const SizedBox.shrink(); // Skip if unlimited (no cap exists)

    final used = planGate.getUsageCount(resourceType);
    final remaining = planGate.remaining(resourceType) ?? max(0, limit - used);
    final planName = _getPlanName(planGate.planId);

    // Determine colors/messages
    Color bgColor;
    Color textColor;
    IconData icon;
    String message;
    bool showAction = true;

    if (used >= limit) {
      bgColor = const Color(0xFFFEE2E2); // Red background
      textColor = const Color(0xFF991B1B); // Dark red text
      icon = AppIcons.block_flipped;
      message = 'All $limit ${resourceName}s used. Upgrade to add more.';
    } else if (remaining <= (limit * 0.2).ceil()) {
      bgColor = const Color(0xFFFEF3C7); // Amber background
      textColor = const Color(0xFF92400E); // Dark amber text
      icon = AppIcons.warning_amber_rounded;
      message = '$remaining ${resourceName}s left on your $planName plan — Upgrade';
    } else {
      bgColor = const Color(0xFFF1F5F9); // Light slate background
      textColor = const Color(0xFF334155); // Dark slate text
      icon = AppIcons.info_outline;
      message = '$used / $limit ${resourceName}s used on $planName plan.';
      showAction = false;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showAction)
            TextButton(
              onPressed: () => context.push('/pricing'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Upgrade',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
