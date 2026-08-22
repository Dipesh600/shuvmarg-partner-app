import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_support_config.dart';
import '../../../core/design/design.dart';
import '../../../domain/app_role.dart';

/// Dynamic, role-aware partner support bottom sheet.
///
/// Features:
/// - 3D support headphone illustration (`support_icon.png`).
/// - Live online support status indicator.
/// - Official brand WhatsApp SVG icon and direct call action.
/// - Role-specific, personalized support options (Fleet Owner for drivers/conductors,
///   Partner Desk for agents).
/// - Dynamic configuration via [AppSupportConfig] (zero hardcoding).
class RoleSupportSheet extends StatelessWidget {
  const RoleSupportSheet({super.key, required this.role});

  final AppRole role;

  static Future<void> show(BuildContext context, {required AppRole role}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RoleSupportSheet(role: role),
    );
  }

  Future<void> _launchDialer(BuildContext context, String phoneUri) async {
    final uri = Uri.parse(phoneUri);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open dialer for ${AppSupportConfig.partnerHelplineDisplay}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final uri = Uri.parse(AppSupportConfig.whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Please try calling the direct line.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 30,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Pill
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header Row: 3D Headphones + Title & Live Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 3D Headphone Asset
                SizedBox(
                  height: 64,
                  width: 64,
                  child: Image.asset(
                    'assets/images/support_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Title and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need help signing in?',
                        style: TextStyle(
                          fontFamily: 'Neue Machina',
                          fontSize: 19,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'We\'ll help you access your ${role.label.toLowerCase()} workspace.',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Live Status Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 7,
                            width: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Support online • Usually < 2 min',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Dynamic Cards Based on User Persona
            if (role == AppRole.driver || role == AppRole.conductor) ...[
              // Card 1: Contact Bus Operator (Primary for crew)
              _SupportCard(
                iconWidget: const Icon(
                  Icons.directions_bus_rounded,
                  size: 22,
                  color: Color(0xFFE84324),
                ),
                iconBgColor: const Color(0xFFFFF2EC),
                title: 'Contact your Bus Operator',
                subtitle: 'Your fleet owner assigns your login phone and password.',
                badgeText: 'RECOMMENDED',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please call or message your bus owner / fleet manager to reset your credentials.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Card 2: Direct Helpline
              _SupportCard(
                iconWidget: const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 21,
                  color: Color(0xFF0284C7),
                ),
                iconBgColor: const Color(0xFFE0F2FE),
                title: 'Call Partner Support',
                subtitle: '${AppSupportConfig.partnerHelplineDisplay} • ${AppSupportConfig.partnerHelplineNote}',
                onTap: () {
                  Navigator.pop(context);
                  _launchDialer(context, AppSupportConfig.partnerHelplineDialable);
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Card 3: WhatsApp Support
              _SupportCard(
                iconWidget: SvgPicture.asset(
                  'assets/icons/whatsapp_icon.svg',
                  height: 22,
                  width: 22,
                ),
                iconBgColor: const Color(0xFFDCFCE7),
                title: 'Chat on WhatsApp',
                subtitle: 'Direct chat with ${AppSupportConfig.whatsappUsername} for quick help',
                onTap: () {
                  Navigator.pop(context);
                  _launchWhatsApp(context);
                },
              ),
            ] else ...[
              // Agent Specific Cards
              _SupportCard(
                iconWidget: const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 21,
                  color: Color(0xFFE84324),
                ),
                iconBgColor: const Color(0xFFFFF2EC),
                title: 'Call Agent Desk',
                subtitle: '${AppSupportConfig.partnerHelplineDisplay} • ${AppSupportConfig.partnerHelplineNote}',
                badgeText: 'DIRECT',
                onTap: () {
                  Navigator.pop(context);
                  _launchDialer(context, AppSupportConfig.partnerHelplineDialable);
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              _SupportCard(
                iconWidget: SvgPicture.asset(
                  'assets/icons/whatsapp_icon.svg',
                  height: 22,
                  width: 22,
                ),
                iconBgColor: const Color(0xFFDCFCE7),
                title: 'Chat on WhatsApp',
                subtitle: 'Direct chat with ${AppSupportConfig.whatsappUsername} for ticketing assistance',
                onTap: () {
                  Navigator.pop(context);
                  _launchWhatsApp(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              _SupportCard(
                iconWidget: const Icon(
                  Icons.badge_outlined,
                  size: 21,
                  color: Color(0xFF6366F1),
                ),
                iconBgColor: const Color(0xFFEEF2FF),
                title: 'Agency Credential Recovery',
                subtitle: 'Recover your registered agency code or phone',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Email support at ${AppSupportConfig.supportEmail} or call helpline.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single interactive premium support option card.
class _SupportCard extends StatefulWidget {
  const _SupportCard({
    required this.iconWidget,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.onTap,
  });

  final Widget iconWidget;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  @override
  State<_SupportCard> createState() => _SupportCardState();
}

class _SupportCardState extends State<_SupportCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF1E8DF),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neutral900.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Squircle
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: widget.iconWidget),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (widget.badgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2EC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.badgeText!,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE84324),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Arrow
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
