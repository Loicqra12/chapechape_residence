import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'app_store_model.freezed.dart';
part 'app_store_model.g.dart';

@freezed
class AppStoreModel with _$AppStoreModel {
  const factory AppStoreModel({
    required String name,
    required String logoUrl,
    required String downloadUrl,
    String? qrCodeUrl,
    String? description,
  }) = _AppStoreModel;

  factory AppStoreModel.fromJson(Map<String, dynamic> json) => 
      _$AppStoreModelFromJson(json);
}
