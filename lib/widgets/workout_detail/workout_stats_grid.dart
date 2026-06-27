import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../theme/app_theme.dart';

class WorkoutStatsGrid extends StatelessWidget {
  final Workout workout;

  const WorkoutStatsGrid({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final List<_MetricData> metrics = [
      _MetricData(
        value: workout.distance != null ? "${workout.distance!.toStringAsFixed(2)} km" : "0.00 km",
        label: "Distance",
      ),
      _MetricData(
        value: "${_calculatePace()} /km",
        label: "Avg Pace",
      ),
      _MetricData(
        value: "${(workout.elevationGain ?? 0.0).round()} m",
        label: "Elevation Gain",
      ),
      _MetricData(
        value: _formatMovingTime(workout.duration),
        label: "Moving Time",
      ),
      _MetricData(
        value: "${workout.caloriesBurned} Cal",
        label: "Calories",
      ),
      _MetricData(
        value: "${(workout.maxElevation ?? (workout.elevationGain != null ? workout.elevationGain! * 1.5 : 0.0)).round()} m",
        label: "Max Elevation",
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: metrics.map((m) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  m.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: uiBoldFontWeight(),
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Fallback for uiBoldFontWeight
  FontWeight uiBoldFontWeight() => FontWeight.bold;

  String _calculatePace() {
    if (workout.distance == null || workout.distance == 0) return '0:00';
    final paceMins = workout.duration / workout.distance!;
    final m = paceMins.truncate();
    final s = ((paceMins - m) * 60).truncate().toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatMovingTime(double durationMins) {
    final int totalSeconds = (durationMins * 60).round();
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
  }
}

class _MetricData {
  final String value;
  final String label;

  _MetricData({required this.value, required this.label});
}
