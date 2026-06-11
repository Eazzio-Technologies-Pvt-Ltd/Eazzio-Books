# Eazzio Books - API Documentation

This document describes the main backend API structure for the Eazzio Books accounting system.

> Note: Endpoint names may vary depending on the actual backend route files. Update this document according to the final implemented routes.

---

## 1. Base URL

For local development:

```text
http://localhost:5000/api
```

For production:

```text
https://your-backend-domain.com/api
```

---

## 2. Authentication APIs

### Register User

```http
POST /api/register
```

Request body:

```json
{
  "email": "user@example.com",
  "password": "password123",
  "organization_name": "Demo Organization",
  "business_type": "Retail"
}
```

Response:

```json
{
  "message": "User registered successfully"
}
```

---

### Login User

```http
POST /api/login
```

Request body:

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:

```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "Admin"
  }
}
```

---

### Logout User

```http
POST /api/logout
```

Response:

```json
{
  "message": "Logout successful"
}
```

---

### Get Profile

```http
GET /api/profile
```

Response:

```json
{
  "id": 1,
  "email": "user@example.com",
  "organization_name": "Demo Organization",
  "role": "Admin"
}
```

---

## 3. Customer APIs

### Get All Customers

```http
GET /api/customers
```

### Get Customer by ID

```http
GET /api/customers/:id
```

### Create Customer

```http
POST /api/customers
```

Request body:

```json
{
  "name": "ABC Traders",
  "email": "abc@example.com",
  "phone": "9876543210",
  "billing_address": "Jamshedpur, Jharkhand"
}
```

### Update Customer

```http
PUT /api/customers/:id
```

### Delete Customer

```http
DELETE /api/customers/:id
```

---

## 4. Vendor APIs

### Get All Vendors

```http
GET /api/vendors
```

### Get Vendor by ID

```http
GET /api/vendors/:id
```

### Create Vendor

```http
POST /api/vendors
```

Request body:

```json
{
  "name": "XYZ Suppliers",
  "email": "xyz@example.com",
  "phone": "9876543210",
  "address": "Ranchi, Jharkhand"
}
```

### Update Vendor

```http
PUT /api/vendors/:id
```

### Delete Vendor

```http
DELETE /api/vendors/:id
```

---

## 5. Item APIs

### Get All Items

```http
GET /api/items
```

### Get Item by ID

```http
GET /api/items/:id
```

### Create Item

```http
POST /api/items
```

Request body:

```json
{
  "name": "Website Development Service",
  "type": "Service",
  "rate": 15000,
  "hsn_code": "998314",
  "unit": "Service"
}
```

### Update Item

```http
PUT /api/items/:id
```

### Delete Item

```http
DELETE /api/items/:id
```

---

## 6. Quote APIs

### Get All Quotes

```http
GET /api/quotes
```

### Get Quote by ID

```http
GET /api/quotes/:id
```

### Create Quote

```http
POST /api/quotes
```

### Update Quote

```http
PUT /api/quotes/:id
```

### Convert Quote to Invoice

```http
POST /api/quotes/:id/convert-to-invoice
```

### Convert Quote to Sales Order

```http
POST /api/quotes/:id/convert-to-sales-order
```

---

## 7. Invoice APIs

### Get All Invoices

```http
GET /api/invoices
```

### Get Invoice by ID

```http
GET /api/invoices/:id
```

### Create Invoice

```http
POST /api/invoices
```

### Update Invoice

```http
PUT /api/invoices/:id
```

### Delete Invoice

```http
DELETE /api/invoices/:id
```

### Generate Invoice PDF

```http
GET /api/invoices/:id/pdf
```

### Send Invoice Email

```http
POST /api/invoices/:id/send-email
```

---

## 8. Payment APIs

### Get All Payments

```http
GET /api/payments-received
```

### Create Payment

```http
POST /api/payments-received
```

Request body:

```json
{
  "invoice_id": 1,
  "amount": 5000,
  "payment_date": "2026-06-11",
  "payment_mode": "Cash"
}
```

---

## 9. Expense APIs

### Get All Expenses

```http
GET /api/expenses
```

### Create Expense

```http
POST /api/expenses
```

Request body:

```json
{
  "expense_date": "2026-06-11",
  "category": "Office Rent",
  "amount": 10000,
  "payment_mode": "Bank"
}
```

---

## 10. Purchase Order APIs

### Get All Purchase Orders

```http
GET /api/purchase-orders
```

### Get Purchase Order by ID

```http
GET /api/purchase-orders/:id
```

### Create Purchase Order

```http
POST /api/purchase-orders
```

### Convert Purchase Order to Bill

```http
POST /api/purchase-orders/:id/convert-to-bill
```

---

## 11. Report APIs

### Profit and Loss Report

```http
GET /api/reports/profit-loss
```

### Balance Sheet

```http
GET /api/reports/balance-sheet
```

### Trial Balance

```http
GET /api/reports/trial-balance
```

### Cash Flow

```http
GET /api/reports/cash-flow
```

### Aging Report

```http
GET /api/reports/aging
```

---

## 12. Common Response Codes

| Status Code | Meaning |
|---|---|
| 200 | Request successful |
| 201 | Data created successfully |
| 400 | Bad request or validation error |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Data not found |
| 500 | Internal server error |

---

## 13. Authentication Note

Protected APIs require a valid login session or JWT token. The frontend should send authentication credentials with API requests.

---

## 14. Conclusion

This API documentation provides the basic structure of the Eazzio Books backend APIs. It should be updated whenever new routes, request fields, or response formats are added.
