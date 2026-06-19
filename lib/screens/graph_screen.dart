import 'package:flutter/material.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB), // muted warm pastel
      body: Center(
        child: Text(
          'Graph Screen Pending',
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
