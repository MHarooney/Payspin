import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_progress.dart';

/// Persists the in-progress phone verification (see [OnboardingProgress]).
///
/// All operations are best-effort: storage failures (e.g. plugin unavailable in
/// tests) never throw to callers so onboarding still works.
class OnboardingProgressStore {
  static const _key = 'payspin_onboarding_phone_progress';

  Future<void> save(OnboardingProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(progress.toJson()));
    } catch (e) {
      debugPrint('OnboardingProgressStore.save failed: $e');
    }
  }

  /// Returns the saved progress, or null when absent/expired/unreadable.
  /// Expired entries are cleared as a side effect.
  Future<OnboardingProgress?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final progress = OnboardingProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (progress.isExpired || !progress.hasPhone) {
        await clear();
        return null;
      }
      return progress;
    } catch (e) {
      debugPrint('OnboardingProgressStore.load failed: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('OnboardingProgressStore.clear failed: $e');
    }
  }
}
