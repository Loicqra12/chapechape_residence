import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/favorite/favorite_bloc.dart';
import '../../../core/blocs/favorite/favorite_event.dart';
import '../../../core/blocs/favorite/favorite_state.dart';

/// Widget pour afficher un bouton de favori permettant d'ajouter ou supprimer une résidence des favoris
class FavoriteButtonWidget extends StatefulWidget {
  final String residenceId;
  final String? favoriteId;
  final bool initialIsFavorite;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  
  const FavoriteButtonWidget({
    Key? key,
    required this.residenceId,
    this.favoriteId,
    this.initialIsFavorite = false,
    this.activeColor,
    this.inactiveColor,
    this.size = 24.0,
  }) : super(key: key);

  @override
  State<FavoriteButtonWidget> createState() => _FavoriteButtonWidgetState();
}

class _FavoriteButtonWidgetState extends State<FavoriteButtonWidget> {
  late bool _isFavorite;
  String? _favoriteId;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
    _favoriteId = widget.favoriteId;
    
    // Vérifier le statut de favori au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteBloc>().add(
        CheckFavoriteStatus(residenceId: widget.residenceId),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? theme.iconTheme.color;
    
    return BlocListener<FavoriteBloc, FavoriteState>(
      listener: (context, state) {
        if (state is FavoriteStatusChecked && 
            state.residenceId == widget.residenceId) {
          setState(() {
            _isFavorite = state.isFavorite;
          });
        } else if (state is FavoriteAdded) {
          setState(() {
            _isFavorite = true;
            _favoriteId = state.favorite.id;
            _isLoading = false;
          });
        } else if (state is FavoriteRemoved &&
                  (_favoriteId == state.favoriteId || 
                  widget.residenceId == state.favoriteId)) {
          setState(() {
            _isFavorite = false;
            _favoriteId = null;
            _isLoading = false;
          });
        } else if (state is FavoriteError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: IconButton(
        icon: _isLoading
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: activeColor,
                ),
              )
            : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? activeColor : inactiveColor,
                size: widget.size,
              ),
        onPressed: _isLoading
            ? null
            : () {
                setState(() {
                  _isLoading = true;
                });
                
                if (_isFavorite) {
                  // Si c'est déjà un favori, on le supprime
                  if (_favoriteId != null) {
                    context.read<FavoriteBloc>().add(
                      RemoveFromFavorites(favoriteId: _favoriteId!),
                    );
                  } else {
                    // Si on n'a pas l'ID du favori, on utilise l'ID de la résidence
                    context.read<FavoriteBloc>().add(
                      RemoveFromFavorites(favoriteId: widget.residenceId),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  }
                } else {
                  // Si ce n'est pas un favori, on l'ajoute
                  context.read<FavoriteBloc>().add(
                    AddToFavorites(residenceId: widget.residenceId),
                  );
                }
              },
      ),
    );
  }
}
