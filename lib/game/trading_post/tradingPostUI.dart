import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' show Vector2;
import '../solidColorImage.dart';
import 'inventory_panel.dart';
import 'item.dart';
import 'item_registry.dart';
import 'long_arrow.dart';

class TradingPost extends StatefulWidget {
  const TradingPost({super.key});

  @override
  State<TradingPost> createState() => _TradingPostState();
}

class _TradingPostState extends State<TradingPost> {
  Map<String, int>? _inventoryCounts;
  late final List<TradeDefinition> _tradeDefinitions;

  @override
  void initState() {
    super.initState();
    _tradeDefinitions = [
      const TradeDefinition(
        giveItemId: 'banana',
        giveCount: 1,
        receiveItemId: 'ananab',
        receiveCount: 4,
      ),
    ];
    _createExampleImages();
  }

  Future<void> _createExampleImages() async {
    final image1 = await solidColorImage(Vector2.all(20), Colors.green);
    final image2 = await solidColorImage(Vector2.all(20), Colors.greenAccent);

    if (!mounted) return;
    setState(() {
      ItemRegistry.setItems({
        'banana': Item(
          id: 'banana',
          image: image1,
          description: 'banana',
        ),
        'ananab': Item(
          id: 'ananab',
          image: image2,
          description: 'ananab',
        ),
      });
      _inventoryCounts = {'banana': 5, 'ananab': 1};
    });
  }

  @override
  Widget build(BuildContext context) {
    final counts = _inventoryCounts;
    if (!ItemRegistry.isInitialized || counts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final trades = _tradeDefinitions.fold<List<TradeData>>([], (list, definition) {
      final giveItem = ItemRegistry.getById(definition.giveItemId);
      final receiveItem = ItemRegistry.getById(definition.receiveItemId);
      if (giveItem == null || receiveItem == null) {
        return list;
      }
      final giveAvailable = counts[definition.giveItemId] ?? 0;
      return list
        ..add(
          TradeData(
            giveItemId: definition.giveItemId,
            giveCount: definition.giveCount,
            receiveItemId: definition.receiveItemId,
            receiveCount: definition.receiveCount,
            canTrade: giveAvailable >= definition.giveCount,
            onTrade: () => _performTrade(definition),
          ),
        );
    });

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: trades.length,
          itemBuilder: (context, index) => Trade(tradeData: trades[index]),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: InventoryPanel(items: ItemRegistry.items, counts: counts),
        ),
      ],
    );
  }

  void _performTrade(TradeDefinition definition) {
    final counts = _inventoryCounts;
    if (counts == null) {
      return;
    }

    final giveAvailable = counts[definition.giveItemId] ?? 0;
    if (giveAvailable < definition.giveCount) {
      return;
    }

    setState(() {
      counts[definition.giveItemId] = giveAvailable - definition.giveCount;
      counts[definition.receiveItemId] =
          (counts[definition.receiveItemId] ?? 0) + definition.receiveCount;
    });
  }
}

class TradeData {
  final String giveItemId;
  final int giveCount;
  final String receiveItemId;
  final int receiveCount;
  final bool canTrade;
  final VoidCallback onTrade;

  TradeData({
    required this.giveItemId,
    required this.giveCount,
    required this.receiveItemId,
    required this.receiveCount,
    required this.canTrade,
    required this.onTrade,
  });
}

class Trade extends StatelessWidget {
  final TradeData tradeData;

  Trade({super.key, required this.tradeData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 10),
          Row(
            children: [
              SizedBox(width: 10),
              Builder(
                builder: (context) {
                  final item = ItemRegistry.getById(tradeData.giveItemId);
                  if (item == null) {
                    return const SizedBox.shrink();
                  }
                  return singleItem(
                    image: item.image,
                    description: item.description,
                    count: tradeData.giveCount,
                    context: context,
                  );
                },
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 16,
                  child: LongArrow(
                    color: Colors.white,
                    thickness: 4,
                    headSize: 16,
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Builder(
                builder: (context) {
                  final item = ItemRegistry.getById(tradeData.receiveItemId);
                  if (item == null) {
                    return const SizedBox.shrink();
                  }
                  return singleItem(
                    image: item.image,
                    description: item.description,
                    count: tradeData.receiveCount,
                    context: context,
                  );
                },
              ),

              SizedBox(width: 10),
            ],
          ),
          SizedBox(height: 10),

          ElevatedButton(
            onPressed: tradeData.canTrade ? tradeData.onTrade : null,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? Colors.grey
                    : Colors.green,
              ),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              padding: WidgetStateProperty.all(EdgeInsets.all(10)),
            ),
            child: Text(tradeData.canTrade ? 'Trade' : 'oof'),
          ),
        ],
      ),
    );
  }

  Widget singleItem({
    required Image image,
    required String description,
    required int count,
    required BuildContext context,
  }) {
    double height = MediaQuery.of(context).size.height;
    return Row(
      children: [
        // Image + description
        Column(
          children: [
            SizedBox(height: height * 0.025),
            image,
            SizedBox(height: height * 0.025),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),

        const SizedBox(width: 8),

        // Count to the right
        Text(
          'x$count',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
