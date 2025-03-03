import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState({required this.locale});

  factory LocaleState.initial([Locale? defaultLocale]) => LocaleState(
    locale: defaultLocale ?? const Locale('fr'),
  );

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object> get props => [locale];
}
