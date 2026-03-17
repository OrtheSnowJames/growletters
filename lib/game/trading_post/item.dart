import 'package:flutter/material.dart';

enum ItemActionType { none, eat, plantTree }

class Item {
  Item({
    required this.id,
    required this.assetPath,
    required this.label,
    required this.description,
    required this.actionType,
    this.actionLabel,
  });

  final String id;
  final String assetPath;
  final String label;
  final String description;
  final ItemActionType actionType;
  final String? actionLabel;

  Image buildImage({BoxFit fit = BoxFit.contain}) {
    return Image.asset(assetPath, fit: fit, filterQuality: FilterQuality.none);
  }
}

typedef ItemCollection = Map<String, Item>;

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.assetPath,
    required this.label,
    required this.description,
    this.initialCount = 0,
    this.actionType = ItemActionType.none,
    this.actionLabel,
  });

  final String id;
  final String assetPath;
  final String label;
  final String description;
  final int initialCount;
  final ItemActionType actionType;
  final String? actionLabel;
}

class TradeDefinition {
  const TradeDefinition({
    required this.giveItemId,
    required this.giveCount,
    required this.receiveItemId,
    required this.receiveCount,
    this.useMarketPrice = false,
  });

  final String giveItemId;
  final int giveCount;
  final String receiveItemId;
  final int receiveCount;
  final bool useMarketPrice;
}
