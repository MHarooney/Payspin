import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A floating action button that defaults to just above the bottom nav bar and
/// can be dragged anywhere on screen. The chosen position is remembered between
/// sessions (stored as a fractional offset so it survives rotation / different
/// screen sizes).
class PayspinDraggableFab extends StatefulWidget {
  const PayspinDraggableFab({
    super.key,
    required this.child,
    this.size = 64,
    this.defaultBottomGap = 104,
    this.storageKey = 'home_fab_position',
  });

  final Widget child;
  final double size;

  /// Gap (logical px) between the FAB and the bottom edge in its default spot.
  final double defaultBottomGap;
  final String storageKey;

  @override
  State<PayspinDraggableFab> createState() => _PayspinDraggableFabState();
}

class _PayspinDraggableFabState extends State<PayspinDraggableFab> {
  /// Top-left position in the parent Stack's coordinate space. Null until the
  /// first layout pass resolves the default (or saved) position.
  Offset? _pos;
  bool _restored = false;
  double? _savedFx;
  double? _savedFy;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _savedFx = prefs.getDouble('${widget.storageKey}_fx');
    _savedFy = prefs.getDouble('${widget.storageKey}_fy');
    if (mounted) setState(() => _restored = true);
  }

  Future<void> _save(Offset pos, double maxX, double maxY) async {
    if (maxX <= 0 || maxY <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${widget.storageKey}_fx', pos.dx / maxX);
    await prefs.setDouble('${widget.storageKey}_fy', pos.dy / maxY);
  }

  @override
  Widget build(BuildContext context) {
    if (!_restored) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final maxX = constraints.maxWidth - widget.size;
        final maxY = constraints.maxHeight - widget.size;

        // Resolve the active position: saved fraction, else default (bottom
        // centre, just above the nav bar).
        _pos ??= () {
          if (_savedFx != null && _savedFy != null) {
            return Offset(
              (_savedFx! * maxX).clamp(0.0, maxX),
              (_savedFy! * maxY).clamp(0.0, maxY),
            );
          }
          final defaultY =
              constraints.maxHeight - widget.size - widget.defaultBottomGap - bottomInset;
          return Offset(
            (constraints.maxWidth - widget.size) / 2,
            defaultY.clamp(0.0, maxY),
          );
        }();

        final pos = Offset(
          _pos!.dx.clamp(0.0, maxX),
          _pos!.dy.clamp(0.0, maxY),
        );

        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _pos = Offset(
                      (pos.dx + d.delta.dx).clamp(0.0, maxX),
                      (pos.dy + d.delta.dy).clamp(0.0, maxY),
                    );
                  });
                },
                onPanEnd: (_) => _save(_pos!, maxX, maxY),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: widget.child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
