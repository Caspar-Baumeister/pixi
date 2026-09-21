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
    final raw = await boundary.toImage(pixelRatio: pixelRatio);
    // Put the (transparent) widget on paper with a margin so it looks good in stories.
    final pad = (raw.width * 0.08).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = raw.width + pad * 2, h = raw.height + pad * 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = const Color(0xFFFAF9F6));
    canvas.drawImage(raw, Offset(pad.toDouble(), pad.toDouble()), Paint());
    final image = await recorder.endRecording().toImage(w, h);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
        text: text);
  }
}
