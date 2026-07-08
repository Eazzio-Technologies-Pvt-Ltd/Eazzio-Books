# Eazzio Books – Mobile App Bug Fix Task List

**How to use this file (Antigravity instructions):**
1. Scan the codebase for each bug described below (file paths are suggestions from a prior session — verify by searching, don't assume).
2. Fix the root cause, not just the visual symptom.
3. Run `flutter analyze` after each fix and confirm no new errors are introduced.
4. Manually verify the fix against the described repro steps.
5. When a task is verified fixed, change `[ ]` to `[x]` **on this file** and add a one-line note of what changed.
6. Do not mark a task `[x]` until it has actually been tested — don't just assume the edit worked.

---

## ✅ Completed (prior session)
- [x] Redesign Login screen — navy brand header + white form + teal (`AppColors.primary`) primary button
- [x] Redesign Register screen — navy step-indicator header, white card body, teal buttons/selection states

---

## 🔴 High Priority — Crashes

### 1. Type-cast crash creating a Project
- [x] **Error:** `Error saving project: type 'String' is not a subtype of type 'num?' in type cast` (Fixed: Added `_parseDouble` in `project.dart` to handle string numbers from backend NUMERIC columns).
- Repro: More → Projects → New Project → fill fields (Budget field involved) → Save

### 2. Type-cast crash loading Projects (Timesheet screen)
- [x] **Error:** `Error loading projects: type 'String' is not a subtype of type 'num?' in type cast` (Fixed: Resolved by fixing the Project model deserialization in `project.dart`).
- Repro: More → Timesheets → New Timesheet → tap Project dropdown

### 3. Full black/blank screen crash
- [x] Screenshot shows an entirely black screen with only the SOS/status icons visible after navigating from Bank Rules area. (Fixed: Added global `ErrorWidget.builder` in `main.dart` and fixed similar NUMERIC->String parsing cast crashes in `bank_account.dart`).

---

## 🟠 UI Overflow Errors (`RIGHT OVERFLOWED BY X PIXELS`)

These appear across many screens as a diagonal yellow/black stripe — classic `RenderFlex` overflow, almost always a `Row` without `Expanded`/`Flexible`/`overflow: TextOverflow.ellipsis` wrapping.

- [x] Top app bar avatar/profile icon overflows on Home / Inventory Movements / Quotes / Sales Orders / Bills / Vendors / Purchase Orders screens (the circular "R" avatar in the top-right) (Fixed: Refactored `_buildAppBar` in `responsive_scaffold.dart` to place back button in leading and hide shell actions on pop-able sub-pages).
- [x] Sales Order list — `CONFIRMED` status badge overflows and overlaps the amount text (Fixed: Wrapped badge and text in `Flexible` + `TextOverflow.ellipsis`).
- [x] Delivery Challan list — `DRAFT` status badge text overflow (Fixed: Wrapped badge and text in `Flexible` + `TextOverflow.ellipsis`).
- [x] Payments Received list — invoice number + payment-mode badge overlap/overflow (multiple rows affected) (Fixed: Wrapped badge and text in `Flexible` + `TextOverflow.ellipsis`).
- [x] New Bill form — "Vendor State" dropdown row overflow (Fixed: Enabled `isExpanded: true` on `StateDropdownField`).
- [x] Bulk Updates screen — "Action" dropdown row overflow (Fixed: Enabled `isExpanded: true` and Text ellipsis in module/action/status dropdowns).
- [x] Taxes & GST Config screen — "Status" filter dropdown overflow (Fixed: Enabled `isExpanded: true` on filter dropdowns).
- [x] All Documents screen — "Category" and "Module" filter dropdowns both overflow (Fixed: Enabled `isExpanded: true` on category/module dropdowns).




**Fix approach:** find the shared widget(s) used for status badges / filter dropdowns / the app-bar avatar (likely one reusable widget each, given how consistently the same overflow appears everywhere) and wrap the offending `Row` children in `Expanded`/`Flexible`, add `TextOverflow.ellipsis` + `maxLines: 1` to text, and reduce fixed-width badge padding on small screens.

---

## 🟡 Blank / Stuck-Loading Screens

- [x] **Record Expense** — screen opens with header only, entire body blank (no form fields render) (Fixed: Resolved runtime Null Safety cast crash in vendor dropdown by changing `DropdownButtonFormField<int>` to `<int?>`).
- [x] **Bill Details** — opens to header only (Bill…, PDF, mail, edit, delete icons) with blank body, PDF/data never loads (Fixed: Resolved type-cast crashes on double formatting of Node-postgres NUMERIC string return fields in `Bill` and `BillItem`).

- [ ] **New Recurring Expense** — header only, form never renders
- [x] **Vendor Credit Details** — header only, blank body (only the PDF icon shows in the app bar) (Fixed: Resolved type-cast crash in `VendorCredit` model and refactored PDF icon to open link using `url_launcher`).

- [x] **Chart of Accounts detail** (opened from Assets/Liabilities/Equity tab) — blank body, just back arrow (Fixed: Resolved type-cast crash in `ChartOfAccount` model deserialization).
- [x] **Financial Dashboard** — gray skeleton/shimmer placeholders never resolve into real data (stuck loading state) (Fixed: Resolved type-cast crashes on double formatting of Node-postgres NUMERIC string return fields in `DashboardSummary`).

- [x] **Assets / Liabilities / Equity tabs** — same stuck skeleton-loading placeholders that never populate with real rows (Fixed: Resolved type-cast crash in `ChartOfAccount.fromJson` openingBalance/currentBalance parsing).


**Fix approach:** check the API call / provider for each screen — likely either (a) the endpoint request never fires, (b) the response fails silently and the loading flag never flips to false, or (c) an exception is being swallowed. Add error states (not just loading/success) so failures are visible instead of blank, and fix the underlying fetch for each.

---

## 🟡 Duplicated Sections in Forms

- [ ] **New Sales Order** — "Notes & Terms" section and "Grand Total" row are both rendered twice on the same screen
- [ ] **New Credit Note** — the entire summary block (Subtotal/Discount/GST Tax/Adjustment/Total Credit) is rendered twice, and "Notes & Terms" is rendered twice
- [ ] **Record Payment** (Received) — "No unpaid invoices found for this customer" text, the "Amount Received / Amount allocated / Amount Refunded / Amount in Excess" summary card, and "Notes" field are all rendered twice

**Fix approach:** likely a widget being appended to a `Column`'s children list twice (e.g. built once for a "sticky/preview" version and once for the "real" form and both left in the tree), or a summary widget accidentally called twice in `build()`. Search each screen's widget tree for the duplicated widget being included twice in the same `Column`/`ListView`.

---

## 🟡 Broken Validation / Save Logic

- [ ] **Record Payment (Received)** — entering an Amount Received (e.g. ₹1250) for a customer with no unpaid invoices still blocks saving with `"Please apply an amount to at least one invoice"`, even though there's nothing to apply it to and the UI itself shows "Amount in Excess: ₹1250.00" (implying an excess/advance payment should be a valid, savable state). Fix validation to allow saving an unapplied/excess payment when there are no open invoices to allocate against.
- [ ] **New Recurring Invoice** — shows `"Missing required fields"` even after Customer, Item (blue pen), and Rate are filled in. Identify which required field the validator is actually checking (likely Profile Name, which is easy to miss/skip) and either surface a field-specific error message or fix the check if it's a false positive.
- [ ] **New Credit Note** — both "Save & Send" and "Save as Draft" return a generic `"Server error"` toast. Needs backend/API log inspection to find the actual failure (payload shape, missing field, auth, etc.) and either fix the request payload or the backend handler. Also replace the generic "Server error" toast with a more specific message where possible.

---

## 🟡 Data Not Persisting

- [ ] **Vendor Credit** — after creating a new vendor credit, the list shows the new entry (`VC-20260707-0001`) but with `₹0.00` as the amount instead of the entered value. Check the create-vendor-credit request payload/mapping — the amount/line-item total is likely not being included or is being lost in transit or in the list's summary calculation.

---

## 🟢 Lower Priority / UX Polish

- [ ] **Vendor Credit → PDF icon** opens a modal showing the raw PDF URL as plain text (`https://eazzio-books.onrender.com/api/vendor-credits/3/pdf`) instead of opening it in a PDF viewer or triggering a download, unlike other PDF icons elsewhere in the app. Make this consistent with how other modules open PDFs.
- [ ] **Bank Rules** and **Currency Adjustments** screens show "coming soon to mobile" placeholders — confirm this is intentional (feature not yet built) rather than a bug, and leave as-is unless product wants these prioritized.
