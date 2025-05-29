import 'package:flutter/foundation.dart';

/// Modèle représentant une question fréquemment posée (FAQ)
class Faq {
  final String question;
  final String answer;

  Faq({
    required this.question,
    required this.answer,
  });

  /// Créer une copie avec certaines valeurs modifiées
  Faq copyWith({
    String? question,
    String? answer,
  }) {
    return Faq(
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }

  /// Convertir un objet JSON en Faq
  factory Faq.fromJson(Map<String, dynamic> json) {
    return Faq(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  /// Convertir un Faq en objet JSON
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }

  @override
  String toString() => 'Faq(question: $question)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Faq &&
           other.question == question &&
           other.answer == answer;
  }

  @override
  int get hashCode => question.hashCode ^ answer.hashCode;
}
