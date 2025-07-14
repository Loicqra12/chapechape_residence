import 'package:chape_core/chape_core.dart';
import 'package:flutter/material.dart';

/// Widget qui affiche le watermark ChapeChape en bas de l'écran
/// pour l'application partenaire
class PartnerWatermarkWidget extends StatelessWidget {
  final TextStyle? style;
  final bool light;
  final EdgeInsets padding;

  const PartnerWatermarkWidget({
    Key? key,
    this.style,
    this.light = false,
    this.padding = const EdgeInsets.only(bottom: 4.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ChapeWatermark().getWatermark(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // Utilise le thème de l'application Partner selon le mode (clair/sombre)
        final defaultStyle = light
            ? Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                )
            : Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                );

        return Padding(
          padding: padding,
          child: Text(
            snapshot.data!,
            style: style ?? defaultStyle,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
