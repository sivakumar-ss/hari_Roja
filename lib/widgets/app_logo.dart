import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool light;

  const AppLogo({super.key, this.size = 48, this.showText = true, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(color: AppColors.violet.withValues(alpha: 0.35), blurRadius: size * 0.42, offset: Offset(0, size * 0.16)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.show_chart_rounded, color: Colors.white.withValues(alpha: 0.28), size: size * 0.62),
              Text(
                '₹',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.46,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Finance',
                style: TextStyle(
                  fontSize: size * 0.40,
                  fontWeight: FontWeight.w800,
                  color: light ? Colors.white : AppColors.textPrimary,
                  height: 1.05,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'Advisor',
                style: TextStyle(
                  fontSize: size * 0.29,
                  fontWeight: FontWeight.w700,
                  color: light ? AppColors.accent : AppColors.accentDark,
                  height: 1.15,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
