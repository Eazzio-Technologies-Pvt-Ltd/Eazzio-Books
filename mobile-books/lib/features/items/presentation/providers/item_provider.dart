import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/items/data/models/item.dart';
import 'package:mobile_books/features/items/data/models/item_history.dart';
import 'package:mobile_books/features/items/data/models/inventory_movement.dart';
import 'package:mobile_books/features/items/data/services/item_service.dart';

class ItemsListFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

/// Filter state for items list: 'all', 'active', 'inactive', 'goods', 'services'
final itemsListFilterProvider = NotifierProvider<ItemsListFilterNotifier, String>(() {
  return ItemsListFilterNotifier();
});

class ItemSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

/// Search query state for items list
final itemSearchQueryProvider = NotifierProvider<ItemSearchQueryNotifier, String>(() {
  return ItemSearchQueryNotifier();
});

/// Notifier that manages the list of items fetched from backend
class ItemsNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() {
    return ref.watch(itemServiceProvider).getItems();
  }

  /// Explicitly reloads item listings from backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(itemServiceProvider).getItems();
    });
  }

  /// Dispatches item creation and refreshes listings.
  Future<Item> createItem(Item item) async {
    final service = ref.read(itemServiceProvider);
    final result = await service.createItem(item);
    ref.invalidateSelf(); // Force rebuild to update list views
    return result;
  }

  /// Dispatches item updates and invalidates cache.
  Future<Item> updateItem(int id, Map<String, dynamic> updates) async {
    final service = ref.read(itemServiceProvider);
    final result = await service.updateItem(id, updates);
    ref.invalidateSelf();
    ref.invalidate(itemDetailsProvider(id)); // Invalidate detail cache
    ref.invalidate(itemHistoryProvider(id)); // Invalidate history cache
    return result;
  }

  /// Dispatches item deletion and updates list views.
  Future<void> deleteItem(int id) async {
    final service = ref.read(itemServiceProvider);
    await service.deleteItem(id);
    ref.invalidateSelf();
    ref.invalidate(itemDetailsProvider(id));
    ref.invalidate(itemHistoryProvider(id));
    ref.invalidate(itemMovementsProvider(id));
  }

  /// Adjusts stock manual adjustment and refreshes inventory.
  Future<Map<String, dynamic>> createInventoryMovement(Map<String, dynamic> body) async {
    final service = ref.read(itemServiceProvider);
    final result = await service.createInventoryMovement(body);
    
    // Invalidate caches to trigger re-fetch and render updated values
    ref.invalidateSelf();
    if (body['item_id'] != null) {
      final itemId = body['item_id'] as int;
      ref.invalidate(itemDetailsProvider(itemId));
      ref.invalidate(itemMovementsProvider(itemId));
    }
    return result;
  }
}

final itemsProvider = AsyncNotifierProvider<ItemsNotifier, List<Item>>(() {
  return ItemsNotifier();
});

/// Filtered list of items matching filter selection and search query
final filteredItemsProvider = Provider<AsyncValue<List<Item>>>((ref) {
  final itemsState = ref.watch(itemsProvider);
  final filter = ref.watch(itemsListFilterProvider);
  final searchQuery = ref.watch(itemSearchQueryProvider).toLowerCase();

  return itemsState.whenData((list) {
    var result = list;

    // Apply category/status filter to match web application views
    if (filter == 'active') {
      // In the database there is no is_active field for items, meaning all items are active
      result = list;
    } else if (filter == 'inactive') {
      // Return empty since no items are inactive on the backend
      result = [];
    } else if (filter == 'low_stock') {
      result = list.where((item) => item.isInventoryTracked && item.stockQuantity <= item.reorderLevel).toList();
    } else if (filter == 'goods') {
      result = list.where((item) => item.itemType.toLowerCase() == 'goods').toList();
    } else if (filter == 'services') {
      result = list.where((item) => 
        item.itemType.toLowerCase() == 'service' || 
        item.itemType.toLowerCase() == 'services'
      ).toList();
    }

    // Apply search query filter
    if (searchQuery.isNotEmpty) {
      result = result.where((item) {
        final name = item.name.toLowerCase();
        final sku = (item.sku ?? '').toLowerCase();
        final desc = (item.description ?? '').toLowerCase();
        final unit = (item.unit ?? '').toLowerCase();
        return name.contains(searchQuery) ||
            sku.contains(searchQuery) ||
            desc.contains(searchQuery) ||
            unit.contains(searchQuery);
      }).toList();
    }

    return result;
  });
});

/// Fetches item details by ID
final itemDetailsProvider = FutureProvider.family<Item, int>((ref, id) {
  return ref.watch(itemServiceProvider).getItemById(id);
});

/// Fetches audit history/modification log for a single item
final itemHistoryProvider = FutureProvider.family<List<ItemHistory>, int>((ref, id) {
  return ref.watch(itemServiceProvider).getItemHistory(id);
});

/// Fetches inventory stock movement logs for a single item
final itemMovementsProvider = FutureProvider.family<List<InventoryMovement>, int>((ref, id) {
  return ref.watch(itemServiceProvider).getItemMovements(id);
});

/// Fetches list of preferred vendors from contacts backend
final legacyVendorsRawProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(itemServiceProvider).getVendors();
});

/// Fetches all inventory movements across all items
final allInventoryMovementsProvider = FutureProvider<List<InventoryMovement>>((ref) {
  return ref.watch(itemServiceProvider).getInventoryMovements();
});
