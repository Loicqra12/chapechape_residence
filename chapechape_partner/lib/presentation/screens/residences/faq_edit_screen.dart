import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/residence/faq.dart';
import '../../../core/services/api/residence_service.dart';
import '../../widgets/common/buttons/primary_button.dart';
import '../../widgets/common/inputs/text_input.dart';

class FaqEditScreen extends StatefulWidget {
  final String residenceId;
  final List<Faq> initialFaqs;

  const FaqEditScreen({
    Key? key,
    required this.residenceId,
    required this.initialFaqs,
  }) : super(key: key);

  @override
  _FaqEditScreenState createState() => _FaqEditScreenState();
}

class _FaqEditScreenState extends State<FaqEditScreen> {
  late List<Faq> _faqs;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Copier la liste initiale pour pouvoir la modifier
    _faqs = List.from(widget.initialFaqs);
  }

  void _addNewFaq() {
    setState(() {
      _faqs.add(Faq(
        question: '',
        answer: '',
      ));
      _hasChanges = true;
    });
  }

  void _removeFaq(int index) {
    setState(() {
      _faqs.removeAt(index);
      _hasChanges = true;
    });
  }

  void _updateFaq(int index, Faq updatedFaq) {
    setState(() {
      _faqs[index] = updatedFaq;
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final residenceService = Provider.of<ResidenceService>(context, listen: false);
      final success = await residenceService.updateFaqs(
        residenceId: widget.residenceId,
        faqs: _faqs,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FAQ mise à jour avec succès')),
        );
        Navigator.pop(context, _faqs);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour de la FAQ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier les FAQ'),
        actions: [
          TextButton(
            onPressed: _hasChanges ? _saveChanges : null,
            child: Text(
              'Enregistrer',
              style: TextStyle(
                color: _hasChanges 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Questions fréquemment posées',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ajoutez des questions et réponses pour aider vos visiteurs à obtenir rapidement des informations sur votre résidence.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ..._buildFaqsList(),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: _addNewFaq,
                    text: 'Ajouter une question',
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildFaqsList() {
    return _faqs.asMap().entries.map((entry) {
      final index = entry.key;
      final faq = entry.value;
      
      return _buildFaqCard(index, faq);
    }).toList();
  }

  Widget _buildFaqCard(int index, Faq faq) {
    final questionController = TextEditingController(text: faq.question);
    final answerController = TextEditingController(text: faq.answer);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFaq(index),
                  tooltip: 'Supprimer cette question',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextInput(
              controller: questionController,
              label: 'Question',
              onChanged: (value) {
                _updateFaq(
                  index,
                  Faq(
                    question: value,
                    answer: faq.answer,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextInput(
              controller: answerController,
              label: 'Réponse',
              maxLines: 4,
              onChanged: (value) {
                _updateFaq(
                  index,
                  Faq(
                    question: faq.question,
                    answer: value,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
