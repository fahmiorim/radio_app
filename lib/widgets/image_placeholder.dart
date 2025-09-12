import 'package:flutter/material.dart';

class ImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const ImagePlaceholder({
    super.key,
    this.icon = Icons.image,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color schemeColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      width: size,
      height: size,
      color: schemeColor.withOpacity(0.1),
      child: Icon(icon, size: size * 0.5, color: schemeColor.withOpacity(0.5)),
    );
  }
}
