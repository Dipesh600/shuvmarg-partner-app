import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/design.dart';

/// Labelled text input, ported from the agent web's form primitives.
///
/// Web reference (`globals.css`):
/// ```css
/// .form-label { font-size: 13px; font-weight: 600; color: #444;
///               margin-bottom: 6px; }
/// .form-input { height: 48px; border: 1.5px solid #DDDDDD;
///               border-radius: 12px; padding: 0 16px; font-size: 14px; }
/// .form-input:focus { border-color: #7A1D1B;
///                     box-shadow: 0 0 0 3px rgba(122,29,27,0.10); }
/// .form-input.error  { border-color: #D32F2F;
///                     box-shadow: 0 0 0 3px rgba(211,47,47,0.10); }
/// ```
///
/// That 3px focus ring is the detail that makes the web's forms feel
/// considered. Flutter's [InputDecoration] can't express it (a border is not a
/// shadow), so the field is wrapped in a container that renders the ring as a
/// zero-blur spread shadow.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.validator,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;

  /// Non-null switches the field into its error state (red border + red ring).
  final String? errorText;

  /// Quiet hint shown below the field when there is no error.
  final String? helperText;

  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;

  bool get _hasError => widget.errorText != null;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    // Only dispose a node we created — disposing a caller-owned node would
    // crash the parent on rebuild.
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  Color get _borderColor {
    if (!widget.enabled) return AppColors.neutral100;
    if (_hasError) return AppColors.danger;
    if (_focused) return AppColors.primary;
    return AppColors.borderInput;
  }

  /// The 3px ring only renders while focused, matching `:focus` in CSS.
  List<BoxShadow>? get _ring {
    if (!_focused || !widget.enabled) return null;
    return [
      BoxShadow(
        color: _hasError ? AppColors.focusRingDanger : AppColors.focusRing,
        blurRadius: 0,
        spreadRadius: 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppText.label),
          const SizedBox(height: 6), // web `margin-bottom: 6px`
        ],
        AnimatedContainer(
          duration: AppMotion.base,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.surface : AppColors.neutral100,
            borderRadius: AppRadius.inputRadius,
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: _ring,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            style: AppText.bodyMd,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.bodyMd.copyWith(
                color: AppColors.textPlaceholder,
              ),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(
                      widget.prefixIcon,
                      size: 18,
                      color: _focused
                          ? AppColors.primary
                          : AppColors.textPlaceholder,
                    ),
              // Material defaults a prefix icon to a 48x48 minimum box, which
              // on its own pushes the field past the web's 48px total height.
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 0,
              ),
              suffixIcon: widget.suffix,
              // The wrapper draws the border; the field itself must not.
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: '',
              isDense: true,
              // Budget for the web's 48px control: 1.5px border top and bottom
              // (3) + 12 + a 21px line box (14px at 1.5) + 12 = 48.
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: widget.maxLines > 1 ? 14 : 12,
              ),
            ),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppText.caption.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(widget.helperText!, style: AppText.caption),
        ],
      ],
    );
  }
}
