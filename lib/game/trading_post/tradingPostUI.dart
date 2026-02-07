import 'package:flutter/material.dart';
import 'package:growletters/game/tools/add_commas.dart';
import '../inventory/inventory_manager.dart';
import 'inventory_panel.dart';
import 'item.dart';
import 'item_registry.dart';
import 'long_arrow.dart';
import '../tools/apple_price_ticker.dart';
import '../../theme/palette.dart';

const double _tradeItemImageSize = 72;

class TradingPost extends StatefulWidget {
  const TradingPost({super.key, this.onTreeSeedPurchased, this.onExit});

  final VoidCallback? onTreeSeedPurchased;
  final Future<void> Function()? onExit;

  @override
  State<TradingPost> createState() => _TradingPostState();
}

class _TradingPostState extends State<TradingPost> {
  late final List<TradeDefinition> _tradeDefinitions;
  final ApplePriceTicker _priceTicker = ApplePriceTicker.instance;

  @override
  void initState() {
    super.initState();
    _priceTicker.attach();
    _tradeDefinitions = [
      const TradeDefinition(
        giveItemId: 'banana',
        giveCount: 1,
        receiveItemId: 'ananab',
        receiveCount: 1,
      ),
    ];
    _createExampleImages();
  }

  Future<void> _createExampleImages() async {
    final image1 = _buildItemImage('assets/banana.png');
    final image2 = _buildItemImage('assets/apple.png');
    final image3 = _buildItemImage('assets/seed.png');

    if (!mounted) return;
    setState(() {
      ItemRegistry.setItems({
        'banana': Item(id: 'banana', image: image1, description: 'banana'),
        'ananab': Item(id: 'ananab', image: image2, description: 'apple'),
        'tree_seed': Item(
          id: 'tree_seed',
          image: image3,
          description: 'tree seed',
        ),
      });
      InventoryManager.initializeIfEmpty({'banana': 5, 'ananab': 1});
    });
  }

  @override
  void dispose() {
    _priceTicker.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady =
        ItemRegistry.isInitialized && InventoryManager.isInitialized;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Trading Post'),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () async {
            final handler = widget.onExit;
            if (handler != null) {
              await handler();
              return;
            }
            if (!mounted) return;
            Navigator.of(context).pop();
          },
        ),
      ),
      body: !isReady
          ? const Center(child: CircularProgressIndicator())
          : _priceTicker.price == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<int>(
              valueListenable: _priceTicker.price!,
              builder: (context, tradePrice, _) {
                return ValueListenableBuilder<Map<String, int>>(
                  valueListenable: InventoryManager.listenable,
                  builder: (context, counts, __) {
                    final trades =
                        _tradeDefinitions.fold<List<TradeData>>([], (
                          list,
                          definition,
                        ) {
                          final giveItem = ItemRegistry.getById(
                            definition.giveItemId,
                          );
                          final receiveItem = ItemRegistry.getById(
                            definition.receiveItemId,
                          );
                          if (giveItem == null || receiveItem == null) {
                            return list;
                          }
                          final giveAvailable =
                              counts[definition.giveItemId] ?? 0;
                          return list..add(
                            TradeData(
                              giveItemId: definition.giveItemId,
                              giveCount: tradePrice,
                              receiveItemId: definition.receiveItemId,
                              receiveCount: definition.receiveCount,
                              canTrade: giveAvailable >= tradePrice,
                              onTrade: () =>
                                  _performTrade(definition, tradePrice),
                            ),
                          );
                        })..add(
                          TradeData(
                            giveItemId: 'ananab',
                            giveCount: 1,
                            receiveItemId: 'tree_seed',
                            receiveCount: 1,
                            canTrade: (counts['ananab'] ?? 0) >= 1,
                            onTrade: _performTreeSeedTrade,
                          ),
                        );

                    return Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                'Current trade price: $tradePrice bananas',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppPalette.card,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 8,
                                  ),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemCount: trades.length,
                                  itemBuilder: (context, index) =>
                                      Trade(tradeData: trades[index]),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: InventoryPanel(
                            items: ItemRegistry.items,
                            counts: counts,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  void _performTrade(TradeDefinition definition, int price) {
    final success = InventoryManager.spendItem(definition.giveItemId, price);
    if (!success) {
      return;
    }
    InventoryManager.addItem(definition.receiveItemId, definition.receiveCount);
  }

  void _performTreeSeedTrade() {
    final success = InventoryManager.spendItem('ananab', 1);
    if (!success) {
      return;
    }
    widget.onTreeSeedPurchased?.call();
  }

  Image _buildItemImage(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );
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

class SingleItem extends StatelessWidget {
  final String itemId;
  final int count;

  const SingleItem({super.key, required this.itemId, required this.count});

  @override
  Widget build(BuildContext context) {
    final item = ItemRegistry.getById(itemId);
    if (item == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _tradeItemImageSize,
          height: _tradeItemImageSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: item.image,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'x${addCommas(count)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Trade extends StatelessWidget {
  final TradeData tradeData;

  const Trade({super.key, required this.tradeData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 10),
              SingleItem(
                itemId: tradeData.giveItemId,
                count: tradeData.giveCount,
              ),
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
              SingleItem(
                itemId: tradeData.receiveItemId,
                count: tradeData.receiveCount,
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: tradeData.canTrade ? tradeData.onTrade : null,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? Colors.grey
                    : Colors.green,
              ),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
            ),
            child: Text(tradeData.canTrade ? 'trade' : 'oof'),
          ),
        ],
      ),
    );
  }
}
