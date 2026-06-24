# Scope: Low-Stock Alerts and Inventory Warning System (Milestone 2)

## Architecture
- Build a new presentation screen: `lib/features/inventory/presentation/low_stock_report_screen.dart` using Riverpod `itemListProvider` to filter items where `isInventoryTracked && stockQuantity <= reorderLevel`.
- Integrate routing in `lib/app/router.dart` (`/inventory/low-stock`).
- Add navigation triggers to:
  - `lib/features/dashboard/presentation/more_screen.dart` (Menu link "Low Stock Report")
  - `lib/features/inventory/presentation/inventory_list_screen.dart` (A visual banner/button showing low stock count and linking to the report).
- Ensure existing warnings on list and details screens display correctly.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Create low stock report screen | `low_stock_report_screen.dart` | None | PLANNED |
| 2 | Configure router | Register `/inventory/low-stock` in `router.dart` | 1 | PLANNED |
| 3 | Add navigation links | Add entry points in `more_screen.dart` and `inventory_list_screen.dart` | 2 | PLANNED |
| 4 | Verification | Run analyze and tests, check visually | 3 | PLANNED |

## Interface Contracts
- Standard widgets and Riverpod state.
