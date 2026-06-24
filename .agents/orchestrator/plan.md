# Project Plan: Eazzio-Books Flutter Mobile Enhancements

This plan outlines the steps to implement the six pending roadmap features for the `eazzio_books_mobile` Flutter application.

## Milestones Overview

### Milestone 1: Environment Configuration & Base URL Setup (R6)
- **Objective**: Clean up hardcoded base URLs and endpoints. Setup staging vs production modes.
- **Verification**: Run the app in development and staging modes; verify config loads correctly.

### Milestone 2: Low-Stock Alerts & Inventory Warning System (R1)
- **Objective**: Real-time stock level monitoring comparing `stockQuantity` against `reorderLevel`. Warning badges/indicators on listing/details. Low-stock report screen.
- **Verification**: UI widget checks and integration checks for warning states.

### Milestone 3: Advanced Dashboard Forecasting Screens (R2)
- **Objective**: Forecaster screens consuming `/api/accounts/projected-payments` and `/api/accounts/projected-expenses` using `fl_chart`.
- **Verification**: Projections match mock server or backend response schemas.

### Milestone 4: Client-Side Item Valuation Reports (R3)
- **Objective**: FIFO, LIFO, and Weighted Average models calculated client-side by fetching movement histories. Render comparison table.
- **Verification**: Automated unit tests for multiple movement history patterns.

### Milestone 5: GST & Tax Compliance Report (R4)
- **Objective**: Tax/GST compliance report screen detailing breakdowns of input/output tax liability.
- **Verification**: Correct math verified by sample transaction logs.

### Milestone 6: Advanced PDF & Excel Exports with Sharing (R5)
- **Objective**: Export financial statements, invoices, and reports to PDF and Excel format. Native sharing and printing integration.
- **Verification**: Print/share dialogs open correctly; files verified for format.

### Milestone 7: Final Hardening, Testing, & Victory Audit
- **Objective**: Write unit/widget tests under `test/`, resolve lint/compile warnings, and run Forensic Victory Audit.
- **Verification**: `flutter analyze` passes, all unit/widget tests pass, auditor gives CLEAN verdict.

## Resource & Team Allocation
- **Orchestrator**: Manages sub-orchestrators/workers, runs gate checks.
- **Explorer**: Investigates codebase and verifies API payloads and SQLite schemas/movement behaviors.
- **Worker**: Implements specific features and compiles/tests.
- **Reviewer/Challenger**: Review correctness, check for regressions.
- **Auditor**: Independent integrity checks.
