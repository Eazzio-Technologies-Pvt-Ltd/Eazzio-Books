# Eazzio Books - Database Schema

This document describes the main database tables used in the Eazzio Books accounting system.

> Note: This is a documentation-level schema. Update column names according to the final database implementation.

---

## 1. Database Used

The project uses:

```text
PostgreSQL
```

Suggested database name:

```text
eazzio_books
```

---

## 2. Main Tables

The main database tables may include:

- users
- organizations
- customers
- vendors
- items
- quotes
- quote_items
- sales_orders
- sales_order_items
- invoices
- invoice_items
- payments_received
- expenses
- purchase_orders
- purchase_order_items
- bills
- chart_of_accounts
- journal_entries
- taxes

---

## 3. Users Table

Stores user login and role details.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| email | VARCHAR | User email |
| password | VARCHAR | Hashed password |
| role | VARCHAR | User role such as Admin, Accountant, Staff, Viewer |
| organization_id | INTEGER | Linked organization |
| reset_password_token | VARCHAR | Password reset token |
| reset_password_expires | TIMESTAMP | Reset token expiry |
| created_at | TIMESTAMP | Account creation date |

---

## 4. Organizations Table

Stores business or organization details.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_name | VARCHAR | Organization name |
| business_type | VARCHAR | Type of business |
| email | VARCHAR | Organization email |
| phone | VARCHAR | Contact number |
| address | TEXT | Business address |
| gst_number | VARCHAR | GST number |
| created_at | TIMESTAMP | Creation date |

---

## 5. Customers Table

Stores customer records.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| name | VARCHAR | Customer name |
| email | VARCHAR | Customer email |
| phone | VARCHAR | Customer phone |
| billing_address | TEXT | Billing address |
| shipping_address | TEXT | Shipping address |
| gst_number | VARCHAR | Customer GST number |
| status | VARCHAR | Active or inactive |
| created_at | TIMESTAMP | Creation date |

---

## 6. Vendors Table

Stores vendor records.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| name | VARCHAR | Vendor name |
| email | VARCHAR | Vendor email |
| phone | VARCHAR | Vendor phone |
| address | TEXT | Vendor address |
| gst_number | VARCHAR | Vendor GST number |
| status | VARCHAR | Active or inactive |
| created_at | TIMESTAMP | Creation date |

---

## 7. Items Table

Stores product and service records.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| name | VARCHAR | Item name |
| type | VARCHAR | Product or Service |
| rate | DECIMAL | Selling price |
| purchase_rate | DECIMAL | Purchase price |
| hsn_code | VARCHAR | HSN/SAC code |
| unit | VARCHAR | Unit such as pcs, kg, service |
| stock_quantity | DECIMAL | Available stock |
| is_inventory_tracked | BOOLEAN | Whether stock is tracked |
| created_at | TIMESTAMP | Creation date |

---

## 8. Quotes Table

Stores quotation details.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| customer_id | INTEGER | Linked customer |
| quote_number | VARCHAR | Quote number |
| quote_date | DATE | Quote date |
| expiry_date | DATE | Quote expiry date |
| subtotal | DECIMAL | Subtotal amount |
| tax_amount | DECIMAL | Tax amount |
| discount_amount | DECIMAL | Discount |
| total_amount | DECIMAL | Final amount |
| status | VARCHAR | Draft, sent, accepted, invoiced |
| created_at | TIMESTAMP | Creation date |

---

## 9. Quote Items Table

Stores line items of quotes.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| quote_id | INTEGER | Linked quote |
| item_id | INTEGER | Linked item |
| item_name | VARCHAR | Item snapshot name |
| hsn_code | VARCHAR | HSN/SAC snapshot |
| quantity | DECIMAL | Quantity |
| rate | DECIMAL | Rate |
| tax_rate | DECIMAL | Tax percentage |
| amount | DECIMAL | Line total |

---

## 10. Invoices Table

Stores invoice records.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| customer_id | INTEGER | Linked customer |
| invoice_number | VARCHAR | Invoice number |
| invoice_date | DATE | Invoice date |
| due_date | DATE | Payment due date |
| subtotal | DECIMAL | Subtotal amount |
| tax_amount | DECIMAL | Tax amount |
| discount_amount | DECIMAL | Discount |
| total_amount | DECIMAL | Final amount |
| amount_paid | DECIMAL | Paid amount |
| balance_due | DECIMAL | Pending amount |
| status | VARCHAR | Draft, sent, partially_paid, paid |
| created_at | TIMESTAMP | Creation date |

---

## 11. Invoice Items Table

Stores line items of invoices.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| invoice_id | INTEGER | Linked invoice |
| item_id | INTEGER | Linked item |
| item_name | VARCHAR | Item snapshot name |
| hsn_code | VARCHAR | HSN/SAC snapshot |
| quantity | DECIMAL | Quantity |
| rate | DECIMAL | Rate |
| tax_rate | DECIMAL | Tax percentage |
| amount | DECIMAL | Line total |

---

## 12. Payments Received Table

Stores payment records against invoices.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| customer_id | INTEGER | Linked customer |
| invoice_id | INTEGER | Linked invoice |
| payment_date | DATE | Payment date |
| amount | DECIMAL | Payment amount |
| payment_mode | VARCHAR | Cash, Bank, UPI, etc. |
| reference_number | VARCHAR | Payment reference |
| notes | TEXT | Additional notes |
| created_at | TIMESTAMP | Creation date |

---

## 13. Expenses Table

Stores business expense records.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| expense_date | DATE | Expense date |
| category | VARCHAR | Expense category |
| amount | DECIMAL | Expense amount |
| payment_mode | VARCHAR | Cash, Bank, UPI, etc. |
| vendor_id | INTEGER | Linked vendor if applicable |
| notes | TEXT | Notes |
| created_at | TIMESTAMP | Creation date |

---

## 14. Purchase Orders Table

Stores purchase order details.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| vendor_id | INTEGER | Linked vendor |
| po_number | VARCHAR | Purchase order number |
| po_date | DATE | Purchase order date |
| expected_delivery_date | DATE | Expected delivery date |
| subtotal | DECIMAL | Subtotal |
| tax_amount | DECIMAL | Tax |
| total_amount | DECIMAL | Final amount |
| status | VARCHAR | Draft, issued, received, billed |
| created_at | TIMESTAMP | Creation date |

---

## 15. Chart of Accounts Table

Stores accounting heads.

| Column | Type | Description |
|---|---|---|
| id | SERIAL / INTEGER | Primary key |
| organization_id | INTEGER | Linked organization |
| account_name | VARCHAR | Account name |
| account_type | VARCHAR | Asset, Liability, Income, Expense, Equity |
| account_code | VARCHAR | Account code |
| status | VARCHAR | Active or inactive |
| created_at | TIMESTAMP | Creation date |

---

## 16. Relationships

Common relationships:

- One organization has many users.
- One organization has many customers.
- One organization has many vendors.
- One customer has many quotes.
- One customer has many invoices.
- One invoice has many invoice items.
- One invoice has many payments.
- One vendor has many purchase orders.
- One quote can be converted into an invoice.
- One quote can be converted into a sales order.
- One purchase order can be converted into a bill.

---

## 17. Notes

- Monetary fields should use `DECIMAL` instead of `FLOAT`.
- Passwords should always be stored in hashed format.
- Soft delete can be used for customers, vendors, and items.
- Organization-wise filtering should be applied to protect business data.
- Foreign keys should be used where possible.
- Created and updated timestamps should be maintained.

---

## 18. Conclusion

This database schema supports the core accounting workflow of Eazzio Books, including sales, purchases, inventory, payments, expenses, and reports.
