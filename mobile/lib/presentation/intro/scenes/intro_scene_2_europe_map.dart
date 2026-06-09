import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter_earth_globe/sphere_style.dart';

import '../../../core/constants/phone_country_codes.dart';
import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../intro_scene_scope.dart';

/// Scene 2 — a live 3D Earth with a Germany hub sending cross-border payment
/// arcs to NL/FR/ES. Rotation pauses while the scene is off-screen and freezes
/// to a static frame under reduced motion.
class IntroScene2 extends StatefulWidget {
  const IntroScene2({super.key, this.sceneIndex = 1});

  final int sceneIndex;

  @override
  State<IntroScene2> createState() => _IntroScene2State();
}

class _IntroScene2State extends State<IntroScene2>
    with SingleTickerProviderStateMixin {
  static const GlobeCoordinates _hub = GlobeCoordinates(51.16, 10.45); // DE
  static const GlobeCoordinates _europeFocus = GlobeCoordinates(48, 6);
  static const double _zoomWide = -0.3;
  static const double _zoomEurope = 0.52;

  static const List<({String iso, GlobeCoordinates coords})> _destinations = [
    (iso: 'NL', coords: GlobeCoordinates(52.13, 5.29)),
    (iso: 'FR', coords: GlobeCoordinates(46.6, 2.2)),
    (iso: 'ES', coords: GlobeCoordinates(40.0, -3.7)),
  ];

  // Brand-blended arc colour (pink → mint) for the cross-border flows.
  static final Color _arcColor = Color.lerp(
    PayspinTokens.pink,
    PayspinTokens.mint,
    0.35,
  )!;

  FlutterEarthGlobeController? _controller;
  AnimationController? _zoomAnim;
  Listenable? _offsetListenable;
  VoidCallback? _offsetListener;
  bool _reduced = false;
  bool _rotating = false;
  bool _entryPlayed = false;
  bool _connectionsAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = PayspinMotion.reduced(context);
    if (_controller == null || reduced != _reduced) {
      _reduced = reduced;
      _entryPlayed = false;
      _connectionsAdded = false;
      _setupGlobe();
    }
    _attachOffsetListener();
  }

  void _setupGlobe() {
    final controller = FlutterEarthGlobeController(
      surface: const AssetImage('assets/textures/earth_day.jpg'),
      rotationSpeed: 0.015,
      isRotating: false,
      isZoomEnabled: false,
      zoom: _zoomWide,
      showAtmosphere: true,
      atmosphereColor: PayspinTokens.mint,
      atmosphereOpacity: 0.38,
      atmosphereBlur: 20,
      atmosphereThickness: 0.05,
      surfaceLightingEnabled: true,
      lightAngle: -35,
      lightIntensity: 0.42,
      ambientLight: 0.78,
      sphereStyle: SphereStyle(
        shadowColor: PayspinTokens.mint.withValues(alpha: 0.22),
        shadowBlurSigma: 14,
        gradientOverlay: const RadialGradient(
          colors: [
            Colors.transparent,
            Color.fromARGB(6, 255, 255, 255),
            Color.fromARGB(16, 0, 0, 0),
          ],
          stops: [0.15, 0.72, 1.0],
        ),
      ),
    );

    controller.addPoint(
      Point(
        id: 'DE',
        coordinates: _hub,
        label: 'DE',
        isLabelVisible: true,
        labelBuilder: (context, point, isHovering, isVisible) =>
            _visiblePill(isVisible, point.label ?? '', PayspinTokens.pink, hub: true),
        style: const PointStyle(
          color: PayspinTokens.pink,
          size: 7,
          altitude: 0.02,
        ),
      ),
    );

    for (final destination in _destinations) {
      controller.addPoint(
        Point(
          id: destination.iso,
          coordinates: destination.coords,
          label: destination.iso,
          isLabelVisible: true,
          labelBuilder: (context, point, isHovering, isVisible) =>
              _visiblePill(isVisible, point.label ?? '', PayspinTokens.mint),
          style: const PointStyle(
            color: PayspinTokens.mint,
            size: 5,
            altitude: 0.01,
          ),
        ),
      );
    }

    controller.onLoaded = () {
      if (!mounted) return;
      _maybePlayEntry();
    };

    setState(() => _controller = controller);
  }

  void _attachOffsetListener() {
    final scope = IntroSceneScope.maybeOf(context);
    if (scope == null || _offsetListener != null) return;
    _offsetListener = _syncRotation;
    _offsetListenable = scope.offsetListenable;
    _offsetListenable!.addListener(_offsetListener!);
  }

  void _maybePlayEntry() {
    final controller = _controller;
    if (controller == null || !controller.isReady || _entryPlayed) return;
    if (IntroSceneScope.visibility(context, widget.sceneIndex) < 0.85) return;

    _entryPlayed = true;
    if (_reduced) {
      _finishStaticView(controller);
      return;
    }
    _runEntryAnimation(controller);
  }

  void _finishStaticView(FlutterEarthGlobeController controller) {
    controller.setZoom(_zoomEurope);
    controller.focusOnCoordinates(_europeFocus, animate: false);
    _addConnections(controller, animateDraw: false);
    _syncRotation();
  }

  void _runEntryAnimation(FlutterEarthGlobeController controller) {
    controller.stopRotation();
    controller.setZoom(_zoomWide);
    controller.focusOnCoordinates(
      _europeFocus,
      animate: true,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );

    _zoomAnim?.dispose();
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    final zoomTween = Tween<double>(begin: _zoomWide, end: _zoomEurope)
        .chain(CurveTween(curve: Curves.easeInOutCubic));
    _zoomAnim!.addListener(() {
      if (!mounted) return;
      controller.setZoom(zoomTween.evaluate(_zoomAnim!));
    });

    Future<void>.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted || _zoomAnim == null) return;
      await _zoomAnim!.forward();
      if (!mounted) return;
      _addConnections(controller, animateDraw: true);
      _syncRotation();
    });
  }

  void _addConnections(
    FlutterEarthGlobeController controller, {
    required bool animateDraw,
  }) {
    if (_connectionsAdded) return;
    _connectionsAdded = true;
    for (final destination in _destinations) {
      controller.addPointConnection(
        PointConnection(
          id: 'DE-${destination.iso}',
          start: _hub,
          end: destination.coords,
          isMoving: !_reduced,
          curveScale: 1.25,
          style: PointConnectionStyle(
            type: PointConnectionType.dotted,
            color: _arcColor,
            dotSize: 2.4,
            spacing: 9,
            dashAnimateTime: _reduced ? 0 : 1400,
            growthAnimationDuration: 900,
          ),
        ),
        animateDraw: animateDraw,
      );
    }
  }

  void _syncRotation() {
    final controller = _controller;
    if (controller == null || !controller.isReady || _reduced) return;

    final visible =
        IntroSceneScope.visibility(context, widget.sceneIndex) > 0.15;
    if (!visible) {
      if (_rotating) {
        _rotating = false;
        controller.stopRotation();
      }
      _zoomAnim?.stop();
      return;
    }

    if (!_entryPlayed) {
      _maybePlayEntry();
      return;
    }

    final entrySettled = _zoomAnim == null || _zoomAnim!.isCompleted;
    if (!entrySettled) return;

    if (_rotating) return;
    _rotating = true;
    controller.startRotation();
  }

  @override
  void dispose() {
    _zoomAnim?.dispose();
    if (_offsetListener != null && _offsetListenable != null) {
      _offsetListenable!.removeListener(_offsetListener!);
    }
    // The globe's own AnimationController is disposed by the FlutterEarthGlobe
    // widget; disposing the controller here would double-dispose it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        // flutter_earth_globe sizes itself from MediaQuery — override it to the
        // illustration slot so the sphere centres instead of clipping to a band.
        final side = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight),
          320.0,
        );
        final radius = side * 0.34;
        final mq = MediaQuery.of(context);

        return Center(
          child: MediaQuery(
            data: mq.copyWith(size: Size(side, side)),
            child: SizedBox(
              width: side,
              height: side,
              // Decorative only — IgnorePointer lets the intro PageView keep
              // horizontal swipes instead of the globe stealing the drag.
              child: controller == null
                  ? const SizedBox.shrink()
                  : IgnorePointer(
                      child: FlutterEarthGlobe(
                        controller: controller,
                        radius: radius,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

Widget _visiblePill(
  bool isVisible,
  String label,
  Color color, {
  bool hub = false,
}) {
  if (!isVisible) return const SizedBox.shrink();
  return _IsoPill(label: label, color: color, hub: hub);
}

class _IsoPill extends StatelessWidget {
  const _IsoPill({required this.label, required this.color, this.hub = false});

  final String label;
  final Color color;
  final bool hub;

  @override
  Widget build(BuildContext context) {
    final flag = isoToFlagEmoji(label);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hub ? 10 : 8, vertical: hub ? 6 : 5),
      decoration: BoxDecoration(
        color: const Color(0xCC15141F),
        borderRadius: BorderRadius.circular(hub ? 22 : 20),
        border: Border.all(
          color: color.withValues(alpha: hub ? 0.75 : 0.6),
          width: hub ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: hub ? 0.45 : 0.3),
            blurRadius: hub ? 16 : 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: TextStyle(fontSize: hub ? 20 : 17)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: hub ? 12 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
