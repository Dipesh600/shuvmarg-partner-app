# shuvmarg_partner_app

Shuvmarg Agent & Conductor Partner App

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
