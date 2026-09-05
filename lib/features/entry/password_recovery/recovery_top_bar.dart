import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../domain/app_role.dart';
import '../widgets/role_support_sheet.dart';

/// Top action bar for password recovery screens with back button and support trigger.
class RecoveryTopBar extends StatelessWidget {
  const RecoveryTopBar({super.key, required this.role, required this.onBack});

  final AppRole role;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neutral900.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => RoleSupportSheet.show(context, role: role),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neutral900.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.headset_mic_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Help',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
