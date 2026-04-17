import 'package:flutter/material.dart';
import 'krave_loading.dart';
import '../theme/app_colors.dart';

class SkeletonCanteenCard extends StatelessWidget {
  const SkeletonCanteenCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: KraveSkeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(width: 140, height: 20, borderRadius: 4),
                      SkeletonBox(width: 60, height: 16, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SkeletonBox(width: 180, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonMenuItem extends StatelessWidget {
  const SkeletonMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: KraveSkeleton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 20, height: 20, borderRadius: 4),
                  const SizedBox(height: 12),
                  SkeletonBox(width: 120, height: 20, borderRadius: 4),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 60, height: 20, borderRadius: 4),
                  const SizedBox(height: 12),
                  SkeletonBox(width: 180, height: 14, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SkeletonBox(width: 120, height: 120, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}
