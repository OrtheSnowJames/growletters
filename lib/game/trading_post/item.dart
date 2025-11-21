import 'package:flutter/material.dart';

class Item {
  Item({
    required this.id,
    required this.image,
    required this.description,
  });

  final String id;
  final Image image;
  final String description;
}

typedef ItemCollection = Map<String, Item>;

class TradeDefinition {
  const TradeDefinition({
    required this.giveItemId,
    required this.giveCount,
    required this.receiveItemId,
    required this.receiveCount,
  });

  final String giveItemId;
  final int giveCount;
  final String receiveItemId;
  final int receiveCount;
}
