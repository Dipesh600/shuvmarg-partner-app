import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../shared/ui/ui.dart';
import '../shell/brand_header.dart';
import '../shell/workspace_shell.dart';

/// A living specimen sheet for the design system.
///
/// This is a **review surface, not a product screen** — it exists so the ported
/// visual language can be checked on a real device before feature screens are
/// built on top of it. Delete it once the real Overview screen lands.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  final _errorFieldController = TextEditingController(text: '98X');

  @override
  void dispose() {
    _errorFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrandHeaderScaffold(
      header: const BrandGreeting(
        salutation: 'Good morning,',
        name: 'Design System',
        trailing: BrandHeaderAction(
          icon: Icons.notifications_none_rounded,
          showDot: true,
          tooltip: 'Notifications',
        ),
      ),
      child: WorkspacePage(
        children: [
          const _Section(
            eyebrow: 'Foundation',
            title: 'Brand colour',
            subtitle:
                '#D94328 — the vermillion already used across the passenger '
                'site and the app icon. Replaces the web\'s maroon #7A1D1B '
                'and coral #D96B62.',
          ),
          const _SwatchRow(
            swatches: [
              _Swatch('50', AppColors.orange50),
              _Swatch('100', AppColors.orange100),
              _Swatch('200', AppColors.orange200),
              _Swatch('300', AppColors.orange300),
              _Swatch('400', AppColors.orange400),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const _SwatchRow(
            swatches: [
              _Swatch('500', AppColors.orange500, isBrand: true),
              _Swatch('600', AppColors.orange600),
              _Swatch('700', AppColors.orange700),
              _Swatch('800', AppColors.orange800),
              _Swatch('900', AppColors.orange900),
            ],
          ),

          const _Section(
            eyebrow: 'Foundation',
            title: 'Surfaces',
            subtitle:
                'Warm creams, never pure white. Card borders are warm beige '
                'rather than grey — that warmth is the most recognisable part '
                'of the web\'s language.',
          ),
          const _SwatchRow(
            swatches: [
              _Swatch('canvas', AppColors.canvas),
              _Swatch('alt', AppColors.canvasAlt),
              _Swatch('auth', AppColors.canvasAuth),
              _Swatch('ivory', AppColors.ivory),
              _Swatch('border', AppColors.border),
            ],
          ),

          const _Section(
            eyebrow: 'Foundation',
            title: 'Typography',
            subtitle:
                'Manrope throughout. Headings mimic Neue Machina\'s metrics '
                '(w300, 1.1 line-height, negative tracking) until the .otf '
                'files are bundled.',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display 1 · 32/300', style: AppText.display1),
                const SizedBox(height: AppSpacing.xs),
                Text('Display 2 · 26/300', style: AppText.display2),
                const SizedBox(height: AppSpacing.xs),
                Text('Display 3 · 22/300', style: AppText.display3),
                const AppDivider(),
                Text('Title Large · 18/600', style: AppText.titleLg),
                const SizedBox(height: AppSpacing.xxs),
                Text('Title Medium · 16/600', style: AppText.titleMd),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Body · 16/400 at 1.6 line-height. The workhorse paragraph '
                  'style, matching the web body rule.',
                  style: AppText.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Body Medium · 14/400 — the size the web uses for almost '
                  'all UI text.',
                  style: AppText.bodyMd,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Body Small · 13/400 secondary', style: AppText.bodySm),
                const AppDivider(),
                const AppEyebrow('Eyebrow · 11/700 · 0.12em'),
                const SizedBox(height: AppSpacing.xs),
                Text('LABEL · 13/600', style: AppText.label),
                const SizedBox(height: AppSpacing.xs),
                Text('CAPTION · 12/500', style: AppText.caption),
                const AppDivider(),
                Text('रू 48,250', style: AppText.statNumber),
                Text(
                  'Stat figure · 28/800 — the one place the system goes heavy.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),

          const _Section(
            eyebrow: 'Components',
            title: 'Buttons',
            subtitle:
                'Press to see the scale(0.98) response and the ambient brand '
                'shadow, both carried over from the web.',
          ),
          AppCard(
            child: Column(
              children: [
                AppButton(
                  label: 'Confirm booking',
                  icon: Icons.check_rounded,
                  onPressed: () => _toast(context, 'Primary pressed'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.secondary(
                  label: 'Save as draft',
                  onPressed: () => _toast(context, 'Secondary pressed'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.danger(
                  label: 'Cancel ticket',
                  icon: Icons.close_rounded,
                  onPressed: () => _toast(context, 'Danger pressed'),
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppButton(
                  label: 'Disabled state',
                  onPressed: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppButton(label: 'Loading', isLoading: true),
                const AppDivider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton.ghost(
                    label: 'Ghost action',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () => _toast(context, 'Ghost pressed'),
                  ),
                ),
              ],
            ),
          ),

          const _Section(
            eyebrow: 'Components',
            title: 'Inputs',
            subtitle:
                'Focus a field to see the 3px ring — the detail that makes the '
                'web\'s forms feel considered.',
          ),
          AppCard(
            child: Column(
              children: [
                const AppTextField(
                  label: 'Mobile number',
                  hint: '98XXXXXXXX',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  helperText: 'Nepali mobile numbers only.',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Mobile number (error state)',
                  controller: _errorFieldController,
                  prefixIcon: Icons.phone_rounded,
                  errorText: 'Enter a valid 10-digit number.',
                ),
                const SizedBox(height: AppSpacing.md),
                const AppTextField(
                  label: 'Disabled',
                  hint: 'Not editable',
                  enabled: false,
                ),
              ],
            ),
          ),

          const _Section(
            eyebrow: 'Components',
            title: 'Status pills',
            subtitle:
                'Tailwind -100/-700 pastel pairs, transcribed from the web\'s '
                'booking status map.',
          ),
          const AppCard(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppBadge(label: 'Completed', tone: AppBadgeTone.success),
                AppBadge(label: 'Active', tone: AppBadgeTone.info),
                AppBadge(label: 'Cancelled', tone: AppBadgeTone.danger),
                AppBadge(label: 'Refunded', tone: AppBadgeTone.special),
                AppBadge(label: 'Pending', tone: AppBadgeTone.pending),
                AppBadge(label: 'Draft', tone: AppBadgeTone.neutral),
              ],
            ),
          ),

          const _Section(
            eyebrow: 'Components',
            title: 'Surfaces & loading',
          ),
          AppCard(
            onTap: () => _toast(context, 'Card tapped — border darkens'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  eyebrow: 'Tappable',
                  title: 'Interactive card',
                  subtitle: 'Border darkens on press, mirroring .card:hover.',
                ),
                const SizedBox(height: AppSpacing.md),
                const AppInsetPanel(
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text('An ivory inset panel inside a white card.'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const AppSkeleton(width: 40, height: 40, radius: 999),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppSkeleton(height: 12),
                          SizedBox(height: AppSpacing.xs),
                          AppSkeleton(width: 140, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gallery-only helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, this.eyebrow, this.subtitle});

  final String title;
  final String? eyebrow;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.sm,
      ),
      child: AppSectionHeader(
        title: title,
        eyebrow: eyebrow,
        subtitle: subtitle,
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.swatches});

  final List<_Swatch> swatches;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < swatches.length; i++) ...[
          Expanded(child: swatches[i]),
          if (i != swatches.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color, {this.isBrand = false});

  final String label;
  final Color color;

  /// Marks the canonical brand step.
  final bool isBrand;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isBrand ? AppColors.neutral900 : AppColors.border,
              width: isBrand ? 2 : 1,
            ),
          ),
          child: isBrand
              ? const Center(
                  child: Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppText.caption.copyWith(
            fontWeight: isBrand ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
