import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/cloud_sync_service.dart';
import 'landing_event.dart';
import 'landing_state.dart';

class LandingBloc extends Bloc<LandingEvent, LandingState> {
  LandingBloc() : super(const LandingState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<LandingState> emit) async {
    emit(state.copyWith(status: LandingStatus.loadingLogin));
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) {
        emit(state.copyWith(status: LandingStatus.initial));
        return;
      }

      final exists = await AuthService.checkUserExistsInCloud();
      if (exists) {
        try {
          await CloudSyncService.restoreAllFromCloud().timeout(const Duration(seconds: 5));
        } catch (e) {
          print('[LandingBloc] Restore gagal: $e');
        }
        emit(state.copyWith(status: LandingStatus.successLogin));
      } else {
        await AuthService.signOut();
        emit(state.copyWith(
          status: LandingStatus.failureLogin,
          errorMessage: 'Akun belum terdaftar. Silakan Register terlebih dahulu.',
        ));
      }
    } catch (e) {
      await AuthService.signOut();
      emit(state.copyWith(status: LandingStatus.failureLogin, errorMessage: e.toString()));
    }
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<LandingState> emit) async {
    emit(state.copyWith(status: LandingStatus.loadingRegister));
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) {
        emit(state.copyWith(status: LandingStatus.initial));
        return;
      }

      final exists = await AuthService.checkUserExistsInCloud();
      if (exists) {
        await AuthService.signOut();
        emit(state.copyWith(
          status: LandingStatus.failureRegister,
          errorMessage: 'Akun sudah terdaftar. Silakan Login.',
        ));
      } else {
        await AuthService.clearLocalSession();
        emit(state.copyWith(status: LandingStatus.successRegister));
      }
    } catch (e) {
      await AuthService.signOut();
      emit(state.copyWith(status: LandingStatus.failureRegister, errorMessage: e.toString()));
    }
  }
}
