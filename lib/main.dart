import 'package:flutter/material.dart';

void main() {
  runApp(const WhyPulseApp());
}

class WhyPulseApp extends StatelessWidget {
  const WhyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF35685B)), useMaterial3: true),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_outline, size: 48),
                SizedBox(height: 16),
                Text('WhyPulse', style: TextStyle(fontSize: 28)),
                SizedBox(height: 8),
                Text('Project setup ready'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
