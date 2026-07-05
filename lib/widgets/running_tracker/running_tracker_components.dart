import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart'; // Assuming responsive extension is used via BuildContext

class MapToolIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const MapToolIcon(this.icon, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: context.fontXL,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: context.fontXS,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class StatItemPace extends StatelessWidget {
  final String label;
  final String value;

  const StatItemPace(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: AppTheme.textMuted, size: context.iconSM),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: context.fontXL,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        Text(label,
            style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: context.fontXS,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final Color textColor;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: context.iconMD),
            SizedBox(width: context.spaceSM),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: context.fontLG,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
