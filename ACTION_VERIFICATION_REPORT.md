# ACTION VERIFICATION REPORT: DOCUMENT ACTIONS

This report provides the verification status of document actions (Save, Save & Send, Mark as Sent) for Quote, Invoice, Sales Order, Delivery Challan, and Credit Note modules across the **@mobile-books** (Flutter frontend) and **@backend-books** (Node.js/Express backend) codebases.

---

## 1. Quote Actions

### Action: Save
- **Feature**: Quote
- **Action**: Save
- **UI Button**: AppBar check icon (`TextButton.icon`) and bottom "Save Quote" `ElevatedButton` in `quote_form_screen.dart`
- **Provider**: `quotesProvider.notifier` (triggers `createQuote` or `updateQuote`) in `quote_provider.dart`
- **Service**: `quote_service.dart` (`createQuote` / `updateQuote`)
- **API Endpoint**: `POST /api/quotes` or `PUT /api/quotes/:id`
- **Backend Route Exists**: YES
- **Verified Working**: YES
- **Flow Details**: Button triggers form validation, calculates correct GST/discount aggregates, maps to JSON model, executes API request, handles response, shows success snackbar, pops screen, and invalidates the quote list state to trigger data refresh.

### Action: Save & Send
- **Feature**: Quote
- **Action**: Save & Send
- **UI Button**: None (Missing)
- **Provider**: None (Missing)
- **Service**: None (Missing)
- **API Endpoint**: None (Missing unified route)
- **Backend Route Exists**: NO
- **Verified Working**: NO
- **Broken / Missing Connections**: 
  - No "Save & Send" button in `quote_form_screen.dart`.
  - No combined controller/route on the backend to create the quote and trigger Nodemailer email generation in a single HTTP request.

### Action: Mark as Sent
- **Feature**: Quote
- **Action**: Mark as Sent
- **UI Button**: None (Missing standalone button)
- **Provider**: `quotesProvider.notifier` (via `sendEmail`)
- **Service**: `quote_service.dart` (`sendQuoteEmail` mapping to `/quotes/:id/send`)
- **API Endpoint**: `POST /api/quotes/:id/send`
- **Backend Route Exists**: YES
- **Verified Working**: NO (Partially working via email dispatch only; no standalone action)
- **Broken / Missing Connections**:
  - No standalone "Mark as Sent" status override button exists in the UI.
  - *Note*: Sending email from the detail view triggers the backend SMTP service, which updates the status to `'sent'` in the DB as a side effect and invalidates Riverpod state. However, a dedicated direct action path from UI to backend without email dispatch is missing.

---

## 2. Invoice Actions

### Action: Save
- **Feature**: Invoice
- **Action**: Save
- **UI Button**: AppBar check icon (`TextButton.icon`) and bottom "Save Invoice" `ElevatedButton` in `invoice_form_screen.dart`
- **Provider**: `invoicesProvider.notifier` (triggers `createInvoice` or `updateInvoice`) in `invoice_provider.dart`
- **Service**: `invoice_service.dart` (`createInvoice` / `updateInvoice`)
- **API Endpoint**: `POST /api/invoices` or `PUT /api/invoices/:id`
- **Backend Route Exists**: YES
- **Verified Working**: YES
- **Flow Details**: Collects fields, executes form validation, calculates totals, maps to JSON model, sends payload to backend APIs, displays success notifications, pops screen, and refreshes UI list providers via invalidation.

### Action: Save & Send
- **Feature**: Invoice
- **Action**: Save & Send
- **UI Button**: None (Missing)
- **Provider**: None (Missing)
- **Service**: None (Missing)
- **API Endpoint**: None (Missing unified route)
- **Backend Route Exists**: NO
- **Verified Working**: NO
- **Broken / Missing Connections**:
  - No "Save & Send" button in `invoice_form_screen.dart`.
  - No consolidated transaction endpoint exists in backend router or controller.

### Action: Mark as Sent
- **Feature**: Invoice
- **Action**: Mark as Sent
- **UI Button**: None (Missing standalone button)
- **Provider**: `invoicesProvider.notifier` (via `sendEmail`)
- **Service**: `invoice_service.dart` (`sendInvoiceEmail` mapping to `/invoices/:id/send`)
- **API Endpoint**: `POST /api/invoices/:id/send`
- **Backend Route Exists**: YES
- **Verified Working**: NO (Partially working via email dispatch only; no standalone action)
- **Broken / Missing Connections**:
  - No dedicated "Mark as Sent" status change button exists in the UI.
  - *Note*: Requesting an email dispatch via details modal updates the DB status to `'sent'` as a side effect and triggers UI updates, but a standalone direct state conversion path is missing.

---

## 3. Sales Order Actions

### Action: Save
- **Feature**: Sales Order
- **Action**: Save
- **UI Button**: AppBar check icon (`TextButton.icon`) and bottom "Save Sales Order" `ElevatedButton` in `sales_order_form_screen.dart`
- **Provider**: `salesOrdersProvider.notifier` (triggers `createSalesOrder` or `updateSalesOrder`) in `sales_order_provider.dart`
- **Service**: `sales_order_service.dart` (`createSalesOrder` / `updateSalesOrder`)
- **API Endpoint**: `POST /api/sales-orders` or `PUT /api/sales-orders/:id`
- **Backend Route Exists**: YES
- **Verified Working**: YES
- **Flow Details**: Collects input variables, performs validations, performs GST calculations, submits JSON payload to DB, updates state, alerts user via SnackBar, and invalidates providers to update UI tables.

### Action: Save & Send
- **Feature**: Sales Order
- **Action**: Save & Send
- **UI Button**: None (Missing)
- **Provider**: None (Missing)
- **Service**: None (Missing)
- **API Endpoint**: None (Missing unified route)
- **Backend Route Exists**: NO
- **Verified Working**: NO
- **Broken / Missing Connections**:
  - No "Save & Send" button in form layout.
  - No combined endpoint on the backend.

### Action: Mark as Sent
- **Feature**: Sales Order
- **Action**: Mark as Sent
- **UI Button**: None (Missing standalone button)
- **Provider**: `salesOrdersProvider.notifier` (via `sendEmail`)
- **Service**: `sales_order_service.dart` (`sendSalesOrderEmail` mapping to `/sales-orders/:id/send`)
- **API Endpoint**: `POST /api/sales-orders/:id/send`
- **Backend Route Exists**: YES
- **Verified Working**: NO (Partially working via email dispatch only; no standalone action)
- **Broken / Missing Connections**:
  - No dedicated "Mark as Sent" action button.
  - *Note*: Sending email updates the status in the DB to `'confirmed'` (not `'sent'`) if the status was originally `'draft'`, but no standalone toggle connection is present.

---

## 4. Delivery Challan Actions

### Action: Save
- **Feature**: Delivery Challan
- **Action**: Save
- **UI Button**: AppBar check icon and bottom "Save Delivery Challan" `ElevatedButton` in `delivery_challan_form_screen.dart`
- **Provider**: `deliveryChallansProvider.notifier` (triggers `createDeliveryChallan` or `updateDeliveryChallan`) in `delivery_challan_provider.dart`
- **Service**: `delivery_challan_service.dart` (`createDeliveryChallan` / `updateDeliveryChallan`)
- **API Endpoint**: `POST /api/delivery-challans` or `PUT /api/delivery-challans/:id`
- **Backend Route Exists**: YES
- **Verified Working**: YES
- **Flow Details**: Fully wired up from forms validation to PostgreSQL storage, alerts on success, pops back, and invalidates list states to pull fresh data.

### Action: Save & Send
- **Feature**: Delivery Challan
- **Action**: Save & Send
- **UI Button**: None (Missing)
- **Provider**: None (Missing)
- **Service**: None (Missing)
- **API Endpoint**: None (Missing unified route)
- **Backend Route Exists**: NO
- **Verified Working**: NO
- **Broken / Missing Connections**:
  - Button missing from form.
  - API endpoint missing on backend.

### Action: Mark as Sent
- **Feature**: Delivery Challan
- **Action**: Mark as Sent
- **UI Button**: None (Missing standalone button)
- **Provider**: `deliveryChallansProvider.notifier` (via `sendEmail`)
- **Service**: `delivery_challan_service.dart` (`sendEmail` mapping to `/delivery-challans/:id/send`)
- **API Endpoint**: `POST /api/delivery-challans/:id/send`
- **Backend Route Exists**: YES
- **Verified Working**: NO
- **Broken / Missing Connections**:
  - No explicit "Mark as Sent" status button in UI (only a "Mark Delivered" button exists, which updates DB status to `'Delivered'`).
  - *Note*: Unlike Invoices and Quotes, the backend email dispatch endpoint (`POST /api/delivery-challans/:id/send`) does **NOT** update the Challan status in the database to `'sent'`. It only executes the email dispatch and returns success.

---

## 5. Credit Note Actions

### Action: Save
- **Feature**: Credit Note
- **Action**: Save
- **UI Button**: AppBar check icon and bottom "Save Credit Note" `ElevatedButton` in `credit_note_form_screen.dart`
- **Provider**: `creditNotesProvider.notifier` (triggers `createCreditNote` or `updateCreditNote`) in `credit_note_provider.dart`
- **Service**: `credit_note_service.dart` (`createCreditNote` / `updateCreditNote`)
- **API Endpoint**: `POST /api/credit-notes` or `PUT /api/credit-notes/:id`
- **Backend Route Exists**: YES
- **Verified Working**: YES
- **Flow Details**: Collects fields, runs validation, executes GST calculation, sends payload, processes response, alerts with SnackBar, pops, and invalidates relevant providers.

### Action: Save & Send
- **Feature**: Credit Note
- **Action**: Save & Send
- **UI Button**: None (Missing)
- **Provider**: None (Missing)
- **Service**: None (Missing)
- **API Endpoint**: None (Missing unified route)
- **Backend Route Exists**: NO
- **Verified Working**: NO
- **Broken / Missing Connections**:
  - Form lacks button.
  - Route lacks unified save-and-send controller logic.

### Action: Mark as Sent
- **Feature**: Credit Note
- **Action**: Mark as Sent
- **UI Button**: None (Missing standalone button)
- **Provider**: `creditNotesProvider.notifier` (via `sendEmail`)
- **Service**: `credit_note_service.dart` (`sendCreditNoteEmail` mapping to `/credit-notes/:id/send`)
- **API Endpoint**: `POST /api/credit-notes/:id/send`
- **Backend Route Exists**: YES
- **Verified Working**: NO
- **Broken / Missing Connections**:
  - No explicit UI button to mark as sent.
  - *Note*: The backend email dispatch endpoint (`POST /api/credit-notes/:id/send`) does **NOT** update the Credit Note status in the database to `'sent'`. It only dispatches the email and returns success.
