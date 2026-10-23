import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'anim.dart';

/// Scales its child down while pressed and springs back — makes any card feel tappable.
class BounceTap extends StatefulWidget {
  const BounceTap({super.key, required this.child, required this.onTap, this.scale = 0.95, this.haptic = true});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 80 : 260),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Cycles through [texts] with a slide-up transition (multilingual greetings).
class RotatingText extends StatefulWidget {
  const RotatingText({super.key, required this.texts, this.style, this.interval = const Duration(milliseconds: 1700)});
  final List<String> texts;
  final TextStyle? style;
  final Duration interval;

  @override
  State<RotatingText> createState() => _RotatingTextState();
}

class _RotatingTextState extends State<RotatingText> {
  int i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() => i = (i + 1) % widget.texts.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 450),
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.45), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: c),
        ),
        child: Text(widget.texts[i], key: ValueKey(i), style: widget.style, textAlign: TextAlign.center),
      );
}

/// Reveals [text] letter by letter (speech bubbles).
class Typewriter extends StatelessWidget {
  const Typewriter({super.key, required this.text, this.style, this.charMs = 28});
  final String text;
  final TextStyle? style;
  final int charMs;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text(text, style: style);
    return TweenAnimationBuilder<int>(
      key: ValueKey(text),
      tween: IntTween(begin: 0, end: text.length),
      duration: Duration(milliseconds: charMs * text.length),
      builder: (_, n, _) => Stack(children: [
        // reserve the final size so the bubble doesn't jump while typing
        Opacity(opacity: 0, child: Text(text, style: style)),
        Text(text.substring(0, n), style: style),
      ]),
    );
  }
}

/// Gentle back-and-forth rotation (flags, flames).
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.child, this.angle = 0.08, this.period = const Duration(milliseconds: 1600), this.enabled = true});
  final Widget child;
  final double angle;
  final Duration period;
  final bool enabled;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enabled && !reduceMotion(context)) {
      _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void didUpdateWidget(Wiggle old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_c.isAnimating && !reduceMotion(context)) _c.repeat();
    if (!widget.enabled) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) => Transform.rotate(angle: math.sin(_c.value * 2 * math.pi) * widget.angle, child: c),
        child: widget.child,
      );
}

/// Flickering streak flame.
class FlameIcon extends StatelessWidget {
  const FlameIcon({super.key, this.size = 20, this.lit = true});
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final flame = Text('🔥', style: TextStyle(fontSize: size));
    if (!lit) return Opacity(opacity: 0.35, child: ColorFiltered(colorFilter: const ColorFilter.matrix(_grey), child: flame));
    return Wiggle(angle: 0.06, period: const Duration(milliseconds: 900), child: Pulse(scale: 0.08, child: flame));
  }

  static const _grey = <double>[0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0, 0, 0, 1, 0];
}

/// Soft drifting blobs and floating glyphs behind onboarding / celebration screens.
class FloatingBackground extends StatefulWidget {
  const FloatingBackground({super.key, required this.child, required this.colors, this.glyphs = const ['ä', 'ö', 'ü', 'ß', 'ç', 'ş', 'ğ', 'A', 'Z', '★']});
  final Widget child;
  final List<Color> colors;
  final List<String> glyphs;

  @override
  State<FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<FloatingBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _BlobPainter(_c.value, widget.colors, widget.glyphs, dark)),
          ),
        ),
      ),
      widget.child,
    ]);
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t, this.colors, this.glyphs, this.dark);
  final double t;
  final List<Color> colors;
  final List<String> glyphs;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final a = 2 * math.pi * t;
    for (var i = 0; i < colors.length; i++) {
      final cx = size.width * (0.2 + 0.6 * ((i * 0.37) % 1)) + math.sin(a + i * 1.7) * size.width * 0.12;
      final cy = size.height * (0.15 + 0.7 * ((i * 0.61) % 1)) + math.cos(a * 0.8 + i) * size.height * 0.08;
      final r = size.shortestSide * (0.32 + 0.08 * math.sin(a * 1.3 + i));
      final paint = Paint()
        ..shader = RadialGradient(colors: [colors[i].withValues(alpha: dark ? 0.22 : 0.30), colors[i].withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
    for (var i = 0; i < glyphs.length; i++) {
      final speed = 0.6 + (i % 3) * 0.25;
      final y = size.height * (1.1 - ((t * speed + i * 0.13) % 1.2));
      final x = size.width * ((i * 0.27 + 0.05) % 1) + math.sin(a * 2 + i) * 14;
      final tp = TextPainter(
        text: TextSpan(text: glyphs[i], style: TextStyle(fontSize: 18 + (i % 4) * 6.0, fontWeight: FontWeight.w900, color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.dark != dark || old.colors != colors;
}

/// Progress bar with the mascot riding along on top of it.
class MascotProgress extends StatelessWidget {
  const MascotProgress({super.key, required this.value, required this.mascot, this.color});
  final double value;
  final Widget mascot;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return LayoutBuilder(builder: (context, box) {
      return TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (_, v, _) => SizedBox(
          height: 44,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
            Positioned(
              left: 0,
              right: 0,
              top: 26,
              child: Container(height: 12, decoration: BoxDecoration(color: c.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8))),
            ),
            Positioned(
              left: 0,
              top: 26,
              child: Container(
                width: (box.maxWidth * v.clamp(0.0, 1.0)).clamp(12.0, box.maxWidth),
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c, Color.lerp(c, Colors.white, 0.25)!]),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(left: (box.maxWidth * v.clamp(0.0, 1.0) - 22).clamp(0.0, box.maxWidth - 40), top: -4, child: mascot),
          ]),
        ),
      );
    });
  }
}
