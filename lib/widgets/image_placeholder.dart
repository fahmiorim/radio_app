import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_colors.dart';

class ImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const ImagePlaceholder({
    Key? key,
    this.icon = Icons.image,
    this.size = 100,
    this.color = AppColors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color.withOpacity(0.1),
      child: Icon(
        icon,
        size: size * 0.5,
        color: color.withOpacity(0.5),
      ),
    );
  }
}
