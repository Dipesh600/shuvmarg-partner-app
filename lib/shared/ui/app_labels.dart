import 'package:flutter/material.dart';

import '../../core/design/design.dart';

/// Small uppercase brand-coloured kicker above a heading.
///
/// Web `.eyebrow`:
/// ```css
/// font-size: 11px; font-weight: 700; letter-spacing: 0.12em;
/// text-transform: uppercase; color: #7A1D1B;  /* → AppColors.primary */
/// ```
///
/// CSS applies `text-transform` at render time; Flutter has no equivalent, so
/// the label is uppercased here rather than at every callsite.
class AppEyebrow extends StatelessWidget {
  const AppEyebrow(this.label, {super.key, this.color});

  final String label;

  /// Overrides the brand colour — e.g. on a brand-filled header where the
  /// eyebrow needs to be white.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: color == null
          ? AppText.eyebrow
          : AppText.eyebrow.copyWith(color: color),
    );
  }
}

/// A section heading with an optional eyebrow and trailing action, matching the
/// header block that sits above every card group in the agent web.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                AppEyebrow(eyebrow!),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(title, style: AppText.titleLg),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle!, style: AppText.bodySm),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// 1px hairline. Web `.divider { height: 1px; background: #DDDDDD; }`
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height = AppSpacing.md});

  /// Total vertical space the divider occupies, including its own 1px.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.neutral200,
        ),
      ),
    );
  }
}

/// Skeleton placeholder used while content loads.
///
/// The web fades content in with `.animate-fade-up`; on mobile a shimmering
/// block reads better than an empty screen or a bare spinner.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.neutral100,
              AppColors.ivoryDark,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
