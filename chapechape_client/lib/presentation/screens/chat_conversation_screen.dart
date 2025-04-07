import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/blocs/chat/chat_bloc.dart' as chat;
import '../../core/models/chat_model.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/api_service.dart';
import '../widgets/chat/message_bubble.dart';
import 'package:go_router/go_router.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatConversation conversation;
  final ChatService chatService;
  final ApiService apiService;
  
  const ChatConversationScreen({
    super.key,
    required this.conversation,
    required this.chatService,
    required this.apiService,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSending = false;
  String? _selectedImagePath;
  bool _isMessagingEnabled = false;

  @override
  void initState() {
    super.initState();
    // Vérifier si la messagerie est activée pour cette conversation
    _checkMessagingStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _checkMessagingStatus() async {
    try {
      if (widget.conversation.reservationId != null) {
        final response = await widget.apiService.get('reservations/${widget.conversation.reservationId}');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _isMessagingEnabled = response.data['messagingEnabled'] ?? false;
          });
        }
      } else {
        // Si pas de réservation associée, on suppose que la messagerie est activée
        setState(() {
          _isMessagingEnabled = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification du statut de messagerie: $e');
      // En cas d'erreur, on laisse quand même la messagerie active
      setState(() {
        _isMessagingEnabled = true;
      });
    }
  }

  void _scrollToBottom() {
    // Ajouter un léger délai pour permettre à Flutter de mettre à jour la liste
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isSending = true;
      });
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // Réduire la qualité pour optimiser l'envoi
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        
        // Afficher une prévisualisation temporaire dans le chat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoi de l\'image en cours...')),
        );
        
        context.read<chat.ChatBloc>().add(
          chat.SendFile(
            conversationId: widget.conversation.id,
            filePath: image.path,
            type: 'image',
          ),
        );
        
        // Faire défiler vers le bas après l'envoi
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              // On pourrait ajouter d'autres options ici (documents, audio, etc.)
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMessagingLockedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Messagerie verrouillée',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'La messagerie avec le propriétaire sera disponible après le paiement de votre réservation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.conversation.reservationId != null)
              ElevatedButton(
                onPressed: () {
                  // Rediriger vers la page de paiement
                  context.push('/payment/${widget.conversation.reservationId}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Procéder au paiement',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<chat.ChatBloc, chat.ChatState>(
      listener: (context, state) {
        // Détecte les changements d'état pour afficher des indicateurs
        if (state is chat.ChatLoaded && _isSending) {
          setState(() {
            _isSending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message envoyé avec succès')),
          );
          _scrollToBottom();
        } else if (state is chat.ChatError) {
          setState(() {
            _isSending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        if (state is chat.ChatLoading && state is! chat.ChatLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is chat.ChatError && state is! chat.ChatLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Erreur'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Text('Erreur: ${state.message}'),
            ),
          );
        }

        // Même si l'état n'est pas chargé, on peut afficher l'interface avec les données de base
        final conversation = widget.conversation;
        // Si des messages sont chargés dans l'état, on les utilise
        final messages = state is chat.ChatLoaded && state.selectedConversation != null 
            ? state.selectedConversation!.messages 
            : [];
        
        // Trouver l'autre participant
        final otherParticipant = conversation.participants.isNotEmpty 
            ? conversation.participants.firstWhere(
                (p) => p.role == 'client',
                orElse: () => conversation.participants.isNotEmpty 
                    ? conversation.participants[0] 
                    : ChatParticipant(id: '', name: 'Utilisateur', role: 'client'),
              )
            : ChatParticipant(id: '', name: 'Utilisateur', role: 'client');

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherParticipant.name),
                if (conversation.residenceName != null && conversation.residenceName!.isNotEmpty)
                  Text(
                    '🏠 ${conversation.residenceName}',
                    style: const TextStyle(fontSize: 12),
                  )
                else if (conversation.residenceId != null || conversation.reservationId != null)
                  Text(
                    conversation.reservationId != null ? '🏠 Réservation associée' : '🏠 Résidence associée',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _isMessagingEnabled 
              ? Column(
                  children: [
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(child: Text('Aucun message dans cette conversation'))
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              itemCount: messages.length + (_selectedImagePath != null && _isSending ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Si nous affichons un message temporaire en cours d'envoi
                                if (_selectedImagePath != null && _isSending && index == 0) {
                                  return const Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                
                                final adjustedIndex = _selectedImagePath != null && _isSending ? index - 1 : index;
                                if (adjustedIndex < 0 || adjustedIndex >= messages.length) return const SizedBox();
                                
                                final message = messages[adjustedIndex];
                                final isMe = message.senderId != otherParticipant.id;
                                return MessageBubble(
                                  message: message,
                                  isMe: isMe,
                                );
                              },
                            ),
                    ),
                    if (_isSending)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Envoi en cours...', style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: _isSending ? null : _showAttachmentOptions,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Écrivez un message...',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !_isSending,
                            ),
                          ),
                          IconButton(
                            icon: _isSending 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send),
                            onPressed: _isSending
                                ? null
                                : () {
                                    if (_messageController.text.isNotEmpty) {
                                      setState(() {
                                        _isSending = true;
                                      });
                                      context.read<chat.ChatBloc>().add(
                                            chat.SendMessage(
                                              conversationId: widget.conversation.id,
                                              content: _messageController.text,
                                            ),
                                          );
                                      _messageController.clear();
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : _buildMessagingLockedUI(),
        );
      },
    );
  }
}
