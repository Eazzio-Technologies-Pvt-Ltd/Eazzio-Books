# Scope: Advanced Dashboard Forecasting Screens (Milestone 3)

## Architecture
- Build projected payment and expense models: `lib/features/dashboard/domain/projected_payment_model.dart` and `lib/features/dashboard/domain/projected_expense_model.dart`.
- Add repository methods/endpoints in `lib/features/dashboard/data/dashboard_repository.dart` (or create a dedicated `forecasting_repository.dart`) targeting `/api/accounts/projected-payments` and `/api/accounts/projected-expenses`.
- Create a dedicated dashboard forecasting screen: `lib/features/dashboard/presentation/forecasting_screen.dart`.
- The forecasting screen should render charts (income vs expense vs profit trends monthly/quarterly/yearly) using the `fl_chart` library.
- Register the route `/dashboard/forecasting` in `lib/app/router.dart`.
- Add a dashboard card / navigation link to `lib/features/dashboard/presentation/dashboard_screen.dart` and a menu item in `lib/features/dashboard/presentation/more_screen.dart`.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Create forecasting models & repo methods | Projected payment/expense models and repository calls | None | PLANNED |
| 2 | Create forecasting presentation screen | `forecasting_screen.dart` using `fl_chart` | 1 | PLANNED |
| 3 | Configure router | Register `/dashboard/forecasting` in `router.dart` | 2 | PLANNED |
| 4 | Add navigation triggers | Link on Dashboard screen and More options screen | 3 | PLANNED |
| 5 | Verification | Unit/widget tests, static analysis, and compliance audit | 4 | PLANNED |

## Interface Contracts
- Repositories consume endpoints using `apiService.get('/accounts/projected-payments')` and `apiService.get('/accounts/projected-expenses')`.
