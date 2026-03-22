import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool   showText;

  const AppLogo({
    super.key,
    this.size     = 80,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  size,
          height: size,
          decoration: BoxDecoration(
            color:        AppColors.secondary,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color:      AppColors.secondary.withOpacity(0.4),
                blurRadius: 20,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cross
              Container(
                width:  size * 0.12,
                height: size * 0.55,
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width:  size * 0.4,
                height: size * 0.12,
                margin: EdgeInsets.only(bottom: size * 0.12),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'ChurchConnect',
            style: TextStyle(
              fontSize:   size * 0.3,
              fontWeight: FontWeight.bold,
              color:      Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Connecting the Body of Christ',
            style: TextStyle(
              fontSize: size * 0.13,
              color:    Colors.white70,
            ),
          ),
        ],
      ],
    );
  }
}