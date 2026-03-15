import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Widget de champ de recherche avec animations et suggestions d'autocomplétion
class AnimatedSearchField extends StatefulWidget {
  /// Le contrôleur de texte pour le champ de recherche
  final TextEditingController controller;
  
  /// Fonction appelée lors de la soumission de recherche
  final ValueChanged<String>? onSubmitted;
  
  /// Fonction appelée à chaque changement de texte
  final ValueChanged<String>? onChanged;
  
  /// Suggestions basées sur le texte saisi
  final Future<List<String>> Function(String)? getSuggestions;
  
  /// Placeholder pour le champ de recherche
  final String hint;
  
  /// Icône de préfixe
  final IconData? prefixIcon;
  
  /// Délai avant de déclencher la recherche automatique
  final Duration autoSearchDelay;
  
  const AnimatedSearchField({
    Key? key,
    required this.controller,
    this.onSubmitted,
    this.onChanged,
    this.getSuggestions,
    this.hint = 'Rechercher une résidence',
    this.prefixIcon = Icons.search,
    this.autoSearchDelay = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<AnimatedSearchField> with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _isHovered = false;
  bool _isSearching = false;
  bool _showSuggestions = false;
  List<String> _suggestions = [];
  late FocusNode _focusNode;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _animationController.forward();
        _fetchSuggestions(widget.controller.text);
      } else {
        _animationController.reverse();
        _showSuggestions = false;
      }
    });
  }
  
  Future<void> _fetchSuggestions(String text) async {
    if (text.isEmpty || widget.getSuggestions == null) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await widget.getSuggestions!(text);
      
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showSuggestions = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ de recherche avec animations
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isFocused ? 0.15 : _isHovered ? 0.1 : 0.05),
                  blurRadius: _isFocused ? 12 : _isHovered ? 8 : 4,
                  offset: Offset(0, _isFocused ? 6 : _isHovered ? 4 : 2),
                ),
              ],
              border: Border.all(
                color: _isFocused 
                  ? AppTheme.primaryColor 
                  : Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: _isFocused 
                    ? AppTheme.primaryColor 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicateur de chargement
                    if (_isSearching)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    
                    // Bouton d'effacement
                    if (widget.controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() {
                            _showSuggestions = false;
                          });
                          if (widget.onChanged != null) {
                            widget.onChanged!('');
                          }
                        },
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        splashRadius: 20,
                      ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                }
                _fetchSuggestions(value);
              },
              onSubmitted: widget.onSubmitted,
            ),
          )
          .animate(controller: _animationController)
          .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1))
          .fadeIn(),
        ),
        
        // Zone de suggestions (conditionnellement affichée)
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.controller.text = suggestion;
                      setState(() {
                        _showSuggestions = false;
                      });
                      if (widget.onSubmitted != null) {
                        widget.onSubmitted!(suggestion);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
          .animate()
          .fade(duration: 200.ms)
          .slideY(begin: -0.1, end: 0, duration: 200.ms),
      ],
    );
  }
}
