import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:textara/domain/entities/ink_stroke.dart';

typedef InkStrokeCommitted = void Function(InkStroke stroke);
typedef InkStrokesErased = void Function(List<String> strokeIds);

/// Drawing overlay for reader scribble.
///
/// Stylus is preferred. Touch draws only when [tool] is an active ink tool.
/// While a stylus pointer is down, touch pointers are ignored (palm rejection).
/// When [tool] is [InkTool.off], the layer is non-interactive so scrolling works.
class InkCanvas extends StatefulWidget {
  final String bookId;
  final String locationKey;
  final InkTool tool;
  final List<InkStroke> strokes;
  final Color penColor;
  final double penWidth;
  final InkStrokeCommitted onStrokeCommitted;
  final InkStrokesErased onStrokesErased;

  const InkCanvas({
    super.key,
    required this.bookId,
    required this.locationKey,
    required this.tool,
    required this.strokes,
    required this.onStrokeCommitted,
    required this.onStrokesErased,
    this.penColor = const Color(0xFF1A1A2E),
    this.penWidth = 2.6,
  });

  @override
  State<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends State<InkCanvas> {
  final List<InkPoint> _activePoints = [];
  int? _activePointer;
  PointerDeviceKind? _activeKind;
  bool _stylusDown = false;

  bool get _drawingEnabled => widget.tool != InkTool.off;

  bool _acceptPointer(PointerDownEvent event) {
    if (!_drawingEnabled) return false;

    // Palm rejection: ignore touch while stylus is actively drawing.
    if (_stylusDown && event.kind == PointerDeviceKind.touch) {
      return false;
    }

    // Reject oversized touch contacts when reported (approximate palm).
    if (event.kind == PointerDeviceKind.touch && event.radiusMajor > 28) {
      return false;
    }

    switch (event.kind) {
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return true;
      case PointerDeviceKind.touch:
        // Finger is secondary — allowed only with an active ink tool.
        return true;
      case PointerDeviceKind.mouse:
        // Desktop/dev convenience.
        return true;
      default:
        return false;
    }
  }

  double _normalizedPressure(PointerEvent event) {
    final min = event.pressureMin;
    final max = event.pressureMax;
    if (max <= min) return 0.5;
    return ((event.pressure - min) / (max - min)).clamp(0.0, 1.0);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_acceptPointer(event)) return;
    if (_activePointer != null) return;

    _activePointer = event.pointer;
    _activeKind = event.kind;
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      _stylusDown = true;
    }

    setState(() {
      _activePoints
        ..clear()
        ..add(
          InkPoint(
            x: event.localPosition.dx,
            y: event.localPosition.dy,
            pressure: _normalizedPressure(event),
          ),
        );
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    setState(() {
      _activePoints.add(
        InkPoint(
          x: event.localPosition.dx,
          y: event.localPosition.dy,
          pressure: _normalizedPressure(event),
        ),
      );
    });
  }

  void _finishStroke() {
    if (_activePoints.length < 2) {
      _activePoints.clear();
      _activePointer = null;
      _activeKind = null;
      return;
    }

    final points = List<InkPoint>.from(_activePoints);
    _activePoints.clear();
    _activePointer = null;
    _activeKind = null;

    if (widget.tool == InkTool.eraser) {
      final victims = widget.strokes
          .where((stroke) => stroke.intersectsEraserPath(points))
          .map((stroke) => stroke.id)
          .toList();
      if (victims.isNotEmpty) {
        widget.onStrokesErased(victims);
      }
      return;
    }

    final isHighlighter = widget.tool == InkTool.highlighter;
    final stroke = InkStroke(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      locationKey: widget.locationKey,
      tool: widget.tool,
      colorValue: isHighlighter
          ? const Color(0x88FFF176).toARGB32()
          : widget.penColor.toARGB32(),
      baseWidth: isHighlighter ? widget.penWidth * 2.4 : widget.penWidth,
      points: points,
      createdAt: DateTime.now(),
    );
    widget.onStrokeCommitted(stroke);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      _stylusDown = false;
    }
    _finishStroke();
    setState(() {});
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    if (_activeKind == PointerDeviceKind.stylus ||
        _activeKind == PointerDeviceKind.invertedStylus) {
      _stylusDown = false;
    }
    _activePoints.clear();
    _activePointer = null;
    _activeKind = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final painter = _InkPainter(
      strokes: widget.strokes,
      activePoints: _activePoints,
      activeTool: widget.tool,
      activeColor: widget.tool == InkTool.highlighter
          ? const Color(0x88FFF176)
          : widget.penColor,
      activeWidth: widget.tool == InkTool.highlighter
          ? widget.penWidth * 2.4
          : widget.penWidth,
    );

    if (!_drawingEnabled) {
      return IgnorePointer(
        child: CustomPaint(painter: painter, child: const SizedBox.expand()),
      );
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: CustomPaint(painter: painter, child: const SizedBox.expand()),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<InkStroke> strokes;
  final List<InkPoint> activePoints;
  final InkTool activeTool;
  final Color activeColor;
  final double activeWidth;

  _InkPainter({
    required this.strokes,
    required this.activePoints,
    required this.activeTool,
    required this.activeColor,
    required this.activeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(
        canvas,
        stroke.points,
        color: stroke.color,
        baseWidth: stroke.baseWidth,
        translucent: stroke.tool == InkTool.highlighter,
      );
    }

    if (activePoints.length >= 2 && activeTool != InkTool.off) {
      if (activeTool == InkTool.eraser) {
        _paintStroke(
          canvas,
          activePoints,
          color: const Color(0x66FF5252),
          baseWidth: 18,
          translucent: true,
        );
      } else {
        _paintStroke(
          canvas,
          activePoints,
          color: activeColor,
          baseWidth: activeWidth,
          translucent: activeTool == InkTool.highlighter,
        );
      }
    }
  }

  void _paintStroke(
    Canvas canvas,
    List<InkPoint> points, {
    required Color color,
    required double baseWidth,
    required bool translucent,
  }) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    final avgPressure =
        points.map((p) => p.pressure).fold<double>(0, (a, b) => a + b) /
        points.length;
    final width = (baseWidth * (0.65 + avgPressure * 0.7)).clamp(1.0, 18.0);

    final paint = Paint()
      ..color = translucent ? color.withValues(alpha: color.a) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activePoints != activePoints ||
        oldDelegate.activeTool != activeTool ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeWidth != activeWidth;
  }
}
