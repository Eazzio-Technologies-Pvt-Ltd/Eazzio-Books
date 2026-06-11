<p align="center">
  <img src="./logo.png" alt="Eazzio-Books Logo" width="320"/>
</p>

# Eazzio-Books

### A modern accounting and business finance management system for growing organizations.

![Stack](https://img.shields.io/badge/Stack-MERN%20%2B%20PostgreSQL-blue)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen)
![Type](https://img.shields.io/badge/Type-Accounting%20Software-purple)
![License](https://img.shields.io/badge/License-Proprietary-red)

---

## 📖 About The Project

**Eazzio-Books** is a full-stack accounting software designed to help businesses manage their financial operations from one powerful and easy-to-use platform.

It provides a complete business accounting workflow covering customer management, vendor management, quotations, sales orders, delivery challans, invoices, payments, expenses, purchases, inventory, banking, reports, and role-based access control.

Whether you are managing a small business, training center, service company, retail operation, or growing enterprise, **Eazzio-Books** acts as a centralized accounting command center for handling day-to-day business transactions and financial decisions.

---

## ✨ Key Features

### 📊 Modern Dashboard

A clean and professional dashboard with real-time business insights.

* Total receivables
* Total payables
* Total income
* Total expenses
* Projected income
* Projected expense
* Monthly overview
* Cash flow charts
* Top expense analysis
* Quick action links

---

### 👥 Customer Management

Manage customer records and track customer-related transactions.

* Add, edit, and manage customers
* Customer profile and contact details
* Customer transaction history
* Customer statements
* Customer aging reports
* Linked quotes, invoices, payments, and credit notes

---

### 🧑‍💼 Vendor Management

Handle vendor and supplier records efficiently.

* Add and manage vendors
* Vendor profile details
* Vendor transaction history
* Vendor aging reports
* Linked purchase orders, bills, payments, and vendor credits

---

### 🧾 Sales Management

Manage the complete sales workflow from quotation to payment.

```text
Customer → Quote → Sales Order → Delivery Challan → Invoice → Payment Received
```

Features:

* Quotes
* Sales Orders
* Delivery Challans
* Invoices
* Payments Received
* Credit Notes
* PDF generation
* Email sending
* Document conversion workflow

---

### 🛒 Purchase Management

Track supplier purchases, bills, expenses, and payments.

```text
Vendor → Purchase Order → Bill → Payment Made → Vendor Credit
```

Features:

* Purchase Orders
* Bills
* Payments Made
* Vendor Credits
* Expenses
* Recurring / Fixed Expenses

---

### 📦 Inventory Management

Track items, stock, and inventory movement.

* Item creation and management
* Inventory tracking option
* Opening stock
* Stock in / stock out
* Inventory movement history
* Reorder level support
* Negative stock prevention
* Service and non-inventory item support

---

### 🏦 Banking & Reconciliation

Manage bank accounts and financial transactions.

* Bank account management
* Bank transaction tracking
* Bank reconciliation
* Bank rules
* Bank statement import support

---

### 📈 Accounting & Reports

Generate important accounting reports for business decision-making.

* Chart of Accounts
* Manual Journals
* Tax management
* Trial Balance
* Profit & Loss
* Balance Sheet
* Cash Flow
* Customer Aging Report
* Vendor Aging Report
* Business summary reports

---

### 🔐 Role-Based Access Control

Eazzio-Books includes secure role-based access for different user types.

| Role       | Access                                                             |
| ---------- | ------------------------------------------------------------------ |
| Admin      | Full access to all modules                                         |
| Accountant | Sales, purchases, accounting, banking, and reports                 |
| Staff      | Operational records like customers, quotes, invoices, and expenses |
| Viewer     | View-only access                                                   |

---

### 📁 Document Management

Attach and manage business documents.

* Upload documents
* Link documents with business records
* Manage supporting files
* View and download files

---

### 🌙 Dark Mode Support

The application includes theme support for light and dark mode, improving usability and user experience across different working environments.

---

## 🛠️ Technology Stack

Eazzio-Books is built using a modern and scalable full-stack architecture.

### Frontend

* React.js
* React Router
* Axios
* Custom CSS
* Responsive UI
* Dashboard charts

### Backend

* Node.js
* Express.js
* REST APIs
* JWT Authentication
* Bcrypt password hashing
* Nodemailer email support
* PDF generation utilities

### Database

* PostgreSQL

### Security

* JWT-based authentication
* Protected routes
* Role-based access control
* Password hashing
* Environment-based configuration

---

## ⚙️ Getting Started

Follow these steps to run the project locally.

---

## ✅ Prerequisites

Make sure you have the following installed:

* Node.js
* npm
* PostgreSQL
* Git

---

## 📥 Clone The Repository

```bash
git clone https://github.com/Eazzio-Technologies-Pvt-Ltd/Eazzio-Books.git
cd Eazzio-Books
```

---

## 🖥️ Backend Setup

Go to the backend folder:

```bash
cd 04_Source_Code/backend
```

Install dependencies:

```bash
npm install
```

Create a `.env` file:

```env
PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=eazzio_books
JWT_SECRET=your_jwt_secret
FRONTEND_URL=http://localhost:3000
```

Start the backend server:

```bash
npm run dev
```

Backend will run on:

```text
http://localhost:5000
```

---

## 🌐 Frontend Setup

Open a new terminal and go to the frontend folder:

```bash
cd 04_Source_Code/frontend
```

Install dependencies:

```bash
npm install
```

Start the frontend application:

```bash
npm start
```

Frontend will run on:

```text
http://localhost:3000
```

---

## 🔒 Environment Variables

Example backend `.env` file:

```env
PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=eazzio_books
JWT_SECRET=your_secret_key
FRONTEND_URL=http://localhost:3000

EMAIL_HOST=smtp-relay.brevo.com
EMAIL_PORT=587
EMAIL_USER=your_email_user
EMAIL_PASS=your_email_password
```

> ⚠️ Do not commit real `.env` credentials to GitHub.

---

## 🏗️ Project Architecture

```text
Client Layer
│
├── React Web Application
│   ├── Dashboard
│   ├── Sales Modules
│   ├── Purchase Modules
│   ├── Inventory
│   ├── Banking
│   └── Reports
│
API Layer
│
├── Node.js + Express.js
│   ├── Authentication APIs
│   ├── Customer APIs
│   ├── Vendor APIs
│   ├── Sales APIs
│   ├── Purchase APIs
│   ├── Inventory APIs
│   ├── Banking APIs
│   └── Report APIs
│
Data Layer
│
└── PostgreSQL Database
    ├── Users
    ├── Customers
    ├── Vendors
    ├── Items
    ├── Quotes
    ├── Invoices
    ├── Bills
    ├── Payments
    ├── Expenses
    └── Reports Data
```

---

## 🗂️ Project Structure

```bash
Eazzio-Books/
│
├── 04_Source_Code/
│   │
│   ├── backend/
│   │   ├── src/
│   │   │   ├── config/
│   │   │   ├── controllers/
│   │   │   ├── middleware/
│   │   │   ├── routes/
│   │   │   ├── utils/
│   │   │   └── index.js
│   │   │
│   │   ├── package.json
│   │   └── .env
│   │
│   └── frontend/
│       ├── src/
│       │   ├── components/
│       │   ├── pages/
│       │   ├── utils/
│       │   ├── App.js
│       │   └── index.js
│       │
│       ├── package.json
│       └── public/
│
└── README.md
```

---

## 🔄 Core Business Workflows

### Sales Workflow

```text
Customer
   ↓
Quote
   ↓
Sales Order
   ↓
Delivery Challan
   ↓
Invoice
   ↓
Payment Received
```

---

### Purchase Workflow

```text
Vendor
   ↓
Purchase Order
   ↓
Bill
   ↓
Payment Made
   ↓
Vendor Credit
```

---

### Inventory Workflow

```text
Item
   ↓
Opening Stock
   ↓
Stock In / Stock Out
   ↓
Inventory Movement
```

---

### Accounting Workflow

```text
Invoice / Bill / Expense / Payment
   ↓
Accounting Reports
   ↓
Trial Balance
   ↓
Profit & Loss
   ↓
Balance Sheet
```

---

## 📌 Current Modules

### ✅ Implemented Modules

* Authentication
* Dashboard
* Customers
* Vendors
* Items
* Quotes
* Sales Orders
* Delivery Challans
* Invoices
* Payments Received
* Purchase Orders
* Bills
* Payments Made
* Expenses
* Banking
* Reports
* Taxes
* Documents
* User & Role Management
* Recurring / Fixed Expenses

---

### 🛠️ In Progress / Planned Enhancements

* Advanced dashboard forecasting
* Low-stock alerts
* Item valuation report
* GST and tax report improvements
* Advanced PDF and Excel exports
* Mobile responsiveness improvements
* Production deployment setup

---

## 📸 Screenshots

> Add screenshots inside a `screenshots` folder and update the image paths below.

```markdown
![Dashboard](./screenshots/dashboard.png)
![Invoices](./screenshots/invoices.png)
![Reports](./screenshots/reports.png)
```

---

## 📜 Available Scripts

### Backend

```bash
npm run dev
```

Runs the backend server using nodemon.

```bash
npm start
```

Runs the backend server normally.

---

### Frontend

```bash
npm start
```

Runs the frontend development server.

```bash
npm run build
```

Creates a production-ready frontend build.

---

## 🔐 Security Features

* JWT authentication
* Bcrypt password hashing
* Protected frontend routes
* Protected backend APIs
* Role-based access control
* Input validation
* Secure environment variable usage

---

## 🌟 Future Scope

* Mobile application support
* Advanced analytics dashboard
* Automated payment reminders
* Advanced banking integration
* Better tax and compliance reports
* Multi-branch support
* Multi-organization support
* Cloud document storage
* AI-powered financial insights

---

## 👥 Organization

**Organization:** Eazzio-Technologies-Pvt-Ltd
**Project:** Eazzio-Books
**Category:** Accounting Software

---

## 📄 License

This project is proprietary software. Unauthorized copying, modification, distribution, or use of this repository without permission is strictly prohibited.

---

## ⭐ Support

If you find this project useful, consider starring the repository and contributing to future improvements.

Made with ❤️ by the Eazzio-Books Development Team.
