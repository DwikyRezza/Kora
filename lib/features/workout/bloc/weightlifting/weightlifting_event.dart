import 'package:equatable/equatable.dart';

abstract class WeightliftingEvent extends Equatable {
  const WeightliftingEvent();

  @override
  List<Object?> get props => [];
}

class SaveWorkout extends WeightliftingEvent {
  final int category; // 0: Bodyweight, 1: Free Weights, 2: Isometric
  final double weight;
  final int reps;
  final int sets;
  final int durationSeconds;
  final String notes;
  final double userWeight;

  const SaveWorkout({
    required this.category,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.durationSeconds,
    required this.notes,
    required this.userWeight,
  });

  @override
  List<Object?> get props => [category, weight, reps, sets, durationSeconds, notes, userWeight];
}
