import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/personas.dart';

/// idle | happy | cheer | sad | thinking | talking
typedef MascotMood = String;

/// Animated mascot drawn procedurally (no image assets): breathing, blinking,
/// gaze, and mood-dependent face/arms. Respects "reduce motion".
class Mascot extends StatefulWidget {
  const Mascot({super.key, required this.personaId, this.mood = 'idle', this.size = 120});

  final String personaId;
  final MascotMood mood;
  final double size;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
      _c.value = 0.3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = personaOf(widget.personaId);
    return Semantics(
      label: '${p.name} the ${p.species}, ${widget.mood}',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _MascotPainter(p, widget.mood, _c)),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter(this.p, this.mood, this.anim) : super(repaint: anim);

  final Persona p;
  final String mood;
  final Animation<double> anim;

  static const _dark = Color(0xFF3A2A1E);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final s = size.width / 200;
    canvas.save();
    canvas.scale(s);

    final fast = mood == 'cheer' ? 3.0 : 1.0;
    final bob = math.sin(2 * math.pi * t * fast) * (mood == 'sad' ? 1.5 : 3.5);
    canvas.translate(0, bob + (mood == 'cheer' ? -math.max(0, math.sin(2 * math.pi * t * 3)) * 8 : 0));

    _shadow(canvas, bob);
    if (p.id == 'fuchs') _tail(canvas, t);
    _arms(canvas, t);
    _feet(canvas);
    switch (p.id) {
      case 'fuchs':
        _foxBody(canvas);
      case 'brezel':
        _pretzelBody(canvas);
      default:
        _bearBody(canvas);
    }
    _face(canvas, t);
    _extras(canvas, t);
    canvas.restore();
  }

  Paint _fill(Color c) => Paint()..color = c;

  void _shadow(Canvas c, double bob) {
    c.drawOval(Rect.fromCenter(center: const Offset(100, 188), width: 90 - bob * 2, height: 10), _fill(Colors.black.withValues(alpha: 0.12)));
  }

  void _feet(Canvas c) {
    final f = _fill(p.id == 'brezel' ? p.body : _shade(p.body, -0.08));
    c.drawOval(Rect.fromCenter(center: const Offset(70, 178), width: 34, height: 18), f);
    c.drawOval(Rect.fromCenter(center: const Offset(130, 178), width: 34, height: 18), f);
  }

  void _arms(Canvas c, double t) {
    final wave = mood == 'cheer' || mood == 'happy' ? math.sin(2 * math.pi * t * 3) : 0.0;
    final armPaint = _fill(_shade(p.body, -0.04));
    final raise = mood == 'cheer' ? 46.0 : 0.0;
    c.drawCircle(Offset(40, 128 - raise + (mood == 'cheer' ? wave * 4 : 0)), 13, armPaint);
    final rightLift = mood == 'happy' ? 34.0 + wave * 6 : raise;
    c.drawCircle(Offset(160, 128 - rightLift), 13, armPaint);
  }

  void _tail(Canvas c, double t) {
    final sway = math.sin(2 * math.pi * t) * 6;
    final path = Path()
      ..moveTo(150, 150)
      ..cubicTo(190, 150 + sway, 205, 100, 178, 84 + sway)
      ..cubicTo(176, 118, 160, 128, 144, 128)
      ..close();
    c.drawPath(path, _fill(p.body));
    final tip = Path()
      ..moveTo(178, 84 + sway)
      ..cubicTo(190, 92, 196, 104, 194, 114)
      ..cubicTo(184, 106, 178, 98, 172, 96 + sway)
      ..close();
    c.drawPath(tip, _fill(Colors.white));
  }

  void _bearBody(Canvas c) {
    for (final x in [56.0, 144.0]) {
      c.drawCircle(Offset(x, 62), 21, _fill(p.body));
      c.drawCircle(Offset(x, 64), 11, _fill(p.belly));
    }
    c.drawOval(Rect.fromCenter(center: const Offset(100, 118), width: 132, height: 118), _fill(p.body));
    c.drawOval(Rect.fromCenter(center: const Offset(100, 150), width: 76, height: 50), _fill(p.belly));
    c.drawOval(Rect.fromCenter(center: const Offset(100, 124), width: 54, height: 40), _fill(p.belly));
  }

  void _foxBody(Canvas c) {
    for (final m in [1.0, -1.0]) {
      double x(double v) => 100 + (v - 100) * m;
      final ear = Path()
        ..moveTo(x(52), 82)
        ..lineTo(x(58), 20)
        ..lineTo(x(98), 56)
        ..close();
      c.drawPath(ear, _fill(p.body));
      final inner = Path()
        ..moveTo(x(62), 70)
        ..lineTo(x(64), 38)
        ..lineTo(x(86), 58)
        ..close();
      c.drawPath(inner, _fill(const Color(0xFF4A2E22)));
    }
    c.drawOval(Rect.fromCenter(center: const Offset(100, 118), width: 134, height: 114), _fill(p.body));
    final cheeks = Path()
      ..moveTo(34, 128)
      ..quadraticBezierTo(70, 112, 100, 150)
      ..quadraticBezierTo(130, 112, 166, 128)
      ..quadraticBezierTo(150, 168, 100, 172)
      ..quadraticBezierTo(50, 168, 34, 128)
      ..close();
    c.drawPath(cheeks, _fill(p.belly));
  }

  void _pretzelBody(Canvas c) {
    final dough = Paint()
      ..color = p.body
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    final hi = Paint()
      ..color = _shade(p.body, 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    // the classic pretzel: big loop whose arms cross and fold over the bottom
    final loop = Path()
      ..moveTo(60, 160)
      ..cubicTo(14, 120, 30, 36, 100, 36)
      ..cubicTo(170, 36, 186, 120, 140, 160);
    c.drawPath(loop, dough);
    final cross = Path()
      ..moveTo(56, 150)
      ..cubicTo(80, 120, 120, 120, 150, 70);
    final cross2 = Path()
      ..moveTo(144, 150)
      ..cubicTo(120, 120, 80, 120, 50, 70);
    c.drawPath(cross2, dough);
    c.drawPath(cross, dough);
    c.drawPath(loop, hi..strokeWidth = 5);
    // face disc
    c.drawOval(Rect.fromCenter(center: const Offset(100, 100), width: 92, height: 80), _fill(p.belly));
    // salt
    final salt = _fill(Colors.white.withValues(alpha: 0.9));
    for (final o in const [Offset(34, 92), Offset(46, 56), Offset(78, 38), Offset(124, 36), Offset(158, 60), Offset(170, 100), Offset(150, 150), Offset(52, 150), Offset(100, 142)]) {
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate((o.dx + o.dy) % 3);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 7, height: 3.5), const Radius.circular(1.5)), salt);
      c.restore();
    }
  }

  Color _shade(Color c, double dl) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + dl).clamp(0.0, 1.0)).toColor();
  }

  // ------------------------------------------------------------------- face

  void _face(Canvas c, double t) {
    final isPretzel = p.id == 'brezel';
    final eyeY = isPretzel ? 92.0 : 104.0;
    final eyeDx = isPretzel ? 18.0 : 24.0;

    // blink: quick close around t≈0.9
    final blinkT = ((t - 0.9).abs() / 0.025).clamp(0.0, 1.0);
    var open = mood == 'happy' || mood == 'cheer' ? 0.0 : blinkT; // happy = closed "^^" arcs
    if (mood == 'sad') open = math.min(open, 0.8);

    final gaze = switch (mood) {
      'thinking' => const Offset(3.5, -3.5),
      _ => Offset(math.sin(2 * math.pi * t) * 1.5, 0),
    };

    for (final sx in [-1.0, 1.0]) {
      final ex = 100 + sx * eyeDx;
      if (mood == 'happy' || mood == 'cheer') {
        final arc = Paint()
          ..color = _dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round;
        c.drawArc(Rect.fromCenter(center: Offset(ex, eyeY + 3), width: 18, height: 16), math.pi * 1.1, math.pi * 0.8, false, arc);
      } else {
        c.drawOval(Rect.fromCenter(center: Offset(ex, eyeY), width: 21, height: 24 * math.max(0.12, open)), _fill(Colors.white));
        if (open > 0.3) {
          c.drawCircle(Offset(ex + gaze.dx, eyeY + gaze.dy), 6.2, _fill(_dark));
          c.drawCircle(Offset(ex + gaze.dx + 2, eyeY + gaze.dy - 2), 1.8, _fill(Colors.white));
        }
      }
      // brows
      final brow = Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      switch (mood) {
        case 'sad':
          // worried: inner ends higher than outer ends
          c.drawLine(Offset(ex + 8 * sx, eyeY - 17), Offset(ex - 8 * sx, eyeY - 23), brow);
        case 'thinking':
          if (sx > 0) c.drawLine(Offset(ex - 8, eyeY - 19), Offset(ex + 8, eyeY - 24), brow);
        case 'idle' || 'talking':
          // stern: outer ends higher than inner ends
          if (p.id == 'fuchs') c.drawLine(Offset(ex + 8 * sx, eyeY - 22), Offset(ex - 8 * sx, eyeY - 17), brow);
      }
    }

    // cheeks
    if (mood == 'happy' || mood == 'cheer') {
      final blush = _fill(const Color(0xFFFF7A7A).withValues(alpha: 0.35));
      c.drawOval(Rect.fromCenter(center: Offset(100 - eyeDx - 10, eyeY + 18), width: 16, height: 10), blush);
      c.drawOval(Rect.fromCenter(center: Offset(100 + eyeDx + 10, eyeY + 18), width: 16, height: 10), blush);
    }

    // nose
    final noseY = isPretzel ? 108.0 : 117.0;
    if (p.id == 'fuchs') {
      c.drawOval(Rect.fromCenter(center: Offset(100, noseY), width: 14, height: 10), _fill(_dark));
    } else if (!isPretzel) {
      c.drawOval(Rect.fromCenter(center: Offset(100, noseY), width: 18, height: 12), _fill(_dark));
    }

    // mouth
    final mouthY = noseY + (isPretzel ? 8 : 12);
    final line = Paint()
      ..color = _dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case 'cheer':
        final m = Path()
          ..moveTo(84, mouthY)
          ..quadraticBezierTo(100, mouthY + 30, 116, mouthY)
          ..close();
        c.drawPath(m, _fill(const Color(0xFF7A2E2E)));
        c.drawOval(Rect.fromCenter(center: Offset(100, mouthY + 11), width: 14, height: 8), _fill(const Color(0xFFFF8A8A)));
      case 'happy':
        c.drawArc(Rect.fromCenter(center: Offset(100, mouthY), width: 30, height: 20), 0.15, math.pi - 0.3, false, line);
      case 'sad':
        c.drawArc(Rect.fromCenter(center: Offset(100, mouthY + 10), width: 24, height: 16), math.pi + 0.3, math.pi - 0.6, false, line);
      case 'thinking':
        c.drawOval(Rect.fromCenter(center: Offset(108, mouthY + 4), width: 9, height: 7), _fill(_dark));
      case 'talking':
        final h = 5 + 9 * (0.5 + 0.5 * math.sin(2 * math.pi * t * 6));
        c.drawOval(Rect.fromCenter(center: Offset(100, mouthY + 4), width: 18, height: h), _fill(const Color(0xFF7A2E2E)));
      default:
        c.drawArc(Rect.fromCenter(center: Offset(100, mouthY - 2), width: 24, height: 14), 0.25, math.pi - 0.5, false, line);
    }
  }

  void _extras(Canvas c, double t) {
    switch (mood) {
      case 'thinking':
        for (var i = 0; i < 3; i++) {
          final a = ((t * 3 - i * 0.25) % 1.0);
          c.drawCircle(Offset(150 + i * 14.0, 42 - i * 10.0), 3.5 + i * 1.6, _fill(p.accent.withValues(alpha: 0.35 + 0.65 * (math.sin(a * math.pi)).abs())));
        }
      case 'cheer':
        for (var i = 0; i < 4; i++) {
          final a = (t * 2 + i * 0.25) % 1.0;
          final o = Offset(30.0 + i * 46, 24 + 10 * math.sin(a * 2 * math.pi));
          _star(c, o, 7 + 3 * math.sin(a * math.pi), p.accent.withValues(alpha: 0.9));
        }
      case 'sad':
        final drop = (t * 1.5) % 1.0;
        c.drawOval(Rect.fromCenter(center: Offset(124, 112 + drop * 22), width: 6, height: 9), _fill(const Color(0xFF6EC1F0).withValues(alpha: 1 - drop)));
    }
  }

  void _star(Canvas c, Offset o, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * 0.4;
      final a = i * math.pi / 4 - math.pi / 2;
      final pt = Offset(o.dx + rad * math.cos(a), o.dy + rad * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, _fill(color));
  }

  @override
  bool shouldRepaint(_MascotPainter old) => old.mood != mood || old.p != p;
}
