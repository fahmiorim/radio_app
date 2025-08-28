import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;
  final bool centerTitle;
  final double? titleSpacing;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final TextStyle? titleStyle;
  final double? toolbarHeight;
  final ShapeBorder? shape;
  final IconThemeData? iconTheme;
  final bool primary;
  final double? titleSpacingNavigation;
  final Widget? flexibleSpace;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
    this.centerTitle = true,
    this.titleSpacing,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.titleStyle,
    this.toolbarHeight = kToolbarHeight,
    this.shape,
    this.iconTheme,
    this.primary = true,
    this.titleSpacingNavigation,
    this.flexibleSpace,
  }) : super(key: key);

  // Factory constructor untuk kasus-kasus khusus
  factory CustomAppBar.transparent({
    required String title,
    Color? titleColor = Colors.white,
    Color? iconColor = Colors.white,
    List<Widget>? actions,
    Widget? leading,
  }) {
    return CustomAppBar(
      title: title,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleColor: titleColor,
      iconColor: iconColor,
      actions: actions,
      leading: leading,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Colors.transparent],
          ),
        ),
      ),
    );
  }

  factory CustomAppBar.dark({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
  }) {
    return CustomAppBar(
      title: title,
      backgroundColor: const Color(0xFF121212),
      titleColor: Colors.white,
      iconColor: Colors.white,
      actions: actions,
      showBackButton: showBackButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    return AppBar(
      title: Text(
        title,
        style:
            titleStyle ??
            TextStyle(
              color: titleColor ?? appBarTheme.titleTextStyle?.color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor:
          backgroundColor ??
          appBarTheme.backgroundColor ??
          scaffoldBackgroundColor,
      elevation: elevation,
      flexibleSpace: flexibleSpace,
      actions: actions,
      bottom: bottom,
      iconTheme:
          iconTheme ??
          IconThemeData(color: iconColor ?? appBarTheme.iconTheme?.color),
      leading: leading ?? (showBackButton ? const BackButton() : null),
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      shape: shape,
      primary: primary,
      titleTextStyle: titleStyle,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);
}
