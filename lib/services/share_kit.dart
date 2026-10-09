import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

/// Share + review helper. Both degrade gracefully: share falls back silently
/// when no share sheet is available; the review prompt is wrapped so it can
/// never crash, and in_app_review itself no-ops when the app was not
/// installed from Play.
class ShareKit {
  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.colorfill';

  static Future<void> shareWin({
    required String playerName,
    required int stars,
    required int level,
    required String modeName,
  }) async {
    final text =
        '$playerName just flooded a $modeName board in Color Fill with $stars ⭐ — can you beat it?\n$storeUrl';
    try {
      await Share.share(text, subject: 'Color Fill');
    } catch (e) {
      debugPrint('share failed: $e');
    }
  }

  static Future<void> shareApp() async {
    const text =
        'Color Fill — flood the whole board with color! Addictive little puzzle game:\n$storeUrl';
    try {
      await Share.share(text, subject: 'Color Fill');
    } catch (e) {
      debugPrint('share failed: $e');
    }
  }

  /// Ask for a Play review at a sensible moment (after a win streak).
  /// Safe to call anywhere: never throws, no-ops when not from Play.
  static Future<void> maybeAskReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('review prompt failed: $e');
    }
  }
}
