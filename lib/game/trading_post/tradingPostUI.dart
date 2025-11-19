import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

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
  Image? _image1;
  Image? _image2;

  @override
  void initState() {
    super.initState();
    _createExampleImages();
  }

  Future<void> _createExampleImages() async {
    final image1 = await solidColorImage(Vector2.all(20), Colors.green);
    final image2 = await solidColorImage(Vector2.all(20), Colors.greenAccent);

    if (!mounted) return;
    setState(() {
      _image1 = image1;
      _image2 = image2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trade = _example();
    if (trade == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        children: [
          Trade(tradeData: _example()!),
          Trade(tradeData: _example()!),
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

  TradeData? _example() {
    final image1 = _image1;
    final image2 = _image2;
    if (image1 == null || image2 == null) {
      return null;
    }
    return TradeData(
      to: SingleItemData(image: image1, imageDescription: "banana", count: 1),
      item: SingleItemData(image: image2, imageDescription: "ananab", count: 4),
    );
  }
}

class SingleItemData {
  Image image;
  String imageDescription;
  int count;

  SingleItemData({
    required this.image,
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
  // TODO: Make functioning trade button

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
                image: tradeData.to.image,
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
                image: tradeData.item.image,
                description: tradeData.item.imageDescription,
                count: tradeData.item.count,
              ),

              SizedBox(width: 10),
            ],
          ),
          SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {},
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              padding: WidgetStateProperty.all(EdgeInsets.all(10)),
            ),
            child: Text("Trade"),
          ),
        ],
      ),
    );
  }

  Widget singleItem({
    required Image image,
    required String description,
    required int count,
  }) {
    return Row(
      children: [
        // Image + description
        Column(
          children: [
            image,
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
