import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' show Vector2;
import 'inventory_panel.dart';
import 'item.dart';
import 'long_arrow.dart';

Future<Image> solidColorImage(Vector2 size, Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;

  final rect = Rect.fromLTWH(0, 0, size.x, size.y);
  canvas.drawRect(rect, paint);

  final picture = recorder.endRecording();
  final uiImage = await picture.toImage(size.x.toInt(), size.y.toInt());
  return Image.memory(
    (await uiImage.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
    width: size.x,
    height: size.y,
  );
}

class TradingPost extends StatefulWidget {
  const TradingPost({super.key});

  @override
  State<TradingPost> createState() => _TradingPostState();
}

class _TradingPostState extends State<TradingPost> {
  Map<String, Item>? _inventory;
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
      _inventory = {
        'banana': Item(
          id: 'banana',
          image: image1,
          description: 'banana',
          count: 5,
        ),
        'ananab': Item(
          id: 'ananab',
          image: image2,
          description: 'ananab',
          count: 1,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = _inventory;
    if (inventory == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final trades = _tradeDefinitions.map((definition) {
      final giveItem = inventory[definition.giveItemId]!;
      final receiveItem = inventory[definition.receiveItemId]!;
      return TradeData(
        give: giveItem.copyWith(count: definition.giveCount),
        receive: receiveItem.copyWith(count: definition.receiveCount),
        canTrade: giveItem.count >= definition.giveCount,
        onTrade: () => _performTrade(definition),
      );
    }).toList();

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
          child: InventoryPanel(inventory: inventory.values.toList()),
        ),
      ],
    );
  }

  void _performTrade(TradeDefinition definition) {
    final inventory = _inventory;
    if (inventory == null) {
      return;
    }

    final giveItem = inventory[definition.giveItemId]!;
    final receiveItem = inventory[definition.receiveItemId]!;

    if (giveItem.count < definition.giveCount) {
      return;
    }

    setState(() {
      giveItem.count -= definition.giveCount;
      receiveItem.count += definition.receiveCount;
    });
  }
}

class TradeData {
  Item give;
  Item receive;
  bool canTrade;
  VoidCallback onTrade;

  TradeData({
    required this.give,
    required this.receive,
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
              singleItem(
                image: tradeData.give.image,
                description: tradeData.give.description,
                count: tradeData.give.count,
                context: context,
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
              singleItem(
                image: tradeData.receive.image,
                description: tradeData.receive.description,
                count: tradeData.receive.count,
                context: context,
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
