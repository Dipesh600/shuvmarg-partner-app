import 'package:flutter/foundation.dart';

enum AgentAssignmentStatus {
  invited('INVITED', 'Needs your answer'),
  active('ACTIVE', 'Ready to sell'),
  suspended('SUSPENDED', 'Selling paused'),
  revoked('REVOKED', 'Access removed'),
  declined('DECLINED', 'You declined'),
  expired('EXPIRED', 'Invitation expired');

  const AgentAssignmentStatus(this.wire, this.label);

  final String wire;
  final String label;

  bool get canRespond => this == invited;
  bool get permitsSelling => this == active;
  bool get isPast => this == declined || this == expired;

  static AgentAssignmentStatus? tryParse(Object? value) {
    final wire = value is String ? value.trim().toUpperCase() : '';
    for (final status in values) {
      if (status.wire == wire) return status;
    }
    return null;
  }
}

@immutable
class AssignmentPermissions {
  const AssignmentPermissions({
    required this.canSellCash,
    required this.canSellOnline,
    required this.canCancel,
    required this.cancelWindowMins,
    required this.maxSeatsPerBooking,
    required this.maxDiscountPct,
  });

  final bool canSellCash;
  final bool canSellOnline;
  final bool canCancel;
  final int cancelWindowMins;
  final int? maxSeatsPerBooking;
  final num maxDiscountPct;

  factory AssignmentPermissions.fromJson(Map<String, dynamic> json) {
    return AssignmentPermissions(
      canSellCash: json['canSellCash'] == true,
      canSellOnline: json['canSellOnline'] == true,
      canCancel: json['canCancel'] == true,
      cancelWindowMins: _integer(json['cancelWindowMins']) ?? 0,
      maxSeatsPerBooking: _integer(json['maxSeatsPerBooking']),
      maxDiscountPct: _number(json['maxDiscountPct']) ?? 0,
    );
  }
}

@immutable
class AssignmentCommission {
  const AssignmentCommission({required this.mode, required this.value});

  final String mode;
  final num value;

  factory AssignmentCommission.fromJson(Map<String, dynamic> json) {
    return AssignmentCommission(
      mode: _string(json['mode'])?.toUpperCase() ?? 'PERCENT',
      value: _number(json['value']) ?? 0,
    );
  }

  String get label => switch (mode) {
    'FLAT_PER_SEAT' => 'Rs ${_plainNumber(value)} per seat',
    'FLAT_PER_BOOKING' => 'Rs ${_plainNumber(value)} per booking',
    _ => '${_plainNumber(value)}% of each booking',
  };
}

@immutable
class AgentAssignment {
  const AgentAssignment({
    required this.id,
    required this.status,
    required this.brandId,
    required this.brandName,
    required this.accessScope,
    required this.permissions,
    required this.commission,
    this.invitedAt,
    this.expiresAt,
    this.acceptedAt,
    this.declinedAt,
    this.statusReason,
  });

  final String id;
  final AgentAssignmentStatus status;
  final String? brandId;
  final String brandName;
  final String accessScope;
  final AssignmentPermissions permissions;
  final AssignmentCommission commission;
  final DateTime? invitedAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final String? statusReason;

  String get accessLabel => switch (accessScope) {
    'ROUTES' => 'Selected routes',
    'SCHEDULES' => 'Selected trips',
    _ => 'All buses from this operator',
  };

  factory AgentAssignment.fromJson(Map<String, dynamic> json) {
    final brand = _map(json['brand']);
    final status = AgentAssignmentStatus.tryParse(json['status']);
    final id = _string(json['assignmentId']);
    if (status == null || id == null) {
      throw const FormatException('Invalid assignment response.');
    }
    return AgentAssignment(
      id: id,
      status: status,
      brandId: _string(brand['id']),
      brandName: _string(brand['name']) ?? 'Bus operator',
      accessScope: _string(json['accessScope'])?.toUpperCase() ?? 'ALL_BUSES',
      permissions: AssignmentPermissions.fromJson(_map(json['permissions'])),
      commission: AssignmentCommission.fromJson(_map(json['commission'])),
      invitedAt: _date(json['invitedAt']),
      expiresAt: _date(json['expiresAt']),
      acceptedAt: _date(json['acceptedAt']),
      declinedAt: _date(json['declinedAt']),
      statusReason: _string(json['statusReason']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

String? _string(Object? value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? null : text;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

num? _number(Object? value) => value is num ? value : null;

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  return null;
}

String _plainNumber(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
