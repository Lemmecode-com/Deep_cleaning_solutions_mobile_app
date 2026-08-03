// lib/utils/app_messenger.dart
//
// ✅ NEW: App-wide root ScaffoldMessenger key.
//
// Problem: SnackBars shown via `ScaffoldMessenger.of(context)` are tied to
// the *current screen's* Scaffold. If that screen gets popped/replaced by
// navigation (context.go / context.pop / GoRouter redirect) right after the
// SnackBar is triggered, the SnackBar can be cut off before it ever renders
// — this is timing-dependent, so it shows up inconsistently across devices
// (faster devices / less overhead = more likely to hide the message).
//
// Fix: attach a single ScaffoldMessengerKey to the top-level MaterialApp
// (see main.dart -> MaterialApp.router(scaffoldMessengerKey: ...)). SnackBars
// shown through this key belong to the app-level messenger, which survives
// screen navigation, so they always render regardless of what the router
// does immediately afterwards.
//
// Usage in any screen:
//   import 'package:dcs_app/utils/app_messenger.dart';
//   AppMessenger.showSnackBar(
//     SnackBar(content: Text('Done!'), backgroundColor: AppColors.green),
//   );

import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppMessenger {
  AppMessenger._();

  static void showSnackBar(SnackBar snackBar) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}
