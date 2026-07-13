const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const tenantMiddleware = require("../middleware/tenantMiddleware");
const { 
  getAccounts, getAccountById, createAccount, updateAccount, deleteAccount, 
  getJournals, getJournalById, createJournal, updateJournal, deleteJournal, 
  getProjectedPayments, getProjectedExpenses, getGeneralLedger 
} = require("../controllers/accountingController");

router.get("/accounting/coa", authMiddleware, tenantMiddleware, getAccounts);
router.get("/accounting/coa/:id", authMiddleware, tenantMiddleware, getAccountById);
router.post("/accounting/coa", authMiddleware, tenantMiddleware, createAccount);
router.put("/accounting/coa/:id", authMiddleware, tenantMiddleware, updateAccount);
router.delete("/accounting/coa/:id", authMiddleware, tenantMiddleware, deleteAccount);

router.get("/accounting/journals", authMiddleware, tenantMiddleware, getJournals);
router.get("/accounting/journals/:id", authMiddleware, tenantMiddleware, getJournalById);
router.post("/accounting/journals", authMiddleware, tenantMiddleware, createJournal);
router.put("/accounting/journals/:id", authMiddleware, tenantMiddleware, updateJournal);
router.delete("/accounting/journals/:id", authMiddleware, tenantMiddleware, deleteJournal);

const checkSubscription = require("../middleware/checkSubscription");

router.get("/accounts/projected-payments", authMiddleware, tenantMiddleware, checkSubscription('premium_feature'), getProjectedPayments);
router.get("/accounts/projected-expenses", authMiddleware, tenantMiddleware, checkSubscription('premium_feature'), getProjectedExpenses);

// General Ledger route
router.get("/accounting/ledger/:accountId", authMiddleware, tenantMiddleware, getGeneralLedger);

module.exports = router;
