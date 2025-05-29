import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/message/message_bloc.dart';
import '../../../core/models/message/conversation.dart';
import 'package:go_router/go_router.dart';

class MessageSearchSheet extends StatefulWidget {
  const MessageSearchSheet({super.key});

  @override
  State<MessageSearchSheet> createState() => _MessageSearchSheetState();
}

class _MessageSearchSheetState extends State<MessageSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<Conversation> _allConversations = [];
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    
    // Obtenir les conversations du bloc de message
    final state = context.read<MessageBloc>().state;
    if (state is ConversationsLoaded) {
      _allConversations = state.conversations;
      _filteredConversations = _allConversations;
    }
    
    // Ajouter un écouteur pour filtrer les conversations en temps réel
    _searchController.addListener(_onSearchChanged);
    
    // Focus sur le champ de recherche automatiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _filterConversations();
    });
  }

  void _filterConversations() {
    if (_searchQuery.isEmpty) {
      _filteredConversations = _allConversations;
    } else {
      _filteredConversations = _allConversations.where((conversation) {
        // Rechercher dans le titre ou le nom des participants
        bool titleMatch = conversation.title?.toLowerCase().contains(_searchQuery) ?? false;
        
        // Rechercher dans les noms des participants
        bool participantMatch = false;
        if (conversation.participants.isNotEmpty) {
          participantMatch = conversation.participants.any(
            (participant) => participant.name.toLowerCase().contains(_searchQuery)
          );
        }
        
        // Rechercher dans le dernier message
        final lastMessage = conversation.lastMessage;
        final lastMessageMatch = lastMessage != null
            ? lastMessage.content?.toLowerCase().contains(_searchQuery) ?? false
            : false;
        
        return titleMatch || participantMatch || lastMessageMatch;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les messages...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          
          // Résultats de recherche
          if (_searchQuery.isNotEmpty) ...[
            Flexible(
              child: _filteredConversations.isEmpty
                  ? const Center(
                      child: Text('Aucun résultat trouvé'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _filteredConversations[index];
                        // Obtenir le nom du contact principal de la conversation
                        String contactName = 'Contact inconnu';
                        String initialLetter = '?';
                        
                        // Si la conversation a un titre explicite, l'utiliser
                        if (conversation.title != null && conversation.title!.isNotEmpty) {
                          contactName = conversation.title!;
                          initialLetter = contactName.substring(0, 1).toUpperCase();
                        } 
                        // Sinon utiliser le nom du premier participant qui n'est pas nous-mêmes
                        else if (conversation.participants.isNotEmpty) {
                          // Pour simplifier, utilisons le premier participant
                          contactName = conversation.participants[0].name;
                          initialLetter = contactName.substring(0, 1).toUpperCase();
                        }
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              initialLetter,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          title: Text(contactName),
                          subtitle: Text(
                            conversation.lastMessage?.content ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            // Naviguer vers la conversation sélectionnée
                            Navigator.pop(context); // Fermer la feuille de recherche
                            
                            // Charger les messages de la conversation
                            context.read<MessageBloc>().add(LoadConversation(conversation.id));
                            
                            // Naviguer vers l'écran de conversation
                            context.go('/messages/${conversation.id}');
                          },
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
