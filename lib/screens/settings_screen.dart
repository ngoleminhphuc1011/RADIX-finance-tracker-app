import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // muted minimalist grey
      body: Center(
        child: Text(
          'Settings Screen Pending',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
