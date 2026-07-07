import 'package:equatable/equatable.dart';

abstract class LandingEvent extends Equatable {
  const LandingEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends LandingEvent {}

class RegisterSubmitted extends LandingEvent {}
