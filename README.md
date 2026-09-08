# shuvmarg_partner_app

Shuvmarg Agent & Conductor Partner App

## Build the staging Android app

The staging build uses the same backend as the passenger, agent web,
bus-owner and admin staging applications:

```text
https://api-staging.shuvmarg.com
```

Build the ARM64 release APK with the versioned launcher so the staging flavour
is always selected consistently. Current Android test devices must support
ARM64:

```bash
zsh tool/build_staging_android.zsh
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Run on a physical Android phone

A physical phone cannot use Android emulator address `10.0.2.2`. Start the
local backend, connect the Mac and phone to the same Wi-Fi, enable USB debugging,
then run:

```bash
zsh tool/run_physical_android.zsh
```

The launcher discovers the Mac's current Wi-Fi address, verifies that the API is
reachable, and passes the correct address to Flutter without committing a LAN IP.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
