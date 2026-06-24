## 2026-06-20T14:34:36Z
You are the Worker subagent for Milestone 3 (Advanced Dashboard Forecasting Screens). Your task is to implement the Cash Flow Forecasting features in the Flutter mobile application located at `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile`.

Please execute the following steps:

1. Create Domain Models:
   - File: `lib/features/dashboard/domain/projected_payment_model.dart`
     Create classes `ProjectedPaymentItem` and `ProjectedPaymentResponse` to safely parse the response of `/accounts/projected-payments`. Use a robust `_toDouble` helper to handle cases where numeric fields (e.g., total_amount, paid_amount, pending_amount) are returned as String or double.
   - File: `lib/features/dashboard/domain/projected_expense_model.dart`
     Create classes `ProjectedExpenseItem` and `ProjectedExpenseResponse` to safely parse the response of `/accounts/projected-expenses`. Use a robust `_toDouble` helper.

2. Create Repository:
   - File: `lib/features/dashboard/data/forecasting_repository.dart`
     Implement a dedicated repository `ForecastingRepository` class that uses the existing `ApiService` (imported from `../../../core/network/api_service.dart`) to make GET requests to `/accounts/projected-payments` and `/accounts/projected-expenses`.

3. Create Riverpod Providers:
   - File: `lib/features/dashboard/presentation/forecasting_provider.dart`
     Define the following:
     - `forecastingRepositoryProvider` providing the repository.
     - `forecastIntervalProvider` (a StateProvider managing a `ForecastTrendInterval` enum of `monthly`, `quarterly`, `yearly`).
     - `forecastingDataProvider` (a FutureProvider providing the aggregated list of `ForecastDataPoint` items, which contains period string, projectedIncome, and projectedExpense).
     - In `forecastingDataProvider`, fetch the raw payments and expenses from the repository, and aggregate them dynamically on the client-side based on the selected interval (monthly, quarterly, or yearly) of the item's `due_date`.
     - Grouping logic:
       - Generate a timeline (e.g., current month + next 5 months).
       - Map overdue items (due date before current month) into the current/first month.
       - Sum the pending amounts for invoices (income) and bills/expenses (expenses) per month.
       - If Quarterly is selected, group the monthly points into quarters (e.g. Q1 '26, Q2 '26, Q3 '26, etc.).
       - If Yearly is selected, group the monthly points into years (e.g. 2026, 2027).

4. Create Presentation Screen:
   - File: `lib/features/dashboard/presentation/forecasting_screen.dart`
     Design the UI:
     - App bar with title 'Cash Flow Forecasting' and back button.
     - Segmented toggle control (SegmentedButton or ToggleButtons) for switching between Monthly, Quarterly, and Yearly.
     - Summary cards showing Total Projected Income, Total Projected Expenses, and Net Forecasted Cash Flow.
     - A LineChart from the `fl_chart` library showing three curves: Projected Income (green), Projected Expenses (red), and Net Profit (navy blue). Configure a customized tooltip showing the absolute formatted values (e.g. ₹1,200.00) when pressed/tapped.
     - A tabular list below the chart displaying the breakdown of period, income, expense, and net profit for each period.
     - RefreshIndicator to reload the data by invalidating the provider.
     - Proper loading/error states.

5. Routing & Integration:
   - Register route `/dashboard/forecasting` in `lib/app/router.dart`.
   - Add a navigation trigger card to `lib/features/dashboard/presentation/dashboard_screen.dart` (right below the Income vs Expense chart).
   - Add a menu item to `lib/features/dashboard/presentation/more_screen.dart` (below the Reports Center).

6. Testing:
   - Create unit tests for domain parsing and provider logic in `test/features/dashboard/forecasting_provider_test.dart`.
   - Create widget tests for the screen rendering, loading, error, and navigation in `test/features/dashboard/forecasting_screen_test.dart`.
   - Remove or fix the obsolete/template `test/widget_test.dart` that is currently failing.
   - Run `flutter analyze` and `flutter test` to ensure all lints pass and all tests in the codebase run successfully.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

When completed, document your changes and test results in `/home/rahul-kumar/Desktop/Eazzio-Books/.agents/teamwork_preview_worker_m3/handoff.md` and send a message back with the status.
