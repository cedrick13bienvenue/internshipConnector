import 'package:flutter/material.dart';

class StartupProfilePage extends StatelessWidget {
  final String id;
  const StartupProfilePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup')),
      body: const Center(child: Text('Startup Profile — coming soon')),
    );
  }
}
