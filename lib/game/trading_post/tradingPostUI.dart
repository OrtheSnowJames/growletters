import 'package:flutter/material.dart';

class TradingPost extends StatefulWidget {
  @override
  State<TradingPost> createState() => _TradingPostState();
}

class _TradingPostState extends State<TradingPost> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 20),
          Text(
            "Trading Post",
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget borderedImage(String assetPath, {double borderWidth = 4}) {
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFD2B48C), // tan color
          width: borderWidth,
        ),
      ),
      child: Image.asset(assetPath),
    );
  }
}

// TODO: work on trade

class SingleItemData {
  String imagePath;
  String imageDescription;
  int count;

  SingleItemData({
    required this.imagePath,
    required this.imageDescription,
    required this.count,
  });
}

class TradeData {
  SingleItemData to;
  SingleItemData item;

  TradeData({required this.to, required this.item});
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
              singleItem(
                imagePath: tradeData.to.imagePath,
                description: tradeData.to.imageDescription,
                count: tradeData.to.count,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 4,
                  color: Colors.green,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.arrow_right_alt, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10),
              singleItem(
                imagePath: tradeData.item.imagePath,
                description: tradeData.item.imageDescription,
                count: tradeData.item.count,
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget singleItem({
    required String imagePath,
    required String description,
    required int count,
  }) {
    return Row(
      children: [
        // Image + description
        Column(
          children: [
            Image.asset(imagePath, width: 50, height: 50),
            const SizedBox(height: 4),
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
