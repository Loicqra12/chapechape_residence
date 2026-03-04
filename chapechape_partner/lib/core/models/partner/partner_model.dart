// Partner Model will be defined here

import 'package:equatable/equatable.dart';

class Partner extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String phoneNumber;
  final String? profilePictureUrl;
  final List<PartnerDocument>? documents;
  final bool isVerified;

  const Partner({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phoneNumber,
    this.profilePictureUrl,
    this.documents,
    this.isVerified = false,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    List<PartnerDocument>? docs;
    if (json['documents'] != null) {
      docs = List<PartnerDocument>.from(
        json['documents'].map((x) => PartnerDocument.fromJson(x)),
      );
    }

    return Partner(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? 'partner',
      phoneNumber: json['phoneNumber'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? json['profileImage'] ?? '',
      documents: docs,
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'documents': documents?.map((doc) => doc.toJson()).toList(),
      'isVerified': isVerified,
    };
  }

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    id, 
    email, 
    firstName, 
    lastName, 
    role, 
    phoneNumber, 
    profilePictureUrl,
    documents,
    isVerified,
  ];

  Partner copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phoneNumber,
    String? profilePictureUrl,
    List<PartnerDocument>? documents,
    bool? isVerified,
  }) {
    return Partner(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      documents: documents ?? this.documents,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class PartnerDocument extends Equatable {
  final String id;
  final String type;
  final String documentUrl;
  final DateTime uploadDate; // Renommé de uploadedAt à uploadDate pour cohérence
  final DateTime? validUntil; // Date d'expiration du document (nouvelle propriété)
  final String status; // 'pending', 'approved', 'rejected'
  final String? comment; // Commentaire de l'administrateur (nouvelle propriété)

  const PartnerDocument({
    required this.id,
    required this.type,
    required this.documentUrl,
    required this.uploadDate,
    this.validUntil,
    required this.status,
    this.comment,
  });

  factory PartnerDocument.fromJson(Map<String, dynamic> json) {
    return PartnerDocument(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type'] ?? '',
      documentUrl: json['documentUrl'] ?? json['url'] ?? '',
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'].toString())
          : json['uploadedAt'] != null
              ? DateTime.parse(json['uploadedAt'].toString())
              : DateTime.now(),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'].toString())
          : null,
      status: json['status'] ?? (json['verified'] == true ? 'approved' : 'pending'),
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'type': type,
      'documentUrl': documentUrl,
      'uploadDate': uploadDate.toIso8601String(),
      'status': status,
    };
    
    if (validUntil != null) {
      data['validUntil'] = validUntil!.toIso8601String();
    }
    
    if (comment != null) {
      data['comment'] = comment;
    }
    
    return data;
  }

  @override
  List<Object?> get props => [id, type, documentUrl, uploadDate, validUntil, status, comment];
}
