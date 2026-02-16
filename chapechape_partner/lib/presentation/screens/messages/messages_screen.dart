import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import '../../../core/blocs/message/message_bloc.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/models/message/conversation.dart';
import '../../../core/models/message/message.dart';
import '../../../core/services/api/message_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/config/app_config_manager.dart';
import '../../widgets/layout/custom_sliver_app_bar.dart';
import '../../widgets/message/message_bubble.dart';
import '../../widgets/message/message_input.dart';
import '../../widgets/skeletons/skeletons.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ScrollController _scrollController = ScrollController();
  Conversation? _selectedConversation;
  bool _isLoadingMore = false;
  bool _isMessagingEnabled = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // État de recherche
  bool _isSearchMode = false;
  String _searchQuery = '';
  List<Message> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _scrollController.addListener(_onScroll);
    
    // Initialiser le service WebSocket
    _initializeSocketService();
  }
  
  // Initialisation du service WebSocket
  Future<void> _initializeSocketService() async {
    await _socketService.initialize();
    
    // Configuration du callback pour les nouveaux messages
    _socketService.onNewMessage = (data) {
      if (data['conversationId'] == _selectedConversation?.id) {
        // Un nouveau message a été reçu pour la conversation actuelle
        debugPrint('📩 Nouveau message reçu via WebSocket: ${data.toString()}');
        
        // Actualiser les messages
        _loadMessages(_selectedConversation!.id);
        
        // Faire défiler automatiquement jusqu'au nouveau message
        Future.delayed(Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    };
  }

  @override
  void dispose() {
    // Quitter la conversation actuelle via WebSocket
    if (_selectedConversation != null) {
      _socketService.leaveConversation(_selectedConversation!.id);
    }
    
    // Déconnecter le WebSocket
    _socketService.disconnect();
    
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadConversations() {
    context.read<MessageBloc>().add(LoadConversations());
  }

  // Méthodes de recherche
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchQuery = '';
        _searchResults.clear();
        _searchController.clear();
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty || _selectedConversation == null) {
      setState(() {
        _searchResults.clear();
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final messageService = MessageService(Dio());
      final results = await messageService.searchMessages(
        conversationId: _selectedConversation!.id,
        query: query,
      );
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint('Erreur lors de la recherche: $e');
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchResults.clear();
      _searchController.clear();
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }

  void _selectConversation(Conversation conversation) {
    setState(() {
      _selectedConversation = conversation;
      _currentPage = 1;
    });
    _loadMessages(conversation.id);
    _checkMessagingStatus(conversation);
    
    // Rejoindre la conversation via WebSocket pour recevoir les mises à jour en temps réel
    _socketService.joinConversation(conversation.id);
  }

  void _goBackToConversations() {
    // Quitter la conversation actuelle via WebSocket
    if (_selectedConversation != null) {
      _socketService.leaveConversation(_selectedConversation!.id);
    }
    
    setState(() {
      _selectedConversation = null;
    });
    _loadConversations();
  }

  void _loadMessages(String conversationId) {
    context.read<MessageBloc>().add(
      LoadMessages(
        conversationId,
        page: _currentPage,
        limit: _pageSize,
      ),
    );
  }

  void _loadMoreMessages() {
    if (!_isLoadingMore && _selectedConversation != null) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      
      context.read<MessageBloc>().add(
        LoadMessages(
          _selectedConversation!.id,
          page: _currentPage,
          limit: _pageSize,
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more messages when reaching the end of the scroll view
      if (_selectedConversation != null && !_isLoadingMore) {
        _loadMoreMessages();
      }
    }
  }
  
  // Vérifie si la messagerie est activée pour cette conversation
  void _checkMessagingStatus(Conversation conversation) async {
    if (conversation.booking != null && conversation.booking!.id.isNotEmpty) {
      try {
        final messageService = context.read<MessageService>();
        final response = await messageService.dio.get('/reservations/${conversation.booking!.id}');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _isMessagingEnabled = response.data['messagingEnabled'] ?? false;
          });
          
          if (!_isMessagingEnabled) {
            // Afficher un message pour indiquer que la messagerie n'est pas encore activée
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('La messagerie sera activée après confirmation du paiement.'),
                backgroundColor: Colors.amber[700],
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        // En cas d'erreur, on laisse la messagerie active par défaut
        setState(() {
          _isMessagingEnabled = true;
        });
      }
    } else {
      // Si pas de réservation associée, la messagerie est activée par défaut
      setState(() {
        _isMessagingEnabled = true;
      });
    }
  }

  void _sendMessage(String content, List<MessageAttachment>? attachments) {
    if (_selectedConversation != null) {
      context.read<MessageBloc>().add(
        SendMessage(
          conversationId: _selectedConversation!.id,
          content: content,
          attachments: attachments,
        ),
      );
    }
  }

  Future<void> _sendWhatsAppMessage(String content) async {
    if (_selectedConversation == null) return;

    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Envoi WhatsApp en cours...'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Utiliser l'endpoint WhatsApp du backend
      final messageService = context.read<MessageService>();
      final response = await messageService.getDio().post(
        '/messages/conversations/${_selectedConversation!.id}/whatsapp',
        data: {
          'content': content,
        },
      );

      if (response.statusCode == 200) {
        // Succès - afficher confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Message WhatsApp envoyé avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Envoyer aussi le message dans le chat interne pour traçabilité
        _sendMessage('[WhatsApp] $content', null);
      }
    } catch (e) {
      // Erreur - afficher message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Erreur envoi WhatsApp: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSMSMessage(String content) async {
    if (_selectedConversation == null) return;

    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Envoi SMS en cours...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Utiliser l'endpoint SMS du backend
      final messageService = context.read<MessageService>();
      final response = await messageService.getDio().post(
        '/sms/send',
        data: {
          'phoneNumber': '+225XXXXXXXX', // TODO: Récupérer le vrai numéro du client
          'message': content,
        },
      );

      if (response.statusCode == 200) {
        // Succès - afficher confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('SMS envoyé avec succès !'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Envoyer aussi le message dans le chat interne pour traçabilité
        _sendMessage('[SMS] $content', null);
      }
    } catch (e) {
      // Erreur - afficher message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Erreur envoi SMS: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAttachmentSelected(String filePath, String? name) async {
    if (_selectedConversation != null) {
      context.read<MessageBloc>().add(UploadAttachment(
        conversationId: _selectedConversation!.id,
        filePath: filePath,
        name: name,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedConversation == null 
          ? _buildConversationsList() 
          : _buildChatScreen(),
    );
  }

  // Interface de recherche
  Widget _buildSearchBar() {
    if (!_isSearchMode) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans les messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Effacer la recherche',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  _performSearch(value);
                } else {
                  _clearSearch();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _toggleSearchMode,
            icon: const Icon(Icons.close),
            tooltip: 'Fermer la recherche',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Résultats de recherche
  Widget _buildSearchResults() {
    if (!_isSearchMode || _searchQuery.isEmpty) return const SizedBox.shrink();
    
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucun message trouvé',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Essayez avec d\'autres mots-clés',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final message = _searchResults[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.yellow[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Résultat ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationsList() {
    return CustomScrollView(
      slivers: [
        CustomSliverAppBar(
          title: 'Messages',
          showLogo: true,
          actions: [
            IconButton(
              icon: SvgPicture.asset(
                AppIcons.search,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcATop,
                ),
              ),
              onPressed: _toggleSearchMode,
            ),
            IconButton(
              icon: SvgPicture.asset(
                AppIcons.unread,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcATop,
                ),
              ),
              onPressed: () {
                context.read<MessageBloc>().add(LoadConversations());
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                AppIcons.support,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcATop,
                ),
              ),
              onPressed: () {
                // TODO: Implement support
              },
            ),
          ],
        ),
        BlocBuilder<MessageBloc, MessageState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const SliverFillRemaining(
                child: MessageListSkeleton(itemCount: 5),
              );
            }

            if (state is ConversationsLoaded) {
              final conversations = state.conversations;
              if (conversations.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyMessagesState(context),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final conversation = conversations[index];
                    final client = conversation.participants.firstWhere(
                      (p) => p.role == 'client',
                      orElse: () => ConversationParticipant(
                        id: '',
                        name: 'Client',
                        role: 'client',
                        isActive: false,
                      ),
                    );

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.secondary,
                            backgroundImage: client.avatar != null
                                ? NetworkImage(AppConfigManager.getProfileImageUrl(client.avatar!))
                                : null,
                            child: client.avatar == null
                                ? Text(
                                    client.name.characters.first.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          if (client.isActive)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        conversation.title ?? client.name,
                        style: AppTextStyles.regularBold.copyWith(
                          color: conversation.unreadCount > 0
                              ? AppColors.secondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (conversation.lastMessage != null)
                            Text(
                              conversation.lastMessage!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.small.copyWith(
                                color: conversation.unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          if (conversation.residenceName != null && conversation.residenceName!.isNotEmpty)
                            Text(
                              '🏠 ${conversation.residenceName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(conversation.updatedAt),
                            style: AppTextStyles.tiny.copyWith(
                              color: conversation.unreadCount > 0
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: AppTextStyles.tiny.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _selectConversation(conversation),
                    );
                  },
                  childCount: conversations.length,
                ),
              );
            }

            return const SliverFillRemaining(
              child: Center(
                child: Text('Une erreur est survenue'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChatScreen() {
    return Scaffold(
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),
          // Interface de chat ou résultats de recherche
          Expanded(
            child: _isSearchMode && _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildChatInterface(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _goBackToConversations,
          tooltip: 'Retour aux conversations',
        ),
        title: Row(
          children: [
            if (_selectedConversation != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary,
                backgroundImage: _getClientAvatar(),
                child: _getClientAvatar() == null
                    ? Text(
                        _getClientName().characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getClientName(),
                      style: AppTextStyles.regularBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        if (_selectedConversation?.residenceName != null && _selectedConversation!.residenceName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '🏠 ${_selectedConversation!.residenceName}',
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Text(
                          _isClientActive() ? 'En ligne' : 'Hors ligne',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          if (_selectedConversation?.booking != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.secondary.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getBookingStatusIcon(_selectedConversation!.booking!.status),
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Réservation: ${_getBookingStatusText(_selectedConversation!.booking!.status)}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: BlocBuilder<MessageBloc, MessageState>(
              builder: (context, state) {
                if (state is MessagesLoading && _currentPage == 1) {
                  return const MessageListSkeleton(itemCount: 4);
                }

                if (state is MessagesLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return _buildEmptyChatState(context);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final message = messages[index];
                      final isMe = message.senderId == context.read<MessageService>().currentUserId;
                      
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  );
                }

                return const Center(
                  child: Text('Une erreur est survenue'),
                );
              },
            ),
          ),
                  MessageInput(
            onSendMessage: _sendMessage,
            onAttachmentSelected: _handleAttachmentSelected,
            onSendWhatsApp: _sendWhatsAppMessage,
            onSendSMS: _sendSMSMessage,
            enabled: _isMessagingEnabled,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 2) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      final weekday = switch (time.weekday) {
        1 => 'Lundi',
        2 => 'Mardi',
        3 => 'Mercredi',
        4 => 'Jeudi',
        5 => 'Vendredi',
        6 => 'Samedi',
        7 => 'Dimanche',
        _ => '',
      };
      return weekday;
    } else {
      return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
    }
  }

  IconData _getBookingStatusIcon(String status) {
    return switch (status) {
      'pending' => Icons.schedule,
      'confirmed' => Icons.check_circle,
      'cancelled' => Icons.cancel,
      'completed' => Icons.done_all,
      'refunded' => Icons.monetization_on,
      _ => Icons.question_mark,
    };
  }

  String _getBookingStatusText(String status) {
    return switch (status) {
      'pending' => 'En attente',
      'confirmed' => 'Confirmée',
      'cancelled' => 'Annulée',
      'completed' => 'Terminée',
      'refunded' => 'Remboursée',
      _ => 'Inconnue',
    };
  }

  ImageProvider? _getClientAvatar() {
    if (_selectedConversation == null) return null;
    final client = _selectedConversation!.participants.firstWhere(
      (p) => p.role == 'client',
      orElse: () => ConversationParticipant(
        id: '',
        name: 'Client',
        role: 'client',
        isActive: false,
      ),
    );
    return client.avatar != null ? NetworkImage(client.avatar!) : null;
  }

  String _getClientName() {
    if (_selectedConversation == null) return 'Discussion';
    final client = _selectedConversation!.participants.firstWhere(
      (p) => p.role == 'client',
      orElse: () => ConversationParticipant(
        id: '',
        name: 'Client',
        role: 'client',
        isActive: false,
      ),
    );
    return _selectedConversation?.title ?? client.name;
  }

  bool _isClientActive() {
    if (_selectedConversation == null) return false;
    final client = _selectedConversation!.participants.firstWhere(
      (p) => p.role == 'client',
      orElse: () => ConversationParticipant(
        id: '',
        name: 'Client',
        role: 'client',
        isActive: false,
      ),
    );
    return client.isActive;
  }

  Widget _buildEmptyMessagesState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Illustration des messages
          Image.asset(
            'assets/images/illustrations/empty_message.png',
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.width * 0.85,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback vers l'icône si l'image ne charge pas
              return Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune conversation',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Vous n\'avez pas encore de messages. Les conversations avec vos clients apparaîtront ici.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Illustration des messages
          Image.asset(
            'assets/images/illustrations/empty_message.png',
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.width * 0.85,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback vers l'icône si l'image ne charge pas
              return Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun message',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Commencez la conversation en envoyant un message.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
