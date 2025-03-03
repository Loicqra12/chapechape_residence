import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/message/message.dart';
import '../../services/api/message_service.dart';

// Events
abstract class MessageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMessages extends MessageEvent {
  final String userId;
  final bool refresh;

  LoadMessages({required this.userId, this.refresh = false});

  @override
  List<Object?> get props => [userId, refresh];
}

class SendMessage extends MessageEvent {
  final Message message;

  SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkMessageAsRead extends MessageEvent {
  final String messageId;

  MarkMessageAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

// States
abstract class MessageState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessagesLoaded extends MessageState {
  final List<Message> messages;

  MessagesLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class MessageError extends MessageState {
  final String message;

  MessageError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageService _messageService;

  MessageBloc(this._messageService) : super(MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    try {
      emit(MessageLoading());
      final messages = await _messageService.getMessages(event.userId);
      emit(MessagesLoaded(messages));
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessageState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is MessagesLoaded) {
        final updatedMessages = List<Message>.from(currentState.messages)
          ..add(event.message);
        emit(MessagesLoaded(updatedMessages));
      }
      
      await _messageService.sendMessage(event.message);
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is MessagesLoaded) {
        final updatedMessages = currentState.messages.map((message) {
          if (message.id == event.messageId) {
            return message.copyWith(isRead: true);
          }
          return message;
        }).toList();
        emit(MessagesLoaded(updatedMessages));
      }
      
      await _messageService.markMessageAsRead(event.messageId);
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }
}
