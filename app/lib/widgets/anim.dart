import 'dart:math' as math;

import 'package:flutter/material.dart';

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Scales a child in with a little overshoot when it first appears.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 450)});
  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final total = delay + duration;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.elasticOut),
      builder: (_, v, c) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * v, child: c)),
      child: child,
    );
  }
}

/// Fades and slides a child up; use [index] for staggered lists.
class SlideFadeIn extends StatelessWidget {
  const SlideFadeIn({super.key, required this.child, this.index = 0, this.offset = 24});
  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = math.min(index, 10) * 45;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay),
      curve: Interval(delay / (380 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, offset * (1 - v)), child: c)),
      child: child,
    );
  }
}

/// Repeating gentle "breathing" scale — for the current lesson node.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.enabled = true, this.scale = 0.06});
  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enabled && !reduceMotion(context)) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) => Transform.scale(scale: 1 + widget.scale * Curves.easeInOut.transform(_c.value), child: c),
        child: widget.child,
      );
}

/// Shakes its child whenever [trigger] changes (wrong answer).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child, required this.trigger});
  final Widget child;
  final int trigger;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) => Transform.translate(offset: Offset(math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value), 0), child: c),
        child: widget.child,
      );
}

/// Counts from [from] to [value] (XP, scores).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.from = 0, this.style, this.prefix = '', this.suffix = '', this.duration = const Duration(milliseconds: 1100)});
  final int value;
  final int from;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text('$prefix$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('$prefix${v.round()}$suffix', style: style),
    );
  }
}

/// 3D card flip between [front] and [back].
class FlipCard extends StatelessWidget {
  const FlipCard({super.key, required this.front, required this.back, required this.flipped});
  final Widget front;
  final Widget back;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return flipped ? back : front;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? 1 : 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      builder: (_, v, _) {
        final showBack = v > 0.5;
        final angle = v * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(showBack ? angle - math.pi : angle),
          child: showBack ? back : front,
        );
      },
    );
  }
}

/// One-shot confetti burst over its child.
class Confetti extends StatefulWidget {
  const Confetti({super.key, required this.child, this.play = true, this.colors});
  final Widget child;
  final bool play;
  final List<Color>? colors;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  final _rng = math.Random(7);
  late final List<_Particle> _parts = List.generate(90, (_) => _Particle.random(_rng));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.play && !reduceMotion(context) && !_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? const [Color(0xFFE8832A), Color(0xFF1F8A8A), Color(0xFFD64545), Color(0xFF3FA96B), Color(0xFFF2C14E), Color(0xFF7B4FB8)];
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => _c.value == 0 || _c.value == 1 ? const SizedBox.shrink() : CustomPaint(painter: _ConfettiPainter(_parts, _c.value, colors)),
          ),
        ),
      ),
    ]);
  }
}

class _Particle {
  _Particle(this.x, this.vx, this.vy, this.spin, this.size, this.color, this.shape);
  factory _Particle.random(math.Random r) =>
      _Particle(0.3 + r.nextDouble() * 0.4, (r.nextDouble() - 0.5) * 1.4, -0.9 - r.nextDouble() * 0.8, r.nextDouble() * 12, 5 + r.nextDouble() * 7, r.nextInt(6), r.nextInt(3));
  final double x, vx, vy, spin, size;
  final int color, shape;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.parts, this.t, this.colors);
  final List<_Particle> parts;
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const g = 2.2;
    for (final p in parts) {
      final x = (p.x + p.vx * t) * size.width;
      final y = size.height * (0.55 + p.vy * t + 0.5 * g * t * t);
      if (y > size.height + 20) continue;
      final paint = Paint()..color = colors[p.color % colors.length].withValues(alpha: (1 - t * 0.7).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      switch (p.shape) {
        case 0:
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
        case 1:
          canvas.drawCircle(Offset.zero, p.size * 0.35, paint);
        default:
          canvas.drawPath(
              Path()
                ..moveTo(0, -p.size / 2)
                ..lineTo(p.size / 2, p.size / 2)
                ..lineTo(-p.size / 2, p.size / 2)
                ..close(),
              paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Animated circular progress (daily goal, scores).
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 56, this.stroke = 7, this.color, this.child});
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(value: v, strokeWidth: stroke, color: c, backgroundColor: c.withValues(alpha: 0.15), strokeCap: StrokeCap.round)),
          ?child,
        ]),
      ),
    );
  }
}
