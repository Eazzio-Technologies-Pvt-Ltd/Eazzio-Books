# Handoff Report — Low Stock Report Navigation Entry Points

## 1. Observation
The following file structures and properties were directly observed in the `eazzio_books_mobile` directory:
- **More Options Menu Hub**: `lib/features/dashboard/presentation/more_screen.dart` (lines 90-97) contains the card for Inventory:
  ```dart
  _buildMenuCard(
    context,
    icon: Icons.inventory_2_outlined,
    title: 'Inventory & Items',
    subtitle: 'View products catalog and tracked stock levels',
    route: '/inventory',
    color: Colors.indigo.shade800,
  ),
  ```
- **Inventory List Layout**: `lib/features/inventory/presentation/inventory_list_screen.dart` (lines 24-34) displays:
  ```dart
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Items'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Field
  ```
- **Item Stock Properties**: In `lib/features/inventory/domain/item_model.dart` (lines 19-24), the model defines stock state attributes:
  ```dart
  final bool isInventoryTracked;
  final double reorderLevel;
  final double stockQuantity;
  ```
- **Routing**: `lib/app/router.dart` maps endpoints using `GoRouter`.

---

## 2. Logic Chain
- To direct users to the upcoming "Low Stock Report", we need persistent and contextual entry points.
- **Entry Point 1 (More Screen)**: Since `more_screen.dart` serves as an options menu, appending a "Low Stock Report" item directly after "Inventory & Items" is the most contextually relevant position.
- **Entry Point 2 (Contextual Banner)**: In `inventory_list_screen.dart`, we watch `itemListProvider`. By parsing the loaded inventory state using:
  ```dart
  final lowStockCount = itemsState.maybeWhen(
    data: (items) => items.where((i) => i.isInventoryTracked && i.stockQuantity <= i.reorderLevel).length,
    orElse: () => 0,
  );
  ```
  we dynamically determine how many items are low in stock.
- If `lowStockCount > 0`, we inject an alert banner below the search bar that visually signals the warning state and navigates directly to `/reports/low-stock` upon tapping.
- Crucially, the new `LowStockReportScreen` can watch `itemListProvider` to retrieve the cached items and filter them client-side. This results in zero extra network overhead.

---

## 3. Caveats
- The `LowStockReportScreen` itself does not yet exist. This is a read-only investigation, so no files were modified. The screen must be created and registered in `router.dart` during the implementation phase.
- Assumed standard Riverpod reactive patterns are used for StateNotifier management.

---

## 4. Conclusion
We recommend implementing navigation hooks in two places:
1. **`more_screen.dart`**: Add a list card below 'Inventory & Items' routing to `'/reports/low-stock'`.
2. **`inventory_list_screen.dart`**: Add a warning alert banner in the layout `Column` (above the list view) when `lowStockCount > 0`.
3. **`router.dart`**: Register the route `/reports/low-stock` pointing to `LowStockReportScreen`.

---

## 5. Verification Method
1. Inspect proposed changes in the analysis file `/home/rahul-kumar/Desktop/Eazzio-Books/.agents/teamwork_preview_explorer_low_stock_2/analysis.md`.
2. Check compiling and running of tests via:
   ```bash
   cd /home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile && flutter test
   ```
3. Verify routes match those specified in `lib/app/router.dart`.
