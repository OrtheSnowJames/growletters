import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    required this.color,
    required this.onDismiss,
  });

  final String message;
  final Color color;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: color,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
