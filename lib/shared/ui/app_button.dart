import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// The three button roles defined by the agent web's `globals.css`
/// (`.btn-primary`, `.btn-secondary`, `.btn-ghost`).
enum AppButtonVariant {
  /// Brand-filled. One per screen — the single most important action.
  primary,

  /// Outlined in the brand colour. Secondary affirmative actions.
  secondary,

  /// Chromeless. Tertiary/dismissive actions, toolbar actions.
  ghost,

  /// Filled with the danger colour. Destructive confirmation only.
  danger,
}

/// Primary/secondary/ghost button, ported from the agent web.
///
/// Web reference (`globals.css`):
/// ```css
/// .btn-primary {
///   background-color: #7A1D1B;   /* → AppColors.primary */
///   color: #FFFFFF;
///   font-weight: 600; font-size: 14px;
///   border-radius: 12px; height: 48px; padding: 0 24px;
///   letter-spacing: 0.01em;
/// }
/// .btn-primary:hover  { background-color: #5C1414;
///                       box-shadow: 0 4px 12px rgba(122,29,27,0.30); }
/// .btn-primary:active { transform: scale(0.98); }
/// .btn-primary:disabled { opacity: 0.5; }
/// ```
///
/// The `scale(0.98)` press response and the coloured shadow are both
/// reproduced — they're a large part of why the web feels tactile.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  /// Convenience constructor for the outlined variant.
  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.secondary;

  /// Convenience constructor for the chromeless variant.
  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.ghost;

  /// Convenience constructor for destructive confirmation.
  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.danger;

  final String label;

  /// `null` disables the button (web `:disabled` → 50% opacity).
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Swaps the label for a spinner and blocks input.
  final bool isLoading;

  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  // Ghost is the one variant the web sizes down: 40px tall, 8px radius, 16px
  // padding — it's a toolbar control, not a form control.
  bool get _isGhost => widget.variant == AppButtonVariant.ghost;

  double get _height =>
      _isGhost ? 40 : AppSpacing.controlHeight;

  double get _radius => _isGhost ? AppRadius.md : AppRadius.button;

  EdgeInsets get _padding => EdgeInsets.symmetric(
    horizontal: _isGhost ? AppSpacing.md : AppSpacing.xl,
  );

  Color get _background => switch (widget.variant) {
    AppButtonVariant.primary =>
      _pressed ? AppColors.primaryDark : AppColors.primary,
    AppButtonVariant.danger =>
      _pressed ? AppColors.dangerDark : AppColors.danger,
    AppButtonVariant.secondary =>
      _pressed ? AppColors.primaryPressed : Colors.transparent,
    AppButtonVariant.ghost =>
      _pressed ? AppColors.ghostPressed : Colors.transparent,
  };

  Color get _foreground => switch (widget.variant) {
    AppButtonVariant.primary || AppButtonVariant.danger => AppColors.onPrimary,
    AppButtonVariant.secondary => AppColors.primary,
    AppButtonVariant.ghost =>
      _pressed ? AppColors.textPrimary : AppColors.textSecondary,
  };

  BoxBorder? get _border => switch (widget.variant) {
    AppButtonVariant.secondary =>
      Border.all(color: AppColors.primary, width: 1.5),
    _ => null,
  };

  // Only the filled variants carry the ambient coloured shadow, and only while
  // pressed — matching the web's `:hover` shadow (hover has no touch analogue).
  List<BoxShadow>? get _shadow {
    if (!_pressed) return null;
    return switch (widget.variant) {
      AppButtonVariant.primary => AppShadows.brandButton,
      _ => null,
    };
  }

  void _setPressed(bool value) {
    if (!_enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(
      widget.label,
      style: AppText.button.copyWith(color: _foreground),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    final content = widget.isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: _foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              // `Flexible` only when the button has a bounded width. A
              // non-full-width button dropped straight into a Row gets
              // unbounded main-axis constraints, and a flex child under
              // unbounded constraints is a hard layout error.
              if (widget.fullWidth) Flexible(child: label) else label,
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(widget.trailingIcon, size: 18, color: _foreground),
              ],
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: Opacity(
        // Web `.btn:disabled { opacity: 0.5 }`
        opacity: _enabled ? 1 : 0.5,
        child: GestureDetector(
          onTap: _enabled ? widget.onPressed : null,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedScale(
            // Web `.btn-primary:active { transform: scale(0.98) }`
            scale: _pressed ? 0.98 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.smooth,
            child: AnimatedContainer(
              duration: AppMotion.base,
              height: _height,
              width: widget.fullWidth ? double.infinity : null,
              padding: _padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(_radius),
                border: _border,
                boxShadow: _shadow,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
