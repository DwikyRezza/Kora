import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/profile_service.dart';
import '../../../../services/cloud_sync_service.dart';
import '../../../../services/auth_service.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<ProfileSubmitted>(_onProfileSubmitted);
  }

  Future<void> _onProfileSubmitted(ProfileSubmitted event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    try {
      bool isUsernameAvail = await ProfileService.isUsernameAvailable(event.username);
      if (!isUsernameAvail) {
        emit(state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: 'Username "${event.username}" sudah digunakan. Silakan pilih username lain.',
        ));
        return;
      }

      await ProfileService.saveProfile(
        name: event.name.isNotEmpty ? event.name : (AuthService.displayName ?? 'User'),
        username: event.username,
        age: event.age,
        gender: event.gender,
        height: event.height,
        weight: event.weight,
        goal: event.goal,
      );

      // Backup ke Firestore tanpa await agar cepat
      CloudSyncService.backupToCloud().catchError((_) {});

      emit(state.copyWith(status: OnboardingStatus.success));
    } catch (e) {
      emit(state.copyWith(status: OnboardingStatus.failure, errorMessage: e.toString()));
    }
  }
}
