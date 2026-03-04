import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import '../../../core/models/partner/partner_model.dart';
import '../../widgets/documents/document_status_card.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<PartnerDocument> _documents = [];
  
  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }
  
  void _loadDocuments() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final partner = authState.partner;
      setState(() {
        _documents = partner.documents ?? [];
      });
    }
  }

  Future<void> _uploadDocument(String type) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Utiliser FilePicker pour sélectionner un document
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Gérer le document selon la plateforme
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          context.read<AuthBloc>().add(
            UploadDocumentRequested(
              documentType: type,
              documentBytes: bytes,
              fileName: result.files.first.name,
            ),
          );
        }
      } else {
        final path = result.files.first.path;
        if (path != null) {
          final file = File(path);
          context.read<AuthBloc>().add(
            UploadDocumentRequested(
              documentType: type,
              documentFile: file,
              fileName: result.files.first.name,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors de l\'upload: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is AuthAuthenticated) {
          final wasLoading = _isLoading;
          setState(() {
            _isLoading = false;
            _documents = state.partner.documents ?? [];
          });
          if (wasLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document téléchargé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (state is AuthFailure) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Documents'),
          actions: [
            IconButton(
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                side: BorderSide(color: Colors.grey.shade300),
                backgroundColor: Colors.transparent,
              ),
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Forcer un rafraîchissement du profil pour obtenir les derniers documents
                context.read<AuthBloc>().add(AuthCheckRequested());
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(theme),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDocumentDialog,
          icon: const Icon(Icons.add),
          label: const Text('Nouveau document'),
        ),
      ),
    );
  }
  
  Widget _buildContent(ThemeData theme) {
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun document téléchargé',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des documents pour compléter votre vérification',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerificationStatus(theme),
          const SizedBox(height: 24),
          
          Text(
            'Documents soumis',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Liste des documents
          ..._documents.map((document) => DocumentStatusCard(
            document: document,
            onReupload: document.status == 'rejected' 
                ? () => _uploadDocument(document.type) 
                : null,
          )),
        ],
      ),
    );
  }
  
  Widget _buildVerificationStatus(ThemeData theme) {
    // Déterminer le statut global en fonction des documents
    bool hasAllRequiredDocs = _hasAllRequiredDocuments();
    bool allDocsApproved = _allDocumentsApproved();
    bool hasRejectedDocs = _hasRejectedDocuments();
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (!hasAllRequiredDocs) {
      statusColor = Colors.orange;
      statusText = 'Documents manquants';
      statusIcon = Icons.warning_amber;
    } else if (hasRejectedDocs) {
      statusColor = Colors.red;
      statusText = 'Documents rejetés';
      statusIcon = Icons.error_outline;
    } else if (allDocsApproved) {
      statusColor = Colors.green;
      statusText = 'Vérification complète';
      statusIcon = Icons.verified;
    } else {
      statusColor = Theme.of(context).colorScheme.primary;
      statusText = 'En attente de vérification';
      statusIcon = Icons.pending_actions;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Statut de vérification',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: theme.textTheme.titleSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildVerificationProgress(),
          const SizedBox(height: 12),
          Text(
            _getVerificationMessage(hasAllRequiredDocs, allDocsApproved, hasRejectedDocs),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildVerificationProgress() {
    const requiredDocs = ['identity', 'address', 'professional'];
    int submitted = 0;
    int approved = 0;
    
    for (final type in requiredDocs) {
      final doc = _documents.firstWhereOrNull((doc) => doc.type == type);
      if (doc != null) {
        submitted++;
        if (doc.status == 'approved') {
          approved++;
        }
      }
    }
    
    // Utiliser la variable approved pour calculer un pourcentage de vérification
    double progress = submitted > 0 ? approved / requiredDocs.length : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progression: $submitted/${requiredDocs.length}'),
            Text('${(progress * 100).toInt()}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          color: progress == 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
  
  void _showAddDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez le type de document à télécharger'),
            const SizedBox(height: 16),
            _buildDocumentTypeButton(
              'Carte d\'identité',
              Icons.badge,
              () {
                Navigator.pop(context);
                _uploadDocument('identity');
              },
              _documents.any((doc) => doc.type == 'identity'),
            ),
            _buildDocumentTypeButton(
              'Justificatif de domicile',
              Icons.home,
              () {
                Navigator.pop(context);
                _uploadDocument('address');
              },
              _documents.any((doc) => doc.type == 'address'),
            ),
            _buildDocumentTypeButton(
              'Document professionnel',
              Icons.business,
              () {
                Navigator.pop(context);
                _uploadDocument('professional');
              },
              _documents.any((doc) => doc.type == 'professional'),
            ),
            _buildDocumentTypeButton(
              'Autre document',
              Icons.description,
              () {
                Navigator.pop(context);
                _showCustomDocumentTypeDialog();
              },
              false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentTypeButton(
    String title, 
    IconData icon, 
    VoidCallback onPressed, 
    bool alreadyUploaded,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: alreadyUploaded ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Un document "$title" existe déjà. Vous pouvez le remplacer en le sélectionnant dans la liste.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        } : onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: alreadyUploaded ? theme.colorScheme.surface : theme.colorScheme.primary,
          foregroundColor: alreadyUploaded ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
  
  void _showCustomDocumentTypeDialog() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Veuillez préciser le type de document que vous souhaitez télécharger',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Type de document',
                hintText: 'Ex: Diplôme, licence, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final type = textController.text.trim();
              if (type.isNotEmpty) {
                Navigator.pop(context);
                _uploadDocument(type.toLowerCase().replaceAll(' ', '_'));
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
  
  // Méthodes pour vérifier le statut des documents
  bool _hasAllRequiredDocuments() {
    const requiredTypes = ['identity', 'address', 'professional'];
    return requiredTypes.every(
      (type) => _documents.any((doc) => doc.type == type),
    );
  }
  
  bool _allDocumentsApproved() {
    if (_documents.isEmpty) return false;
    
    const requiredTypes = ['identity', 'address', 'professional'];
    return requiredTypes.every(
      (type) => _documents.any(
        (doc) => doc.type == type && doc.status == 'approved',
      ),
    );
  }
  
  bool _hasRejectedDocuments() {
    return _documents.any((doc) => doc.status == 'rejected');
  }
  
  String _getVerificationMessage(bool hasAll, bool allApproved, bool hasRejected) {
    if (!hasAll) {
      return 'Veuillez télécharger tous les documents requis pour compléter votre vérification.';
    } else if (hasRejected) {
      return 'Certains documents ont été rejetés. Veuillez les soumettre à nouveau.';
    } else if (allApproved) {
      return 'Félicitations! Votre compte est entièrement vérifié.';
    } else {
      return 'Vos documents sont en cours d\'examen par notre équipe. Nous vous notifierons une fois la vérification terminée.';
    }
  }
}

// Extension pour la méthode firstWhereOrNull
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
