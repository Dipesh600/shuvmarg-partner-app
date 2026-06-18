import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

enum _PayMode { cash, online }

class PaymentModeScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const PaymentModeScreen({super.key, required this.bookingData});

  @override
  State<PaymentModeScreen> createState() => _PaymentModeScreenState();
}

class _PaymentModeScreenState extends State<PaymentModeScreen> {
  _PayMode? _selected;

  void _continue() {
    if (_selected == null) return;

    final updatedData = {
      ...widget.bookingData,
      'paymentMode': _selected == _PayMode.cash ? 'CASH' : 'ONLINE',
    };

    if (_selected == _PayMode.cash) {
      // Cash bookings skip QR — go straight to confirm
      context.push(AppRoutes.bookingConfirm, extra: {
        ...updatedData,
        'isCash': true,
      });
    } else {
      context.push(AppRoutes.paymentQr, extra: updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Payment Mode', style: AppTextStyles.labelLg(AppColors.textPrimary)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              Text(
                'How is the\npassenger paying?',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // ── Cash Card ──────────────────────────────────────────
              _PaymentCard(
                mode: _PayMode.cash,
                selected: _selected == _PayMode.cash,
                icon: Icons.payments_rounded,
                title: 'Cash',
                subtitle: 'Passenger pays you in cash.\nSettled directly with the bus operator.',
                accentColor: AppColors.warning,
                onTap: () => setState(() => _selected = _PayMode.cash),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Online Card ────────────────────────────────────────
              _PaymentCard(
                mode: _PayMode.online,
                selected: _selected == _PayMode.online,
                icon: Icons.phone_android_rounded,
                title: 'Online',
                subtitle: 'Passenger pays via Khalti or eSewa.\nCommission credited to your wallet.',
                accentColor: AppColors.accentLime,
                onTap: () => setState(() => _selected = _PayMode.online),
              ),

              const Spacer(),

              // Visual reminder of what's selected
              if (_selected != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: (_selected == _PayMode.cash ? AppColors.warning : AppColors.accentLime)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_selected == _PayMode.cash ? AppColors.warning : AppColors.accentLime)
                          .withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selected == _PayMode.cash
                            ? Icons.payments_rounded
                            : Icons.check_circle_outline_rounded,
                        color: _selected == _PayMode.cash ? AppColors.warning : AppColors.accentLime,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _selected == _PayMode.cash
                            ? 'Cash booking selected — collect payment from passenger'
                            : 'Online — QR code will be shown for passenger to scan',
                        style: AppTextStyles.bodySmall(AppColors.textSecond),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              PrimaryButton(
                label: _selected == _PayMode.cash ? 'Book (Cash)' : 'Continue',
                onPressed: _selected != null ? _continue : null,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final _PayMode mode;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: selected ? accentColor.withOpacity(0.08) : AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppRadius.card - 4),
          border: Border(
            left: BorderSide(
              color: selected ? accentColor : Colors.transparent,
              width: 4,
            ),
            top: BorderSide(color: selected ? accentColor.withOpacity(0.3) : AppColors.stroke),
            right: BorderSide(color: selected ? accentColor.withOpacity(0.3) : AppColors.stroke),
            bottom: BorderSide(color: selected ? accentColor.withOpacity(0.3) : AppColors.stroke),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(selected ? 0.18 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading3(AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(AppColors.textSecond),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accentColor : AppColors.stroke,
                  width: 2,
                ),
                color: selected ? accentColor : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: AppColors.primaryDark, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
