import 'package:flutter/material.dart';
import 'package:why_pulse/app/app_state.dart';
import 'package:why_pulse/app/theme.dart';
import 'package:why_pulse/features/why_pulse_ui.dart';

void main() {
  runApp(const WhyPulseApp());
}

class WhyPulseApp extends StatefulWidget {
  const WhyPulseApp({super.key});

  @override
  State<WhyPulseApp> createState() => _WhyPulseAppState();
}

class _WhyPulseAppState extends State<WhyPulseApp> {
  final WhyPulseState _state = WhyPulseState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WhyPulseScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'WhyPulse',
            debugShowCheckedModeBanner: false,
            theme: buildPulseTheme(),
            home: _state.onboarded
                ? const WhyPulseShell()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
