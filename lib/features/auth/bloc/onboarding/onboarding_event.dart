import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class ProfileSubmitted extends OnboardingEvent {
  final String name;
  final String username;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String goal;

  const ProfileSubmitted({
    required this.name,
    required this.username,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.goal,
  });

  @override
  List<Object?> get props => [name, username, age, gender, height, weight, goal];
}
