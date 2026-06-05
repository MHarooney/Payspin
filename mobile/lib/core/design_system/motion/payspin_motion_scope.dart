import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../theme/payspin_motion.dart';

/// Provides a single, app-wide device-tilt signal that glass surfaces read to
/// drive 3D parallax + the liquid specular highlight.
///
/// One accelerometer subscription powers the whole app (cheap). The signal is
/// low-pass filtered against a slowly-drifting baseline, so it responds to
/// *changes* in orientation and re-centres to `Offset.zero` when the device is
/// held steady — the same feel as iOS parallax wallpapers.
///
/// Read it with [PayspinMotionScope.of] (returns a zero listenable when no
/// scope or sensors are present, so widgets work everywhere).
class PayspinMotionScope extends StatefulWidget {
  const PayspinMotionScope({super.key, required this.child});

  final Widget child;

  /// Shared zero signal used when no scope/sensor is available.
  static final ValueNotifier<Offset> _zero = ValueNotifier<Offset>(Offset.zero);

  static ValueListenable<Offset> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_MotionInherited>();
    return scope?.tilt ?? _zero;
  }

  @override
  State<PayspinMotionScope> createState() => _PayspinMotionScopeState();
}

class _PayspinMotionScopeState extends State<PayspinMotionScope>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset> _tilt = ValueNotifier<Offset>(Offset.zero);
  StreamSubscription<AccelerometerEvent>? _sub;

  /// Slow ambient drift so liquid sheen + 3D tilt remain visible on simulators
  /// and desktops where the accelerometer never fires.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  static const double _g = 9.81;
  static const double _gain = 2.6;
  static const double _ambientGain = 0.22;

  // Two-rate low-pass: fast = responsive reading, slow = drifting baseline.
  double _fastX = 0, _fastY = 0, _slowX = 0, _slowY = 0;
  bool _seeded = false;
  bool _sensorActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  void _maybeStart() {
    if (!mounted) return;
    if (PayspinMotion.reduced(context)) return;
    _ambient.repeat();
    _ambient.addListener(_publishCombined);
    _initSensors();
  }

  void _initSensors() {
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
          .listen(
        _onEvent,
        onError: (_, __) {
          _sub?.cancel();
          _sub = null;
        },
        cancelOnError: true,
      );
    } catch (_) {
      // Plugin missing (e.g. hot restart after pub add) — ambient drift only.
    }
  }

  void _onEvent(AccelerometerEvent e) {
    _sensorActive = true;
    if (!_seeded) {
      _fastX = _slowX = e.x;
      _fastY = _slowY = e.y;
      _seeded = true;
      return;
    }
    _fastX += (e.x - _fastX) * 0.22;
    _fastY += (e.y - _fastY) * 0.22;
    _slowX += (e.x - _slowX) * 0.02;
    _slowY += (e.y - _slowY) * 0.02;
    _publishCombined();
  }

  void _publishCombined() {
    final sensorX = _sensorActive
        ? (((_fastX - _slowX) / _g) * _gain).clamp(-1.0, 1.0)
        : 0.0;
    final sensorY = _sensorActive
        ? (((_fastY - _slowY) / _g) * _gain).clamp(-1.0, 1.0)
        : 0.0;

    // Figure-8 ambient path — always on so simulators still show liquid glass.
    final t = _ambient.value * 2 * math.pi;
    final ambientX = math.sin(t) * _ambientGain;
    final ambientY = math.cos(t * 0.85) * _ambientGain * 0.75;

    final next = Offset(
      (sensorX + ambientX).clamp(-1.0, 1.0),
      (sensorY + ambientY).clamp(-1.0, 1.0),
    );

    if ((next - _tilt.value).distanceSquared > 0.00002) {
      _tilt.value = next;
    }
  }

  @override
  void dispose() {
    _ambient.removeListener(_publishCombined);
    _ambient.dispose();
    _sub?.cancel();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MotionInherited(tilt: _tilt, child: widget.child);
  }
}

/// Translates [child] opposite to the device tilt for a subtle depth/parallax
/// effect. No-ops under Reduce Motion or when no sensor is present.
class PayspinParallax extends StatelessWidget {
  const PayspinParallax({
    super.key,
    required this.child,
    this.dx = 14,
    this.dy = 10,
  });

  final Widget child;

  /// Max horizontal / vertical travel in logical pixels.
  final double dx;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: PayspinMotionScope.of(context),
      child: child,
      builder: (context, tilt, ch) => Transform.translate(
        offset: Offset(-tilt.dx * dx, -tilt.dy * dy),
        child: ch,
      ),
    );
  }
}

class _MotionInherited extends InheritedWidget {
  const _MotionInherited({required this.tilt, required super.child});

  final ValueListenable<Offset> tilt;

  @override
  bool updateShouldNotify(_MotionInherited oldWidget) => tilt != oldWidget.tilt;
}
