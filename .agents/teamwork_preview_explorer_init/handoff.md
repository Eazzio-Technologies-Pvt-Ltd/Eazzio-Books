# Handoff Report: Initial Codebase Exploration & Mapping

## 1. Observation

- **Flutter Analyze**:
  - Command run: `flutter analyze` inside `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile`
  - Output:
    ```text
    Analyzing eazzio_books_mobile...                                
    No issues found! (ran in 2.1s)
    ```

- **Flutter Test**:
  - Command run: `flutter test` inside `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile`
  - Output:
    ```text
    00:19 +0 -1: Counter increments smoke test [E]                                 
      Test failed. See exception logs above.
      The test description was: Counter increments smoke test
      ...
    00:19 +0 -1: Some tests failed.
    ```
  - Verbatim Exception:
    ```text
    Expected: exactly one matching candidate
      Actual: _TextWidgetFinder:<Found 0 widgets with text "0": []>
       Which: means none were found but one was expected
    ```

- **Accounting Routes & Controllers (Dashboard Forecasting)**:
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/routes/accountingRoutes.js`
    - Line 18: `router.get("/accounts/projected-payments", authMiddleware, getProjectedPayments);`
    - Line 19: `router.get("/accounts/projected-expenses", authMiddleware, getProjectedExpenses);`
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/controllers/accountingController.js`
    - Lines 355-394: Function `getProjectedPayments` queries `invoices` table joined with `customers` table on `customer_id`. Sums `balance_due` into `total_projected_payment` and returns mapped rows as `bills`.
    - Lines 403-481: Function `getProjectedExpenses` queries unpaid bills from `bills` table (type: `'Bill'`) and active recurring expenses from `recurring_expenses` (type: `'Recurring'`) hitting the next month. Sums `pending_amount` into `total_projected_expense`.

- **Inventory Routes & Controllers**:
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/routes/inventoryRoutes.js`
    - Line 8: `router.get("/inventory/items/:itemId/movements", authMiddleware, getItemMovements);`
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/controllers/inventoryController.js`
    - Lines 15-28: Table creation statement:
      ```sql
      CREATE TABLE IF NOT EXISTS inventory_movements (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        movement_type VARCHAR(30) NOT NULL,
        quantity NUMERIC(12,2) NOT NULL,
        ...
      )
      ```
    - Lines 123-128: Insert query inside `createMovement`:
      ```javascript
      const moveRes = await client.query(
        `INSERT INTO inventory_movements 
         (user_id, item_id, transaction_type, quantity_change, reference_number, entry_date, description)
         VALUES ($1, $2, 'adjustment', $3, $4, CURRENT_DATE, $5) RETURNING *`,
        [req.user.id, item_id, qtyChange, reference_number, notes || reason]
      );
      ```
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/controllers/deliveryChallanController.js`
    - Lines 400-402: Uses INSERT statement with `transaction_type`, `quantity_change`, `entry_date`, `description`.
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/controllers/itemController.js`
    - Lines 116-118: Uses INSERT statement with `transaction_type`, `quantity_change`, `entry_date`, `description`.
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile/lib/features/inventory/domain/inventory_movement_model.dart`
    - Lines 32-35:
      ```dart
      final type = json['transaction_type'] as String? ?? json['movement_type'] as String? ?? 'adjustment';
      final qty = (json['quantity_change'] as num? ?? json['quantity'] as num? ?? 0).toDouble();
      final desc = json['description'] as String? ?? json['reason'] as String?;
      final entryDate = json['entry_date'] as String? ?? json['created_at'] as String? ?? '';
      ```

- **Taxes Routes & Controllers**:
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/routes/taxRoutes.js`
  - File: `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/controllers/taxController.js`
    - Lines 7-18: Table `taxes` columns are `id`, `user_id`, `tax_name`, `tax_type`, `rate`, `description`, `status`, `is_deleted`, `created_at`, `updated_at`.
    - Endpoints: `GET /api/taxes`, `GET /api/taxes/:id`, `POST /api/taxes`, `PUT /api/taxes/:id`, `DELETE /api/taxes/:id` (which soft-deletes with `is_deleted = true`).

---

## 2. Logic Chain

1. Since `flutter analyze` completed with "No issues found!", the Flutter project code currently conforms to lint rules and compiler requirements.
2. Since `flutter test` failed and outputted an expectation error on `find.text('0')` in `widget_test.dart` line 19, and because the test tries to pump `EazzioBooksApp` (which watches `routerProvider` and expects `ProviderScope`) without a `ProviderScope` or correct UI widgets present, the test failure is due to a stale default test file left from the initial template, rather than a regression in production code.
3. In `inventoryController.js`, `deliveryChallanController.js`, and `itemController.js`, the SQL insert statements specify columns `transaction_type`, `quantity_change`, `entry_date`, and `description`. For these queries to execute successfully in the production/live database, those columns must be present.
4. However, the DDL block `ensureInventoryTables()` in `inventoryController.js` specifies `movement_type`, `quantity`, `reason`, `notes`, and `created_at`. This indicates that the table definition code is inconsistent with the data insertion code.
5. In `inventory_movement_model.dart`, the JSON parsing logic explicitly falls back between both formats (`transaction_type`/`movement_type`, `quantity_change`/`quantity`, etc.). This client-side mapping ensures that the mobile application remains robust against whichever version of the schema is active in the database.

---

## 3. Caveats

- Since no local Postgres server is running and no `.env` file containing database credentials is present in the workspace, a direct query on the active database catalog could not be performed.
- Assumptions are made based entirely on the backend code query structures and the mobile client fallbacks.

---

## 4. Conclusion

- The Flutter codebase is clean under linting but contains a stale/failing default widget test (`widget_test.dart`).
- All requested endpoints (dashboard forecasting, inventory movements, tax/GST) are mapped out successfully with their response schemas.
- The `inventory_movements` table schema exhibits a column-name discrepancy between backend table creation (`movement_type`, `quantity`) and data insertion/usage (`transaction_type`, `quantity_change`). The mobile app successfully bridges this discrepancy by parsing both schemas using dynamic fallbacks in `InventoryMovement.fromJson()`.

---

## 5. Verification Method

- Run `flutter analyze` inside `eazzio_books_mobile` to verify zero linting/compilation issues.
- Run `flutter test` inside `eazzio_books_mobile` to observe the widget test failure.
- Review `/home/rahul-kumar/Desktop/Eazzio-Books/backend-books/src/controllers/inventoryController.js` at lines 15-28 and lines 123-128 to confirm the schema vs query mismatch.
- Review `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile/lib/features/inventory/domain/inventory_movement_model.dart` at lines 30-51 to verify the client-side fallback parsing.
