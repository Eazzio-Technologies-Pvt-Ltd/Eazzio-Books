# Low Stock Report Navigation Entry Points Analysis

## Executive Summary
This analysis explores the navigation entry points and triggers for integrating a new **Low Stock Report** screen within the `eazzio_books_mobile` application. 
- A new menu item will be integrated into the navigation hub `more_screen.dart` to allow direct access to the report.
- A dynamic, visual alert banner will be placed in the inventory overview screen `inventory_list_screen.dart` to notify users of critical inventory states and act as a quick link to the report.
- Riverpod state caching will be leveraged via `itemListProvider` to fetch/filter low stock data reactively without unnecessary network calls.

---

## 1. File Locations & Scope

The following files were located and analyzed:
1. **`lib/features/dashboard/presentation/more_screen.dart`** - Main hub for advanced menus and screens.
2. **`lib/features/inventory/presentation/inventory_list_screen.dart`** - Main list view for products and services.
3. **`lib/features/inventory/presentation/inventory_provider.dart`** - State notifier and provider configuration for inventory items.
4. **`lib/app/router.dart`** - Routing management using `go_router`.
5. **`lib/features/inventory/domain/item_model.dart`** - Definition of the `Item` data model (contains properties like `isInventoryTracked`, `stockQuantity`, `reorderLevel`).

---

## 2. UI Structures & Integration Locations

### A. More Screen (`more_screen.dart`)
- **Structure**: Uses a standard stateless `Scaffold` with a `ListView` padding of `16.0`. Individual items are represented by a custom private method `_buildMenuCard` that returns an elevated `Card` wrapped in an `InkWell` for router navigation.
- **Proposed Location**: Position the "Low Stock Report" right below the **Inventory & Items** card. This keeps inventory-specific menus grouped logically together.
- **Menu Card Details**:
  - **Icon**: `Icons.warning_amber_outlined` (visually distinct warning color/shape).
  - **Title**: `'Low Stock Report'`
  - **Subtitle**: `'Monitor items that are running low and require reorder'`
  - **Route**: `'/reports/low-stock'`
  - **Color**: `Colors.orange.shade850` (warm alert tone consistent with warnings).

### B. Inventory List Screen (`inventory_list_screen.dart`)
- **Structure**: A `ConsumerStatefulWidget` containing a `Column` with two main children:
  1. A `Padding` containing a search `TextField` (`Search Field`).
  2. An `Expanded` list that resolves `itemsState` (from `itemListProvider`) through a `.when` callback (representing `data`, `loading`, and `error` states).
- **Proposed Location**: Directly inside the main `Column`, right below the Search Field and above the `Expanded` inventory items list. This ensures the banner is anchored at the top of the content area for maximum visibility.
- **Dynamic State Logic**: Instead of placing the logic deeply inside the `.when` data branch, we can read the low stock count in the root of the build method via `maybeWhen` on `itemListProvider`. This simplifies layouts and prevents display errors when loading or recovery states occur.

---

## 3. Implementation Recommendations

### Recommendation 1: More Screen Entry Point (`more_screen.dart`)
Inject a new menu card below `Inventory & Items` (around line 97):

```dart
          _buildMenuCard(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Inventory & Items',
            subtitle: 'View products catalog and tracked stock levels',
            route: '/inventory',
            color: Colors.indigo.shade800,
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.warning_amber_outlined,
            title: 'Low Stock Report',
            subtitle: 'Monitor items that are running low and require reorder',
            route: '/reports/low-stock',
            color: Colors.orange.shade800,
          ),
```

### Recommendation 2: Inventory List Screen Banner (`inventory_list_screen.dart`)
Retrieve the count at the beginning of the `build` method using `itemListProvider`:

```dart
    final itemsState = ref.watch(itemListProvider);
    
    // Dynamically compute count of items below reorder thresholds
    final lowStockCount = itemsState.maybeWhen(
      data: (items) => items.where((i) => i.isInventoryTracked && i.stockQuantity <= i.reorderLevel).length,
      orElse: () => 0,
    );
```

Then, inject the conditional banner directly into the `Column` layout:

```dart
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField( ... ),
          ),

          // Dynamic Low Stock Banner
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
              child: Card(
                elevation: 0,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () => context.push('/reports/low-stock'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$lowStockCount items are low in stock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          'View Report',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.amber.shade900, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
```

### Recommendation 3: Add Routing Entry in `lib/app/router.dart`
Add the path in the `GoRouter` configuration:

```dart
      GoRoute(
        path: '/reports/low-stock',
        builder: (context, state) => const LowStockReportScreen(),
      ),
```

### Recommendation 4: Create `LowStockReportScreen` (`lib/features/reports/presentation/low_stock_report_screen.dart`)
Implement the report page leveraging the existing `itemListProvider` for performance optimization and local caching:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../inventory/presentation/inventory_provider.dart';

class LowStockReportScreen extends ConsumerWidget {
  const LowStockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Report'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: itemsState.when(
        data: (items) {
          final lowStockItems = items
              .where((item) =>
                  item.isInventoryTracked &&
                  item.stockQuantity <= item.reorderLevel)
              .toList();

          if (lowStockItems.isEmpty) {
            return const Center(
              child: Text(
                'All items are sufficiently stocked!',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(itemListProvider.notifier).loadItems(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lowStockItems.length,
              itemBuilder: (context, index) {
                final item = lowStockItems[index];
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
                    subtitle: Text('SKU: ${item.sku ?? "N/A"}'),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Stock: ${item.stockQuantity.toStringAsFixed(0)} ${item.unit ?? "pcs"}',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Reorder Level: ${item.reorderLevel.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Failed to load low stock items: $err'),
        ),
      ),
    );
  }
}
```
