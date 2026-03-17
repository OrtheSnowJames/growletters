import 'dart:async';
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
const List<ItemDefinition> kDefaultTradingPostItemDefinitions = [
  ItemDefinition(
    id: 'banana',
    assetPath: 'assets/banana.png',
    label: 'Banana',
    description: 'Harvested from your banana trees.',
    initialCount: 5,
    actionType: ItemActionType.eat,
    actionLabel: 'Eat',
  ),
  ItemDefinition(
    id: 'ananab',
    assetPath: 'assets/apple.png',
    label: 'Apple',
    description: 'Sell these to score points.',
    initialCount: 1,
    actionType: ItemActionType.eat,
    actionLabel: 'Eat',
  ),
  ItemDefinition(
    id: 'tree_seed',
    assetPath: 'assets/seed.png',
    label: 'Tree Seed',
    description: 'Plant this to grow another tree.',
    initialCount: 8,
    actionType: ItemActionType.plantTree,
    actionLabel: 'Plant',
  ),
];

const List<TradeDefinition> kDefaultTradingPostTradeDefinitions = [
  TradeDefinition(
    giveItemId: 'banana',
    giveCount: 1,
    receiveItemId: 'ananab',
    receiveCount: 1,
    useMarketPrice: true,
  ),
  TradeDefinition(
    giveItemId: 'ananab',
    giveCount: 1,
    receiveItemId: 'tree_seed',
    receiveCount: 1,
  ),
];

void initializeTradingPostItemsAndInventory([
  List<ItemDefinition> itemDefinitions = kDefaultTradingPostItemDefinitions,
]) {
  final itemMap = <String, Item>{};
  final initialCounts = <String, int>{};

  for (final definition in itemDefinitions) {
    itemMap[definition.id] = Item(
      id: definition.id,
      assetPath: definition.assetPath,
      label: definition.label,
      description: definition.description,
      actionType: definition.actionType,
      actionLabel: definition.actionLabel,
    );
    if (definition.initialCount > 0) {
      initialCounts[definition.id] = definition.initialCount;
    }
  }

  ItemRegistry.setItems(itemMap);
  InventoryManager.initializeIfEmpty(initialCounts);
}

class TradingPost extends StatefulWidget {
  const TradingPost({
    super.key,
    this.onExit,
    this.timeLimitSeconds = 600,
    this.startedAt,
    this.itemDefinitions = kDefaultTradingPostItemDefinitions,
    this.tradeDefinitions = kDefaultTradingPostTradeDefinitions,
  });

  final Future<void> Function()? onExit;
  final int timeLimitSeconds;
  final DateTime? startedAt;
  final List<ItemDefinition> itemDefinitions;
  final List<TradeDefinition> tradeDefinitions;

  @override
  State<TradingPost> createState() => _TradingPostState();
}

class _TradingPostState extends State<TradingPost> {
  final ApplePriceTicker _priceTicker = ApplePriceTicker.instance;
  Timer? _timeTicker;

  @override
  void initState() {
    super.initState();
    _priceTicker.attach();
    if (widget.startedAt != null) {
      _timeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    _initializeItems();
  }

  @override
  void dispose() {
    _priceTicker.detach();
    _timeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady =
        ItemRegistry.isInitialized && InventoryManager.isInitialized;
    final bodyContent = !isReady
        ? const Center(child: CircularProgressIndicator())
        : _priceTicker.price == null
        ? const Center(child: CircularProgressIndicator())
        : ValueListenableBuilder<int>(
            valueListenable: _priceTicker.price!,
            builder: (context, tradePrice, _) {
              return ValueListenableBuilder<Map<String, int>>(
                valueListenable: InventoryManager.listenable,
                builder: (context, counts, __) {
                  final trades = _buildTrades(
                    tradePrice: tradePrice,
                    counts: counts,
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
                          const SizedBox(height: 8),
                          _TradingPostTimeLeftBanner(
                            timeLimitSeconds: widget.timeLimitSeconds,
                            startedAt: widget.startedAt,
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Column(
                              children: [
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
                                const SizedBox(height: 16),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ),
                              ],
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
          );

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
      body: bodyContent,
    );
  }

  void _initializeItems() {
    initializeTradingPostItemsAndInventory(widget.itemDefinitions);
  }

  List<TradeData> _buildTrades({
    required int tradePrice,
    required Map<String, int> counts,
  }) {
    return widget.tradeDefinitions.fold<List<TradeData>>([], (
      list,
      definition,
    ) {
      final giveItem = ItemRegistry.getById(definition.giveItemId);
      final receiveItem = ItemRegistry.getById(definition.receiveItemId);
      if (giveItem == null || receiveItem == null) {
        return list;
      }
      final effectiveGiveCount = definition.useMarketPrice
          ? tradePrice
          : definition.giveCount;
      final giveAvailable = counts[definition.giveItemId] ?? 0;
      return list..add(
        TradeData(
          giveItemId: definition.giveItemId,
          giveCount: effectiveGiveCount,
          receiveItemId: definition.receiveItemId,
          receiveCount: definition.receiveCount,
          canTrade: giveAvailable >= effectiveGiveCount,
          onTrade: () => _performTrade(definition, effectiveGiveCount),
        ),
      );
    });
  }

  void _performTrade(TradeDefinition definition, int effectiveGiveCount) {
    final success = InventoryManager.spendItem(
      definition.giveItemId,
      effectiveGiveCount,
    );
    if (!success) {
      return;
    }
    InventoryManager.addItem(definition.receiveItemId, definition.receiveCount);
  }
}

class _TradingPostTimeLeftBanner extends StatelessWidget {
  const _TradingPostTimeLeftBanner({
    required this.timeLimitSeconds,
    required this.startedAt,
  });

  final int timeLimitSeconds;
  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) {
    final timeLeft = _formatDuration(_timeLeft());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        'Time left: $timeLeft',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Duration _timeLeft() {
    final startedAtValue = startedAt;
    if (startedAtValue == null) {
      return Duration(seconds: timeLimitSeconds);
    }
    final endAt = startedAtValue.add(Duration(seconds: timeLimitSeconds));
    final remaining = endAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');
    return '$minutesText:$secondsText';
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
          child: FittedBox(fit: BoxFit.contain, child: item.buildImage()),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'x${addCommas(count)}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
