import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_lock_service.dart';

/// App-wide gate state for the lock screen.
///
/// Re-locks only after [autoLockTimeout] of genuine inactivity — not on every
/// lifecycle blip while navigating inside the app. Backgrounding the app starts
/// the same timer: returning within the window stays unlocked.
class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController(
    this._service, {
    Duration autoLockTimeout = const Duration(seconds: 60),
  }) : _autoLockTimeout = autoLockTimeout;

  final AppLockService _service;
  final Duration _autoLockTimeout;

  /// Default inactivity window before the lock overlay appears.
  static const Duration defaultAutoLockTimeout = Duration(seconds: 60);

  bool _enabled = false;
  bool _locked = false;
  bool _suspendAutoLock = false;
  bool _attached = false;
  DateTime _lastActivityAt = DateTime.now();
  Timer? _idleTimer;

  /// True when the lock overlay should cover the app.
  bool get isLocked => _locked;

  /// True when a passcode/biometric lock has been set up.
  bool get isEnabled => _enabled;

  Duration get autoLockTimeout => _autoLockTimeout;

  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _attached = false;
    }
    super.dispose();
  }

  /// Called once before `runApp`: lock immediately if enabled so secured
  /// content never paints on a cold start.
  Future<void> evaluateStartupLock() async {
    _enabled = await _service.isLockEnabled();
    _locked = _enabled;
    if (_enabled && !_locked) {
      recordUserActivity();
    }
    notifyListeners();
  }

  /// Marks the lock active and currently open (the user just authenticated
  /// during setup).
  void markEnabledUnlocked() {
    _enabled = true;
    _locked = false;
    recordUserActivity();
    notifyListeners();
  }

  /// Clears lock state (logout / forgot passcode).
  void markDisabled() {
    _enabled = false;
    _locked = false;
    _cancelIdleTimer();
    notifyListeners();
  }

  void unlock() {
    if (_locked) {
      _locked = false;
      recordUserActivity();
      notifyListeners();
    }
  }

  void lockNow() {
    if (_enabled && !_locked) {
      _locked = true;
      _cancelIdleTimer();
      notifyListeners();
    }
  }

  /// Resets the inactivity clock. Call on taps, scrolls, and typing.
  void recordUserActivity() {
    if (!_enabled || _locked || _suspendAutoLock) return;
    _lastActivityAt = DateTime.now();
    _scheduleIdleLock();
  }

  /// Prevents idle / lifecycle re-lock while a system biometric sheet is showing.
  set suspendAutoLock(bool value) {
    _suspendAutoLock = value;
    if (value) {
      _cancelIdleTimer();
    } else if (_enabled && !_locked) {
      recordUserActivity();
    }
  }

  /// Seconds remaining before auto-lock from the last user interaction.
  int get secondsUntilAutoLock {
    if (!_enabled || _locked) return _autoLockTimeout.inSeconds;
    final elapsed = DateTime.now().difference(_lastActivityAt);
    final remaining = _autoLockTimeout - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled || _suspendAutoLock) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Do not lock here — brief pauses happen during in-app navigation on
        // some devices. Evaluate on resume against the inactivity window.
        _cancelIdleTimer();
        break;
      case AppLifecycleState.resumed:
        _evaluateInactivityLock();
        if (!_locked) _scheduleIdleLock();
        break;
      case AppLifecycleState.inactive:
        // Transitional (control centre, incoming call overlay). Keep the timer.
        break;
      case AppLifecycleState.detached:
        _cancelIdleTimer();
        break;
    }
  }

  void _evaluateInactivityLock() {
    if (!_enabled || _locked) return;
    final idleFor = DateTime.now().difference(_lastActivityAt);
    if (idleFor >= _autoLockTimeout) {
      lockNow();
    }
  }

  void _scheduleIdleLock() {
    _cancelIdleTimer();
    if (!_enabled || _locked || _suspendAutoLock) return;

    final idleFor = DateTime.now().difference(_lastActivityAt);
    final remaining = _autoLockTimeout - idleFor;
    if (remaining <= Duration.zero) {
      lockNow();
      return;
    }

    _idleTimer = Timer(remaining, () {
      if (_enabled && !_locked && !_suspendAutoLock) {
        _evaluateInactivityLock();
      }
    });
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }
}
