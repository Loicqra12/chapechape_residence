import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../../core/blocs/auth/auth_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  File? _profileImage;
  
  @override
  void initState() {
    super.initState();
    final partner = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).partner
        : null;
    
    _firstNameController = TextEditingController(text: partner?.firstName);
    _lastNameController = TextEditingController(text: partner?.lastName);
    _emailController = TextEditingController(text: partner?.email);
    _phoneController = TextEditingController(text: partner?.phoneNumber);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        if (kIsWeb) {
          // Pour le web, nous ne pouvons pas utiliser File
          final bytes = await image.readAsBytes();
          setState(() {
            _profileImage = null; // Car nous ne pouvons pas utiliser File sur le web
          });
          
          // Upload directement les bytes de l'image
          context.read<AuthBloc>().add(UploadProfilePictureRequested(bytes));
        } else {
          // Pour mobile, utiliser File
          setState(() {
            _profileImage = File(image.path);
          });
          
          // Upload directement l'image
          context.read<AuthBloc>().add(UploadProfilePictureRequested(_profileImage));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      // Préparer les données à mettre à jour
      final userData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
      };
      
      // Envoyer l'événement de mise à jour
      context.read<AuthBloc>().add(UpdateProfileRequested(userData: userData));
    }
  }

  String _getFullImageUrl(String url) {
    if (url.startsWith('http')) {
      // L'URL est déjà complète
      return url;
    }
    
    // Vérifier si l'URL commence par /uploads/
    if (url.startsWith('/uploads/')) {
      // C'est un chemin relatif correct, ajouter juste le domaine
      return 'http://localhost:4000${url}';
    } else if (url.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin complet
      return 'http://localhost:4000/uploads/profiles${url}';
    } else {
      // URL sans slash initial, ajouter le chemin complet avec slash
      return 'http://localhost:4000/uploads/profiles/${url}';
    }
  }

  Future<void> _uploadDocument(String type) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? document = await picker.pickImage(source: ImageSource.gallery);
      
      if (document != null) {
        if (kIsWeb) {
          // Pour le web, nous ne pouvons pas utiliser File
          final bytes = await document.readAsBytes();
          
          // Upload le document en bytes
          context.read<AuthBloc>().add(
            UploadDocumentRequested(
              documentType: type,
              documentFile: bytes,
            ),
          );
        } else {
          // Pour mobile, utiliser File
          final documentFile = File(document.path);
          
          // Upload le document
          context.read<AuthBloc>().add(
            UploadDocumentRequested(
              documentType: type,
              documentFile: documentFile,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partner = context.select((AuthBloc bloc) =>
        bloc.state is AuthAuthenticated ? (bloc.state as AuthAuthenticated).partner : null);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is AuthAuthenticated) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil mis à jour avec succès')),
          );
        } else if (state is AuthFailure) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modifier le profil'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo de profil
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                          image: _profileImage != null
                              ? DecorationImage(
                                  image: FileImage(_profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : partner?.profilePictureUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_getFullImageUrl(partner!.profilePictureUrl!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _profileImage == null && partner?.profilePictureUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: theme.colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            onTap: _pickImage,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Informations personnelles
                Text(
                  'Informations personnelles',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Ce champ est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Ce champ est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Contact
                Text(
                  'Contact',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Ce champ est requis';
                    }
                    if (!value!.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Ce champ est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Documents
                Text(
                  'Documents',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _DocumentUploadCard(
                  title: 'Carte d\'identité',
                  subtitle: 'Format JPG ou PDF, max 5MB',
                  onUpload: () => _uploadDocument('identity'),
                  isUploaded: partner?.documents?.any((doc) => doc.type == 'identity') ?? false,
                ),
                const SizedBox(height: 12),
                _DocumentUploadCard(
                  title: 'Justificatif de domicile',
                  subtitle: 'Format JPG ou PDF, max 5MB',
                  onUpload: () => _uploadDocument('address'),
                  isUploaded: partner?.documents?.any((doc) => doc.type == 'address') ?? false,
                ),
                const SizedBox(height: 12),
                _DocumentUploadCard(
                  title: 'Document professionnel',
                  subtitle: 'Format JPG ou PDF, max 5MB',
                  onUpload: () => _uploadDocument('professional'),
                  isUploaded: partner?.documents?.any((doc) => doc.type == 'professional') ?? false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onUpload;
  final bool isUploaded;

  const _DocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.onUpload,
    this.isUploaded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onUpload,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUploaded 
                      ? Colors.green.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUploaded ? Icons.check : Icons.upload_file,
                  color: isUploaded ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      isUploaded ? 'Document téléchargé' : subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUploaded ? Colors.green : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
