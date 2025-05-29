import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/promotion/promotion_bloc.dart';
import '../../../core/blocs/promotion/promotion_event.dart';
import '../../../core/blocs/promotion/promotion_state.dart';
import '../../../core/models/promotion/promotion_model.dart';
import 'promotion_item_widget.dart';

/// Widget pour afficher une liste de promotions avec gestion d'état
class PromotionsListWidget extends StatefulWidget {
  final String? residenceId;
  final PromotionType? type;
  final bool? onlyActive;
  final bool? onlyExclusive;
  final Function(PromotionModel)? onPromotionSelected;
  final Function(PromotionModel)? onPromotionEdit;
  final Function(PromotionModel)? onPromotionDelete;
  final bool showControls;
  final bool showEmptyMessage;
  final String emptyMessage;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  
  const PromotionsListWidget({
    Key? key,
    this.residenceId,
    this.type,
    this.onlyActive,
    this.onlyExclusive,
    this.onPromotionSelected,
    this.onPromotionEdit,
    this.onPromotionDelete,
    this.showControls = true,
    this.showEmptyMessage = true,
    this.emptyMessage = 'Aucune promotion trouvée',
    this.physics,
    this.padding,
  }) : super(key: key);

  @override
  State<PromotionsListWidget> createState() => _PromotionsListWidgetState();
}

class _PromotionsListWidgetState extends State<PromotionsListWidget> {
  @override
  void initState() {
    super.initState();
    
    // Charger les promotions en fonction des filtres
    _loadPromotions();
  }
  
  /// Charge les promotions selon les filtres
  void _loadPromotions() {
    if (widget.residenceId != null) {
      context.read<PromotionBloc>().add(
        LoadResidencePromotions(widget.residenceId!),
      );
    } else if (widget.onlyActive == true) {
      context.read<PromotionBloc>().add(
        const LoadActivePromotions(),
      );
    } else if (widget.onlyExclusive == true) {
      context.read<PromotionBloc>().add(
        const LoadExclusivePromotions(),
      );
    } else {
      context.read<PromotionBloc>().add(
        LoadPromotions(
          type: widget.type,
          exclusive: widget.onlyExclusive,
          residenceId: widget.residenceId,
          active: widget.onlyActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PromotionBloc, PromotionState>(
      listener: (context, state) {
        if (state is PromotionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is PromotionDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotion supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PromotionsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (state is PromotionsLoaded) {
          final promotions = state.promotions;
          
          if (promotions.isEmpty && widget.showEmptyMessage) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.emptyMessage,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PromotionBloc>().add(const RefreshPromotions());
            },
            child: ListView.builder(
              physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
              padding: widget.padding ?? const EdgeInsets.all(16),
              shrinkWrap: true,
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final promotion = promotions[index];
                return PromotionItemWidget(
                  promotion: promotion,
                  showControls: widget.showControls,
                  onTap: widget.onPromotionSelected != null
                      ? () => widget.onPromotionSelected!(promotion)
                      : null,
                  onEdit: widget.onPromotionEdit != null
                      ? () => widget.onPromotionEdit!(promotion)
                      : null,
                  onDelete: widget.onPromotionDelete != null
                      ? () => widget.onPromotionDelete!(promotion)
                      : null,
                );
              },
            ),
          );
        }
        
        // État initial ou autre état
        return const SizedBox();
      },
    );
  }
}
