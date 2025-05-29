import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/review/review_bloc.dart';
import '../../../core/blocs/review/review_event.dart';
import '../../../core/blocs/review/review_state.dart';
import '../../../core/models/review/review_model.dart';

/// Dialogue pour répondre à un avis
class ReviewResponseDialog extends StatefulWidget {
  final ReviewModel review;

  const ReviewResponseDialog({Key? key, required this.review}) : super(key: key);

  @override
  _ReviewResponseDialogState createState() => _ReviewResponseDialogState();
}

class _ReviewResponseDialogState extends State<ReviewResponseDialog> {
  final TextEditingController _responseController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec la réponse existante, s'il y en a une
    if (widget.review.response != null) {
      _responseController.text = widget.review.response!;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is RespondingToReview) {
          setState(() {
            _isSubmitting = true;
          });
        } else if (state is ReviewResponseSuccess) {
          setState(() {
            _isSubmitting = false;
          });
          Navigator.of(context).pop(true); // Fermer le dialogue avec succès
        } else if (state is ReviewResponseFailure) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        title: Text(widget.review.response != null 
            ? 'Modifier votre réponse' 
            : 'Répondre à l\'avis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Avis du client:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.review.comment),
              const SizedBox(height: 16),
              const Text(
                'Votre réponse:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _responseController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Écrivez votre réponse ici...',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isSubmitting,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting 
                ? null 
                : () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting 
                ? null 
                : () {
                    if (_responseController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez saisir une réponse'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    context.read<ReviewBloc>().add(
                      RespondToReview(
                        reviewId: widget.review.id,
                        response: _responseController.text.trim(),
                      ),
                    );
                  },
            child: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
