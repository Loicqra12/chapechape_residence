import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/help/faq_model.dart';
import '../../services/api/help_service.dart';

// Events
abstract class HelpEvent extends Equatable {
  const HelpEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadFAQs extends HelpEvent {
  final String? category;
  
  const LoadFAQs({this.category});
  
  @override
  List<Object?> get props => [category];
}

class SendSupportMessage extends HelpEvent {
  final String message;
  
  const SendSupportMessage({required this.message});
  
  @override
  List<Object> get props => [message];
}

class ReportProblem extends HelpEvent {
  final String category;
  final String subject;
  final String description;
  
  const ReportProblem({
    required this.category,
    required this.subject,
    required this.description,
  });
  
  @override
  List<Object> get props => [category, subject, description];
}

// States
abstract class HelpState extends Equatable {
  const HelpState();
  
  @override
  List<Object?> get props => [];
}

class HelpInitial extends HelpState {}

class HelpLoading extends HelpState {}

class HelpLoaded extends HelpState {
  final List<FAQItem> faqs;
  
  const HelpLoaded({required this.faqs});
  
  @override
  List<Object> get props => [faqs];
}

class HelpError extends HelpState {
  final String message;
  
  const HelpError({required this.message});
  
  @override
  List<Object> get props => [message];
}

class HelpActionSuccess extends HelpState {
  final String message;
  
  const HelpActionSuccess({required this.message});
  
  @override
  List<Object> get props => [message];
}

// Bloc
class HelpBloc extends Bloc<HelpEvent, HelpState> {
  final HelpService _helpService;
  
  HelpBloc({required HelpService helpService})
      : _helpService = helpService,
        super(HelpInitial()) {
    on<LoadFAQs>(_onLoadFAQs);
    on<SendSupportMessage>(_onSendSupportMessage);
    on<ReportProblem>(_onReportProblem);
  }
  
  Future<void> _onLoadFAQs(
    LoadFAQs event,
    Emitter<HelpState> emit,
  ) async {
    try {
      emit(HelpLoading());
      
      final faqs = await _helpService.getFAQs(category: event.category);
      
      emit(HelpLoaded(faqs: faqs));
    } catch (e) {
      emit(HelpError(message: e.toString()));
    }
  }
  
  Future<void> _onSendSupportMessage(
    SendSupportMessage event,
    Emitter<HelpState> emit,
  ) async {
    try {
      // Garder l'état actuel pour les FAQs
      final currentState = state;
      List<FAQItem> faqs = [];
      
      if (currentState is HelpLoaded) {
        faqs = currentState.faqs;
      }
      
      await _helpService.sendSupportMessage(message: event.message);
      
      emit(HelpActionSuccess(message: 'Votre message a été envoyé avec succès'));
      
      // Restaurer l'état précédent avec les FAQs
      if (faqs.isNotEmpty) {
        emit(HelpLoaded(faqs: faqs));
      }
    } catch (e) {
      emit(HelpError(message: e.toString()));
      
      // Restaurer l'état précédent
      if (state is HelpLoaded) {
        final previousState = state as HelpLoaded;
        emit(HelpLoaded(faqs: previousState.faqs));
      }
    }
  }
  
  Future<void> _onReportProblem(
    ReportProblem event,
    Emitter<HelpState> emit,
  ) async {
    try {
      // Garder l'état actuel pour les FAQs
      final currentState = state;
      List<FAQItem> faqs = [];
      
      if (currentState is HelpLoaded) {
        faqs = currentState.faqs;
      }
      
      await _helpService.reportProblem(
        category: event.category,
        subject: event.subject,
        description: event.description,
      );
      
      emit(HelpActionSuccess(message: 'Votre problème a été signalé avec succès'));
      
      // Restaurer l'état précédent avec les FAQs
      if (faqs.isNotEmpty) {
        emit(HelpLoaded(faqs: faqs));
      }
    } catch (e) {
      emit(HelpError(message: e.toString()));
      
      // Restaurer l'état précédent
      if (state is HelpLoaded) {
        final previousState = state as HelpLoaded;
        emit(HelpLoaded(faqs: previousState.faqs));
      }
    }
  }
} 