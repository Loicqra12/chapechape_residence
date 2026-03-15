import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final Widget? action;
  final double imageHeight;
  final EdgeInsets padding;
  final bool hasAnimation;
  final IconData? fallbackIcon;

  const EmptyStateWidget({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.action,
    this.imageHeight = 220,
    this.padding = const EdgeInsets.all(40.0),
    this.hasAnimation = true,
    this.fallbackIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;
    final subtitleColor = scheme.onSurface.withOpacity(0.7);
    
    Widget content = SingleChildScrollView(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Image.asset(
            imagePath,
            height: imageHeight,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              fallbackIcon ?? Icons.image_not_supported_outlined,
              size: imageHeight * 0.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: subtitleColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          // CTA
          if (action != null) ...[
            const SizedBox(height: 28),
            action!,
          ],
        ],
      ),
    );

    if (hasAnimation) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value), // Slight scale up
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    return content;
  }
}
