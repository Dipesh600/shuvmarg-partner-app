import 'package:flutter/foundation.dart';

/// Driver-persona identity returned by `GET /api/driver/me`.
///
/// This is intentionally separate from the shared authenticated user: one login account
/// can also be a passenger or agent, while the name and compliance details an
/// operator entered belong specifically to its Driver profile.
@immutable
class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.experienceYears,
    required this.operationalStatus,
    required this.accessStatus,
    required this.license,
    required this.medicalCertificate,
    this.email,
    this.gender,
    this.brand,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? gender;
  final int experienceYears;
  final DriverBrand? brand;
  final String operationalStatus;
  final String accessStatus;
  final DriverLicense license;
  final DriverMedicalCertificate medicalCertificate;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: _requiredString(json, 'driverId'),
      fullName: _requiredString(json, 'fullName'),
      phone: _requiredString(json, 'phone'),
      email: _string(json['email']),
      gender: _string(json['gender']),
      experienceYears: _nonNegativeInt(json['experienceYears']),
      brand: json['brand'] is Map
          ? DriverBrand.fromJson((json['brand'] as Map).cast<String, dynamic>())
          : null,
      operationalStatus: _requiredString(json, 'operationalStatus'),
      accessStatus: _requiredString(json, 'accessStatus'),
      license: DriverLicense.fromJson(_requiredMap(json, 'license')),
      medicalCertificate: DriverMedicalCertificate.fromJson(
        _requiredMap(json, 'medicalCertificate'),
      ),
    );
  }
}

@immutable
class DriverBrand {
  const DriverBrand({required this.id, this.name, this.code});

  final String id;
  final String? name;
  final String? code;

  factory DriverBrand.fromJson(Map<String, dynamic> json) => DriverBrand(
    id: _requiredString(json, 'id'),
    name: _string(json['name']),
    code: _string(json['code']),
  );
}

@immutable
class DriverLicense {
  const DriverLicense({
    required this.number,
    required this.type,
    required this.expiry,
    required this.documentUploaded,
  });

  final String number;
  final String type;
  final DateTime expiry;
  final bool documentUploaded;

  factory DriverLicense.fromJson(Map<String, dynamic> json) => DriverLicense(
    number: _requiredString(json, 'number'),
    type: _requiredString(json, 'type'),
    expiry: _requiredDate(json, 'expiry'),
    documentUploaded: json['documentUploaded'] == true,
  );
}

@immutable
class DriverMedicalCertificate {
  const DriverMedicalCertificate({this.expiry, required this.documentUploaded});

  final DateTime? expiry;
  final bool documentUploaded;

  factory DriverMedicalCertificate.fromJson(Map<String, dynamic> json) =>
      DriverMedicalCertificate(
        expiry: _date(json['expiry']),
        documentUploaded: json['documentUploaded'] == true,
      );
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('Driver profile "$key" must be an object.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _string(json[key]);
  if (value != null) return value;
  throw FormatException('Driver profile "$key" is missing.');
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _nonNegativeInt(Object? value) {
  final parsed = value is int ? value : (value is num ? value.toInt() : null);
  if (parsed == null || parsed < 0) {
    throw const FormatException('Driver experience is invalid.');
  }
  return parsed;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _date(json[key]);
  if (value != null) return value;
  throw FormatException('Driver profile "$key" is invalid.');
}

DateTime? _date(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
