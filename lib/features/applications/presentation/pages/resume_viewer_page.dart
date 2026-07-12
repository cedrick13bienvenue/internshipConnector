// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ResumeViewerPage extends StatefulWidget {
  final String url;
  final String applicantName;

  const ResumeViewerPage({
    super.key,
    required this.url,
    required this.applicantName,
  });

  @override
  State<ResumeViewerPage> createState() => _ResumeViewerPageState();
}

class _ResumeViewerPageState extends State<ResumeViewerPage> {
  late final String _viewId;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'resume-viewer-${DateTime.now().microsecondsSinceEpoch}';
    final url = widget.url;

    ui.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..onLoad.listen((_) {
          if (mounted) setState(() => _loaded = true);
        });
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.applicantName}\'s Resume',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: HtmlElementView(viewType: _viewId),
          ),
          if (!_loaded)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('Loading resume...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
