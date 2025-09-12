import 'dart:ui';
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
  final double toolbarHeight;
  final ShapeBorder? shape;
  final bool primary;
  final Widget? flexibleSpace;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    this.elevation = 0,
    Color? backgroundColor,
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
  }) : backgroundColor = backgroundColor;

  // Transparan + blur + gradasi halus dari surface → transparan
  factory CustomAppBar.transparent({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    Color? titleColor,
    Color? iconColor,
    required BuildContext context,
    bool showGradient = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CustomAppBar(
      title: title,
      backgroundColor: isDark
          ? colors.surface.withOpacity(0.9)
          : colors.surface.withOpacity(0.7),
      elevation: 0,
      titleColor: titleColor ?? (isDark ? colors.onSurface : colors.onSurface),
      iconColor: iconColor ?? (isDark ? colors.onSurface : colors.onSurface),
      actions: actions,
      leading: leading,
      flexibleSpace: showGradient
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.surface.withOpacity(isDark ? 0.9 : 0.7),
                        colors.surface.withOpacity(isDark ? 0.7 : 0.5),
                        colors.surface.withOpacity(isDark ? 0.4 : 0.3),
                        colors.surface.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.30, 0.60, 1.0],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // Varian gelap semi-transparan
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

    return CustomAppBar(
      title: title,
      backgroundColor: backgroundColor ?? colors.surface.withOpacity(0.90),
      titleColor: titleColor ?? colors.onSurface,
      iconColor: iconColor ?? colors.onSurface,
      actions: actions,
      showBackButton: showBackButton,
      leading: leading,
      elevation: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Always use the theme's app bar background color
    final effectiveBackgroundColor =
        backgroundColor ?? theme.appBarTheme.backgroundColor ?? colors.surface;

    // Use the theme's text and icon colors
    final effectiveTitleColor =
        titleColor ??
        theme.appBarTheme.titleTextStyle?.color ??
        colors.onSurface;
    final effectiveIconColor =
        iconColor ?? theme.appBarTheme.iconTheme?.color ?? colors.onSurface;

    return AppBar(
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          color: effectiveTitleColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
      backgroundColor: effectiveBackgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: toolbarHeight,
      shape: shape,
      primary: primary,
      flexibleSpace: flexibleSpace,
      iconTheme: IconThemeData(color: effectiveIconColor, size: 24),
      actionsIconTheme: IconThemeData(color: effectiveIconColor, size: 24),
      leading:
          leading ??
          (showBackButton
              ? _buildModernBackButton(context, colors, effectiveIconColor)
              : null),
      leadingWidth: showBackButton ? 56 : null,
      actions: actions != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
            ]
          : null,
      bottom: bottom,
    );
  }

  // Tombol back modern dengan latar transparan
  Widget _buildModernBackButton(
    BuildContext context,
    ColorScheme colors,
    Color fg,
  ) {
    const bg = AppColors.transparent;

    return IconButton(
      onPressed: () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: colors.outline.withOpacity(0.3), width: 1),
      ),
      tooltip: 'Kembali',
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
