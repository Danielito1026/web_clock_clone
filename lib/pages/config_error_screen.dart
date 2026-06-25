import 'package:flutter/material.dart';

/// Hard block screen shown when [featureConfigProvider] throws or returns an
/// invalid config (e.g. face-only pipeline with no Login or QR).
///
/// No retry button — the admin must fix the configuration server-side.
/// The app becomes usable again once the device is restarted and the
/// corrected config is fetched on boot.
class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'App Configuration Error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The app could not load its configuration from the server. '
                'This may be caused by an invalid setup or a network issue '
                'at startup.\n\n'
                'Please contact your administrator to resolve this.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}