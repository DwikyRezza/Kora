import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RunningStatus { initial, running, paused, stopped, saving, success, error }

class RunningState extends Equatable {
  final RunningStatus status;
  final LatLng? currentLocation;
  final List<LatLng> routePoints;
  final double distanceKm;
  final int elapsedSeconds;
  final int movingSeconds;
  final String pace;

  const RunningState({
    this.status = RunningStatus.initial,
    this.currentLocation,
    this.routePoints = const [],
    this.distanceKm = 0.0,
    this.elapsedSeconds = 0,
    this.movingSeconds = 0,
    this.pace = '--:--',
  });

  RunningState copyWith({
    RunningStatus? status,
    LatLng? currentLocation,
    List<LatLng>? routePoints,
    double? distanceKm,
    int? elapsedSeconds,
    int? movingSeconds,
    String? pace,
  }) {
    return RunningState(
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      routePoints: routePoints ?? this.routePoints,
      distanceKm: distanceKm ?? this.distanceKm,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      movingSeconds: movingSeconds ?? this.movingSeconds,
      pace: pace ?? this.pace,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentLocation,
        routePoints,
        distanceKm,
        elapsedSeconds,
        movingSeconds,
        pace,
      ];
}
