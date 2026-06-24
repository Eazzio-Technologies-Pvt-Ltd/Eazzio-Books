# Presentation Layer Design: Cash Flow Forecasting Screen

This document details the analysis and design for the presentation layer of the Cash Flow Forecasting screen in the Eazzio-Books mobile application, specifically targeted at the planned **Milestone 3 (M3)**.

---

## 1. Executive Summary
The Cash Flow Forecasting screen (`lib/features/dashboard/presentation/forecasting_screen.dart`) will visualize projected income, projected expenses, and net profit trends over time. The screen will utilize the `fl_chart` library with a customized `LineChart` showing three interactive trend lines. Users can toggle the trend granularity between **Monthly**, **Quarterly**, and **Yearly** views. The state will be managed using Riverpod providers, which will handle data loading, error handling, interval selection, and formatting calculations.

---

## 2. Riverpod State Management & Models

To manage user interaction and data flow, we define state providers and models.

### A. Core Models
The data structure for a single forecasting point represents a time period (e.g., month, quarter, or year) and its associated projections:

```dart
class ForecastDataPoint {
  final String period; // e.g., "Jul '26", "Q3 '26", "2027"
  final double projectedIncome;
  final double projectedExpense;
  
  double get netProfit => projectedIncome - projectedExpense;

  ForecastDataPoint({
    required this.period,
    required this.projectedIncome,
    required this.projectedExpense,
  });

  factory ForecastDataPoint.fromJson(Map<String, dynamic> json) {
    return ForecastDataPoint(
      period: json['period'] as String? ?? '',
      projectedIncome: (json['projected_income'] as num? ?? 0).toDouble(),
      projectedExpense: (json['projected_expense'] as num? ?? 0).toDouble(),
    );
  }
}
```

### B. Segmented Interval State
To control whether the data is aggregated by Month, Quarter, or Year, we use a simple state provider:

```dart
enum ForecastTrendInterval { monthly, quarterly, yearly }

final forecastIntervalProvider = StateProvider<ForecastTrendInterval>((ref) {
  return ForecastTrendInterval.monthly;
});
```

### C. Data Provider
We define the forecasting data provider, which watches the selected interval and triggers a fetch from the repository.

```dart
final forecastingRepositoryProvider = Provider<ForecastingRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ForecastingRepository(apiService);
});

final forecastingDataProvider = FutureProvider.autoDispose<List<ForecastDataPoint>>((ref) async {
  final repository = ref.watch(forecastingRepositoryProvider);
  final interval = ref.watch(forecastIntervalProvider);
  
  // The repository fetches raw data (invoices, bills, recurring expenses)
  // and aggregates it, or requests aggregated data from the backend API.
  return await repository.getForecastData(interval: interval);
});
```

---

## 3. Data Aggregation & Grouping Logic

Depending on the API design, the client-side will either fetch pre-aggregated data or fetch raw items (unpaid invoices, unpaid bills, active recurring expenses) and group them dynamically inside the provider.

### Aggregation Rules
1. **Projected Income**: Sum of `balance_due` on all active unpaid or partially paid invoices with a due date falling within the target period.
2. **Projected Expense**: Sum of:
   - `balance_due` on all active unpaid or partially paid bills with a due date in the target period.
   - Calculated occurrences of active recurring expenses.
3. **Recurring Expenses Calculation**: For each active recurring expense:
   - Determine its occurrences in the target period based on its `frequency` ("Monthly", "Quarterly", "Yearly") and `start_date` / `end_date`.
   - Add the expense amount for each occurrence.

### Granularity Grouping Mechanisms
* **Monthly Toggle**:
  - Timeline: Next 12 months starting from the current month.
  - Grouping: Group all calculations by `due_date.year` and `due_date.month`.
  - Period Format: `"MMM 'yy"` (e.g. `DateFormat("MMM 'yy").format(date)` -> `"Jul '26"`).
* **Quarterly Toggle**:
  - Timeline: Next 4 to 6 quarters.
  - Grouping: Group months into calendar quarters:
    - Q1: Jan, Feb, Mar
    - Q2: Apr, May, Jun
    - Q3: Jul, Aug, Sep
    - Q4: Oct, Nov, Dec
  - Sum the income and expenses for all months inside each quarter.
  - Period Format: `"QX 'yy"` (e.g., `"Q3 '26"`).
* **Yearly Toggle**:
  - Timeline: Next 3 to 5 calendar/fiscal years.
  - Grouping: Group calculations by `due_date.year`.
  - Sum the income and expenses for all months within each year.
  - Period Format: `"YYYY"` (e.g., `"2027"`).

---

## 4. fl_chart (`LineChart`) Design Details

We use `fl_chart`'s `LineChart` to map three lines: Projected Income, Projected Expense, and Net Profit.

### A. Mapping Spots
To map data points into the chart coordinate space, we use the list index as `x` and the monetary values as `y`:

```dart
final incomeSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.projectedIncome)).toList();
final expenseSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.projectedExpense)).toList();
final profitSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.netProfit)).toList();
```

### B. Line Styling and Config
```dart
LineChartBarData(
  spots: incomeSpots,
  isCurved: true,
  color: Colors.green.shade600,
  barWidth: 3,
  isStrokeCapRound: true,
  dotData: const FlDotData(show: true),
  belowBarData: BarAreaData(
    show: true,
    color: Colors.green.shade600.withOpacity(0.1),
  ),
),
LineChartBarData(
  spots: expenseSpots,
  isCurved: true,
  color: Colors.red.shade600,
  barWidth: 3,
  isStrokeCapRound: true,
  dotData: const FlDotData(show: true),
  belowBarData: BarAreaData(
    show: true,
    color: Colors.red.shade600.withOpacity(0.1),
  ),
),
LineChartBarData(
  spots: profitSpots,
  isCurved: true,
  color: const Color(0xFF1A237E), // Navy Blue matching theme
  barWidth: 4, // Thicker to emphasize net profit
  isStrokeCapRound: true,
  dotData: const FlDotData(show: true),
  belowBarData: BarAreaData(show: false),
)
```

### C. Tooltip & Touch Interaction
Ensure that when a user taps/hovers over a spot, they see the absolute currency values for all three metrics simultaneously:

```dart
lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    tooltipBgColor: Colors.blueGrey.shade800,
    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
      return touchedBarSpots.map((barSpot) {
        final flSpot = barSpot;
        final value = flSpot.y;
        final label = barSpot.barIndex == 0 
            ? 'Income' 
            : barSpot.barIndex == 1 ? 'Expense' : 'Net Profit';
        final formatter = NumberFormat.compactSimpleCurrency(locale: 'en_IN', decimalDigits: 1);
        return LineTooltipItem(
          '$label: ${formatter.format(value)}',
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        );
      }).toList();
    },
  ),
)
```

### D. Axis Formatting
* **Bottom Titles**: Map index `x` back to `data[x.toInt()].period` string.
* **Left Titles**: Format scale markers to avoid visual clutter (e.g., format `150,000` to `"150K"` or `"1.5L"`, `1,000,000` to `"10L"` or `"1M"`).

---

## 5. UI Widget Layout and Tree

The forecasting screen will follow the standard modular theme (deep navy `#1A237E` headers, soft rounded cards, and clean typography).

### Widget Tree
```
Scaffold
 ├── AppBar (Title: "Forecasting", Navigation back arrow)
 └── RefreshIndicator (Trigger ref.refresh(forecastingDataProvider.future))
      └── SingleChildScrollView
           └── Padding (16dp padding)
                └── Column
                     ├── Granularity Toggle Row (SegmentedButton)
                     ├── Gap (16dp)
                     ├── Summary Cards (Horizontal/Grid row for aggregates: Income, Expense, Profit)
                     ├── Gap (24dp)
                     ├── Chart Card
                     │    └── Padding
                     │         └── Column
                     │              ├── Chart Title & Interval Label
                     │              ├── SizedBox(height: 300) -> LineChart
                     │              └── Legend row (Income/Expense/Profit color indicators)
                     ├── Gap (24dp)
                     └── Tabular Breakdown Table / List
                          └── Column (List of rows displaying absolute period values)
```

### Component Details

#### 1. Segmented Granularity Selector
Use Flutter's `SegmentedButton` for modern, platform-native toggles:

```dart
SegmentedButton<ForecastTrendInterval>(
  segments: const [
    ButtonSegment(value: ForecastTrendInterval.monthly, label: Text('Monthly')),
    ButtonSegment(value: ForecastTrendInterval.quarterly, label: Text('Quarterly')),
    ButtonSegment(value: ForecastTrendInterval.yearly, label: Text('Yearly')),
  ],
  selected: {ref.watch(forecastIntervalProvider)},
  onSelectionChanged: (newSelection) {
    ref.read(forecastIntervalProvider.notifier).state = newSelection.first;
  },
)
```

#### 2. Chart Card Widget
The chart must be wrapped in a card with explicit constraints to handle `fl_chart`'s layout requirements:

```dart
Card(
  elevation: 3,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Projected Cash Flow Trend',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              // Chart properties configured here
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Projected Income', Colors.green.shade600),
            const SizedBox(width: 16),
            _buildLegendItem('Projected Expenses', Colors.red.shade600),
            const SizedBox(width: 16),
            _buildLegendItem('Net Profit Trend', const Color(0xFF1A237E)),
          ],
        )
      ],
    ),
  ),
)
```

#### 3. Detail Tabular List
For accessibility and precise data inspection, render a list containing details for each projection period:

```dart
ListView.separated(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: data.length,
  separatorBuilder: (context, index) => const Divider(),
  itemBuilder: (context, index) {
    final point = data[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(point.period, style: const TextStyle(fontWeight: FontWeight.bold)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Inc: ${_formatCurrency(point.projectedIncome)}', style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
              Text('Exp: ${_formatCurrency(point.projectedExpense)}', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              Text('Net: ${_formatCurrency(point.netProfit)}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  },
)
```
