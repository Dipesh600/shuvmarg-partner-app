import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/design/design.dart';
import '../../../../domain/agent_identity.dart';
import '../../../../shared/ui/ui.dart';

/// The agent's code, front and centre.
///
/// This is the one thing an agent needs from this screen: a permanent identifier
/// they read out, copy, or share so a bus operator can add them as a ticket
/// agent. It is not a secret — it is meant to be handed out — so it is displayed
/// in full rather than masked.
///
/// [sharePayload] is the sentence the *server* composed for the share sheet. When
/// it has not arrived the Share action is disabled rather than falling back to
/// wording invented here, so the app, the agent web console and the operator
/// console never drift apart on what the message says.
class AgentCodeCard extends StatelessWidget {
  const AgentCodeCard({
    super.key,
    required this.identity,
    this.sharePayload,
  });

  final AgentIdentity identity;
  final String? sharePayload;

  @override
  Widget build(BuildContext context) {
    final code = identity.shareableCode;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AppEyebrow('Your agent code')),
              if (identity.scope != null)
                AppBadge(
                  label: identity.scope!.label,
                  tone: AppBadgeTone.info,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (code == null)
            const _MissingCode()
          else
            _CodeValue(code: code, isLegacy: identity.agentCode == null),
          const SizedBox(height: AppSpacing.sm),
          Text(
            code == null
                ? 'A bus operator cannot add you to their team until your code '
                      'is issued. Contact support if this does not resolve.'
                : 'Give this code to a bus operator. They use it to add you as '
                      'their ticket agent — you keep the same code with every '
                      'operator you work for.',
            style: AppText.bodySm,
          ),
          if (code != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Copy',
                    icon: Icons.content_copy_rounded,
                    onPressed: () => _copy(context, code),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Share',
                    icon: Icons.ios_share_rounded,
                    // Disabled until the server hands us its wording.
                    onPressed: sharePayload == null
                        ? null
                        : () => _share(context, sharePayload!),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Agent code copied.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _share(BuildContext context, String payload) async {
    // iPad anchors the share sheet to a rect; without one it lands in the corner
    // or throws. The card's own box is the closest thing to the tapped button.
    final box = context.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.share(payload, sharePositionOrigin: origin);
  }
}

/// The code itself, in the inset panel so it reads as a value to be transcribed
/// rather than body copy.
class _CodeValue extends StatelessWidget {
  const _CodeValue({required this.code, required this.isLegacy});

  final String code;

  /// True when we are showing the superseded `SHV-AG-…` identifier because no
  /// `SM-AG-…` code has been issued. Said out loud rather than passed off as
  /// current.
  final bool isLegacy;

  @override
  Widget build(BuildContext context) {
    return AppInsetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            code,
            style: AppText.statNumberSm.copyWith(letterSpacing: 1.4),
          ),
          if (isLegacy) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('Older code format', style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

/// Shown when the profile carries no code at all. An empty box would look like a
/// code that failed to render; this says what is actually true.
class _MissingCode extends StatelessWidget {
  const _MissingCode();

  @override
  Widget build(BuildContext context) {
    return AppInsetPanel(
      child: Row(
        children: [
          const Icon(
            Icons.pending_outlined,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Not issued yet', style: AppText.bodyMd),
          ),
        ],
      ),
    );
  }
}
