# Eazzio Books - Deployment Guide

This guide explains how to deploy the Eazzio Books accounting system.

---

## 1. Deployment Overview

Eazzio Books has three main parts:

1. Frontend
2. Backend
3. PostgreSQL Database

Recommended deployment platforms:

| Part | Suggested Platform |
|---|---|
| Frontend | Vercel / Netlify / Render |
| Backend | Render / Railway / VPS |
| Database | Render PostgreSQL / Railway PostgreSQL / Neon / Supabase |

---

## 2. Prepare the Project

Before deployment, make sure:

- Project runs locally.
- All environment variables are ready.
- Database connection is working.
- Frontend API URL points to backend production URL.
- Backend CORS allows frontend production domain.

---

## 3. Backend Deployment on Render

### Step 1: Push Code to GitHub

```bash
git add .
git commit -m "Prepare project for deployment"
git push origin main
```

### Step 2: Create New Web Service

On Render:

1. Create a new Web Service.
2. Connect the GitHub repository.
3. Select the backend folder if required.
4. Add build and start commands.

Example build command:

```bash
npm install
```

Example start command:

```bash
npm start
```

Or:

```bash
npm run dev
```

for development only.

---

## 4. Backend Environment Variables

Add these variables in Render:

```env
PORT=5000
DATABASE_URL=your_production_database_url
JWT_SECRET=your_secure_jwt_secret
EMAIL_USER=your_email
EMAIL_PASS=your_email_password
NODE_ENV=production
```

Important:

- Do not upload `.env` file to GitHub.
- Use strong JWT secret.
- Use production database URL.

---

## 5. Database Deployment

You can use:

- Render PostgreSQL
- Railway PostgreSQL
- Neon PostgreSQL
- Supabase PostgreSQL

After creating the database, copy the connection string and add it to backend environment variables as:

```env
DATABASE_URL=your_database_connection_string
```

---

## 6. Frontend Deployment on Vercel

### Step 1: Import Repository

1. Go to Vercel.
2. Click New Project.
3. Import the GitHub repository.
4. Select the frontend folder if the project is inside `/frontend`.

### Step 2: Build Settings

Example settings:

```text
Framework: React
Build Command: npm run build
Output Directory: build
```

### Step 3: Add Environment Variable

Add frontend API URL:

```env
REACT_APP_API_URL=https://your-backend-url.com/api
```

---

## 7. CORS Configuration

In backend, allow frontend domain:

```js
app.use(cors({
  origin: "https://your-frontend-domain.com",
  credentials: true
}));
```

For local development, allow:

```text
http://localhost:3000
```

For production, allow the deployed frontend URL.

---

## 8. Production Checklist

Before final deployment:

- Backend deployed successfully.
- Frontend deployed successfully.
- Database connected.
- Login and registration working.
- Customer module working.
- Invoice module working.
- Payment module working.
- Expense module working.
- Reports working.
- PDF generation working.
- Email sending working.
- CORS configured properly.
- Environment variables added securely.
- `.env` file not pushed to GitHub.

---

## 9. Common Deployment Errors

### 9.1 Backend not starting

Check:

- Start command
- Missing environment variables
- Database connection
- Node version

### 9.2 Frontend API not working

Check:

- API base URL
- CORS settings
- Backend deployed URL
- HTTPS URL usage

### 9.3 Database error

Check:

- DATABASE_URL is correct
- Database is active
- Tables are created
- SSL setting if required by hosting provider

### 9.4 Login issue after deployment

Check:

- JWT_SECRET exists
- Cookie settings
- CORS credentials
- Frontend and backend URLs

---

## 10. Suggested Low-Cost Deployment

For a minimum-cost setup:

| Component | Platform |
|---|---|
| Frontend | Vercel free tier |
| Backend | Render free/low-cost tier |
| Database | Neon / Supabase free PostgreSQL |
| Repository | GitHub |

---

## 11. Suggested Production Deployment

For better performance:

| Component | Platform |
|---|---|
| Frontend | Vercel Pro / Netlify Pro |
| Backend | Render paid service / Railway / VPS |
| Database | Managed PostgreSQL |
| Storage | Cloud storage if documents are uploaded |
| Monitoring | Uptime monitoring and logging |

---

## 12. Conclusion

Eazzio Books can be deployed using modern cloud platforms such as Vercel, Render, Railway, Neon, and Supabase. For testing and demo purposes, free tiers are enough. For real business usage, a paid backend and managed database are recommended.
