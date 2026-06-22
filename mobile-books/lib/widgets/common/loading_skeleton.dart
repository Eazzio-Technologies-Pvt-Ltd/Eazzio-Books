import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  final Widget child;

  const LoadingSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: const Duration(milliseconds: 1200),
      baseColor: const Color(0xFFE8EAF0),
      highlightColor: const Color(0xFFF8F9FF),
      child: child,
    );
  }

  // Pre-built variant: SkeletonCard matching AppCard dimensions
  static Widget skeletonCard({double height = 120}) {
    return LoadingSkeleton(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  // Pre-built variant: SkeletonListItem (avatar + 2 lines of text)
  static Widget skeletonListItem() {
    return LoadingSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pre-built variant: SkeletonText with variable width lines
  static Widget skeletonText({int lines = 3}) {
    return LoadingSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          final isLast = index == lines - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0.0 : 8.0),
            child: Container(
              width: isLast ? 180.0 : double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
