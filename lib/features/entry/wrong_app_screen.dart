import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design/design.dart';
import '../../shared/ui/ui.dart';

/// An honest dead-end for accounts that belong to a *different* Shuvmarg app.
///
/// Passengers and bus owners have real platform accounts, but not ones this app
/// can sign in — the login endpoint rejects their role for this `X-App-Source`.
/// Rather than surface that as a failed login, the welcome screen offers a way
/// here, where we can say plainly which app they need instead.
class WrongAppScreen extends StatelessWidget {
  const WrongAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadius.cardRadius,
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'This app is for partners',
                style: AppText.titleLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Shuvmarg Partner signs in agents, conductors and drivers. '
                'If you book travel, use the Shuvmarg passenger app. If you '
                'manage buses, sign in to the bus-owner web portal.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                label: 'Back to role selection',
                onPressed: () => context.go(AppRoutes.welcome),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
