import 'package:flutter/material.dart';

class ResourceManager {
  // placeholders
  static const AssetImage tree1 = AssetImage('assets/missing_content.jpg');
  static const AssetImage tree2 = AssetImage('assets/sprout.png');
  static const AssetImage tree3 = AssetImage('assets/branchy.png');
  static const AssetImage tree4 = AssetImage('assets/sapling.png');
  static const AssetImage tree5 = AssetImage('assets/grown.png');

  static const AssetImage grownNoBananas = AssetImage('assets/grown.png');
  static const AssetImage grownOneBanana = AssetImage('assets/banana.png');
  static const AssetImage grownManyBananas = AssetImage('assets/bananas.png');

  static final List<AssetImage> all = [
    tree1,
    tree2,
    tree3,
    tree4,
    tree5,
    grownNoBananas,
    grownOneBanana,
    grownManyBananas,
  ];

  /// Preload all images at once
  static Future<void> preload(BuildContext context) async {
    for (final tree in all) {
      await precacheImage(tree, context);
    }
  }
}
