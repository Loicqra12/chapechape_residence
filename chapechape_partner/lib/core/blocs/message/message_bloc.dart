import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/message/message.dart';
import '../../models/message/conversation.dart';
import '../../services/api/message_service.dart';
import 'package:flutter/foundation.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

// Events
abstract class MessageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadConversations extends MessageEvent {}

class LoadConversation extends MessageEvent {
  final String conversationId;
  LoadConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class LoadMessages extends MessageEvent {
  final String conversationId;
  final int page;
  final int limit;

  LoadMessages(this.conversationId, {this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [conversationId, page, limit];
}

class SendMessage extends MessageEvent {
  final String conversationId;
  final String content;
  final List<MessageAttachment>? attachments;
  final String? bookingId;

  SendMessage({
    required this.conversationId,
    required this.content,
    this.attachments,
    this.bookingId,
  });

  @override
  List<Object?> get props => [conversationId, content, attachments, bookingId];
}

class UploadAttachment extends MessageEvent {
  final String conversationId;
  final String filePath;
  final String? name;

  UploadAttachment({
    required this.conversationId,
    required this.filePath,
    this.name,
  });

  @override
  List<Object?> get props => [conversationId, filePath, name];
}

class MarkAsRead extends MessageEvent {
  final String conversationId;
  MarkAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class FilterConversations extends MessageEvent {
  final bool onlyUnread;
  FilterConversations({this.onlyUnread = true});

  @override
  List<Object?> get props => [onlyUnread];
}

// States
abstract class MessageState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {}

class ConversationsLoading extends MessageState {}

class ConversationsLoaded extends MessageState {
  final List<Conversation> conversations;
  ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class ConversationLoading extends MessageState {}

class ConversationLoaded extends MessageState {
  final Conversation conversation;
  ConversationLoaded(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class MessagesLoading extends MessageState {}

class MessagesLoaded extends MessageState {
  final List<Message> messages;
  final Map<String, dynamic> pagination;
  MessagesLoaded(this.messages, this.pagination);

  @override
  List<Object?> get props => [messages, pagination];
}

class MessageSending extends MessageState {}

class MessageSent extends MessageState {
  final Message message;
  MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class AttachmentUploading extends MessageState {}

class AttachmentUploaded extends MessageState {
  final Message message;
  AttachmentUploaded(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageError extends MessageState {
  final String error;
  MessageError(this.error);

  @override
  List<Object?> get props => [error];
}

// Bloc
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageService _messageService;

  MessageBloc(this._messageService) : super(MessageInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadConversation>(_onLoadConversation);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<UploadAttachment>(_onUploadAttachment);
    on<MarkAsRead>(_onMarkAsRead);
    on<FilterConversations>(_onFilterConversations);
  }

  Future<void> _onLoadConversations(LoadConversations event, Emitter<MessageState> emit) async {
    try {
      emit(ConversationsLoading());
      final conversations = await _messageService.getConversations();
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      debugPrint('ERREUR DÉTAILLÉE de chargement des conversations: $e');
      emit(MessageError('Erreur lors du chargement des conversations: ${e.toString()}'));
    }
  }

  Future<void> _onLoadConversation(LoadConversation event, Emitter<MessageState> emit) async {
    try {
      final conversation = await _messageService.getConversation(event.conversationId);
      if (conversation != null) {
        emit(ConversationLoaded(conversation));
      } else {
        emit(MessageError('Conversation non trouvée'));
      }
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    try {
      if (state is! MessagesLoaded) {
        emit(MessagesLoading());
      }
      
      final messages = await _messageService.getMessages(
        event.conversationId,
        page: event.page,
        limit: event.limit,
      );

      if (state is MessagesLoaded && event.page > 1) {
        // Ajouter les nouveaux messages aux messages existants pour la pagination
        final currentMessages = (state as MessagesLoaded).messages;
        final updatedMessages = [...currentMessages, ...messages];
        emit(MessagesLoaded(updatedMessages, {'page': event.page, 'limit': event.limit}));
      } else {
        emit(MessagesLoaded(messages, {'page': event.page, 'limit': event.limit}));
      }
    } catch (e) {
      AppLogger.d('ERREUR DÉTAILLÉE lors du chargement des messages: $e');
      emit(MessageError('Erreur lors du chargement des messages'));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<MessageState> emit) async {
    try {
      emit(MessageSending());
      if (event.content.trim().isEmpty && (event.attachments == null || event.attachments!.isEmpty)) {
        emit(MessageError('Le message ne peut pas être vide'));
        return;
      }

      final message = await _messageService.sendMessage(
        event.conversationId,
        event.content,
        attachments: event.attachments,
      );
      
      // Émettre le succès
      emit(MessageSent(message));
      
      // Recharger les messages pour mettre à jour la liste
      add(LoadMessages(event.conversationId));
    } catch (e) {
      AppLogger.d('ERREUR DÉTAILLÉE lors de l\'envoi du message: $e');
      emit(MessageError('Erreur lors de l\'envoi du message'));
    }
  }

  Future<void> _onUploadAttachment(UploadAttachment event, Emitter<MessageState> emit) async {
    try {
      emit(AttachmentUploading());
      final attachment = await _messageService.uploadAttachment(
        event.conversationId,
        event.filePath,
        name: event.name,
      );
      // Une fois l'upload réussi, on envoie un message avec la pièce jointe
      add(SendMessage(
        conversationId: event.conversationId,
        content: '',
        attachments: [attachment],
      ));
    } catch (e) {
      AppLogger.d('ERREUR DÉTAILLÉE lors de l\'upload: $e');
      emit(MessageError('Erreur lors de l\'upload du fichier'));
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<MessageState> emit) async {
    try {
      await _messageService.markAsRead(event.conversationId);
      // Recharger les conversations pour mettre à jour les compteurs
      add(LoadConversations());
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  Future<void> _onFilterConversations(FilterConversations event, Emitter<MessageState> emit) async {
    if (state is ConversationsLoaded) {
      final currentState = state as ConversationsLoaded;
      // Note: Idéalement, on devrait garder une copie de la liste originale dans le state
      // ou refaire une requête si on veut annuler le filtre. 
      // Pour l'instant, on recharge tout si on désactive le filtre.
      if (!event.onlyUnread) {
        add(LoadConversations());
        return;
      }

      final filtered = currentState.conversations.where((c) => c.unreadCount > 0).toList();
      emit(ConversationsLoaded(filtered));
    } else {
       // Si pas encore chargé, on charge tout puis on filtre
       // (Ce cas est rare si l'UI gère bien l'état)
       add(LoadConversations()); 
    }
  }
}
