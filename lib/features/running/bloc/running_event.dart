import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/workout.dart';

abstract class RunningEvent extends Equatable {
  const RunningEvent();
  @override
  List<Object?> get props => [];
}

class RunningInit extends RunningEvent {}
class RunningStart extends RunningEvent {}
class RunningPause extends RunningEvent {}
class RunningResume extends RunningEvent {}
class RunningStop extends RunningEvent {}

class RunningUpdateLocation extends RunningEvent {
  final LatLng location;
  const RunningUpdateLocation(this.location);
  @override
  List<Object?> get props => [location];
}

class RunningUpdateMetrics extends RunningEvent {
  final double distance;
  final int elapsed;
  final int movingTime;
  const RunningUpdateMetrics(this.distance, this.elapsed, this.movingTime);
  @override
  List<Object?> get props => [distance, elapsed, movingTime];
}

class RunningSaveWorkout extends RunningEvent {
  final Workout workout;
  const RunningSaveWorkout(this.workout);
  @override
  List<Object?> get props => [workout];
}
