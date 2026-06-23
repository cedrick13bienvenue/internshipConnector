import 'package:flutter/material.dart';

class ApplicationFormPage extends StatelessWidget {
  final String opportunityId;
  const ApplicationFormPage({super.key, required this.opportunityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply')),
      body: const Center(child: Text('Application Form — coming soon')),
    );
  }
}
