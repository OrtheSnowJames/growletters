import 'item.dart';

class ItemRegistry {
  ItemRegistry._();

  static final ItemCollection _items = {};

  static ItemCollection get items => _items;

  static void setItems(ItemCollection newItems) {
    _items
      ..clear()
      ..addAll(newItems);
  }

  static Item? getById(String id) => _items[id];

  static bool get isInitialized => _items.isNotEmpty;
}
