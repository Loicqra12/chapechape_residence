import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends UserEvent {
  const LoadUserProfile();
}

class UpdateUserProfile extends UserEvent {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profilePicture;
  final bool? isPhoneVerified;
  final Map<String, dynamic>? metadata;

  const UpdateUserProfile({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePicture,
    this.isPhoneVerified,
    this.metadata,
  });

  @override
  List<Object?> get props => [firstName, lastName, phoneNumber, profilePicture, isPhoneVerified, metadata];
}

class ChangeUserPassword extends UserEvent {
  final String currentPassword;
  final String newPassword;

  const ChangeUserPassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class UploadProfilePicture extends UserEvent {
  final String filePath;

  const UploadProfilePicture(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class LoadBookingHistory extends UserEvent {
  const LoadBookingHistory();
}

class LoadFavoriteResidences extends UserEvent {
  const LoadFavoriteResidences();
}
