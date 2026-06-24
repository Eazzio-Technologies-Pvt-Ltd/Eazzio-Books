# Low-Stock Alerts and Inventory Warning System Analysis (Milestone 2)

## Executive Summary
This analysis details the structure and implementation requirements for the **Low-Stock Alerts and Inventory Warning System** in the `eazzio_books_mobile` codebase. The existing router, models, and provider structures are fully compatible, and we recommend a client-side filtered Riverpod provider combined with a custom `LowStockReportScreen` using standard Indigo styling for seamless integration.

---

## 1. Codebase Location & Structure Analysis

### A. Router Configuration (`lib/app/router.dart`)
The application uses the `go_router` package for navigation. In `lib/app/router.dart`, the router matches paths in the order they are defined.
Currently, inventory routes are defined as:
```dart
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryListScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ItemDetailScreen(itemId: id);
        },
      ),
```
* **Routing Conflict Constraint**: Because `/inventory/:id` attempts to parse the route parameter `id` as an `int` via `int.parse(...)`, declaring a route like `/inventory/low-stock` *after* `/inventory/:id` would lead to route matching collision, resulting in a runtime `FormatException` (invalid radix-10 number).
* **Mitigation**: The `/inventory/low-stock` route must be declared **before** the `/inventory/:id` route in the router's list of routes.

### B. Inventory Features Directory (`lib/features/inventory/`)
The inventory module follows a clean feature-first architecture:
* **Domain Layer (`lib/features/inventory/domain/`)**:
  - `item_model.dart`: Defines the `Item` model representing goods/services.
  - `inventory_movement_model.dart`: Records adjustments, additions, and removals of stock.
* **Data Layer (`lib/features/inventory/data/`)**:
  - `inventory_repository.dart`: Coordinates network calls to the backend via `ApiService`.
* **Presentation Layer (`lib/features/inventory/presentation/`)**:
  - `inventory_list_screen.dart`: Catalog of products/services with a search query.
  - `inventory_provider.dart`: Contains Riverpod providers for managing inventory state.
  - `item_detail_screen.dart`: Visualizes item specifics and lists history logs of stock movements.

---

## 2. Model & State Management Verification

### A. Item Model Verification (`item_model.dart`)
The `Item` class defines all required attributes for tracking inventory. Verification details:
- **`isInventoryTracked`**: Defined as `final bool isInventoryTracked` (line 19) and correctly parsed from/to JSON (lines 71, 99).
- **`stockQuantity`**: Defined as `final double stockQuantity` (line 24) and correctly parsed from/to JSON (lines 76, 104).
- **`reorderLevel`**: Defined as `final double reorderLevel` (line 23) and correctly parsed from/to JSON (lines 75, 103).

### B. State Management (`inventory_provider.dart`)
- **`itemListProvider`**: A `StateNotifierProvider` that uses `ItemListNotifier` to fetch a list of all items (`List<Item>`) from the `/items` endpoint via `InventoryRepository.getItems()`.
- The UI handles errors and loading states reactively using Riverpod's `AsyncValue` pattern.

### C. Backend Alignment Awareness
In `backend-books`, database tables are patched upon startup via `src/controllers/inventoryController.js`, adding:
- `stock_quantity` (NUMERIC)
- `reorder_level` (NUMERIC)
- `is_inventory_tracked` (BOOLEAN)
These columns are read/updated by `itemController.js` and `inventoryController.js`. The mobile app's `Item.fromJson` handles safety fallbacks seamlessly.

---

## 3. Implementation Strategy for Low-Stock Alerts

### A. Derived Riverpod Provider
Rather than creating separate API queries, we should define a derived Riverpod provider in `lib/features/inventory/presentation/inventory_provider.dart` to compute the low-stock list reactively:
```dart
final lowStockItemsProvider = Provider.autoDispose<AsyncValue<List<Item>>>((ref) {
  final itemsState = ref.watch(itemListProvider);
  return itemsState.whenData((items) => items.where((item) =>
    item.isInventoryTracked && item.stockQuantity <= item.reorderLevel
  ).toList());
});
```

### B. Routing Configuration
Add the route to `lib/app/router.dart` **before** `/inventory/:id` as shown below:
```dart
      // Import the new screen
      import '../features/inventory/presentation/low_stock_report_screen.dart';

      // Inside routerProvider routes list:
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryListScreen(),
      ),
      GoRoute(
        path: '/inventory/low-stock',
        builder: (context, state) => const LowStockReportScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ItemDetailScreen(itemId: id);
        },
      ),
```

### C. UI Component Blueprint (`low_stock_report_screen.dart`)
Create `lib/features/inventory/presentation/low_stock_report_screen.dart` with the following implementation design to match existing typography and styling (Indigo theme):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'inventory_provider.dart';

class LowStockReportScreen extends ConsumerWidget {
  const LowStockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockState = ref.watch(itemListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Report'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: lowStockState.when(
        data: (items) {
          final lowStockItems = items.where((item) {
            return item.isInventoryTracked && item.stockQuantity <= item.reorderLevel;
          }).toList();

          if (lowStockItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'All stock levels are healthy!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No items are currently below their reorder levels.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info Banner at Top
              Container(
                width: double.infinity,
                color: Colors.amber.shade50,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${lowStockItems.length} items have fallen below their reorder thresholds.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(itemListProvider.notifier).loadItems(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: lowStockItems.length,
                    itemBuilder: (context, index) {
                      final item = lowStockItems[index];
                      final shortage = item.reorderLevel - item.stockQuantity;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade800,
                            child: const Icon(Icons.warning_amber_rounded),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'SKU: ${item.sku ?? "N/A"} | Reorder Level: ${item.reorderLevel.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Stock: ${item.stockQuantity.toStringAsFixed(0)} ${item.unit ?? "pcs"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Shortage: ${shortage.toStringAsFixed(0)} ${item.unit ?? "pcs"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/inventory/${item.id}'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text('Failed to load report: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(itemListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### D. Navigation Entry Points
1. **Inventory App Bar Icon**: Add an action button in `/inventory` App Bar for fast navigation:
   ```dart
   actions: [
     IconButton(
       icon: const Icon(Icons.warning_amber_rounded),
       tooltip: 'Low Stock Report',
       onPressed: () => context.push('/inventory/low-stock'),
     ),
   ]
   ```
2. **More Screen Menu**: Link to `/inventory/low-stock` under the reports section or as a standalone alert menu.
