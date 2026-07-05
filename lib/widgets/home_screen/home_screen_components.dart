import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PillToggle extends StatelessWidget {
  final int dashboardTab;
  final ValueChanged<int> onTabChanged;

  const PillToggle({
    super.key,
    required this.dashboardTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: dashboardTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 43,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(0),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.restaurant_outlined,
                        size: 16,
                        color: dashboardTab == 0 ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(1),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.fitness_center_outlined,
                        size: 16,
                        color: dashboardTab == 1 ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
