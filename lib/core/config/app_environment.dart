import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Build flavours.
///
/// Selected at compile time with `--dart-define=SHUVMARG_FLAVOR=<name>`.
/// Defaults to [AppFlavor.local] so a plain `flutter run` talks to a dev API
/// and can never accidentally hit production.
/// ─────────────────────────────────────────────────────────────────────────────
enum AppFlavor {
  local,
  staging,
  production;

  bool get isLocal => this == AppFlavor.local;
  bool get isProduction => this == AppFlavor.production;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — environment configuration
///
/// This replaces the previous `ApiEndpoints` class, which pinned the base URL to
/// a single hardcoded constant:
///
///   ```dart
///   static const _env = DevTarget.physicalDevice;
///   case DevTarget.physicalDevice: return 'http://10.232.45.245:7012';
///   ```
///
/// That LAN address belonged to one developer's laptop on one Wi-Fi network. It
/// was committed, it went stale the moment DHCP reassigned, and switching
/// targets meant editing and recompiling source. Redesign brief item C1 requires
/// the base URL to live in per-environment config instead — this file is it.
///
/// Resolution order for [baseUrl]:
///
///   1. `--dart-define=SHUVMARG_API_BASE_URL=<url>` — an explicit override that
///      always wins. This is how you point a *physical device* at your laptop:
///      pass your current LAN IP at run time rather than committing it.
///   2. Otherwise derived from [flavor].
///
/// Nothing here is `const` at the top level except the compile-time inputs, so
/// no address can be baked into a release build by accident.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppEnvironment {
  // ───────────────────────────────────────────────────────────────────────────
  // Compile-time inputs
  // ───────────────────────────────────────────────────────────────────────────

  static const String _flavorName = String.fromEnvironment(
    'SHUVMARG_FLAVOR',
    defaultValue: 'local',
  );

  static const String _baseUrlOverride = String.fromEnvironment(
    'SHUVMARG_API_BASE_URL',
  );

  /// Port the Express server listens on in development (`index.js`).
  static const int _localApiPort = int.fromEnvironment(
    'SHUVMARG_API_PORT',
    defaultValue: 7012,
  );

  /// The one production host, carried over from the previous implementation.
  static const String _productionBaseUrl = 'https://api.shuvmarg.com';

  // ───────────────────────────────────────────────────────────────────────────
  // Flavour
  // ───────────────────────────────────────────────────────────────────────────

  static AppFlavor get flavor => switch (_flavorName.trim().toLowerCase()) {
    'local' || 'dev' || 'development' => AppFlavor.local,
    'staging' || 'stage' => AppFlavor.staging,
    'production' || 'prod' => AppFlavor.production,
    // Fail loudly. Silently falling back to `local` would make a mistyped
    // release build look like it worked while pointing at localhost; falling
    // back to `production` would be worse.
    final unknown => throw StateError(
      'Unknown SHUVMARG_FLAVOR "$unknown". '
      'Expected one of: local, staging, production.',
    ),
  };

  // ───────────────────────────────────────────────────────────────────────────
  // Base URL
  // ───────────────────────────────────────────────────────────────────────────

  /// API origin with no trailing slash — e.g. `https://api.shuvmarg.com`.
  ///
  /// Route paths in `ApiPaths` all begin with `/api/...`, so this must be an
  /// origin only, never an origin + prefix.
  static String get baseUrl {
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _stripTrailingSlash(_baseUrlOverride.trim());
    }

    return switch (flavor) {
      AppFlavor.local => _loopbackBaseUrl,
      AppFlavor.production => _productionBaseUrl,
      // There is no known staging host to hardcode, and inventing one would be
      // worse than refusing to guess. Supply it at build time.
      AppFlavor.staging => throw StateError(
        'The staging API host is not compiled in. Build with '
        '--dart-define=SHUVMARG_FLAVOR=staging '
        '--dart-define=SHUVMARG_API_BASE_URL=https://<staging-host>',
      ),
    };
  }

  /// Host that reaches the developer's machine from a **simulator/emulator**.
  ///
  /// Android runs in a VM whose `10.0.2.2` is an alias for the host's loopback;
  /// the iOS simulator shares the host network, so `127.0.0.1` is correct there.
  ///
  /// A *physical* device is on neither — it needs the LAN IP, which is exactly
  /// what `--dart-define=SHUVMARG_API_BASE_URL` is for. Encoding a LAN IP here
  /// is what went wrong last time.
  static String get _loopbackBaseUrl {
    final host = switch (defaultTargetPlatform) {
      TargetPlatform.android => '10.0.2.2',
      _ => '127.0.0.1',
    };
    return 'http://$host:$_localApiPort';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Derived policy
  // ───────────────────────────────────────────────────────────────────────────

  /// Whether plain-HTTP traffic is expected.
  ///
  /// Only true for `local`, where the dev server has no TLS. The Android
  /// manifest correspondingly permits cleartext for **debug builds only** — the
  /// previous global `usesCleartextTraffic="true"` is gone.
  static bool get allowsCleartext => flavor.isLocal;

  /// Whether to attach verbose request/response logging.
  static bool get verboseNetworkLogs => kDebugMode && !flavor.isProduction;

  /// Local development should fail quickly when the laptop address is wrong;
  /// production keeps a wider window for real mobile networks.
  static Duration get connectTimeout =>
      flavor.isLocal ? const Duration(seconds: 5) : const Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Document uploads carry image payloads over Nepali mobile networks; the
  /// default send window is too tight for them.
  static const Duration uploadTimeout = Duration(seconds: 60);

  // ───────────────────────────────────────────────────────────────────────────
  // Startup validation
  // ───────────────────────────────────────────────────────────────────────────

  /// Throws if the compiled configuration is internally inconsistent.
  ///
  /// Called once from bootstrap so a misconfigured build dies at launch with a
  /// readable message instead of failing later as an opaque connection error.
  static void assertValid() {
    final url = baseUrl; // resolves, and throws for unconfigured staging
    final uri = Uri.tryParse(url);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('SHUVMARG_API_BASE_URL is not a valid origin: "$url"');
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      throw StateError(
        'SHUVMARG_API_BASE_URL must be an origin without a path, got "$url". '
        'Route prefixes live in ApiPaths.',
      );
    }
    if (!flavor.isLocal && uri.scheme != 'https') {
      throw StateError(
        'Refusing to use non-HTTPS "$url" for the ${flavor.name} flavour.',
      );
    }
  }

  /// One-line summary for debug overlays and bug reports.
  static String describe() => '${flavor.name} → $baseUrl';

  static String _stripTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
