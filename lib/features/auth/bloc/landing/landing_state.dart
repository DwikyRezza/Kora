import 'package:equatable/equatable.dart';

enum LandingStatus { initial, loadingLogin, loadingRegister, successLogin, successRegister, failureLogin, failureRegister }

class LandingState extends Equatable {
  final LandingStatus status;
  final String? errorMessage;

  const LandingState({
    this.status = LandingStatus.initial,
    this.errorMessage,
  });

  LandingState copyWith({
    LandingStatus? status,
    String? errorMessage,
  }) {
    return LandingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
