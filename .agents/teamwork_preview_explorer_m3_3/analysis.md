# Milestone 3 Navigation Integration & Automated Testing Design Analysis

## Summary of Findings
This analysis details the design and strategy for integrating the new Cash Flow Forecasting feature (Milestone 3) into the Flutter codebase of Eazzio Books. The integration includes registering the route `/dashboard/forecasting`, placing entry points (triggers/cards/links) in the main Dashboard and More Options screens, and setting up an automated testing strategy based on existing patterns in the project.

---

## 1. Navigation Integration Design

### 1.1 Route Registration in `lib/app/router.dart`
In `eazzio_books_mobile/lib/app/router.dart`, routes are declared in the `routerProvider` via `GoRouter`. The path `/dashboard/forecasting` should be registered as a standalone route outside the main `ShellRoute` (similar to other report/inventory screens like `/inventory/low-stock`), providing the maximum screen real estate for graphs, curves, and detail lists.

#### Proposed Routing Code Modification in `lib/app/router.dart`
We would import `../features/dashboard/presentation/forecasting_screen.dart` and append the new route to the `routes` array of `GoRouter` at the bottom of the list (e.g., around line 276):

```dart
      // Import at top:
      import '../features/dashboard/presentation/forecasting_screen.dart';

      // Within routes array:
      GoRoute(
        path: '/dashboard/forecasting',
        builder: (context, state) => const ForecastingScreen(),
      ),
```

---

### 1.2 Entry Points & Triggers in the UI

#### A. Main Dashboard Screen (`eazzio_books_mobile/lib/features/dashboard/presentation/dashboard_screen.dart`)
We will add an interactive **Insights Card** at the bottom of `_buildDashboardContent` (right after the Income vs Expense bar chart section around line 200). This card provides a clean, visual entry point into the forecasting feature.

##### Proposed Code Snippet:
```dart
        const SizedBox(height: 24),
        // Cash Flow Forecasting Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => context.push('/dashboard/forecasting'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.stacked_line_chart, color: Colors.blue.shade800, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cash Flow Forecasting',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Analyze future cash projections based on invoices & expenses.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
```

#### B. More Screen (`eazzio_books_mobile/lib/features/dashboard/presentation/more_screen.dart`)
We will add a new menu card inside the `ListView` in `MoreScreen` using the existing `_buildMenuCard` method (e.g., right after "Reports Center" on line 133).

##### Proposed Code Snippet:
```dart
          _buildMenuCard(
            context,
            icon: Icons.stacked_line_chart_outlined,
            title: 'Cash Flow Forecasting',
            subtitle: 'Predict future receivables, payables, and net balance',
            route: '/dashboard/forecasting',
            color: Colors.blue.shade800,
          ),
```

---

## 2. Review of Existing Tests (Reference)

By analyzing the tests under `eazzio_books_mobile/test/features/inventory/`:
- **`low_stock_provider_test.dart`**:
  - Implements a mock/fake repository (`FakeInventoryRepository` implementing `InventoryRepository`) overriding only necessary methods.
  - Overrides the repository provider under a unit-testing `ProviderContainer` (`inventoryRepositoryProvider.overrideWithValue(...)`).
  - Calls relevant notifier action methods and asserts downstream computed states (`lowStockItemsProvider` filtering logic).
- **`low_stock_screen_test.dart`**:
  - Sets up screen widget testing via `WidgetTester` and `tester.pumpWidget(...)`.
  - Wraps the tested screen (`LowStockReportScreen`) in `ProviderScope` with repository overrides and a wrapper `MaterialApp` or `MaterialApp.router`.
  - Tests 3 main UI phases: loading state (finding `CircularProgressIndicator`), success/rendering state (finding text contents), and failure/empty states.
  - Tests router integration by defining a localized mock `GoRouter` containing `/inventory/low-stock` and a target detail route `/inventory/:id` to check route transition.

---

## 3. Automated Testing Strategy for Forecasting

### 3.1 Unit Testing: Forecasting Provider
We will create `eazzio_books_mobile/test/features/dashboard/forecasting_provider_test.dart` to verify that calculations and state emissions function properly.

#### Test Cases:
1. **Successful Data Transform**: Ensures that raw API forecast metrics are computed/sorted correctly (e.g. chronological ordering of days, correct summation of cumulative balance projections).
2. **Empty Data Handling**: Ensures that if the API returns no projections, the provider does not crash and exposes a clean empty state.
3. **Repository Failure Propagation**: Verifies that when the repository throws an network error, the provider emits the error state.

#### Concrete Unit Test Code Outline:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eazzio_books_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:eazzio_books_mobile/features/dashboard/presentation/dashboard_provider.dart';

// Assuming we add forecasting methods to DashboardRepository or a new ForecastingRepository
class FakeDashboardRepository implements DashboardRepository {
  final Map<String, dynamic> mockForecastingResponse;
  final bool shouldFail;

  FakeDashboardRepository({required this.mockForecastingResponse, this.shouldFail = false});

  @override
  Future<dynamic> getForecastingData() async {
    if (shouldFail) throw Exception('API connection failed');
    return mockForecastingResponse;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('forecastingDataProvider calculates cumulative projection correctly', () async {
    final mockResponse = {
      'forecast_points': [
        {'date': '2026-06-21', 'predicted_income': 1000.0, 'predicted_expense': 400.0},
        {'date': '2026-06-22', 'predicted_income': 500.0, 'predicted_expense': 800.0},
      ],
      'starting_cash': 5000.0,
    };

    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository(mockForecastingResponse: mockResponse)),
      ],
    );
    addTearDown(container.dispose);

    // Read the forecasting future state
    final state = await container.read(forecastingDataProvider.future);

    // Verify correct calculations
    expect(state.startingCash, 5000.0);
    expect(state.points.length, 2);
    // 5000 + 1000 - 400 = 5600
    expect(state.points[0].cumulativeCash, 5600.0);
    // 5600 + 500 - 800 = 5300
    expect(state.points[1].cumulativeCash, 5300.0);
  });
}
```

---

### 3.2 Widget Testing: Forecasting Screen
We will create `eazzio_books_mobile/test/features/dashboard/forecasting_screen_test.dart` to verify visual elements, charts, and screen-level interactions.

#### Test Cases:
1. **Loading State**: Check that the screen displays a `CircularProgressIndicator` during initialization.
2. **Success Rendering**: Ensure standard cards (e.g. "Starting Cash", "Net Forecasted Cash Flow", "Final Projected Cash") and the line chart are rendered.
3. **Error State and Retry**: Validate that error messages are rendered upon API failure, and tapping the "Retry" button invalidates the provider.
4. **Navigation Integration**: Test that the back button in the AppBar works as expected to return to the previous screen.

#### Concrete Widget Test Code Outline:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eazzio_books_mobile/features/dashboard/presentation/forecasting_screen.dart';
import 'package:eazzio_books_mobile/features/dashboard/data/dashboard_repository.dart';

void main() {
  testWidgets('ForecastingScreen displays line chart and projection metrics when loaded', (WidgetTester tester) async {
    final fakeRepo = FakeDashboardRepository(
      mockForecastingResponse: {
        'forecast_points': [
          {'date': '2026-06-21', 'predicted_income': 1000.0, 'predicted_expense': 400.0},
        ],
        'starting_cash': 5000.0,
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ForecastingScreen(),
        ),
      ),
    );

    // Verify initial loading screen state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the provider data to resolve
    await tester.pumpAndSettle();

    // Verify layout content renders
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Starting Cash'), findsOneWidget);
    expect(find.textContaining('₹5,000.00'), findsOneWidget);
    expect(find.textContaining('Projected Cash Flow'), findsOneWidget);
  });

  testWidgets('ForecastingScreen renders retry button on failure', (WidgetTester tester) async {
    final fakeRepo = FakeDashboardRepository(
      mockForecastingResponse: {},
      shouldFail: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ForecastingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify error state components
    expect(find.textContaining('Failed to load forecasting data'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
  });
}
```
