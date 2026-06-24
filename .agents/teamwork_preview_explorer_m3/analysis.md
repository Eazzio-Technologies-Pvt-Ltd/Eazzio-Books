# Cash Flow Forecasting Analysis (Milestone 3)

## Executive Summary
This analysis details the design, codebase integration, and automated testing architecture for **Milestone 3: Advanced Dashboard Forecasting Screens** in Eazzio-Books. The forecasting features, charts, navigation, and testing coverage are already fully implemented in the workspace, compile successfully, and pass all automated tests.

---

## 1. Codebase Architecture & File Locations
The feature-first modular structure for Cash Flow Forecasting is located within the `dashboard` and `core` directories of `eazzio_books_mobile`:

| Layer | File Path | Purpose |
|---|---|---|
| **Domain Models** | `lib/features/dashboard/domain/projected_payment_model.dart` | Models customer invoices due (projected receivables) |
| **Domain Models** | `lib/features/dashboard/domain/projected_expense_model.dart` | Models vendor bills & active recurring expenses (projected payables) |
| **Data Repositories** | `lib/features/dashboard/data/forecasting_repository.dart` | Repository wrapper executing HTTP requests to the backend APIs |
| **State Providers** | `lib/features/dashboard/presentation/forecasting_provider.dart` | Riverpod providers handling caching, concurrent fetching, and timeline aggregations |
| **Screens** | `lib/features/dashboard/presentation/forecasting_screen.dart` | Rendering the user interface, summary cards, trend chart, and breakdown table |
| **Screens** | `lib/features/dashboard/presentation/dashboard_screen.dart` | Main dashboard containing a quick-access card to navigate to forecasting |
| **Screens** | `lib/features/dashboard/presentation/more_screen.dart` | Drawer/More list containing a menu item linking to forecasting |
| **Routing** | `lib/app/router.dart` | `GoRouter` mapping configuration for `/dashboard/forecasting` |
| **Unit Tests** | `test/features/dashboard/forecasting_provider_test.dart` | Verifies models parsing, Concurrent fetching, overdue pooling, and interval math |
| **Widget Tests** | `test/features/dashboard/forecasting_screen_test.dart` | Verifies loader rendering, table contents, tab switcher, error states, and navigation |

---

## 2. API Data Contracts & Domain Models
The forecasting screen consumes two backend endpoints under the `/api` prefix:
1. `GET /api/accounts/projected-payments` (Returns pending customer invoices due for upcoming months)
2. `GET /api/accounts/projected-expenses` (Returns combined pending vendor bills and active recurring expenses)

### A. Projected Payments Schema
**Backend Query:** Fetches from `invoices` table where `balance_due > 0` and status is not `'paid'`, `'cancelled'`, etc.
**API Payload Format:**
```json
{
  "total_projected_payment": 25000.00,
  "projected_month": 7,
  "projected_year": 2026,
  "bills": [
    {
      "bill_id": 12,
      "bill_number": "INV-001",
      "vendor_name": "Customer Name LLC",
      "bill_date": "2026-06-15T00:00:00.000Z",
      "due_date": "2026-07-15T00:00:00.000Z",
      "total_amount": "5000.00",
      "paid_amount": "2500.00",
      "pending_amount": "2500.00",
      "status": "Partially Paid",
      "projected_for_month": 7,
      "projected_for_year": 2026,
      "write_off_status": null
    }
  ]
}
```
**Dart Parsing Strategy (`ProjectedPaymentItem`):**
To ensure resilience against backend differences (e.g. numeric fields returned as strings or floats), parsing incorporates a helper method `_toDouble`:
```dart
static double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
```
Properties mapped in domain: `billId`, `billNumber`, `vendorName` (supports `vendor_name` or `customer_name` JSON keys), `billDate`, `dueDate`, `totalAmount`, `paidAmount`, `pendingAmount`, `status`, `projectedForMonth`, `projectedForYear`, `writeOffStatus`.

### B. Projected Expenses Schema
**Backend Query:** Joins pending bills from `bills` table and active recurring expenses from `recurring_expenses` hitting in the target range, sorted by `due_date`.
**API Payload Format:**
```json
{
  "total_projected_expense": 18000.00,
  "projected_month": 7,
  "projected_year": 2026,
  "expenses": [
    {
      "expense_id": 3,
      "reference_number": "BILL-99",
      "vendor_name": "Initech",
      "date": "2026-06-10T00:00:00.000Z",
      "due_date": "2026-07-10T00:00:00.000Z",
      "total_amount": "10000.00",
      "pending_amount": "10000.00",
      "status": "Open",
      "type": "Bill"
    },
    {
      "expense_id": 4,
      "reference_number": "Office Rent",
      "vendor_name": "Office Expense",
      "date": "2026-01-01T00:00:00.000Z",
      "due_date": "2026-07-01T00:00:00.000Z",
      "total_amount": "8000.00",
      "pending_amount": "8000.00",
      "status": "Active",
      "type": "Recurring",
      "frequency": "Monthly"
    }
  ]
}
```
**Dart Parsing Strategy (`ProjectedExpenseItem`):**
Fields parsed: `expenseId`, `referenceNumber`, `vendorName`, `date`, `dueDate`, `totalAmount`, `pendingAmount`, `status`, `type` (distinguishes `'Bill'` vs `'Recurring'`), `dueDay`, `frequency`. Uses the same `_toDouble` safety conversion.

---

## 3. Riverpod State Providers & Aggregation Logic
The state management uses Riverpod to concurrently fetch both endpoints and transform raw items into structured period datapoints.

### A. Repositories & Sub-Providers
- `forecastingRepositoryProvider`: Resolves to `ForecastingRepository` using `apiServiceProvider`.
- `projectedPaymentsProvider`: Auto-disposed future provider retrieving customer receivables.
- `projectedExpensesProvider`: Auto-disposed future provider retrieving expenses.
- `forecastIntervalProvider`: State provider tracking user interval: `ForecastTrendInterval.monthly`, `quarterly`, or `yearly`.

### B. Core Aggregation Algorithm (`forecastingDataProvider`)
1. **Concurrent Fetching:** Hits both `projectedPaymentsProvider` and `projectedExpensesProvider` using `Future.wait`.
2. **Timeline Generation:** Reads the start month and year from the backend responses (defaulting to the current local month/year if unavailable) and constructs a **6-month future timeline**:
   ```dart
   final List<DateTime> months = List.generate(6, (i) {
     return DateTime(start.year, start.month + i, 1);
   });
   ```
3. **Overdue Pooling (Financial Rule):** Payments or expenses with a due date *before* the first month in our timeline are grouped into the **first month** (`months.first`). This treats overdue outstanding cash flows as immediate. Remaining items are assigned to their respective months.
4. **Interval Transformation:**
   - **Monthly:** Returns 6 data points labeled using `DateFormat("MMM 'yy")`.
   - **Quarterly:** Groups the 6 months into their respective quarters (e.g. `Q3 '26`) and sums the income and expenses for those months.
   - **Yearly:** Groups the 6 months into their respective years (e.g. `2026`) and sums the values.

---

## 4. Forecasting Screen Visualization using `fl_chart`
The `ForecastingScreen` uses a `LineChart` from the `fl_chart` library to visualize cash flow trends.

### A. LineChart Datapoints (`spots`)
We draw three lines representing three trend indicators:
1. **Projected Income (Green Line):** `LineChartBarData` built using spots:
   `spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].projectedIncome))`
2. **Projected Expenses (Red Line):** `LineChartBarData` built using spots:
   `spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].projectedExpense))`
3. **Net Cash Flow (Navy Blue Line):** `LineChartBarData` built using spots:
   `spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].netProfit))`

### B. Custom Horizontal Axis (X-Axis) Titles
To render period labels (e.g. "Jul '26", "Q3 '26", "2026") on the bottom axis, `getTitlesWidget` extracts the labels:
```dart
bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    getTitlesWidget: (double value, TitleMeta meta) {
      final idx = value.toInt();
      if (idx >= 0 && idx < points.length) {
        return SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4.0,
          child: Text(
            points[idx].period,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        );
      }
      return const SizedBox();
    },
    reservedSize: 24,
    interval: 1,
  ),
)
```

### C. Touch Interaction Tooltips
We style tooltips using `LineTouchTooltipData` to format currency dynamically when the user taps points on the lines:
```dart
LineTouchTooltipData(
  getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
  getTooltipItems: (List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((LineBarSpot touchedSpot) {
      final textStyle = TextStyle(
        color: touchedSpot.bar.color ?? Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );
      String title = 'Income';
      if (touchedSpot.barIndex == 1) {
        title = 'Expense';
      } else if (touchedSpot.barIndex == 2) {
        title = 'Net';
      }
      return LineTooltipItem(
        '$title: ${_formatCurrency(touchedSpot.y)}',
        textStyle,
      );
    }).toList();
  },
)
```

---

## 5. UI Integration Details
1. **Router (`router.dart`):** Registered as a root-level route outside the main `ShellRoute` so it can overlay full screen with its own back button:
   ```dart
   GoRoute(
     path: '/dashboard/forecasting',
     builder: (context, state) => const ForecastingScreen(),
   )
   ```
2. **Dashboard (`dashboard_screen.dart`):** Integrates an interactive `forecasting_navigation_card` beneath the Income vs Expenses chart. Tapping it calls `context.push('/dashboard/forecasting')`.
3. **More Screen (`more_screen.dart`):** Appends a new menu card for `Cash Flow Forecasting` that routes users directly to `/dashboard/forecasting`.

---

## 6. Automated Testing & Verification Strategy
The tests verify the implementation robustness under unit (logic) and widget (UI) levels.

### A. Mocking Strategy
The repository is mocked using `FakeForecastingRepository` extending `ForecastingRepository`:
```dart
class FakeForecastingRepository implements ForecastingRepository {
  final ProjectedPaymentResponse mockPayments;
  final ProjectedExpenseResponse mockExpenses;
  bool shouldFail = false;

  FakeForecastingRepository({required this.mockPayments, required this.mockExpenses});

  @override
  Future<ProjectedPaymentResponse> getProjectedPayments() async {
    if (shouldFail) throw Exception('API Error');
    return mockPayments;
  }

  @override
  Future<ProjectedExpenseResponse> getProjectedExpenses() async {
    if (shouldFail) throw Exception('API Error');
    return mockExpenses;
  }
}
```

### B. Riverpod State Overrides in Tests
- **Unit Tests:** Override providers using a `ProviderContainer`:
  ```dart
  final container = ProviderContainer(
    overrides: [
      forecastingRepositoryProvider.overrideWithValue(fakeRepo),
    ],
  );
  addTearDown(container.dispose);
  ```
- **Widget Tests:** Override providers in a `ProviderScope`:
  ```dart
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        forecastingRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(home: ForecastingScreen()),
    ),
  );
  ```

### C. Critical Test Scenarios Evaluated
1. **Model Parsing:** Confirms string decimal fields parse correctly to `double`.
2. **Overdue Mapping:** Verifies that invoices overdue from previous months are grouped into the first month of the forecast timeline.
3. **Quarterly & Yearly Accumulations:** Verifies proper quarter and year mathematical additions.
4. **Segmented Control Switching:** Verifies that clicking "Quarterly" and "Yearly" segmented buttons rebuilds the charts and tables with correct period groupings.
5. **Error & Recovery Check:** Verifies error state displays, tapping "Retry" triggers a fresh fetch, and renders successfully upon recovery.
6. **Navigation Test:** Validates that clicking the menu card in `MoreScreen` successfully navigates to `ForecastingScreen` when wrapped with `GoRouter`.

*Note: All 15 tests (including the low stock alerts tests and forecasting tests) pass clean.*

---

## 7. Step-by-Step Implementation Verification Checklist
To confirm or re-verify this milestone from scratch, follow this exact sequence:
1. Run `flutter pub get` inside `eazzio_books_mobile` to verify package configs.
2. Confirm the presence of API routes `/accounts/projected-payments` and `/accounts/projected-expenses` in the backend.
3. Review the `projected_payment_model.dart` and `projected_expense_model.dart` domains.
4. Check the `forecasting_repository.dart` and the mapping providers in `forecasting_provider.dart`.
5. Verify `fl_chart` imports and line configs in `forecasting_screen.dart`.
6. Inspect the integration card in `dashboard_screen.dart` and list entry in `more_screen.dart`.
7. Ensure route `/dashboard/forecasting` is imported and registered in `router.dart`.
8. Execute `flutter test` to verify all automated test assertions pass successfully.
