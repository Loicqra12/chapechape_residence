import 'package:equatable/equatable.dart';

class FAQItem extends Equatable {
  final String id;
  final String question;
  final String answer;
  final String category;
  final bool isExpanded;

  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.isExpanded = false,
  });

  @override
  List<Object?> get props => [id, question, answer, category, isExpanded];

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
    };
  }

  FAQItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    bool? isExpanded,
  }) {
    return FAQItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class FAQCategory extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int count;

  const FAQCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.count,
  });

  @override
  List<Object> get props => [id, name, icon, count];

  factory FAQCategory.fromJson(Map<String, dynamic> json) {
    return FAQCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'count': count,
    };
  }
} 