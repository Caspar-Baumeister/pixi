import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a [RepaintBoundary] to PNG and opens the system share sheet.
class ShareService {
  ShareService._();

  static Future<void> shareBoundary(
    GlobalKey boundaryKey, {
    required String fileName,
    String? text,
    double pixelRatio = 3,
  }) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) return;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
        text: text);
  }
}
