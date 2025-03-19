import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';

part 'chat_bloc.freezed.dart';
part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;

  ChatBloc({
    required ChatService chatService,
  })  : _chatService = chatService,
        super(const ChatState.initial()) {
    on<LoadConversations>(_onLoadConversations);
    on<CreateConversation>(_onCreateConversation);
    on<SendMessage>(_onSendMessage);
    on<SendFile>(_onSendFile);
    on<SendImage>(_onSendImage);
    on<LoadMessages>(_onLoadMessages);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatState.loading());
      final conversations = await _chatService.getConversations();
      emit(ChatState.loaded(conversations: conversations));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatState.loading());
      final conversation = await _chatService.createConversation(
        userId: event.userId,
        residenceId: event.residenceId,
        reservationId: event.reservationId,
      );
      final conversations = await _chatService.getConversations();
      emit(ChatState.loaded(
        conversations: conversations,
        selectedConversation: conversation,
      ));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      final message = await _chatService.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
      );

      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          return conversation.copyWith(
            messages: [...conversation.messages, message],
          );
        }
        return conversation;
      }).toList();

      final selectedConversation = updatedConversations.firstWhere(
        (c) => c.id == event.conversationId,
        orElse: () => currentState.selectedConversation!,
      );

      emit(ChatState.loaded(
        conversations: updatedConversations,
        selectedConversation: selectedConversation,
      ));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onSendFile(
    SendFile event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      final message = await _chatService.sendFile(
        conversationId: event.conversationId,
        filePath: event.filePath,
        type: event.type,
      );

      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          return conversation.copyWith(
            messages: [...conversation.messages, message],
          );
        }
        return conversation;
      }).toList();

      final selectedConversation = updatedConversations.firstWhere(
        (c) => c.id == event.conversationId,
        orElse: () => currentState.selectedConversation!,
      );

      emit(ChatState.loaded(
        conversations: updatedConversations,
        selectedConversation: selectedConversation,
      ));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onSendImage(
    SendImage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      final message = await _chatService.sendImage(
        conversationId: event.conversationId,
        imagePath: event.imagePath,
      );

      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          return conversation.copyWith(
            messages: [...conversation.messages, message],
          );
        }
        return conversation;
      }).toList();

      final selectedConversation = updatedConversations.firstWhere(
        (c) => c.id == event.conversationId,
        orElse: () => currentState.selectedConversation!,
      );

      emit(ChatState.loaded(
        conversations: updatedConversations,
        selectedConversation: selectedConversation,
      ));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      final messages = await _chatService.getMessages(event.conversationId);

      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          return conversation.copyWith(messages: messages);
        }
        return conversation;
      }).toList();

      final selectedConversation = updatedConversations.firstWhere(
        (c) => c.id == event.conversationId,
        orElse: () => currentState.selectedConversation!,
      );

      emit(ChatState.loaded(
        conversations: updatedConversations,
        selectedConversation: selectedConversation,
      ));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      await _chatService.markAsRead(event.messageId);

      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          final updatedMessages = conversation.messages.map((message) {
            if (message.id == event.messageId) {
              return message.copyWith(isRead: true);
            }
            return message;
          }).toList();
          return conversation.copyWith(messages: updatedMessages);
        }
        return conversation;
      }).toList();

      final selectedConversation = updatedConversations.firstWhere(
        (c) => c.id == event.conversationId,
        orElse: () => currentState.selectedConversation!,
      );

      emit(ChatState.loaded(
        conversations: updatedConversations,
        selectedConversation: selectedConversation,
      ));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      await _chatService.markAllAsRead(event.conversationId);

      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          final updatedMessages = conversation.messages.map((message) {
            return message.copyWith(isRead: true);
          }).toList();
          return conversation.copyWith(messages: updatedMessages);
        }
        return conversation;
      }).toList();

      final selectedConversation = updatedConversations.firstWhere(
        (c) => c.id == event.conversationId,
        orElse: () => currentState.selectedConversation!,
      );

      emit(ChatState.loaded(
        conversations: updatedConversations,
        selectedConversation: selectedConversation,
      ));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }
}