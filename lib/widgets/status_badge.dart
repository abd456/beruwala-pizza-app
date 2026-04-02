import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case AppConstants.statusReceived:
        return AppColors.info;
      case AppConstants.statusPreparing:
        return AppColors.warning;
      case AppConstants.statusReady:
        return AppColors.accent;
      case AppConstants.statusDelivered:
        return AppColors.success;
      default:
        return AppColors.textGrey;
    }
  }

  String get _label {
    switch (status) {
      case AppConstants.statusReceived:
        return 'New';
      case AppConstants.statusPreparing:
        return 'Preparing';
      case AppConstants.statusReady:
        return 'Ready';
      case AppConstants.statusDelivered:
        return 'Delivered';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
