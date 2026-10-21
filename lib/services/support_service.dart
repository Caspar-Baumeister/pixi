import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/links.dart';
import 'analytics.dart';

/// Feedback mail with the facts that help answering it: app, version, build,
/// iOS version and device.
class SupportService {
  SupportService._();

  static Future<String> versionLabel() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } catch (_) {
      return '';
    }
  }

  static Future<void> sendFeedback({String source = 'settings', String body = ''}) async {
    Analytics.instance.track('feedback_tapped', {'source': source});
    var facts = 'App: Pixi';
    try {
      final info = await PackageInfo.fromPlatform();
      facts += '\nVersion: ${info.version} (${info.buildNumber})';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await DeviceInfoPlugin().iosInfo;
        facts += '\niOS: ${ios.systemVersion}\nDevice: ${ios.utsname.machine}';
      }
    } catch (e) {
      debugPrint('Device info failed: $e');
    }
    final subject = Uri.encodeComponent('Pixi Feedback');
    final text = Uri.encodeComponent('${body.isEmpty ? '' : '$body\n\n'}\n\n---\n$facts');
    try {
      await launchUrl(Uri.parse('mailto:${Links.supportEmail}?subject=$subject&body=$text'));
    } catch (e) {
      debugPrint('Mail failed: $e');
    }
  }

  static Future<void> openX({required String source}) async {
    Analytics.instance.track('x_profile_tapped', {'source': source});
    await launchUrl(Uri.parse(Links.x), mode: LaunchMode.externalApplication);
  }
}
