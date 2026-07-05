import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isWarning;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(label,
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            if (isWarning) ...[
              const SizedBox(width: 8),
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF3400), size: 18),
            ]
          ]),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
