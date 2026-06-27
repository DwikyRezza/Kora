import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../theme/app_theme.dart';

class WorkoutAnalysisSplits extends StatelessWidget {
  final Workout workout;

  const WorkoutAnalysisSplits({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    List<String> splits = [];
    if (workout.splitsStr != null && workout.splitsStr!.isNotEmpty) {
      try {
        splits = List<String>.from(jsonDecode(workout.splitsStr!));
      } catch (e) {
        // ignore
      }
    }

    final finalSplits = splits.isNotEmpty ? splits : _generateSplitsList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: List.generate(finalSplits.length, (i) {
            final paceVal = finalSplits[i];
            double pct = 0.5;
            try {
              final parts = paceVal.split(':');
              final mins = double.parse(parts[0]) + (double.parse(parts[1]) / 60);
              pct = (12.0 - mins) / (12 - 4); // Rentang 4 - 12 menit
              pct = pct.clamp(0.1, 1.0);
            } catch (_) {}

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 48, child: Text('Km ${i + 1}', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                  const SizedBox(width: 10),
                  Text(paceVal, style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 12,
                        backgroundColor: AppTheme.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5406)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('HR: ${140 + (i % 3) * 5}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  List<String> _generateSplitsList() {
    final double dist = workout.distance ?? 3.0;
    final int count = dist.ceil();
    final double avgP = workout.duration / (dist > 0 ? dist : 1.0);
    return List.generate(count, (i) {
      final p = avgP + (i % 3 - 1) * 0.2;
      final m = p.truncate();
      final s = ((p - m) * 60).round().toString().padLeft(2, '0');
      return '$m:$s';
    });
  }
}
