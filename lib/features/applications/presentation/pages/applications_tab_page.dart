import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ApplicationsTabPage extends StatelessWidget {
  const ApplicationsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Applications — coming soon', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
