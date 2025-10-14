// lib/widgets/availability_indicator.dart
import 'package:flutter/material.dart';

class AvailabilityIndicator extends StatelessWidget {
  final int availableSpots;
  final int totalCapacity;

  const AvailabilityIndicator({
    Key? key,
    required this.availableSpots,
    required this.totalCapacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = availableSpots / totalCapacity;
    Color indicatorColor;
    String statusText;
    IconData statusIcon;

    if (percentage > 0.5) {
      indicatorColor = Colors.green;
      statusText = 'متاح';
      statusIcon = Icons.check_circle;
    } else if (percentage > 0.2) {
      indicatorColor = Colors.orange;
      statusText = 'أماكن محدودة';
      statusIcon = Icons.warning;
    } else if (percentage > 0) {
      indicatorColor = Colors.red;
      statusText = 'شبه ممتلئ';
      statusIcon = Icons.error;
    } else {
      indicatorColor = Colors.grey;
      statusText = 'ممتلئ';
      statusIcon = Icons.block;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: indicatorColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: indicatorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
          const SizedBox(height: 4),
          Text(
            '$availableSpots من $totalCapacity أماكن متاحة',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
