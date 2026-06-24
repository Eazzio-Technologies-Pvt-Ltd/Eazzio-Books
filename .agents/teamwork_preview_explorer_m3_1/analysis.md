# Domain Models & Repository Design: Milestone 3 Advanced Dashboard Forecasting

This report provides the architectural design, exact files to create, implementation code, and testing strategies for the Advanced Dashboard Forecasting Screens (Milestone 3).

---

## 1. Executive Summary
For the Advanced Dashboard Forecasting feature, we will consume two backend API endpoints:
- `GET /api/accounts/projected-payments` (upcoming receivables from customer invoices)
- `GET /api/accounts/projected-expenses` (upcoming payables from vendor bills and recurring expenses)

Rather than adding these forecasting endpoints to `lib/features/dashboard/data/dashboard_repository.dart`, we recommend creating a dedicated repository `lib/features/dashboard/data/forecasting_repository.dart` to maintain single-responsibility principles and keep the dashboard code modular.

---

## 2. Directory Structure & Files to Create
To support the domain models and repository, the following files should be created:

```
eazzio_books_mobile/lib/features/dashboard/
├── data/
│   ├── dashboard_repository.dart
│   └── forecasting_repository.dart              <-- NEW FILE
└── domain/
    ├── dashboard_model.dart
    ├── projected_expense_model.dart             <-- NEW FILE
    └── projected_payment_model.dart             <-- NEW FILE
```

---

## 3. Data Integrity & Safe Parsing Analysis
### 🔍 Technical Observation on Numeric Types
In PostgreSQL, fields of type `NUMERIC` (like invoice amounts, balances, and recurring amounts) are returned as `String` in Node JS via the `pg` library to avoid floating-point precision loss.
Looking at the backend controller `backend-books/src/controllers/accountingController.js`:
- In `getProjectedPayments`:
  ```javascript
  const bills = result.rows.map(bill => {
    const pending = parseFloat(bill.pending_amount) || 0;
    total_projected_payment += pending;
    return {
      ...bill, // keeps total_amount, paid_amount, pending_amount as String
      projected_for_month: projMonth,
      ...
    };
  });
  ```
- In `getProjectedExpenses`:
  ```javascript
  let items = billsResult.rows.map(bill => {
    total_projected_expense += parseFloat(bill.pending_amount) || 0;
    return bill; // keeps total_amount, pending_amount as String
  });
  ```

Because of this, the fields `total_amount`, `paid_amount`, and `pending_amount` inside the lists will be `String` objects in the JSON payload, whereas the root-level aggregate values `total_projected_payment` and `total_projected_expense` are parsed with `parseFloat` and will be `double` (`num`) objects.

**Fix**: Our Dart serialization factory must use a robust `_toDouble` conversion function. Simple type casts like `json['total_amount'] as double` or `(json['total_amount'] as num).toDouble()` will fail and throw a `_TypeError` at runtime.

---

## 4. Domain Models Design

### A. Projected Payment Model
**File Path**: `eazzio_books_mobile/lib/features/dashboard/domain/projected_payment_model.dart`

```dart
class ProjectedPaymentItem {
  final int billId;
  final String billNumber;
  final String vendorName; // Note: Frontend uses vendorName, mapped from customer display name
  final DateTime? billDate;
  final DateTime? dueDate;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String status;
  final int projectedForMonth;
  final int projectedForYear;
  final String? writeOffStatus;

  ProjectedPaymentItem({
    required this.billId,
    required this.billNumber,
    required this.vendorName,
    required this.billDate,
    required this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.status,
    required this.projectedForMonth,
    required this.projectedForYear,
    this.writeOffStatus,
  });

  factory ProjectedPaymentItem.fromJson(Map<String, dynamic> json) {
    return ProjectedPaymentItem(
      billId: json['bill_id'] as int? ?? 0,
      billNumber: json['bill_number'] as String? ?? '',
      vendorName: json['vendor_name'] as String? ?? '',
      billDate: json['bill_date'] != null ? DateTime.tryParse(json['bill_date'] as String) : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      totalAmount: _toDouble(json['total_amount']),
      paidAmount: _toDouble(json['paid_amount']),
      pendingAmount: _toDouble(json['pending_amount']),
      status: json['status'] as String? ?? '',
      projectedForMonth: json['projected_for_month'] as int? ?? 0,
      projectedForYear: json['projected_for_year'] as int? ?? 0,
      writeOffStatus: json['write_off_status'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ProjectedPaymentResponse {
  final double totalProjectedPayment;
  final int projectedMonth;
  final int projectedYear;
  final List<ProjectedPaymentItem> payments;

  ProjectedPaymentResponse({
    required this.totalProjectedPayment,
    required this.projectedMonth,
    required this.projectedYear,
    required this.payments,
  });

  factory ProjectedPaymentResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> billsList = json['bills'] as List? ?? [];
    return ProjectedPaymentResponse(
      totalProjectedPayment: _toDouble(json['total_projected_payment']),
      projectedMonth: json['projected_month'] as int? ?? 0,
      projectedYear: json['projected_year'] as int? ?? 0,
      payments: billsList
          .map((item) => ProjectedPaymentItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
```

### B. Projected Expense Model
**File Path**: `eazzio_books_mobile/lib/features/dashboard/domain/projected_expense_model.dart`

```dart
class ProjectedExpenseItem {
  final int expenseId;
  final String referenceNumber;
  final String vendorName;
  final DateTime? date;
  final DateTime? dueDate;
  final double totalAmount;
  final double pendingAmount;
  final String status;
  final String type; // 'Bill' or 'Recurring'
  final int? dueDay;
  final String? frequency;

  ProjectedExpenseItem({
    required this.expenseId,
    required this.referenceNumber,
    required this.vendorName,
    required this.date,
    required this.dueDate,
    required this.totalAmount,
    required this.pendingAmount,
    required this.status,
    required this.type,
    this.dueDay,
    this.frequency,
  });

  factory ProjectedExpenseItem.fromJson(Map<String, dynamic> json) {
    return ProjectedExpenseItem(
      expenseId: json['expense_id'] as int? ?? 0,
      referenceNumber: json['reference_number'] as String? ?? '',
      vendorName: json['vendor_name'] as String? ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      totalAmount: _toDouble(json['total_amount']),
      pendingAmount: _toDouble(json['pending_amount']),
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? '',
      dueDay: json['due_day'] as int?,
      frequency: json['frequency'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ProjectedExpenseResponse {
  final double totalProjectedExpense;
  final int projectedMonth;
  final int projectedYear;
  final List<ProjectedExpenseItem> expenses;

  ProjectedExpenseResponse({
    required this.totalProjectedExpense,
    required this.projectedMonth,
    required this.projectedYear,
    required this.expenses,
  });

  factory ProjectedExpenseResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> expensesList = json['expenses'] as List? ?? [];
    return ProjectedExpenseResponse(
      totalProjectedExpense: _toDouble(json['total_projected_expense']),
      projectedMonth: json['projected_month'] as int? ?? 0,
      projectedYear: json['projected_year'] as int? ?? 0,
      expenses: expensesList
          .map((item) => ProjectedExpenseItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
```

---

## 5. Repository Design

We propose creating a new repository `lib/features/dashboard/data/forecasting_repository.dart` and registering it in a new Riverpod provider definition.

### A. Forecasting Repository
**File Path**: `eazzio_books_mobile/lib/features/dashboard/data/forecasting_repository.dart`

```dart
import '../../../core/network/api_service.dart';
import '../domain/projected_payment_model.dart';
import '../domain/projected_expense_model.dart';

class ForecastingRepository {
  final ApiService _apiService;

  ForecastingRepository(this._apiService);

  /// Fetch projected upcoming payments (receivables/invoices) for next month
  Future<ProjectedPaymentResponse> getProjectedPayments() async {
    final response = await _apiService.get('/accounts/projected-payments');
    if (response.data != null) {
      return ProjectedPaymentResponse.fromJson(response.data as Map<String, dynamic>);
    }
    throw ApiException(message: 'Invalid response from projected payments API');
  }

  /// Fetch projected upcoming expenses (bills and active recurring expenses) for next month
  Future<ProjectedExpenseResponse> getProjectedExpenses() async {
    final response = await _apiService.get('/accounts/projected-expenses');
    if (response.data != null) {
      return ProjectedExpenseResponse.fromJson(response.data as Map<String, dynamic>);
    }
    throw ApiException(message: 'Invalid response from projected expenses API');
  }
}
```

### B. Riverpod Providers Registration
**File Path**: `eazzio_books_mobile/lib/features/dashboard/presentation/forecasting_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';
import '../data/forecasting_repository.dart';
import '../domain/projected_payment_model.dart';
import '../domain/projected_expense_model.dart';

final forecastingRepositoryProvider = Provider<ForecastingRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ForecastingRepository(apiService);
});

final projectedPaymentsProvider = FutureProvider.autoDispose<ProjectedPaymentResponse>((ref) async {
  final repository = ref.watch(forecastingRepositoryProvider);
  return await repository.getProjectedPayments();
});

final projectedExpensesProvider = FutureProvider.autoDispose<ProjectedExpenseResponse>((ref) async {
  final repository = ref.watch(forecastingRepositoryProvider);
  return await repository.getProjectedExpenses();
});
```

---

## 6. Mock Data & Unit Testing

### A. JSON Mock Payloads
These mock payloads match the backend JSON structure exactly (including the `String` formatting of numeric values).

#### Projected Payments Mock JSON:
```json
{
  "total_projected_payment": 2500.0,
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

#### Projected Expenses Mock JSON:
```json
{
  "total_projected_expense": 1200.0,
  "projected_month": 7,
  "projected_year": 2026,
  "expenses": [
    {
      "expense_id": 3,
      "reference_number": "BILL-99",
      "vendor_name": "Vendor Display Name",
      "date": "2026-06-10T00:00:00.000Z",
      "due_date": "2026-07-10T00:00:00.000Z",
      "total_amount": "1000.00",
      "pending_amount": "1000.00",
      "status": "Open",
      "type": "Bill"
    },
    {
      "expense_id": 5,
      "reference_number": "Office Rent",
      "vendor_name": "Office Expense Category",
      "date": "2026-05-01T00:00:00.000Z",
      "due_date": "2026-07-01T00:00:00.000Z",
      "total_amount": "200.00",
      "pending_amount": "200.00",
      "status": "Active",
      "type": "Recurring",
      "due_day": 1,
      "frequency": "Monthly"
    }
  ]
}
```

### B. Unit Test Implementation
To test the domain model parsing and provider integration, write the following unit test.

**File Path**: `eazzio_books_mobile/test/features/dashboard/forecasting_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eazzio_books_mobile/features/dashboard/domain/projected_payment_model.dart';
import 'package:eazzio_books_mobile/features/dashboard/domain/projected_expense_model.dart';
import 'package:eazzio_books_mobile/features/dashboard/presentation/forecasting_provider.dart';
import 'package:eazzio_books_mobile/features/dashboard/data/forecasting_repository.dart';

class FakeForecastingRepository implements ForecastingRepository {
  final ProjectedPaymentResponse mockPayments;
  final ProjectedExpenseResponse mockExpenses;
  bool shouldFail = false;

  FakeForecastingRepository({
    required this.mockPayments,
    required this.mockExpenses,
  });

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

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProjectedPaymentResponse testPayments;
  late ProjectedExpenseResponse testExpenses;

  setUp(() {
    testPayments = ProjectedPaymentResponse.fromJson({
      "total_projected_payment": 2500.0,
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
    });

    testExpenses = ProjectedExpenseResponse.fromJson({
      "total_projected_expense": 1200.0,
      "projected_month": 7,
      "projected_year": 2026,
      "expenses": [
        {
          "expense_id": 3,
          "reference_number": "BILL-99",
          "vendor_name": "Vendor Display Name",
          "date": "2026-06-10T00:00:00.000Z",
          "due_date": "2026-07-10T00:00:00.000Z",
          "total_amount": "1000.00",
          "pending_amount": "1000.00",
          "status": "Open",
          "type": "Bill"
        }
      ]
    });
  });

  group('Forecasting Models Parsing', () {
    test('ProjectedPaymentResponse correctly parses string decimal values to double', () {
      expect(testPayments.totalProjectedPayment, 2500.0);
      expect(testPayments.payments.first.totalAmount, 5000.0);
      expect(testPayments.payments.first.paidAmount, 2500.0);
      expect(testPayments.payments.first.pendingAmount, 2500.0);
      expect(testPayments.payments.first.billNumber, "INV-001");
    });

    test('ProjectedExpenseResponse correctly parses values', () {
      expect(testExpenses.totalProjectedExpense, 1200.0);
      expect(testExpenses.expenses.first.totalAmount, 1000.0);
      expect(testExpenses.expenses.first.pendingAmount, 1000.0);
      expect(testExpenses.expenses.first.referenceNumber, "BILL-99");
    });
  });

  group('Forecasting Provider', () {
    test('projectedPaymentsProvider and projectedExpensesProvider return correct mocked values', () async {
      final fakeRepo = FakeForecastingRepository(
        mockPayments: testPayments,
        mockExpenses: testExpenses,
      );

      final container = ProviderContainer(
        overrides: [
          forecastingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final paymentResult = await container.read(projectedPaymentsProvider.future);
      expect(paymentResult.totalProjectedPayment, 2500.0);
      expect(paymentResult.payments.length, 1);

      final expenseResult = await container.read(projectedExpensesProvider.future);
      expect(expenseResult.totalProjectedExpense, 1200.0);
      expect(expenseResult.expenses.length, 1);
    });
  });
}
```
