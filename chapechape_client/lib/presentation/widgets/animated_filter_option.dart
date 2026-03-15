import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';

/// Widget d'option de filtre animé pour la section de recherche
class AnimatedFilterOption extends StatefulWidget {
  /// Libellé de l'option
  final String label;
  
  /// Description courte (facultative)
  final String? subtitle;
  
  /// L'icône à afficher
  final IconData icon;
  
  /// Fonction appelée lorsque l'option est sélectionnée
  final VoidCallback onTap;
  
  /// Si l'option est actuellement active/sélectionnée
  final bool isActive;
  
  /// Couleur personnalisée (utilise primaryColor par défaut)
  final Color? color;
  
  const AnimatedFilterOption({
    Key? key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.color,
  }) : super(key: key);

  @override
  State<AnimatedFilterOption> createState() => _AnimatedFilterOptionState();
}

class _AnimatedFilterOptionState extends State<AnimatedFilterOption> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    if (widget.isActive) {
      _animationController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(AnimatedFilterOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;
    final backgroundColor = widget.isActive 
        ? color.withOpacity(0.12) 
        : _isHovered 
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.12) 
            : Colors.transparent;
    
    final borderColor = widget.isActive 
        ? color 
        : _isHovered 
            ? AppTheme.dividerColor 
            : AppTheme.dividerColor;
    
    final iconColor = widget.isActive 
        ? color 
        : _isHovered 
            ? Theme.of(context).colorScheme.onSurface 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.8);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.smd),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: borderColor,
              width: widget.isActive ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (widget.isActive || _isHovered)
                BoxShadow(
                  color: color.withOpacity(widget.isActive ? 0.15 : 0.05),
                  blurRadius: widget.isActive ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône avec animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Icon(
                    widget.icon,
                    color: iconColor,
                    size: 20 + (_animationController.value * 2),
                  );
                },
              ),
              
              SizedBox(width: AppSpacing.sm),
              
              // Texte et sous-titre
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Libellé principal
                    Text(
                      widget.label,
                      style: AppTextStyles.body.copyWith(
                        color: widget.isActive ? color : Theme.of(context).colorScheme.onSurface,
                        fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    
                    // Sous-titre (si présent)
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Indicateur de sélection (visible uniquement si actif)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animationController.value,
                    child: Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm * _animationController.value),
                      child: Icon(
                        Icons.check_circle,
                        color: color,
                        size: 16 * _animationController.value,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        )
        .animate(target: widget.isActive ? 1 : 0)
        .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), curve: Curves.easeOutQuad, duration: 200.ms),
      ),
    );
  }
}
