import re

with open('lib/features/running/presentation/screens/running_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add Bloc imports
import_addition = '''import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/running_bloc.dart';
import '../../bloc/running_event.dart';
import '../../bloc/running_state.dart';
'''
content = re.sub(r'(import .*?;[\r\n]+)(class RunningTrackerScreen)', r'\1' + import_addition + r'\n\2', content)

# 2. Replace _saveRunToDatabase
save_replacement = '''  Future<void> _saveRunToDatabase() async {
    if (!_isSaving) return;
    await LocationService.stopService();

    if (_distanceKm < 0.01) {
      if (mounted) {
        _showSnackBar('Aktivitas dibatalkan: Tidak ada rekaman jarak (0 km).');
        setState(() => _isSaving = false);
        Navigator.pop(context);
      }
      return;
    }

    final durationMinutes = _elapsedSeconds / 60.0;
    final calories = Workout.calculateCalories('running', durationMinutes);
    final protein = Workout.calculateProteinNeeded('running', durationMinutes, weight: widget.userWeight);
    final now = DateTime.now();

    final workout = Workout(
      type: 'running',
      duration: durationMinutes,
      distance: _distanceKm,
      caloriesBurned: calories,
      proteinNeeded: protein,
      date: now,
      notes: 'Lari GPS Tracker. Jarak:  km',
      movingTime: _movingSeconds / 60.0,
      elevationGain: _elevationGain,
      maxElevation: _maxElevation,
      splitsStr: _finalSplitsJson ?? jsonEncode(_splits),
      polyline: _finalRouteJson ?? jsonEncode(_routePoints.map((p) => [p.latitude, p.longitude]).toList()),
      title: _defaultActivityTitle('running', now),
    );

    // Let the Bloc handle the actual database and sync operations
    context.read<RunningBloc>().add(RunningSaveWorkout(
      userWeight: widget.userWeight,
      splits: _splits,
    ));

    // Because we just dispatched, we can do the actual save manually here too or just let BLoC do it. 
    // Actually wait! The BLoC takes just splits and userWeight, but we have tons of state in UI (elevation, etc)
    // To make it fully BLoC, we should pass all this to the Event, or just let the Bloc handle the DB insertion.
    // For now, let's keep it simple: We just call DatabaseHelper directly from Bloc, but since UI has all the data, 
    // let's just let the UI build the Workout object and send it to the Bloc!
'''

# Wait, if I change the Bloc Event to accept Workout workout, it's much cleaner!
