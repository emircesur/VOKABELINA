import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// Dart's toUpperCase() is locale-blind ("iyi" → "IYI"); Turkish needs İ / I.
String upperCase(String s, {required bool turkish}) => (turkish ? s.replaceAll('i', 'İ').replaceAll('ı', 'I') : s).toUpperCase();

/// Chunky "3D" button with a darker bottom edge that presses down on tap.
class ChunkyButton extends ConsumerStatefulWidget {
  const ChunkyButton({super.key, required this.label, required this.onPressed, this.color, this.edge, this.foreground = Colors.white, this.icon, this.compact = false, this.turkishCase});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? edge;
  final Color foreground;
  final IconData? icon;
  final bool compact;

  /// Overrides the app language for upper-casing (used before the profile exists, i.e. onboarding).
  final bool? turkishCase;

  @override
  ConsumerState<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends ConsumerState<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final appIsTurkish = ref.watch(profileProvider.select((p) => p.nativeLang == 'tr'));
    final turkish = widget.turkishCase ?? appIsTurkish;
    final base = widget.color ?? Theme.of(context).colorScheme.primary;
    final color = enabled ? base : Colors.grey.shade400;
    final edge = enabled ? (widget.edge ?? HSLColor.fromColor(base).withLightness((HSLColor.fromColor(base).lightness - 0.14).clamp(0, 1)).toColor()) : Colors.grey.shade500;
    const depth = 5.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true, // the upper-cased text would be read a second time
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          margin: EdgeInsets.only(top: _down ? depth : 0, bottom: _down ? 0 : depth),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: widget.compact ? 10 : 15),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _down ? [] : [BoxShadow(color: edge, offset: const Offset(0, depth))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, color: widget.foreground, size: 20), const SizedBox(width: 8)],
              Flexible(
                child: Text(upperCase(widget.label, turkish: turkish),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: widget.foreground, fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: widget.compact ? 13 : 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
