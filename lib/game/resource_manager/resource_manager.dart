import 'package:flutter/material.dart';

class ResourceManager {
  static final AssetImage tree1 = const AssetImage('assets/missing_content.png');
  static final AssetImage tree2 = const AssetImage('assets/missing_content.png');
  static final AssetImage tree3 = const AssetImage('assets/missing_content.png');
  static final AssetImage tree4 = const AssetImage('assets/missing_content.png');
  static final AssetImage tree5 = const AssetImage('assets/missing_content.png');

  static final List<AssetImage> all = [
    tree1, tree2, tree3, tree4, tree5,
  ];

  /// Preload all images at once
  static Future<void> preload(BuildContext context) async {
    for (final tree in all) {
      await precacheImage(tree, context);
    }
  }
}