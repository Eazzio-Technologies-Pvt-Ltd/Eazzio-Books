# Eazzio Books — Mobile Parity Report

## Summary
- Total Frontend Pages: 58
- Implemented in Mobile: 53
- Missing in Mobile: 5
- Completion: 91.3%

## Feature Matrix
| # | Feature | Frontend Page | Backend Route | Mobile Screen File | Status |
|---|---------|--------------|---------------|--------------------|--------|
| 1 | Dashboard | /dashboard | GET /api/dashboard | dashboard_screen.dart | DONE |
| 2 | Items | /items | GET /api/items | items_screen.dart | DONE |
| 3 | Add Item | /items/new | POST /api/items | item_form_screen.dart | DONE |
| 4 | Edit Item | /items/:id/edit | PUT /api/items/:id | item_form_screen.dart | DONE |
| 5 | Item Detail | /items/:id | GET /api/items/:id | item_detail_screen.dart | DONE |
| 6 | Stock Adjustments | /inventory/stock | POST /api/inventory/adjustment | stock_adjustment_form_screen.dart | DONE |
| 7 | Inventory Movements | /inventory/movements | GET /api/inventory/movements | inventory_movements_screen.dart | DONE |
| 8 | Low Stock Alerts | /inventory/low-stock | N/A (Client Filter) | Placeholder Page | MISSING |
| 9 | Item Valuation Report | /reports/item-valuation | N/A (Client Filter) | Placeholder Page | MISSING |
| 10 | Customers | /customers | GET /api/customers | customers_screen.dart | DONE |
| 11 | Add Customer | /customers/new | POST /api/customers | customer_form_screen.dart | DONE |
| 12 | Edit Customer | /customers/:id/edit | PUT /api/customers/:id | customer_form_screen.dart | DONE |
| 13 | Customer Detail | /customers/:id | GET /api/customers/:id | customer_detail_screen.dart | DONE |
| 14 | Quotes | /quotes | GET /api/quotes | quotes_screen.dart | DONE |
| 15 | Add Quote | /quotes/new | POST /api/quotes | quote_form_screen.dart | DONE |
| 16 | Quote Detail | /quotes/:id | GET /api/quotes/:id | quote_detail_screen.dart | DONE |
| 17 | Edit Quote | /quotes/:id/edit | PUT /api/quotes/:id | quote_form_screen.dart | DONE |
| 18 | Quote Email | /quotes/:id/email | POST /api/quotes/:id/email | N/A | MISSING |
| 19 | Quote Document | /quotes/:id/document | N/A (Web view/PDF) | N/A | MISSING |
| 20 | Invoices | /invoices | GET /api/invoices | invoices_screen.dart | DONE |
| 21 | Add Invoice | /invoices/new | POST /api/invoices | invoice_form_screen.dart | DONE |
| 22 | Invoice Detail | /invoices/:id | GET /api/invoices/:id | invoice_detail_screen.dart | DONE |
| 23 | Edit Invoice | /invoices/:id/edit | PUT /api/invoices/:id | invoice_form_screen.dart | DONE |
| 24 | Invoice Document | /invoices/:id/document | N/A (Web view/PDF) | N/A | MISSING |
| 25 | Expenses | /expenses | GET /api/expenses | expenses_list_screen.dart | DONE |
| 26 | Add Expense | /expenses/new | POST /api/expenses | expense_form_screen.dart | DONE |
| 27 | Edit Expense | /expenses/:id/edit | PUT /api/expenses/:id | expense_form_screen.dart | DONE |
| 28 | Sales Orders | /sales-orders | GET /api/sales-orders | sales_orders_list_screen.dart | DONE |
| 29 | Add Sales Order | /sales-orders/new | POST /api/sales-orders | sales_order_form_screen.dart | DONE |
| 30 | Edit Sales Order | /sales-orders/:id/edit | PUT /api/sales-orders/:id | sales_order_form_screen.dart | DONE |
| 31 | Sales Order Detail | /sales-orders/:id/document | GET /api/sales-orders/:id | sales_order_detail_screen.dart | DONE |
| 32 | Payments Received | /payments-received | GET /api/payments | payments_received_list_screen.dart | DONE |
| 33 | Record Payment | /payments-received/new | POST /api/payments | payment_received_form_screen.dart | DONE |
| 34 | Delivery Challans | /delivery-challans | GET /api/delivery-challans | delivery_challans_list_screen.dart | DONE |
| 35 | Add Challan | /delivery-challans/new | POST /api/delivery-challans | delivery_challan_form_screen.dart | DONE |
| 36 | Challan Detail | /delivery-challans/:id/document | GET /api/delivery-challans/:id | delivery_challan_detail_screen.dart | DONE |
| 37 | Recurring Invoices | /recurring-invoices | GET /api/recurring-invoices | recurring_invoices_list_screen.dart | DONE |
| 38 | Add Recurring Invoice | /recurring-invoices/new | POST /api/recurring-invoices | recurring_invoice_form_screen.dart | DONE |
| 39 | Credit Notes | /credit-notes | GET /api/credit-notes | credit_notes_list_screen.dart | DONE |
| 40 | Add Credit Note | /credit-notes/new | POST /api/credit-notes | credit_note_form_screen.dart | DONE |
| 41 | Credit Note Detail | /credit-notes/:id/document | GET /api/credit-notes/:id | credit_note_detail_screen.dart | DONE |
| 42 | Vendors | /vendors | GET /api/vendors | vendors_list_screen.dart | DONE |
| 43 | Add Vendor | /vendors/new | POST /api/vendors | vendor_form_screen.dart | DONE |
| 44 | Vendor Detail | /vendors/:id | GET /api/vendors/:id | vendor_detail_screen.dart | DONE |
| 45 | Bills | /bills | GET /api/bills | bills_list_screen.dart | DONE |
| 46 | Add Bill | /bills/new | POST /api/bills | bill_form_screen.dart | DONE |
| 47 | Bill Detail | /bills/:id/document | GET /api/bills/:id | bill_detail_screen.dart | DONE |
| 48 | Payments Made | /payments-made | GET /api/payments-made | payments_made_list_screen.dart | DONE |
| 49 | Record Payment Made | /payments-made/new | POST /api/payments-made | payment_made_form_screen.dart | DONE |
| 50 | Vendor Credits | /vendor-credits | GET /api/vendor-credits | vendor_credits_list_screen.dart | DONE |
| 51 | Add Vendor Credit | /vendor-credits/new | POST /api/vendor-credits | vendor_credit_form_screen.dart | DONE |
| 52 | Projects | /projects | GET /api/projects | projects_list_screen.dart | DONE |
| 53 | Add Project | /projects/new | POST /api/projects | project_form_screen.dart | DONE |
| 54 | Project Detail | /projects/:id | GET /api/projects/:id | project_detail_screen.dart | DONE |
| 55 | Timesheets | /timesheets | GET /api/timesheets | timesheets_list_screen.dart | DONE |
| 56 | Add Timesheet | /timesheets/new | POST /api/timesheets | timesheet_form_screen.dart | DONE |
| 57 | Organization Settings | /organization-settings | GET/PUT /api/organization-settings | organization_settings_screen.dart | DONE |
| 58 | Documents | /documents | GET /api/documents | documents_list_screen.dart | DONE |

## Missing Features (Priority Order)

### HIGH — Backend API exists, Frontend exists, Mobile MISSING
| Feature | Frontend File | Backend Route | Action Needed |
|---------|--------------|---------------|---------------|
| Quote Email | src/QuoteEmail.js | POST /api/quotes/:id/email | Add email button on QuoteDetail screen and build input dialog sheet. |
| Quote Document Preview | src/QuoteDocument.js | N/A (Frontend PDF rendering) | Implement HTML/Canvas template or web preview wrapper within QuoteDetail Screen. |
| Invoice Document Preview | src/InvoiceDocument.js | N/A (Frontend PDF rendering) | Build inline PDF viewer/generator screen in mobile using the raw data model. |

### MEDIUM — Partial implementation
| Feature | What Exists | What is Missing |
|---------|-------------|-----------------|
| Low Stock Alerts | Placeholder page in mobile router | Connect real-time alert trigger checks on the items list locally. |
| Item Valuation Report | Placeholder page in mobile router | Calculation UI layout for asset holdings valuation summary. |

### LOW — Nice to have
| Feature | Notes |
|---------|-------|
| Users & Roles | Currently desktop/admin-only placeholder. Mobile handles authorization automatically based on active token's role check. |
