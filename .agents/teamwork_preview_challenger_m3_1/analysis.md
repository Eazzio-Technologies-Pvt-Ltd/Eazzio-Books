## Challenge Summary

**Overall risk assessment**: MEDIUM

Our review and empirical stress testing of the Cash Flow Forecasting logic and provider calculations revealed a few key vulnerabilities and design assumptions. While the system behaves gracefully in terms of not crashing on empty responses and basic date omissions, it suffers from unreachable empty UI states, non-deterministic system-clock fallbacks, date-parsing fragility, and potential timezone offsets.

---

## Challenges

### [Medium] Challenge 1: Unreachable Empty UI State (Dead Code)

- **Assumption challenged**: The screen assumes that the `forecastingDataProvider` can return an empty list when there is no backend forecasting data, displaying a `"No forecasting data available"` message.
- **Attack scenario**: If the backend returns no data (empty payments/expenses arrays), the provider (`forecastingDataProvider`) still generates 6 consecutive month records using the start date, filling each month's income and expense maps with `0.0`. Thus, `points` will always have exactly 6 items in monthly mode. 
- **Blast radius**: The `if (points.isEmpty)` check in `forecasting_screen.dart` (line 69) is **always false**. The screen will show empty cards and a table with ₹0.00 entries for 6 months instead of showing the user a clear empty state message.
- **Mitigation**: Update the empty-state condition to check if all values are zero (e.g., `points.every((p) => p.projectedIncome == 0 && p.projectedExpense == 0)`) or add an explicit `hasData` flag returned by the provider/repository, rather than checking list emptiness.

### [Medium] Challenge 2: Non-deterministic System Clock Fallback for Null/Invalid Dates

- **Assumption challenged**: If both `dueDate` and `billDate` (or `date`) are null or invalid (e.g. failing to parse), the provider defaults the transaction's date to `DateTime.now()`.
- **Attack scenario**: 
  - If a transaction has no valid date, falling back to `DateTime.now()` aggregates it into the current calendar month.
  - If the user’s system clock is in a different month/year from the forecast period (e.g. the system clock is in 2028, but the forecast period is July 2026), the transaction's date fallback will place it outside the 6-month window, causing it to be silently omitted from the forecast map.
  - This introduces non-deterministic behavior where the same backend payload yields different forecasting outputs depending on the user's client system clock.
- **Blast radius**: Flaky test results and inconsistent financial calculations.
- **Mitigation**: Rather than falling back to `DateTime.now()`, use the start month of the forecast (`start`) or raise an explicit mapping error. Undated transactions should be mapped into a specific category or defaulted to the first month of the forecast window.

### [Low] Challenge 3: Insecure String Type Casting During JSON Deserialization

- **Assumption challenged**: The models assume that date strings and names returned from the API are always Strings, using direct casts like `as String`.
- **Attack scenario**: If the API returns a number or other non-string data type for fields like `bill_date`, `due_date`, or `vendor_name`, the model constructors (`ProjectedPaymentItem.fromJson`, `ProjectedExpenseItem.fromJson`) will throw a `TypeError` during parsing, completely crashing the feed.
- **Blast radius**: Full UI breakdown (displaying the error screen) due to API schema modifications.
- **Mitigation**: Use `.toString()` or safe checks rather than explicit `as String` casts (e.g., `json['due_date']?.toString()`).

### [Low] Challenge 4: Inconsistent Quarterly Label Year Substring Calculation

- **Assumption challenged**: The quarterly grouping logic assumes that the calendar year will always be represented by a string of length >= 4, performing `date.year.toString().substring(2)`.
- **Attack scenario**: If a date has a year less than 1000 (e.g., system test with year 0 or negative years), `substring(2)` will throw a `RangeError`.
- **Blast radius**: Screen crash due to unhandled layout processing error.
- **Mitigation**: Use `DateFormat("yy").format(date)` or `date.year % 100` to calculate the double-digit year representation consistently.

---

## Stress Test Results

We wrote and executed a dedicated suite of stress tests located at `test/features/dashboard/forecasting_stress_test.dart`. The tests verify how the forecasting framework handles extreme inputs:

- **Empty payload deserialization** → `ProjectedPaymentResponse.fromJson({})` parses without throwing an exception. → **PASS**
- **Empty data aggregation** → `forecastingDataProvider` aggregates empty lists into exactly 6 data points of all 0.0 values, rather than crashing or returning empty. → **PASS**
- **Null/Invalid due date parsing** → Payments with `null` or invalid string formats are parsed safely to `null` dates. → **PASS**
- **Boundary dates (overdue, window end, outside window)** → Overdue items are aggregated into the first month, items in the window match their months, and items outside the window are correctly excluded. → **PASS**
- **Widget rendering with empty data** → Renders zero cards and the table showing all-zero rows without crashing the chart. Verify that the table is displayed instead of the empty state. → **PASS**

---

## Unchallenged Areas

- **Backend Aggregation Performance**: We did not challenge database performance on the backend when retrieving and grouping invoices/expenses under large tables.
- **`fl_chart` Performance under Extreme Values**: We did not stress-test how the chart displays under extremely high values (e.g., trillions) or negative ranges that overlap other visual elements.
