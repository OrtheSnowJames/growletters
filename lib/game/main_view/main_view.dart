import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../trading_post/tradingPostUI.dart';
import '../tools/apple_price_ticker.dart';
import 'game_tree.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final List<TreeData> _trees =
      List<TreeData>.generate(10, (_) => TreeData.basic());

  final ScrollController _scrollController = ScrollController();
  double _currentOffset = 0;
  final ApplePriceTicker _priceTicker = ApplePriceTicker.instance;

  @override
  void initState() {
    super.initState();
    _priceTicker.attach();
  }

  @override
  void dispose() {
    _priceTicker.detach();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    final maxExtent = _scrollController.position.hasContentDimensions
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final double target = (_currentOffset + delta).clamp(0, maxExtent);
    _currentOffset = target;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _openTradingPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradingPost(
          onTreeSeedPurchased: _handleTreeSeedPurchase,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forest')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Trees(
                treeData: _trees,
                controller: _scrollController,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _scrollBy(-300),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _openTradingPost,
                  child: const Text('Trading Post'),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _scrollBy(300),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}

  void _handleTreeSeedPurchase() {
    if (!mounted) return;
    setState(() {
      _trees.add(TreeData.basic());
    });
  }
}

class Trees extends StatelessWidget {
  const Trees({super.key, required this.treeData, required this.controller});

  final List<TreeData> treeData;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double itemWidth = 160;
        const double itemHeight = 220;
        final rows =
            math.max(1, (constraints.maxHeight / itemHeight).floor());

        return GridView.builder(
          controller: controller,
          scrollDirection: Axis.horizontal,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rows,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemCount: treeData.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: itemWidth,
              child: Tree(dat: treeData[index]),
            );
          },
        );
      },
    );
  }
}
