import 'package:flutter/material.dart';

class OpportunityDetailPage extends StatelessWidget {
  final String id;
  const OpportunityDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity')),
      body: const Center(child: Text('Opportunity Detail — coming soon')),
    );
  }
}
