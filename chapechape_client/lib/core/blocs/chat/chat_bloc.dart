import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import 'dart:async';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;

  ChatBloc({
    required ChatService chatService,
  })  : _chatService = chatService,
        super(const ChatInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<CreateConversation>(_onCreateConversation);
    on<SelectConversation>(_onSelectConversation);
  }
  
  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    
    try {
      final conversations = await _chatService.getConversations();
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      emit(ChatError('Erreur lors du chargement des conversations: $e'));
    }
  }
  
  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    // Conserver les conversations si elles sont déjà chargées
    final currentState = state;
    List<ChatConversation>? conversations;
    
    if (currentState is ConversationsLoaded) {
      conversations = currentState.conversations;
    } else if (currentState is MessagesLoaded) {
      conversations = currentState.conversations;
    }
    
    emit(const ChatLoading());
    
    try {
      final messages = await _chatService.getMessages(event.conversationId);
      
      // Marquer tous les messages comme lus
      if (event.markAsRead) {
        await _chatService.markAllAsRead(event.conversationId);
      }
      
      emit(MessagesLoaded(
        conversations: conversations ?? [],
        messages: messages,
        currentConversationId: event.conversationId,
      ));
    } catch (e) {
      emit(ChatError('Erreur lors du chargement des messages: $e'));
    }
  }
  
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Récupérer l'état actuel pour conserver les données
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      
      try {
        final newMessage = await _chatService.sendMessage(
          event.conversationId,
          event.content,
        );
        
        if (newMessage != null) {
          // Ajouter le nouveau message à la liste des messages
          final updatedMessages = List<ChatMessage>.from(currentState.messages)
            ..add(newMessage);
          
          // Mettre à jour la conversation avec le dernier message
          final updatedConversations = currentState.conversations.map((conversation) {
            if (conversation.id == event.conversationId) {
              return conversation.copyWith(
                lastMessage: newMessage,
                updatedAt: DateTime.now(),
              );
            }
            return conversation;
          }).toList();
          
          emit(MessagesLoaded(
            conversations: updatedConversations,
            messages: updatedMessages,
            currentConversationId: currentState.currentConversationId,
          ));
        }
      } catch (e) {
        emit(ChatError('Erreur lors de l\'envoi du message: $e'));
        
        // Restaurer l'état précédent
        emit(currentState);
      }
    }
  }
  
  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      
      try {
        final success = await _chatService.markMessageAsRead(event.messageId);
        
        if (success) {
          // Mettre à jour le statut du message
          final updatedMessages = currentState.messages.map((message) {
            if (message.id == event.messageId) {
              return message.copyWith(status: MessageStatus.read);
            }
            return message;
          }).toList();
          
          emit(MessagesLoaded(
            conversations: currentState.conversations,
            messages: updatedMessages,
            currentConversationId: currentState.currentConversationId,
          ));
        }
      } catch (e) {
        emit(ChatError('Erreur lors du marquage du message comme lu: $e'));
      }
    }
  }
  
  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      
      try {
        final success = await _chatService.markAllAsRead(event.conversationId);
        
        if (success) {
          // Mettre à jour le statut de tous les messages
          final updatedMessages = currentState.messages.map((message) {
            return message.copyWith(status: MessageStatus.read);
          }).toList();
          
          // Mettre à jour le compteur de messages non lus dans la conversation
          final updatedConversations = currentState.conversations.map((conversation) {
            if (conversation.id == event.conversationId) {
              return conversation.copyWith(unreadCount: 0);
            }
            return conversation;
          }).toList();
          
          emit(MessagesLoaded(
            conversations: updatedConversations,
            messages: updatedMessages,
            currentConversationId: currentState.currentConversationId,
          ));
        }
      } catch (e) {
        emit(ChatError('Erreur lors du marquage des messages: $e'));
        
        // Restaurer l'état précédent
        emit(currentState);
      }
    }
  }
  
  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    
    try {
      final newConversation = await _chatService.createConversation(event.recipientId);
      
      if (newConversation != null) {
        // Récupérer les conversations existantes si disponibles
        List<ChatConversation> existingConversations = [];
        
        if (state is ConversationsLoaded) {
          existingConversations = (state as ConversationsLoaded).conversations;
        } else if (state is MessagesLoaded) {
          existingConversations = (state as MessagesLoaded).conversations;
        }
        
        // Ajouter la nouvelle conversation
        final updatedConversations = [newConversation, ...existingConversations];
        
        emit(ConversationsLoaded(updatedConversations));
        
        // Charger les messages de la nouvelle conversation
        add(LoadMessages(newConversation.id));
      } else {
        emit(const ChatError('Impossible de créer une nouvelle conversation'));
      }
    } catch (e) {
      emit(ChatError('Erreur lors de la création de la conversation: $e'));
    }
  }
  
  void _onSelectConversation(
    SelectConversation event,
    Emitter<ChatState> emit,
  ) {
    add(LoadMessages(event.conversationId, markAsRead: true));
  }

  // Getter pour accéder au service
  ChatService get chatService => _chatService;
}