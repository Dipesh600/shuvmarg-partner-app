import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRIMARY BUTTON  (#D3D925 lime, or custom color)
// ─────────────────────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.accentLime;
    final fg = textColor ?? AppColors.primaryDark;
    final disabled = onPressed == null || isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: disabled ? bg.withOpacity(0.45) : bg,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: disabled ? null : AppShadows.glow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fg,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: disabled ? fg.withOpacity(0.6) : fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OUTLINE / GHOST BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;
  final double height;

  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.borderColor,
    this.textColor,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.primary;
    final fg = textColor ?? AppColors.primary;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP INPUT FIELD
// ─────────────────────────────────────────────────────────────────────────────
class AppInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const AppInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelSm(AppColors.textSecond),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge(AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASSMORPHISM CARD
// ─────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color ?? const Color(0xE100564E),
        border: Border.all(color: AppColors.stroke),
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT BADGE  (CASH=amber, ONLINE=green)
// ─────────────────────────────────────────────────────────────────────────────
class PaymentBadge extends StatelessWidget {
  final bool isCash;
  const PaymentBadge({super.key, required this.isCash});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCash ? AppColors.badgeCashBg : AppColors.badgeOnlineBg,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        isCash ? 'CASH' : 'ONLINE',
        style: AppTextStyles.bodyTiny(
          isCash ? AppColors.badgeCashText : AppColors.badgeOnlineText,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP PROGRESS BAR  (used in application screens)
// ─────────────────────────────────────────────────────────────────────────────
class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: AppTextStyles.labelSm(AppColors.textSecond),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTextStyles.labelSm(AppColors.accentLime),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.stroke,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentLime),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SHIMMER PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.stroke,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.labelMed(AppColors.textSecond)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: AppTextStyles.labelSm(AppColors.accentLime),
            ),
          ),
      ],
    );
  }
}
