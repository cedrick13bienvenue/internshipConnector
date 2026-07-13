import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class ResumeBody extends StatelessWidget {
  final String url;
  const ResumeBody({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded, size: 72, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              'Resume',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(url);
                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Resume'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
