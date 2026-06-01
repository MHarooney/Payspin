import 'package:flutter/widgets.dart';

import 'app_lock_service.dart';

/// App-wide gate state for the lock screen.
///
/// Drives an overlay in [PayspinApp] and re-locks when the app is sent to the
/// background, so a returning user must re-authenticate.
class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController(this._service);

  final AppLockService _service;

  bool _enabled = false;
  bool _locked = false;
  bool _suspendAutoLock = false;

  /// True when the lock overlay should cover the app.
  bool get isLocked => _locked;

  /// True when a passcode/biometric lock has been set up.
  bool get isEnabled => _enabled;

  void attach() => WidgetsBinding.instance.addObserver(this);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called once before `runApp`: lock immediately if enabled so secured
  /// content never paints on a cold start.
  Future<void> evaluateStartupLock() async {
    _enabled = await _service.isLockEnabled();
    _locked = _enabled;
    notifyListeners();
  }

  /// Marks the lock active and currently open (the user just authenticated
  /// during setup).
  void markEnabledUnlocked() {
    _enabled = true;
    _locked = false;
    notifyListeners();
  }

  /// Clears lock state (logout / forgot passcode).
  void markDisabled() {
    _enabled = false;
    _locked = false;
    notifyListeners();
  }

  void unlock() {
    if (_locked) {
      _locked = false;
      notifyListeners();
    }
  }

  void lockNow() {
    if (_enabled && !_locked) {
      _locked = true;
      notifyListeners();
    }
  }

  /// Prevents the lifecycle observer from re-locking while a system biometric
  /// sheet is showing (some platforms emit a spurious pause/resume).
  set suspendAutoLock(bool value) => _suspendAutoLock = value;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled || _suspendAutoLock) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (!_locked) {
        _locked = true;
        notifyListeners();
      }
    }
  }
}
