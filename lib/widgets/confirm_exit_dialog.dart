import 'package:flutter/material.dart';

Future<bool> showLobbyExitDialog(
  BuildContext context, {
  bool showHostWarning = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave lobby?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will eradicate you from the lobby. Are you sure you want to continue?',
          ),
          if (showHostWarning) ...[
            const SizedBox(height: 12),
            Text(
              'This will also disconnect all players from the lobby.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return result ?? false;
}
