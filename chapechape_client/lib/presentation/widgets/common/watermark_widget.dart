import 'package:chape_core/chape_core.dart';
import 'package:flutter/material.dart';

/// Widget qui affiche le watermark ChapeChape en bas de l'écran
class ChapeWatermarkWidget extends StatelessWidget {
  final TextStyle? style;
  final bool light;

  const ChapeWatermarkWidget({
    Key? key,
    this.style,
    this.light = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ChapeWatermark().getWatermark(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final defaultStyle = light
            ? Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                )
            : Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                );

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
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
