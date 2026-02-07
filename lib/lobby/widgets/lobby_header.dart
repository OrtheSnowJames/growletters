import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/palette.dart';
import '../models.dart';

class LobbyHeader extends StatelessWidget {
  const LobbyHeader({super.key, required this.info});

  final LobbyInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final link = '${Uri.base.origin}/?code=${info.lobbyCode}';
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Code',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.blueGrey[200]),
              ),
              Text(
                info.lobbyCode,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied!')));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
