import 'package:flutter/material.dart';

/// Shown on app launch while [featureConfigProvider] is loading.
/// No logic here — RouterNotifier redirects away automatically once
/// config resolves (or fails). This screen just needs to look good.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Color(0xFF0D1B2A), // match your app's dark navy
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replace with your actual logo asset:
              // Image.asset('assets/images/logo.png', width: 120),
              Icon(Icons.fingerprint, size: 80, color: Color(0xFFE63946)),
              SizedBox(height: 24),
              Text(
                'Time & Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Color(0xFFE63946),
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
