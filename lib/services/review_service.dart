import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/links.dart';

/// App Store rating. Uses Apple's own in-app rating sheet; if that is not
/// available it opens the "write a review" page of the App Store.
///
/// Note: Apple never shows the in-app sheet in TestFlight builds and limits
/// it to three times a year per user.
class ReviewService {
  ReviewService._();

  static Future<void> ask() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
    } catch (e) {
      debugPrint('In-app review failed: $e');
    }
    await openStore();
  }

  static Future<void> openStore() async {
    try {
      await launchUrl(Uri.parse(Links.writeReview), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Opening the App Store failed: $e');
    }
  }
}
