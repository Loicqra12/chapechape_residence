import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/blocs/promotion/promotion_bloc.dart';
import '../../../core/blocs/promotion/promotion_event.dart';
import '../../../core/blocs/promotion/promotion_state.dart';
import '../../../core/models/promotion/promotion_model.dart';

/// Dialog pour créer ou modifier une promotion
class PromotionFormDialog extends StatefulWidget {
  final String residenceId;
  final PromotionModel? promotion; // Si null, c'est une création, sinon une modification
  
  const PromotionFormDialog({
    Key? key,
    required this.residenceId,
    this.promotion,
  }) : super(key: key);

  @override
  State<PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<PromotionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _discountAmountController = TextEditingController();
  
  late PromotionType _selectedType;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;
  late bool _isExclusive;
  // Monnaie par défaut
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser avec les valeurs existantes si en mode édition
    if (widget.promotion != null) {
      _titleController.text = widget.promotion!.title;
      _descriptionController.text = widget.promotion!.description;
      _discountPercentageController.text = widget.promotion!.discountPercentage.toString();
      _discountAmountController.text = widget.promotion!.discountAmount?.toString() ?? '';
      _selectedType = widget.promotion!.type;
      _startDate = widget.promotion!.startDate;
      _endDate = widget.promotion!.endDate;
      _isActive = widget.promotion!.isActive;
      _isExclusive = widget.promotion!.isExclusive;
    } else {
      // Valeurs par défaut pour la création
      _selectedType = PromotionType.discount;
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
      _isActive = true;
      _isExclusive = false;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }
  
  /// Sélectionner une date avec le sélecteur de date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Si la date de fin est avant la date de début, on l'ajuste
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }
  
  /// Soumettre le formulaire
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final discountPercentage = double.tryParse(_discountPercentageController.text) ?? 0.0;
      final discountAmount = _discountAmountController.text.isNotEmpty
          ? double.tryParse(_discountAmountController.text)
          : null;
      
      final promotion = PromotionModel(
        id: widget.promotion?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
        isExclusive: _isExclusive,
        residenceId: widget.residenceId,
        usageLimit: 100, // Valeur par défaut
        usageCount: 0, // Valeur par défaut
        imageUrl: widget.promotion?.imageUrl ?? 'https://via.placeholder.com/600x400?text=ChapeChape+Promotion', // Image placeholder externe
      );
      
      if (widget.promotion == null) {
        // Création d'une nouvelle promotion
        context.read<PromotionBloc>().add(CreatePromotion(promotion));
      } else {
        // Mise à jour d'une promotion existante
        context.read<PromotionBloc>().add(UpdatePromotion(
          promotionId: widget.promotion!.id,
          promotion: promotion,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        child: BlocListener<PromotionBloc, PromotionState>(
          listener: (context, state) {
            if (state is PromotionCreated || state is PromotionUpdated) {
              Navigator.of(context).pop(true); // Fermer le dialog avec succès
            } else if (state is PromotionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du dialog
                  Text(
                    widget.promotion == null
                        ? 'Créer une promotion'
                        : 'Modifier la promotion',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Titre de la promotion
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre',
                      hintText: 'Entrez le titre de la promotion',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Description de la promotion
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Entrez la description de la promotion',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Type de promotion
                  DropdownButtonFormField<PromotionType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type de promotion',
                      border: OutlineInputBorder(),
                    ),
                    items: PromotionType.values.map((type) {
                      return DropdownMenuItem<PromotionType>(
                        value: type,
                        child: Text(_getPromotionTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Pourcentage de réduction
                  TextFormField(
                    controller: _discountPercentageController,
                    decoration: const InputDecoration(
                      labelText: 'Pourcentage de réduction',
                      hintText: 'Ex: 15',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un pourcentage';
                      }
                      final percentage = double.tryParse(value);
                      if (percentage == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      if (percentage < 0 || percentage > 100) {
                        return 'Le pourcentage doit être entre 0 et 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Montant de réduction (optionnel)
                  TextFormField(
                    controller: _discountAmountController,
                    decoration: InputDecoration(
                      labelText: 'Montant de réduction (optionnel)',
                      hintText: 'Ex: 5000',
                      suffixText: 'CFA',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Dates de début et fin
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de début',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              dateFormat.format(_startDate),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de fin',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              dateFormat.format(_endDate),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Options actif/exclusif
                  Row(
                    children: [
                      // Option actif
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Actif'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      // Option exclusif
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Exclusif'),
                          value: _isExclusive,
                          onChanged: (value) {
                            setState(() {
                              _isExclusive = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(
                          widget.promotion == null ? 'Créer' : 'Mettre à jour',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Obtenir le libellé du type de promotion
  String _getPromotionTypeLabel(PromotionType type) {
    switch (type) {
      case PromotionType.discount:
        return 'Réduction simple';
      case PromotionType.flash:
        return 'Promotion flash';
      case PromotionType.seasonal:
        return 'Promotion saisonnière';
      case PromotionType.bundle:
        return 'Bundle d\'offres';
      case PromotionType.exclusive:
        return 'Offre exclusive';
      case PromotionType.newUser:
        return 'Nouveaux clients';
    }
  }
}
