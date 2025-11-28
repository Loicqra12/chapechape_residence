import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme/app_theme.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final bool hasGlassEffect;
  final double borderRadius;
  final double elevation;
  final Border? border;

  const PremiumCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.backgroundColor,
    this.gradientColors,
    this.hasGlassEffect = false,
    this.borderRadius = 20.0,
    this.elevation = 5.0,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Default background color based on theme if not provided
    final Color effectiveBgColor = backgroundColor ?? 
        (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white);

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: hasGlassEffect ? effectiveBgColor.withOpacity(0.7) : (gradientColors == null ? effectiveBgColor : null),
        gradient: gradientColors != null && !hasGlassEffect
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: hasGlassEffect ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (hasGlassEffect) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: cardContent,
        ),
      );
    }

    // Wrap with container for margin and shadow if glass effect is on (shadow needs to be outside ClipRRect)
    if (hasGlassEffect) {
      cardContent = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
              spreadRadius: 0,
            ),
          ],
        ),
        child: cardContent,
      );
    } else if (margin != null) {
      cardContent = Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
