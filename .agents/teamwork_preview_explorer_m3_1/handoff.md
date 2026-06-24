# Handoff Report: Milestone 3 Advanced Dashboard Forecasting Screens

This handoff report summarizes the observations, logic chain, caveats, conclusion, and verification method for the domain model and repository design for Milestone 3.

---

## 1. Observation
* **Endpoint Definitions**: In `/backend-books/src/routes/accountingRoutes.js` at line 18:
  `router.get("/accounts/projected-payments", authMiddleware, getProjectedPayments);`
  and in backend controller `/backend-books/src/controllers/accountingController.js` at lines 355 & 403.
* **JSON Structure Output**:
  - In `getProjectedPayments` (lines 389-394):
    ```javascript
    res.json({
      total_projected_payment,
      projected_month: projMonth,
      projected_year: projYear,
      bills
    });
    ```
    Note that the key containing the payment items list is named `"bills"` in the returned JSON, even though it maps customer invoices (receivables).
  - In `getProjectedExpenses` (lines 476-481):
    ```javascript
    res.json({
      total_projected_expense,
      projected_month: projMonth,
      projected_year: projYear,
      expenses: items
    });
    ```
* **Data Typings**: PostgreSQL `NUMERIC` types are returned as `String` in the list entries (such as `"5000.00"`) while aggregate values `total_projected_payment` and `total_projected_expense` are parsed with `parseFloat()` and returned as `double` (`num`).
* **Existing Code Style**:
  - `eazzio_books_mobile/lib/features/dashboard/data/dashboard_repository.dart` uses a concrete `DashboardRepository` class wrapping `ApiService`.
  - `eazzio_books_mobile/lib/features/dashboard/presentation/dashboard_provider.dart` registers providers via Riverpod.
  - `eazzio_books_mobile/test/features/inventory/low_stock_provider_test.dart` uses subclassed fake repositories with `noSuchMethod` implementation for testing.

---

## 2. Logic Chain
1. Since the backend returns numeric strings (e.g. `"5000.00"`) inside lists but numbers for root totals, simple casts (e.g. `as double` or `as num`) will fail at runtime and throw type casting exceptions.
2. Therefore, domain models must use a custom dynamic parser helper `_toDouble` that handles both `String` and `num` to prevent parsing failures.
3. Because the payments endpoint returns the list under the key `"bills"`, the ProjectedPaymentResponse parser must query the `"bills"` key to map payment items correctly.
4. Using a separate `ForecastingRepository` instead of extending `DashboardRepository` prevents class bloating and conforms to the Single Responsibility Principle.

---

## 3. Caveats
* The investigation does not cover the UI or charting screen design (e.g. `fl_chart`), as it is restricted to backend endpoints, domain models, and repositories.
* Assumes the backend behavior and database structures remain constant.

---

## 4. Conclusion
* We propose creating:
  1. `lib/features/dashboard/domain/projected_payment_model.dart`
  2. `lib/features/dashboard/domain/projected_expense_model.dart`
  3. `lib/features/dashboard/data/forecasting_repository.dart`
  4. `lib/features/dashboard/presentation/forecasting_provider.dart`
  5. `test/features/dashboard/forecasting_provider_test.dart`
* Exact code structures, json parsing methods, and test mocks are fully documented in `/home/rahul-kumar/Desktop/Eazzio-Books/.agents/teamwork_preview_explorer_m3_1/analysis.md`.

---

## 5. Verification Method
* **Test Command**: Run `flutter test test/features/dashboard/forecasting_provider_test.dart` (once files are created) to verify that model parsing handles both string decimals and numeric values successfully.
* **Layout Check**: Verify files are located inside `lib/features/dashboard/` and not in `.agents/` or core directories to maintain project structure layouts.
