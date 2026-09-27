import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/sound.dart';
import '../core/theme.dart';

/// A chunky, pressable, toy-like button with a 3D bottom edge.
class BubblyButton extends StatefulWidget {
  const BubblyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = AppColors.adventure,
    this.depth = 6,
    this.radius = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    this.width,
    this.height,
    this.sound = Sfx.tap,
    this.borderColor,
    this.gradient = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double depth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Sfx? sound;
  final Color? borderColor;
  final bool gradient;
  final String? semanticLabel;

  /// Convenience: an icon + label button.
  factory BubblyButton.label({
    Key? key,
    required String label,
    IconData? icon,
    String? emoji,
    required VoidCallback? onTap,
    Color color = AppColors.adventure,
    Color textColor = Colors.white,
    double fontSize = 22,
    double? width,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
  }) {
    return BubblyButton(
      key: key,
      onTap: onTap,
      color: color,
      width: width,
      height: height,
      padding: padding,
      semanticLabel: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emoji != null) ...[
            Text(emoji, style: KidText.emoji(fontSize * 1.05)),
            const SizedBox(width: 8),
          ],
          if (icon != null) ...[
            Icon(icon, color: textColor, size: fontSize * 1.15),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: KidText.display(fontSize, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<BubblyButton> createState() => _BubblyButtonState();
}

class _BubblyButtonState extends State<BubblyButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = enabled ? widget.color : AppColors.locked;
    final offset = _down ? widget.depth : 0.0;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapCancel: () => _setDown(false),
        onTapUp: enabled
            ? (_) {
                _setDown(false);
                if (widget.sound != null) context.read<SoundService>().play(widget.sound!);
                widget.onTap!();
              }
            : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height == null ? null : widget.height! + widget.depth,
          child: Stack(
            children: [
              // 3D edge.
              Positioned.fill(
                top: widget.depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: base.darken(0.16),
                    borderRadius: BorderRadius.circular(widget.radius),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                margin: EdgeInsets.only(top: offset, bottom: widget.depth - offset),
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: base,
                  gradient: widget.gradient
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [base.lighten(0.08), base],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: widget.borderColor == null ? null : Border.all(color: widget.borderColor!, width: 3),
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button (close, back, speaker...).
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = AppColors.ink,
    this.size = 52,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return BubblyButton(
      onTap: onTap,
      color: color,
      width: size,
      height: size,
      depth: 4,
      radius: size / 2,
      padding: EdgeInsets.zero,
      gradient: false,
      semanticLabel: semanticLabel,
      child: Icon(icon, color: iconColor, size: size * 0.55),
    );
  }
}
