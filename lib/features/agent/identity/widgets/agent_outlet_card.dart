import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../domain/agent_identity.dart';
import '../../../../shared/ui/ui.dart';

/// The agent's outlet: what kind of shopfront they run and where it is.
///
/// Every row is conditional and the card is only built when
/// [AgentIdentity.hasOutletDetails] is true, because these fields are optional
/// for both scopes — a solo agent created by an operator from nothing but a name
/// and a phone number has none of them. An empty row labelled "District —" would
/// read as missing data rather than data that was never asked for.
///
/// Presentation only. No rule anywhere reads the outlet type.
class AgentOutletCard extends StatelessWidget {
  const AgentOutletCard({super.key, required this.identity});

  final AgentIdentity identity;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (identity.outletType != null)
        _OutletRow(label: 'Outlet', value: identity.outletType!.label),
      if (identity.businessName != null)
        _OutletRow(label: 'Business', value: identity.businessName!),
      if (identity.locationLine != null)
        _OutletRow(label: 'Location', value: identity.locationLine!),
      if (identity.shopAddress != null)
        _OutletRow(label: 'Address', value: identity.shopAddress!),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppEyebrow('Your outlet'),
          const SizedBox(height: AppSpacing.sm),
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) const AppDivider(height: AppSpacing.sm),
            row,
          ],
        ],
      ),
    );
  }
}

class _OutletRow extends StatelessWidget {
  const _OutletRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: AppText.caption),
        ),
        Expanded(
          child: Text(
            value,
            style: AppText.bodyMd,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
