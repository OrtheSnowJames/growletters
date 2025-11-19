import 'package:flutter/material.dart';

class Item {
  Item({
    required this.id,
    required this.image,
    required this.description,
    required this.count,
  });

  final String id;
  final Image image;
  final String description;
  int count;

  Item copyWith({int? count}) {
    return Item(
      id: id,
      image: image,
      description: description,
      count: count ?? this.count,
    );
  }
}

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
