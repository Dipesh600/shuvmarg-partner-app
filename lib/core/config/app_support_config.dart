/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — Support & Helpline Configuration
///
/// Centralized source of truth for all support channels, contacts, and desk info.
/// Allows dynamic runtime or build-time overrides without hardcoding in UI widgets.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppSupportConfig {
  /// Primary Partner Support Phone Number
  static const String partnerHelplineDisplay = String.fromEnvironment(
    'SHUVMARG_SUPPORT_PHONE_DISPLAY',
    defaultValue: '+977 9803643115',
  );

  /// Raw dialable phone URI string (e.g. `tel:+9779803643115`)
  static const String partnerHelplineDialable = String.fromEnvironment(
    'SHUVMARG_SUPPORT_PHONE_DIAL',
    defaultValue: 'tel:+9779803643115',
  );

  /// Phone helpline subtitle note
  static const String partnerHelplineNote = 'Direct Partner Support Line';

  /// Official WhatsApp Username
  static const String whatsappUsername = '@shuvmarg';

  /// WhatsApp Phone Number
  static const String whatsappNumber = String.fromEnvironment(
    'SHUVMARG_SUPPORT_WHATSAPP',
    defaultValue: '9779746592506',
  );

  /// WhatsApp direct universal link
  static String get whatsappUrl => 'https://wa.me/$whatsappNumber';

  /// Official Support Email
  static const String supportEmail = String.fromEnvironment(
    'SHUVMARG_SUPPORT_EMAIL',
    defaultValue: 'partner-support@shuvmarg.com',
  );

  /// Average expected response time text
  static const String responseTimeText = 'Usually responds in < 5 mins';

  /// Desk availability hours
  static const String availabilityText = '24/7 Dedicated Partner Desk';
}
