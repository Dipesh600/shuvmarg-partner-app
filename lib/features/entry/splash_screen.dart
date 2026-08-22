import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../shared/ui/ui.dart';

/// The first frame, shown on the brand-coloured canvas while the router decides
/// where to send the user.
///
/// By the time this mounts, bootstrap has already awaited the persisted session
/// read, so the guard resolves on the next frame — the spinner is here for the
/// rare slow first layout, not for a real wait. It deliberately shows no
/// affordances: there is nothing for the user to do here.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Shuvmarg',
              style: AppText.display1.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppEyebrow('Partner', color: AppColors.goldLight),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
