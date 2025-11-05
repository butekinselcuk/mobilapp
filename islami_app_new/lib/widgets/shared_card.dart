import 'package:flutter/material.dart';

class SharedCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const SharedCard({
    Key? key,
    required this.child,
    this.color,
    this.elevation = 2,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: color ?? Theme.of(context).cardColor,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}