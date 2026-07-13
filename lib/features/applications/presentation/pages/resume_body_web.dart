// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ResumeBody extends StatefulWidget {
  final String url;
  const ResumeBody({super.key, required this.url});

  @override
  State<ResumeBody> createState() => _ResumeBodyState();
}

class _ResumeBodyState extends State<ResumeBody> {
  late final String _viewId;
  Timer? _fallback;
  bool _loaded = false;

  static String _toEmbedUrl(String raw) {
    final gdrive = RegExp(r'drive\.google\.com/file/d/([^/]+)');
    final match = gdrive.firstMatch(raw);
    if (match != null) {
      return 'https://drive.google.com/file/d/${match.group(1)}/preview';
    }
    if (raw.contains('dropbox.com')) {
      return raw
          .replaceAll('dl=0', 'raw=1')
          .replaceAll('www.dropbox.com', 'dl.dropboxusercontent.com');
    }
    return raw;
  }

  void _markLoaded() {
    if (mounted && !_loaded) setState(() => _loaded = true);
  }

  @override
  void initState() {
    super.initState();
    _viewId = 'resume-viewer-${DateTime.now().microsecondsSinceEpoch}';
    final embedUrl = _toEmbedUrl(widget.url);

    ui.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..onLoad.listen((_) => _markLoaded());
      return iframe;
    });

    _fallback = Timer(const Duration(seconds: 4), _markLoaded);
  }

  @override
  void dispose() {
    _fallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(child: HtmlElementView(viewType: _viewId)),
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
    );
  }
}
