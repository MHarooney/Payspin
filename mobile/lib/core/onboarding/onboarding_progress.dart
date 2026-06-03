import 'package:equatable/equatable.dart';

/// Snapshot of an in-progress phone verification, persisted so the user lands
/// back on the OTP step (not Welcome) after iOS backgrounds/kills the app while
/// the external Firebase reCAPTCHA / SMS flow is on screen.
class OnboardingProgress extends Equatable {
  const OnboardingProgress({
    required this.countryCode,
    required this.phone,
    required this.displayName,
    required this.savedAt,
    this.verificationId,
    this.codeSent = false,
  });

  final String countryCode;
  final String phone;
  final String displayName;
  final DateTime savedAt;

  /// Firebase `verificationId` from `codeSent`. When present on restore we can
  /// show the code-entry UI directly instead of re-triggering reCAPTCHA.
  final String? verificationId;

  /// Whether Firebase has confirmed the SMS was dispatched.
  final bool codeSent;

  /// In-progress verifications older than this are treated as stale and dropped.
  static const Duration ttl = Duration(minutes: 15);

  /// Firebase SMS codes expire quickly; re-send when a restored session is older.
  static const Duration resendAfter = Duration(minutes: 4);

  bool get isExpired => DateTime.now().difference(savedAt) > ttl;

  bool get hasPhone => phone.trim().isNotEmpty;

  /// True when Firebase handed us a [verificationId] — the SMS flow is live and
  /// we can restore straight to the OTP screen without re-triggering reCAPTCHA.
  bool get hasActiveVerification =>
      verificationId != null && verificationId!.isNotEmpty;

  /// Resume at OTP only when Firebase confirmed SMS dispatch; phone-only snapshots
  /// (e.g. reCAPTCHA interrupted before `codeSent`) go back to the phone step.
  bool get shouldRestoreOtp => hasActiveVerification && codeSent;

  /// True when a restored OTP session is old enough that the SMS code likely expired.
  bool get needsResend => DateTime.now().difference(savedAt) > resendAfter;

  /// Phone was entered but no confirmed SMS — pick up at step 2.
  bool get shouldRestorePhone => hasPhone && !shouldRestoreOtp;

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'phone': phone,
        'displayName': displayName,
        'verificationId': verificationId,
        'codeSent': codeSent,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    return OnboardingProgress(
      countryCode: json['countryCode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      verificationId: json['verificationId'] as String?,
      codeSent: json['codeSent'] as bool? ?? false,
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['savedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  List<Object?> get props =>
      [countryCode, phone, displayName, verificationId, codeSent, savedAt];
}
