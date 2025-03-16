part of 'chat_bloc.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading() = ChatLoading;
  const factory ChatState.loaded({
    required List<ChatConversation> conversations,
    ChatConversation? selectedConversation,
    @Default(false) bool isLoading,
  }) = ChatLoaded;
  const factory ChatState.error({
    required String message,
  }) = ChatError;
}