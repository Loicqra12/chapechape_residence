import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BeforeAfterGallery extends StatefulWidget {
  final List<String> images;
  final double height;
  final bool showLabels;

  const BeforeAfterGallery({
    Key? key,
    required this.images,
    this.height = 300,
    this.showLabels = true,
  }) : super(key: key);

  @override
  State<BeforeAfterGallery> createState() => _BeforeAfterGalleryState();
}

class _BeforeAfterGalleryState extends State<BeforeAfterGallery> {
  int _currentPairIndex = 0;
  double _sliderValue = 0.5;

  List<List<String>> get _imagePairs {
    final pairs = <List<String>>[];
    for (var i = 0; i < widget.images.length - 1; i += 2) {
      pairs.add([widget.images[i], widget.images[i + 1]]);
    }
    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.length < 2) {
      return const SizedBox();
    }

    final currentPair = _imagePairs[_currentPairIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabels) ...[
          Text(
            'Avant / Après',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 16),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Images container
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Image "Après"
                    Image.network(
                      currentPair[1],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Image "Avant" avec clip
                    ClipPath(
                      clipper: _BeforeAfterClipper(sliderPosition: _sliderValue),
                      child: Image.network(
                        currentPair[0],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Labels
                    if (widget.showLabels) ...[
                      _Label(
                        text: 'AVANT',
                        alignment: Alignment.centerLeft,
                        visible: _sliderValue > 0.1,
                      ),
                      _Label(
                        text: 'APRÈS',
                        alignment: Alignment.centerRight,
                        visible: _sliderValue < 0.9,
                      ),
                    ],
                    // Slider
                    Positioned.fill(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackShape: const RoundedRectSliderTrackShape(),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.3),
                        ),
                        child: Slider(
                          value: _sliderValue,
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation buttons
              if (_imagePairs.length > 1) ...[
                _NavigationButton(
                  icon: Icons.arrow_back_ios_new,
                  onPressed: _currentPairIndex > 0
                      ? () {
                          setState(() {
                            _currentPairIndex--;
                          });
                        }
                      : null,
                ),
                _NavigationButton(
                  icon: Icons.arrow_forward_ios,
                  alignment: Alignment.centerRight,
                  onPressed: _currentPairIndex < _imagePairs.length - 1
                      ? () {
                          setState(() {
                            _currentPairIndex++;
                          });
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BeforeAfterClipper extends CustomClipper<Path> {
  final double sliderPosition;

  _BeforeAfterClipper({required this.sliderPosition});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(
        0,
        0,
        size.width * sliderPosition,
        size.height,
      ));
  }

  @override
  bool shouldReclip(_BeforeAfterClipper oldClipper) {
    return sliderPosition != oldClipper.sliderPosition;
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final bool visible;

  const _Label({
    required this.text,
    required this.alignment,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Alignment alignment;

  const _NavigationButton({
    required this.icon,
    required this.onPressed,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: onPressed != null
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ),
    );
  }
}
