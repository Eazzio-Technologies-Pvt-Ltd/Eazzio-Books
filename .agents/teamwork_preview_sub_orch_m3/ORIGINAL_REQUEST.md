# Original User Request

## 2026-06-20T14:33:20Z

You are the Sub-Orchestrator for Milestone 3 (Advanced Dashboard Forecasting Screens). Your working directory is `/home/rahul-kumar/Desktop/Eazzio-Books/.agents/teamwork_preview_sub_orch_m3/`.

Your parent is `c082e5ea-f2dd-4449-ae3f-9422e6ae8612`.

Your task is to implement Milestone 3:
1. Initialize your BRIEFING.md and progress.md in your working directory.
2. Read the scope description in `SCOPE.md` (in your working directory) and the initial explorer report in `/home/rahul-kumar/Desktop/Eazzio-Books/.agents/teamwork_preview_explorer_init/analysis.md`.
3. Execute the Explorer -> Worker -> Reviewer -> Auditor iteration cycle to:
   - Create projected payment and projected expense models under `eazzio_books_mobile/lib/features/dashboard/domain/`.
   - Update `dashboard_repository.dart` (or create a dedicated `forecasting_repository.dart`) to call `/accounts/projected-payments` and `/accounts/projected-expenses`.
   - Create `eazzio_books_mobile/lib/features/dashboard/presentation/forecasting_screen.dart` displaying the projected income, expenses, and net profit trends (monthly, quarterly, and yearly) using the `fl_chart` library.
   - Register route `/dashboard/forecasting` in `eazzio_books_mobile/lib/app/router.dart`.
   - Add navigation triggers to `dashboard_screen.dart` and `more_screen.dart`.
   - Add automated widget / unit tests to verify the forecasting logic and screen rendering under `test/features/dashboard/`.
   - Ensure lints pass and tests run successfully.
4. Spawn a Forensic Auditor (`teamwork_preview_auditor`) to verify compliance and integrity.
5. Verify and close the gate, write your completion handoff.md, and send a message back to the parent agent (conversation ID: c082e5ea-f2dd-4449-ae3f-9422e6ae8612) when done.
