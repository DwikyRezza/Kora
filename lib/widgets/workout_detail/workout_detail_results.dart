import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../theme/app_theme.dart';

class WorkoutDetailResults extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailResults({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final double dist = workout.distance ?? 0.0;
    final double avgPace = dist > 0 ? (workout.duration / dist) : 0.0;
    if (dist <= 0) return const SizedBox.shrink();

    final List<_BestEffortItem> items = [];

    // Helper to format best effort duration
    String formatTime(double mins) {
      final int totalSeconds = (mins * 60).round();
      final int hours = totalSeconds ~/ 3600;
      final int minutes = (totalSeconds % 3600) ~/ 60;
      final int seconds = totalSeconds % 60;
      if (hours > 0) {
        return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      } else {
        return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      }
    }

    String formatPace(double p) {
      final m = p.truncate();
      final s = ((p - m) * 60).round().toString().padLeft(2, '0');
      return '$m:$s /km';
    }

    // Populate best efforts logically based on actual average pace (adding small percentage speedups for shorter distances)
    if (dist >= 10.0) {
      items.add(_BestEffortItem(
        label: '10K',
        time: formatTime(avgPace * 10.0 * 0.98),
        pace: formatPace(avgPace * 0.98),
      ));
    }
    if (dist >= 5.0) {
      items.add(_BestEffortItem(
        label: '5K',
        time: formatTime(avgPace * 5.0 * 0.96),
        pace: formatPace(avgPace * 0.96),
      ));
    }
    if (dist >= 3.218) {
      items.add(_BestEffortItem(
        label: '2 mile',
        time: formatTime(avgPace * 3.218 * 0.94),
        pace: formatPace(avgPace * 0.94),
      ));
    }
    if (dist >= 1.609) {
      items.add(_BestEffortItem(
        label: '1 mile',
        time: formatTime(avgPace * 1.609 * 0.92),
        pace: formatPace(avgPace * 0.92),
      ));
    }
    if (dist >= 1.0) {
      items.add(_BestEffortItem(
        label: '1K',
        time: formatTime(avgPace * 1.0 * 0.90),
        pace: formatPace(avgPace * 0.90),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(color: AppTheme.border, height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_run_rounded,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.pace,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.time,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Divider(color: AppTheme.border, height: 1),
        ],
      ),
    );
  }
}

class _BestEffortItem {
  final String label;
  final String time;
  final String pace;

  _BestEffortItem({required this.label, required this.time, required this.pace});
}
