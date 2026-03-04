import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'documents_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import 'package:chapechape_partner/core/config/app_config_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/common/inputs/advanced_phone_input_widget.dart';
import '../../../core/models/phone_number.dart';

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
  // Variables pour le widget de téléphone avancé
  PhoneNumber? _selectedPhoneNumber;
  bool _isPhoneValid = false;
  String _phoneE164 = ''; // Conserver le numéro en format E.164 complet
  bool _isLoading = false;
  File? _profileImage;
  bool _isCompressing = false;
  double _compressionProgress = 0.0;
  bool _uploadFailed = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  @override
  void initState() {
    super.initState();
    final partner = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).partner
        : null;
    
    _firstNameController = TextEditingController(text: partner?.firstName);
    _lastNameController = TextEditingController(text: partner?.lastName);
    _emailController = TextEditingController(text: partner?.email);
    // Initialiser le numéro de téléphone pour le widget avancé
    if (partner?.phoneNumber != null && partner!.phoneNumber.isNotEmpty) {
      // Conserver la version E.164 originale
      _phoneE164 = partner.phoneNumber.startsWith('+')
          ? partner.phoneNumber
          : '+225${partner.phoneNumber}';
      
      // Parser pour l'affichage dans le widget
      _selectedPhoneNumber = PhoneNumber.parseE164(_phoneE164);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    // _phoneController supprimé car remplacé par AdvancedPhoneInputWidget
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Réinitialiser les indicateurs d'erreur
      setState(() {
        _uploadFailed = false;
        _errorMessage = '';
        _retryCount = 0;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        // On limite déjà la qualité lors de la sélection pour réduire la taille
        imageQuality: 85,
      );

      if (image != null) {
        await _processAndUploadImage(image);
      }
    } catch (e) {
      _handleImageError('Erreur lors de la sélection de l\'image', e);
    }
  }

  // Nouvelle méthode pour traiter et uploader l'image
  Future<void> _processAndUploadImage(XFile image) async {
    try {
      // Afficher un indicateur de progression
      setState(() {
        _isCompressing = true;
        _compressionProgress = 0.1; // Début du processus
      });

      if (kIsWeb) {
        await _processWebImage(image);
      } else {
        await _processMobileImage(image);
      }

      // Fin du processus
      setState(() {
        _isCompressing = false;
        _compressionProgress = 1.0;
      });
    } catch (e) {
      _handleImageError('Erreur lors du traitement de l\'image', e);
    }
  }

  // Traitement des images sur Web
  Future<void> _processWebImage(XFile image) async {
    try {
      // Pour le web, nous ne pouvons pas utiliser File
      final bytes = await image.readAsBytes();

      // Mise à jour de l'indicateur
      setState(() {
        _compressionProgress = 0.3;
      });

      // Compresser les bytes (Web)
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 75, // Qualité adaptée au contexte africain (économie de données)
        minHeight: 800,
        minWidth: 800,
      );

      setState(() {
        _profileImage = null; // Car nous ne pouvons pas utiliser File sur le web
        _compressionProgress = 0.7;
      });

      // Afficher le taux de compression
      final compressionRate = 100 - ((compressedBytes.length / bytes.length) * 100);
      _showCompressionSuccessMessage(compressionRate);

      // Upload l'image compressée
      context.read<AuthBloc>().add(UploadProfilePictureRequested(compressedBytes));
    } catch (e) {
      _handleImageError('Erreur lors du traitement de l\'image web', e);
    }
  }

  // Traitement des images sur Mobile
  Future<void> _processMobileImage(XFile image) async {
    try {
      // Pour mobile, compresser le fichier
      setState(() {
        _compressionProgress = 0.3;
      });

      // Obtenir un chemin temporaire pour l'image compressée
      final tempDir = await path_provider.getTemporaryDirectory();
      final targetPath = path.join(tempDir.path, 'compressed_${path.basename(image.path)}');

      // Compresser l'image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 75, // Qualité adaptée au contexte africain
        minHeight: 800,
        minWidth: 800,
      );

      if (compressedFile != null) {
        // Calculer le taux de compression
        final originalFile = File(image.path);
        final originalSize = await originalFile.length();
        final compressedSize = await compressedFile.length();
        final compressionRate = 100 - ((compressedSize / originalSize) * 100);

        setState(() {
          _profileImage = File(compressedFile.path);
          _compressionProgress = 0.7;
        });

        _showCompressionSuccessMessage(compressionRate);

        // Upload l'image compressée
        context.read<AuthBloc>().add(UploadProfilePictureRequested(_profileImage));
      } else {
        // Si la compression échoue, utiliser l'original
        setState(() {
          _profileImage = File(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compression impossible, utilisation de l\'image originale'),
            backgroundColor: Colors.orange,
          ),
        );
        context.read<AuthBloc>().add(UploadProfilePictureRequested(_profileImage));
      }
    } catch (e) {
      _handleImageError('Erreur lors de la compression de l\'image mobile', e);
    }
  }

  // Affiche un message de succès pour la compression
  void _showCompressionSuccessMessage(double compressionRate) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image compressée : ${compressionRate.toStringAsFixed(1)}% d\'économie'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Gestion des erreurs d'image avec retry
  void _handleImageError(String errorContext, dynamic error) {
    setState(() {
      _isCompressing = false;
      _uploadFailed = true;
      _errorMessage = '$errorContext: ${error.toString()}';
    });
    
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: _retryCount < _maxRetries ? SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: () {
            if (_errorMessage.contains('image') || _errorMessage.contains('photo')) {
              _retryImageUpload();
            } else {
              _saveProfile(); // Réessayer l'enregistrement du profil
            }
            
            // Indiquer que nous ne sommes plus en erreur
            setState(() {
              _uploadFailed = false;
            });
          },
        ) : null,
      ),
    );
  }

  // Fonction pour réessayer l'upload
  Future<void> _retryImageUpload() async {
    if (_retryCount >= _maxRetries) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre maximum de tentatives atteint. Veuillez réessayer plus tard.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _retryCount++;
      _uploadFailed = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nouvelle tentative ${_retryCount}/$_maxRetries...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    if (_profileImage != null) {
      // Réessayer avec l'image existante
      context.read<AuthBloc>().add(UploadProfilePictureRequested(_profileImage));
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
        'phone': _phoneE164.isNotEmpty ? _phoneE164 : _selectedPhoneNumber?.completeNumber ?? '',
      };
      
      // Envoyer l'événement de mise à jour
      context.read<AuthBloc>().add(UpdateProfileRequested(userData: userData));
    }
  }

  /// Construit l'URL complète d'une image de profil à partir d'un chemin relatif
  String _buildProfileImageUrl(String url) {
    // Validation et nettoyage de l'URL
    if (url.isEmpty) return '';

    // Le backend (user.model) met profileImage par défaut à "default.jpg" alors qu'aucun fichier n'existe → 404
    if (url == 'default.jpg' || url.endsWith('/default.jpg') || url.toLowerCase().contains('default.jpg')) {
      debugPrint('URL placeholder default.jpg ignorée (fichier absent sur le serveur): $url');
      return '';
    }

    // Détection des URLs problématiques
    if (url.contains('placeholder.com') || url.contains('undefined')) {
      debugPrint('URL d\'image problématique détectée: $url - Elle sera ignorée');
      return '';
    }
    
    // Si l'URL est déjà complète, la retourner telle quelle
    if (url.startsWith('http')) {
      debugPrint('URL d\'image déjà complète: $url');
      return url;
    }
    
    // Gérer les différents formats de chemins relatifs pour éviter les 404
    final String baseUrl = AppConfigManager.apiBaseUrl;
    
    // Construire l'URL complète selon différents formats de chemins possibles
    String completeUrl;
    if (url.startsWith('/uploads/')) {
      // Le chemin commence par /uploads/
      completeUrl = '$baseUrl$url';
    } else if (url.startsWith('/')) {
      // Autre chemin absolu
      completeUrl = '$baseUrl$url';
    } else if (url.startsWith('uploads/')) {
      // Chemin relatif sans slash initial
      completeUrl = '$baseUrl/$url';
    } else {
      // Autre format (probablement juste un nom de fichier)
      completeUrl = '$baseUrl/uploads/$url';
    }
    
    debugPrint('URL d\'image construite: $completeUrl');
    return completeUrl;
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
          // Pour mobile, utiliser File en convertissant XFile en File
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
            _uploadFailed = false;
            _errorMessage = '';
            _retryCount = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profil mis à jour avec succès'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is AuthFailure) {
          setState(() {
            _isLoading = false;
            _uploadFailed = true;
            _errorMessage = state.message;
          });
          
          // Message d'erreur détaillé avec possibilité de retry
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Erreur: ${state.message}')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: _retryCount < _maxRetries ? SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: () {
                  if (_errorMessage.contains('image') || _errorMessage.contains('photo')) {
                    _retryImageUpload();
                  } else {
                    _saveProfile(); // Réessayer l'enregistrement du profil
                  }
                },
              ) : null,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: const Text('Modifier le profil'),
          ),
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
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo de profil
                Center(
                  child: Column(
                    children: [
                      // Indicateur de compression
                      if (_isCompressing)
                        Column(
                          children: [
                            const Text(
                              'Optimisation de l\'image...',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: LinearProgressIndicator(
                                    value: _compressionProgress,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '${(_compressionProgress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Économie de données mobiles en cours',
                              style: TextStyle(fontSize: 10, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      Stack(
                        children: [
                          // Image avec indication visuelle en cas d'erreur
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primaryContainer,
                              border: _uploadFailed 
                                ? Border.all(color: Colors.red, width: 3) 
                                : null,
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover,
                                      colorFilter: _uploadFailed 
                                          ? ColorFilter.mode(Colors.red.withOpacity(0.2), BlendMode.srcATop)
                                          : null,
                                    )
                                  : (partner?.profilePictureUrl != null &&
                                     _buildProfileImageUrl(partner!.profilePictureUrl!).isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(_buildProfileImageUrl(partner.profilePictureUrl!)),
                                          fit: BoxFit.cover,
                                          colorFilter: _uploadFailed 
                                              ? ColorFilter.mode(Colors.red.withOpacity(0.2), BlendMode.srcATop)
                                              : null,
                                        )
                                      : null,
                            ),
                            child: _profileImage == null &&
                                (partner?.profilePictureUrl == null ||
                                 _buildProfileImageUrl(partner!.profilePictureUrl!).isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: _uploadFailed
                                        ? Colors.red
                                        : theme.colorScheme.onPrimaryContainer,
                                  )
                                : _uploadFailed
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 40,
                                        ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Informations personnelles
                Text(
                  'Informations personnelles',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => FormValidators.validateName(value, fieldName: 'Le prénom'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => FormValidators.validateName(value, fieldName: 'Le nom'),
                ),
                const SizedBox(height: 20),

                // Contact
                Text(
                  'Contact',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'exemple@domaine.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: FormValidators.validateEmail,
                ),
                const SizedBox(height: 12),
                AdvancedPhoneInputWidget(
                  label: 'Téléphone',
                  hint: 'Entrez votre numéro de téléphone',
                  initialPhoneNumber: _selectedPhoneNumber,
                  enabled: !_isLoading,
                  isRequired: true,
                  themeColor: theme.primaryColor,
                  onPhoneChanged: (PhoneNumber phoneNumber) {
                    setState(() {
                      _selectedPhoneNumber = phoneNumber;
                      _phoneE164 = phoneNumber.completeNumber;
                    });
                  },
                  onValidationChanged: (bool isValid) {
                    setState(() {
                      _isPhoneValid = isValid;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Documents
                Text(
                  'Documents',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
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
                
                const SizedBox(height: 24),
                
                // Bouton pour voir tous les documents et statuts
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DocumentsScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Voir tous les documents et statuts de vérification'),
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
