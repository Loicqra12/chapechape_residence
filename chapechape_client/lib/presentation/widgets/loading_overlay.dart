import 'package:flutter/material.dart';

/// Widget qui affiche un indicateur de chargement par-dessus son contenu
/// lorsque isLoading est true
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color overlayColor;
  final double opacity;
  final Widget? loadingWidget;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.overlayColor = Colors.black,
    this.opacity = 0.5,
    this.loadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Le contenu principal
        child,
        
        // L'overlay de chargement
        if (isLoading)
          Positioned.fill(
            child: _buildLoadingOverlay(),
          ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: overlayColor.withOpacity(opacity),
      child: Center(
        child: loadingWidget ?? _defaultLoadingWidget(),
      ),
    );
  }

  Widget _defaultLoadingWidget() {
    return const Card(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 