// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import '../widgets/skeleton/app_header_skeleton.dart';

class AppHeader extends StatelessWidget {
  final bool isLoading;
  const AppHeader({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppHeaderSkeleton(); // tampilkan skeleton
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/logo-white.png', height: 50),
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage("assets/user4.jpg"),
            ),
          ),
        ),
      ],
    );
  }
}
