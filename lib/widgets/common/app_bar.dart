import 'package:flutter/material.dart';

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
  final double? toolbarHeight;
  final ShapeBorder? shape;
  final bool primary;
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
    this.toolbarHeight = kToolbarHeight,
    this.shape,
    this.primary = true,
    this.flexibleSpace,
  }) : super(key: key);

  // Factory constructor untuk kasus-kasus khusus
  factory CustomAppBar.transparent({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    Color? titleColor,
    Color? iconColor,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomAppBar(
      title: title,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleColor: titleColor ?? theme.textTheme.titleLarge?.color,
      iconColor: iconColor ?? theme.iconTheme.color,
      actions: actions,
      leading: leading,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              isDark
                  ? theme.colorScheme.surface.withOpacity(0.7)
                  : theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
      ),
    );
  }

  factory CustomAppBar.dark({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    required BuildContext context,
    Widget? leading,
    Color? backgroundColor,
    Color? titleColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CustomAppBar(
      title: title,
      backgroundColor: backgroundColor ?? colors.surface.withOpacity(0.9),
      titleColor: titleColor ?? theme.textTheme.titleLarge?.color,
      iconColor: iconColor ?? theme.iconTheme.color,
      actions: actions,
      showBackButton: showBackButton,
      leading: leading,
      elevation: isDark ? 4 : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Gunakan warna dari theme
    final effectiveTitleColor =
        titleColor ??
        (isDark ? textTheme.titleLarge?.color : colors.onPrimary) ??
        colors.onSurface;

    final effectiveIconColor =
        iconColor ??
        (isDark ? theme.iconTheme.color : colors.onPrimary) ??
        colors.onSurface;

    return AppBar(
      iconTheme: IconThemeData(
        color: effectiveIconColor,
        size: theme.iconTheme.size ?? 24,
      ),
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          color: effectiveTitleColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor:
          backgroundColor ??
          (isDark ? theme.colorScheme.surface : theme.colorScheme.primary),
      elevation: elevation,
      flexibleSpace: flexibleSpace,
      actions: actions,
      bottom: bottom,
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: effectiveIconColor,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null),
      titleSpacing: titleSpacing ?? NavigationToolbar.kMiddleSpacing,
      toolbarHeight: toolbarHeight,
      shape: shape,
      primary: primary,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);
}
