import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/services/user_service.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserService _userService;

  UserBloc({
    required UserService userService,
  })  : _userService = userService,
        super(const UserInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<ChangeUserPassword>(_onChangeUserPassword);
    on<UploadProfilePicture>(_onUploadProfilePicture);
    on<LoadBookingHistory>(_onLoadBookingHistory);
    on<LoadFavoriteResidences>(_onLoadFavoriteResidences);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final user = await _userService.getUserProfile();
      emit(UserProfileLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final user = await _userService.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        profilePicture: event.profilePicture,
      );
      emit(UserProfileUpdated(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onChangeUserPassword(
    ChangeUserPassword event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      await _userService.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(const UserPasswordChanged());
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUploadProfilePicture(
    UploadProfilePicture event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final profilePictureUrl = await _userService.uploadProfilePicture(event.filePath);
      emit(ProfilePictureUploaded(profilePictureUrl));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadBookingHistory(
    LoadBookingHistory event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final bookings = await _userService.getBookingHistory();
      emit(BookingHistoryLoaded(bookings));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadFavoriteResidences(
    LoadFavoriteResidences event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final favorites = await _userService.getFavoriteResidences();
      emit(FavoriteResidencesLoaded(favorites));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
