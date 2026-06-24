## 2026-06-20T14:46:18Z

You are the Worker subagent (Generation 2) for Milestone 3. Your task is to resolve all the code quality, UX/style, and testing issues identified during the review and challenger phases.

Please implement the following changes in the mobile app located at `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile`:

1. Fix Redundant Network Calls (Performance Bug):
   - Decouple the network request from the interval selection.
   - Create a cached `rawForecastingDataProvider` that concurrently fetches the raw ProjectedPaymentResponse and ProjectedExpenseResponse (using FutureProvider).
   - In `forecastingDataProvider`, watch `rawForecastingDataProvider` and `forecastIntervalProvider`. Aggregate/group the data synchronously when `rawForecastingDataProvider` has data.
   - This ensures toggling Monthly, Quarterly, and Yearly intervals does NOT trigger new network calls or show the loading spinner.

2. Fix Unsafe Type Casts in Deserialization:
   - In `lib/features/dashboard/domain/projected_payment_model.dart` and `lib/features/dashboard/domain/projected_expense_model.dart`, avoid using direct `as String` or `as int` casts for API fields that could vary. Use `.toString()` or safe checks. Ensure maps are cast safely (e.g., `item is Map<String, dynamic> ? item : {}`).
   - Centralize the `_toDouble` helper function or ensure it is clean and safe.

3. Fix Flawed Stress Test Assertion:
   - In `test/features/dashboard/forecasting_stress_test.dart` (line 218 or wherever relevant), fix the assertion `expect(find.text('₹0.00'), findsNWidgets(3))` which fails because of zero values in the breakdown table.
   - Restrict the search scope of the widget finder using `find.descendant` with target card keys (e.g., wrap card text widgets in cards with Key('income_card'), Key('expense_card'), Key('net_card') and verify them individually).

4. Improve LineChart Layout and Design:
   - Add a clean Legend below the chart to distinguish Income (green), Expenses (red), and Net Profit (navy blue).
   - Enable left/right Y-axis labels with formatted scales (e.g., formatting values using `NumberFormat.compactSimpleCurrency` or similar to show K, L, M and avoid text overlapping).
   - Handle the single-point line chart crash/render loop: in `forecasting_screen.dart`, if the data points list has length < 2, do not render `LineChart`, but display an informational message instead.

5. Responsive UI adjustments:
   - Avoid card squeezing/truncation. Ensure summary cards utilize Flexible/Expanded layout and handle longer text.
   - Right-align numeric currency columns in the tabular breakdown list/table.

6. Clean up Dead Code:
   - Remove or fix the dead `if (points.isEmpty)` check in `forecasting_screen.dart` (since the provider always yields 6 points). You can check if the sum of all income/expense points is zero to display an empty state, or remove the check.

7. Non-deterministic Date Fallback:
   - Avoid using `DateTime.now()` directly inside data mapping or keep it clean and testable.
   - Use `DateFormat("yy").format(date)` instead of `.substring(2)` on year strings to prevent potential FormatExceptions/crashes.

8. GoRouter Parameter Formatting Check:
   - In `lib/app/router.dart`, at route builders like `/customers/:id`, `/invoices/:id`, `/bills/:id`, `/vendors/:id`, `/inventory/:id`, `/quotes/:id`, `/sales-orders/:id`, `/purchase-orders/:id`, `/delivery-challans/:id`, replace `int.parse(state.pathParameters['id']!)` with `int.tryParse(state.pathParameters['id']!) ?? 0` (or fallback redirect) to prevent crash when navigating with malformed parameters (e.g. `/customers/abc`).

Verification:
- Run `flutter analyze` and `flutter test` inside `eazzio_books_mobile` to verify that all lints pass and all tests compile and pass successfully.
- Write your handoff report to `/home/rahul-kumar/Desktop/Eazzio-Books/.agents/teamwork_preview_worker_m3_2/handoff.md` and send a message back.
