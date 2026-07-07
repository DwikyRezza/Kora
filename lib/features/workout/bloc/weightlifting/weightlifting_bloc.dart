import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/workout.dart';
import '../../../../services/database_helper.dart';
import 'weightlifting_event.dart';
import 'weightlifting_state.dart';

class WeightliftingBloc extends Bloc<WeightliftingEvent, WeightliftingState> {
  WeightliftingBloc() : super(const WeightliftingState()) {
    on<SaveWorkout>(_onSaveWorkout);
  }

  Future<void> _onSaveWorkout(SaveWorkout event, Emitter<WeightliftingState> emit) async {
    emit(state.copyWith(status: WeightliftingStatus.loading));
    try {
      double durationMins = 0.0;
      
      if (event.category == 2) {
        durationMins = (event.durationSeconds * event.sets) / 60.0;
        if (durationMins < 1.0) durationMins = 5.0; 
      } else {
        durationMins = event.sets * 3.0; 
        if (durationMins <= 0) durationMins = 10.0;
      }

      final calories = Workout.calculateCalories('weightlifting', durationMins);
      final protein = Workout.calculateProteinNeeded('weightlifting', durationMins, weight: event.userWeight);

      String subTypeStr = event.category == 0 
          ? "Bodyweight" 
          : (event.category == 1 ? "Free Weights" : "Isometric");

      String volumeTotal = '';
      if (event.category == 1) {
        volumeTotal = '${(event.weight * event.reps * event.sets).toStringAsFixed(1)} kg';
      } else if (event.category == 0) {
        volumeTotal = '${event.reps * event.sets} repetisi';
      } else {
        volumeTotal = '${event.durationSeconds * event.sets} detik';
      }

      String notes = "Kategori: $subTypeStr\nVolume: $volumeTotal\n";
      if (event.notes.isNotEmpty) {
        notes += "Catatan: ${event.notes}";
      }

      final now = DateTime.now();
      final workout = Workout(
        type: 'weightlifting',
        duration: durationMins,
        distance: null,
        sets: event.sets,
        reps: event.reps,
        weight: event.category == 1 ? event.weight : null,
        caloriesBurned: calories,
        proteinNeeded: protein,
        notes: notes,
        date: now,
        title: _defaultActivityTitle('weightlifting', now),
      );

      await DatabaseHelper().insertWorkout(workout);
      emit(state.copyWith(status: WeightliftingStatus.success, subTypeStr: subTypeStr));
    } catch (e) {
      emit(state.copyWith(status: WeightliftingStatus.failure, errorMessage: e.toString()));
    }
  }

  String _defaultActivityTitle(String type, DateTime date) {
    final hour = date.hour;
    String timeLabel;
    if (hour >= 5 && hour < 10) {
      timeLabel = 'Morning';
    } else if (hour >= 10 && hour < 14) {
      timeLabel = 'Midday';
    } else if (hour >= 14 && hour < 17) {
      timeLabel = 'Afternoon';
    } else if (hour >= 17 && hour < 20) {
      timeLabel = 'Evening';
    } else {
      timeLabel = 'Night';
    }
    return '$timeLabel Workout';
  }
}
