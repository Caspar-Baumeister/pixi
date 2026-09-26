import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a [RepaintBoundary] to PNG and opens the system share sheet.
class ShareService {
  ShareService._();

  /// Screen rect of the widget behind [context] (the tapped button). Since
  /// iOS 26 the share sheet needs a non-empty source rect on iPhone too,
  /// otherwise it silently refuses to open.
  static Rect originOf(BuildContext? context) {
    final box = context?.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      final r = box.localToGlobal(Offset.zero) & box.size;
      if (!r.isEmpty) return r;
    }
    // Fallback: a small rect in the lower middle of the screen.
    final view = ui.PlatformDispatcher.instance.implicitView;
    final size = view == null ? const Size(400, 800) : view.physicalSize / view.devicePixelRatio;
    return Rect.fromCenter(center: Offset(size.width / 2, size.height - 80), width: 2, height: 2);
  }

  /// Returns false when something went wrong (the caller shows a hint).
  static Future<bool> shareBoundary(
    GlobalKey boundaryKey, {
    required String fileName,
    String? text,
    double pixelRatio = 3,
    BuildContext? origin,
  }) async {
    try {
      final ctx = boundaryKey.currentContext;
      if (ctx == null) return false;
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
      if (bytes == null) return false;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_safe(fileName)}');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: text,
        sharePositionOrigin: originOf(origin),
      );
      return true;
    } catch (e) {
      debugPrint('Share failed: $e');
      return false;
    }
  }

  /// Share a file that already exists (e.g. the JSON export).
  static Future<bool> shareFile(String path, {String? mimeType, BuildContext? origin}) async {
    try {
      await Share.shareXFiles([XFile(path, mimeType: mimeType)], sharePositionOrigin: originOf(origin));
      return true;
    } catch (e) {
      debugPrint('Share failed: $e');
      return false;
    }
  }

  /// File names from map titles may contain spaces, umlauts or "?".
  static String _safe(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    final clean = base.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').replaceAll(RegExp(r'_+'), '_');
    return '${clean.isEmpty ? 'pixi' : clean}$ext';
  }
}
