# Eazzio Books - Installation Guide

This guide explains how to clone, install, and run the Eazzio Books project on a local system.

---

## 1. Prerequisites

Before running the project, make sure the following tools are installed:

- Git
- Node.js
- npm
- PostgreSQL
- VS Code or any code editor

---

## 2. Clone the Repository

Open PowerShell or terminal and go to the Desktop:

```bash
cd C:\Users\priti\Desktop
```

Clone the repository:

```bash
git clone https://github.com/Eazzio-Technologies-Pvt-Ltd/Eazzio-Books.git
```

Go inside the project folder:

```bash
cd Eazzio-Books
```

---

## 3. Project Folder Structure

The project may contain frontend and backend folders:

```text
Eazzio-Books/
│
├── frontend/
├── backend/
├── documents/
├── README.md
└── package.json
```

---

## 4. Backend Setup

Go to the backend folder:

```bash
cd backend
```

Install dependencies:

```bash
npm install
```

Create a `.env` file inside the backend folder:

```env
PORT=5000
DATABASE_URL=your_postgresql_database_url
JWT_SECRET=your_jwt_secret_key
EMAIL_USER=your_email
EMAIL_PASS=your_email_password
```

Run the backend server:

```bash
npm run dev
```

If `npm run dev` does not work, try:

```bash
npm start
```

---

## 5. Frontend Setup

Open another terminal and go to the frontend folder:

```bash
cd C:\Users\priti\Desktop\Eazzio-Books\frontend
```

Install dependencies:

```bash
npm install
```

Start the frontend:

```bash
npm start
```

The frontend usually runs on:

```text
http://localhost:3000
```

---

## 6. Database Setup

Create a PostgreSQL database for the project.

Example database name:

```text
eazzio_books
```

Update the database connection string in the backend `.env` file.

Example:

```env
DATABASE_URL=postgresql://username:password@localhost:5432/eazzio_books
```

Run migration or table creation scripts if available in the backend folder.

---

## 7. Check Project Status

To check Git status:

```bash
git status
```

To open the project in VS Code:

```bash
code .
```

---

## 8. Common Issues

### 8.1 npm install error

Try deleting `node_modules` and `package-lock.json`, then run:

```bash
npm install
```

### 8.2 Port already in use

Change the port in the `.env` file or stop the existing process.

### 8.3 Database connection error

Check:

- PostgreSQL is running
- Database exists
- Username and password are correct
- DATABASE_URL is correct

### 8.4 Login or API not working

Check:

- Backend server is running
- Frontend API base URL is correct
- JWT secret is available in `.env`
- Database tables are created

---

## 9. Final Run Commands

Backend:

```bash
cd backend
npm install
npm run dev
```

Frontend:

```bash
cd frontend
npm install
npm start
```

---

## 10. Conclusion

After completing the setup, the Eazzio Books project should run locally with the frontend and backend connected to the PostgreSQL database.
