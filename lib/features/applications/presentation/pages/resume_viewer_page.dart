import 'resume_body_stub.dart'
    if (dart.library.html) 'resume_body_web.dart';
import 'package:flutter/material.dart';

class ResumeViewerPage extends StatelessWidget {
  final String url;
  final String applicantName;

  const ResumeViewerPage({
    super.key,
    required this.url,
    required this.applicantName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$applicantName\'s Resume',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ResumeBody(url: url),
    );
  }
}
