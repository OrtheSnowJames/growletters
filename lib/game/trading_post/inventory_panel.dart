import 'package:flutter/material.dart';

import 'item.dart';

class InventoryPanel extends StatelessWidget {
  const InventoryPanel({super.key, required this.items, required this.counts});

  final ItemCollection items;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Inventory',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...counts.entries.map(
            (entry) {
              final item = items[entry.key];
              if (item == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 24, height: 24, child: item.image),
                    const SizedBox(width: 8),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${entry.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
