import React, { useState, useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function AddPaymentMade() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const queryVendorId = searchParams.get("vendor_id") || "";
  const queryBillId = searchParams.get("bill_id") || "";

  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(true);
  const [vendors, setVendors] = useState([]);
  const [bills, setBills] = useState([]);

  // Form states
  const [vendorId, setVendorId] = useState(queryVendorId);
  const [billId, setBillId] = useState(queryBillId);
  const [amount, setAmount] = useState("");
  const [paymentNumber, setPaymentNumber] = useState("");
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().slice(0, 10));
  const [paymentMode, setPaymentMode] = useState("Cash");
  const [paidThrough, setPaidThrough] = useState("Petty Cash");
  const [referenceNumber, setReferenceNumber] = useState("");
  const [notes, setNotes] = useState("");

  // Vendor Advance specific states
  const [tds, setTds] = useState("");
  const [depositTo, setDepositTo] = useState("Petty Cash");

  const [showVendorDetailsPanel, setShowVendorDetailsPanel] = useState(false);
  const [activeFormTab, setActiveFormTab] = useState("Bill Payment");
  const [advanceDepositTo, setAdvanceDepositTo] = useState("Advance Tax");

  // Keep track of applied amounts on each bill in a map
  const [appliedAmounts, setAppliedAmounts] = useState({});

  useEffect(() => {
    const init = async () => {
      try {
        const [, bRes] = await Promise.all([fetchVendors(), fetchBills()]);
        // Default Payment Number generation (mocked)
        setPaymentNumber(Math.floor(1000 + Math.random() * 9000).toString());

        if (queryBillId) {
          const list = bRes?.bills || [];
          const b = list.find(x => String(x.id) === String(queryBillId));
          if (b) {
            setAmount(b.balance_due);
            setAppliedAmounts({ [b.id]: b.balance_due });
          }
        }
      } finally {
        setFetching(false);
      }
    };
    init();
  }, [queryBillId]);

  const fetchVendors = async () => {
    try {
      const res = await apiRequest("/vendors");
      setVendors(res?.vendors || []);
      return res;
    } catch (err) {
      toast.error("Failed to load vendors");
    }
  };

  const fetchBills = async () => {
    try {
      const res = await apiRequest("/bills");
      setBills(res?.bills || []);
      return res;
    } catch (err) {
      toast.error("Failed to load bills");
    }
  };

  const selectedVendor = vendors.find(v => String(v.id) === String(vendorId));
  const selectedBill = bills.find(b => b.id === parseInt(billId));
  const maxAmount = selectedBill ? parseFloat(selectedBill.balance_due) : 0;

  // Filter bills to only show unpaid/partially paid bills for the selected vendor
  const availableBills = bills.filter(b => 
    b.vendor_id === parseInt(vendorId) && 
    parseFloat(b.balance_due) > 0 && 
    b.status !== "draft"
  );

  const totalOutstanding = availableBills.reduce((acc, curr) => acc + parseFloat(curr.balance_due || 0), 0);

  // Calculations for bottom summary card
  const amountPaid = parseFloat(amount || 0);
  const amountUsed = Object.values(appliedAmounts).reduce((acc, curr) => acc + (parseFloat(curr) || 0), 0);
  const amountRefunded = 0.0;
  const amountInExcess = Math.max(0, amountPaid - amountUsed);

  const handleSave = async (e, customStatus = null) => {
    if (e) e.preventDefault();

    if (!vendorId) return toast.error("Please select a vendor");
    
    // For Bill Payment tab, a target bill must be selected
    if (activeFormTab === "Bill Payment" && !billId) {
      return toast.error("Please select a bill to apply payment");
    }

    const payAmount = parseFloat(amount);
    if (!payAmount || payAmount <= 0) return toast.error("Amount must be greater than 0");

    if (activeFormTab === "Bill Payment" && payAmount > maxAmount) {
      return toast.error(`Amount cannot exceed the balance due of ₹${maxAmount}`);
    }

    setLoading(true);
    try {
      // Determine backend target bill ID (fallback to first available bill if it's an advance payment)
      let targetBillId = billId;
      if (activeFormTab === "Vendor Advance") {
        const firstBill = bills.find(b => b.vendor_id === parseInt(vendorId));
        targetBillId = firstBill ? firstBill.id.toString() : (billId || "1");
      }

      const payload = {
        vendor_id: vendorId,
        bill_id: targetBillId,
        amount: payAmount,
        payment_date: paymentDate,
        payment_mode: paymentMode,
        reference_number: referenceNumber || paymentNumber,
        notes: notes || (activeFormTab === "Vendor Advance" 
          ? `Vendor Advance. TDS: ${tds || "None"}. Deposit To: ${advanceDepositTo}. Paid Through: ${depositTo}. Status: ${customStatus || 'Paid'}`
          : `Paid through ${paidThrough}. Status: ${customStatus || 'Paid'}`
        )
      };

      await apiRequest("/payments-made", { method: "POST", body: JSON.stringify(payload) });
      toast.success(customStatus === "Draft" ? "Saved as draft" : "Payment recorded successfully");
      navigate("/payments-made");
    } catch (err) {
      toast.error(err.message || "Failed to record payment");
    } finally {
      setLoading(false);
    }
  };

  if (fetching) {
    return (
      <div style={{ padding: "30px", maxWidth: "1050px", margin: "auto", fontFamily: "system-ui, -apple-system, sans-serif", background: "#f8fafc", minHeight: "calc(100vh - 60px)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
          <h2 style={{ fontSize: "20px", color: "#1c2434", fontWeight: "700", margin: 0 }}>New Payment</h2>
          <button onClick={() => navigate("/payments-made")} style={secondaryBtn}>Close</button>
        </div>
        <div style={{ background: "#ffffff", padding: "32px", borderRadius: "8px", border: "1px solid #eaecf0" }}>
          <FormSkeleton fields={5} />
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: "30px", maxWidth: "1050px", margin: "auto", fontFamily: "system-ui, -apple-system, sans-serif", background: "#f8fafc", minHeight: "calc(100vh - 60px)" }}>
      
      {/* Top Breadcrumb / Title Bar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
        <h2 style={{ fontSize: "20px", color: "#1c2434", fontWeight: "700", margin: 0 }}>New Payment</h2>
        <button onClick={() => navigate("/payments-made")} style={secondaryBtn}>Close</button>
      </div>

      {/* Main Form container with tab header */}
      <div style={{ background: "#ffffff", borderRadius: "8px", border: "1px solid #eaecf0", boxShadow: "0 1px 3px rgba(16, 24, 40, 0.05)", overflow: "hidden" }}>
        
        {/* Tab Headers */}
        <div style={{ display: "flex", borderBottom: "1px solid #eaecf0", background: "#fcfcfd", padding: "0 24px" }}>
          <button 
            type="button" 
            onClick={() => setActiveFormTab("Bill Payment")}
            style={{
              padding: "14px 20px",
              border: "none",
              background: "none",
              fontSize: "13px",
              fontWeight: "600",
              color: activeFormTab === "Bill Payment" ? "#006ee6" : "#64748b",
              borderBottom: activeFormTab === "Bill Payment" ? "2px solid #006ee6" : "2px solid transparent",
              cursor: "pointer"
            }}
          >
            Bill Payment
          </button>
          <button 
            type="button" 
            onClick={() => setActiveFormTab("Vendor Advance")}
            style={{
              padding: "14px 20px",
              border: "none",
              background: "none",
              fontSize: "13px",
              fontWeight: "600",
              color: activeFormTab === "Vendor Advance" ? "#006ee6" : "#64748b",
              borderBottom: activeFormTab === "Vendor Advance" ? "2px solid #006ee6" : "2px solid transparent",
              cursor: "pointer"
            }}
          >
            Vendor Advance
          </button>
        </div>

        {/* Form Body */}
        <div style={{ padding: "32px" }}>
          <form onSubmit={(e) => handleSave(e)}>
            
            {/* VENDOR NAME FIELD */}
            <div style={{ display: "flex", alignItems: "center", gap: "16px", marginBottom: "24px", flexWrap: "wrap" }}>
              <div style={{ flex: 1, minWidth: "300px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "6px", marginBottom: "6px" }}>
                  <label style={labelStyle}>Vendor Name *</label>
                  <span style={{ display: "inline-flex", width: "8px", height: "8px", borderRadius: "50%", background: "#006ee6" }}></span>
                </div>
                <select 
                  value={vendorId} 
                  onChange={e => { 
                    const selectedVid = e.target.value;
                    setVendorId(selectedVid); 
                    setShowVendorDetailsPanel(false);
                    
                    const vendorBills = bills.filter(b => 
                      b.vendor_id === parseInt(selectedVid) && 
                      parseFloat(b.balance_due) > 0 && 
                      b.status !== "draft"
                    );
                    if (vendorBills.length > 0) {
                      setBillId(vendorBills[0].id.toString());
                      setAmount(vendorBills[0].balance_due);
                      setAppliedAmounts({ [vendorBills[0].id]: vendorBills[0].balance_due });
                    } else {
                      setBillId("");
                      setAmount("");
                      setAppliedAmounts({});
                    }
                  }} 
                  style={inputStyle} 
                  required
                >
                  <option value="">Select Vendor</option>
                  {vendors.map(v => (
                    <option key={v.id} value={v.id}>{v.display_name || v.company_name || v.email}</option>
                  ))}
                </select>
              </div>

              {selectedVendor && (
                <div style={{ marginTop: "22px" }}>
                  <button 
                    type="button" 
                    onClick={() => setShowVendorDetailsPanel(!showVendorDetailsPanel)}
                    style={{
                      background: "#2d3748",
                      color: "#ffffff",
                      border: "none",
                      padding: "10px 16px",
                      borderRadius: "6px",
                      fontSize: "12px",
                      fontWeight: "600",
                      cursor: "pointer",
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                      transition: "background 0.15s ease"
                    }}
                  >
                    <span>{selectedVendor.display_name || selectedVendor.company_name || "Vendor"}'s Details</span>
                    <span style={{ fontSize: "10px" }}>{showVendorDetailsPanel ? "▼" : "▶"}</span>
                  </button>
                </div>
              )}
            </div>

            {/* Vendor Mini Details Drawer */}
            {showVendorDetailsPanel && selectedVendor && (
              <div style={{
                background: "#f8fafc",
                border: "1px solid #e2e8f0",
                borderRadius: "8px",
                padding: "20px",
                marginBottom: "24px",
                fontSize: "13px",
                color: "#334155",
                animation: "slideDown 0.2s ease-out"
              }}>
                <h4 style={{ margin: "0 0 10px 0", fontSize: "14px", fontWeight: "600", color: "#1e293b" }}>Vendor Contact Info</h4>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px" }}>
                  <div><strong>Company Name:</strong> {selectedVendor.company_name || "—"}</div>
                  <div><strong>Email Address:</strong> {selectedVendor.email || "—"}</div>
                  <div><strong>Phone Number:</strong> {selectedVendor.phone || "—"}</div>
                  <div><strong>GSTIN / Tax ID:</strong> {selectedVendor.gst_number || "—"}</div>
                </div>
                {selectedVendor.billing_address && (
                  <div style={{ marginTop: "12px", borderTop: "1px solid #e2e8f0", paddingTop: "10px" }}>
                    <strong>Billing Address:</strong> {selectedVendor.billing_address}
                  </div>
                )}
              </div>
            )}

            {/* OTHER DETAILS (Visible after Vendor is chosen) */}
            {vendorId ? (
              <div style={{ animation: "fadeIn 0.3s ease-out" }}>
                
                {/* PAYMENT NUMBER */}
                <div style={{ marginBottom: "20px", maxWidth: "450px" }}>
                  <label style={labelStyle}>Payment #*</label>
                  <input 
                    type="text" 
                    value={paymentNumber} 
                    onChange={e => setPaymentNumber(e.target.value)} 
                    style={inputStyle} 
                    required 
                  />
                </div>

                {/* PAYMENT MADE AMOUNT */}
                <div style={{ marginBottom: "20px", maxWidth: "450px" }}>
                  <label style={labelStyle}>Payment Made *</label>
                  <div style={{ display: "flex", position: "relative", alignItems: "center" }}>
                    <span style={{
                      position: "absolute",
                      left: "12px",
                      fontSize: "13px",
                      fontWeight: "600",
                      color: "#64748b"
                    }}>
                      INR
                    </span>
                    <input 
                      type="number" 
                      step="0.01"
                      min="0.01"
                      value={amount} 
                      onChange={e => {
                        const val = e.target.value;
                        setAmount(val);
                        if (billId) {
                          setAppliedAmounts(prev => ({
                            ...prev,
                            [billId]: val
                          }));
                        }
                      }} 
                      style={{ ...inputStyle, paddingLeft: "45px" }} 
                      required 
                      placeholder="e.g. 1560"
                    />
                  </div>
                  {activeFormTab === "Bill Payment" && totalOutstanding > 0 && (
                    <label style={{ display: "flex", alignItems: "center", gap: "8px", marginTop: "8px", fontSize: "13px", color: "#475569", cursor: "pointer" }}>
                      <input 
                        type="checkbox" 
                        checked={selectedBill ? parseFloat(amount) === parseFloat(selectedBill.balance_due) : false}
                        onChange={(e) => {
                          if (e.target.checked && selectedBill) {
                            setAmount(selectedBill.balance_due);
                            setAppliedAmounts(prev => ({
                              ...prev,
                              [selectedBill.id]: selectedBill.balance_due
                            }));
                          }
                        }}
                      />
                      <span>Pay full amount (₹{selectedBill ? parseFloat(selectedBill.balance_due).toLocaleString("en-IN") : parseFloat(totalOutstanding).toLocaleString("en-IN")})</span>
                    </label>
                  )}
                </div>

                {/* TDS OPTIONS (Directly below Payment Made, Vendor Advance Tab Only) */}
                {activeFormTab === "Vendor Advance" && (
                  <div style={{ marginBottom: "20px", maxWidth: "450px", animation: "fadeIn 0.2s ease-out" }}>
                    <label style={labelStyle}>TDS</label>
                    <select 
                      value={tds} 
                      onChange={e => setTds(e.target.value)} 
                      style={inputStyle}
                    >
                      <option value="">Select TDS Tax</option>
                      <option value="Commission or Brokerage [2%]">Commission or Brokerage [2%]</option>
                      <option value="Dividend [10%]">Dividend [10%]</option>
                      <option value="Other Interest than securities [10%]">Other Interest than securities [10%]</option>
                      <option value="Payment of contractors for Others [2%]">Payment of contractors for Others [2%]</option>
                      <option value="Payment of contractors HUF/Indiv [1%]">Payment of contractors HUF/Indiv [1%]</option>
                      <option value="Technical Fees (2%) [2%]">Technical Fees (2%) [2%]</option>
                    </select>
                  </div>
                )}

                {/* PAYMENT DATE */}
                <div style={{ marginBottom: "20px", maxWidth: "450px" }}>
                  <label style={labelStyle}>Payment Date *</label>
                  <input 
                    type="date" 
                    value={paymentDate} 
                    onChange={e => setPaymentDate(e.target.value)} 
                    style={inputStyle} 
                    required 
                  />
                </div>

                {/* PAYMENT MODE & PAID THROUGH (Or Deposit To) */}
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px", marginBottom: "24px" }}>
                  <div>
                    <label style={labelStyle}>Payment Mode</label>
                    <select value={paymentMode} onChange={e => setPaymentMode(e.target.value)} style={inputStyle}>
                      <option value="Cash">Cash</option>
                      <option value="Bank Transfer">Bank Transfer</option>
                      <option value="UPI">UPI</option>
                      <option value="Cheque">Cheque</option>
                      <option value="Card">Card</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>

                  {activeFormTab === "Bill Payment" ? (
                    <div>
                      <label style={labelStyle}>Paid Through *</label>
                      <select value={paidThrough} onChange={e => setPaidThrough(e.target.value)} style={inputStyle} required>
                        <option value="Cash">Cash</option>
                        <option value="Petty Cash">Petty Cash</option>
                        <option value="Undeposited Funds">Undeposited Funds</option>
                        <option value="Other Current Liability">Other Current Liability</option>
                        <option value="Employee Reimbursements">Employee Reimbursements</option>
                        <option value="TDS Payable">TDS Payable</option>
                        <option value="Equity">Equity</option>
                        <option value="Capital Stock">Capital Stock</option>
                        <option value="Distributions">Distributions</option>
                        <option value="Dividends Paid">Dividends Paid</option>
                        <option value="Drawings">Drawings</option>
                        <option value="Investments">Investments</option>
                        <option value="Opening Balance Offset">Opening Balance Offset</option>
                        <option value="Owner's Equity">Owner's Equity</option>
                        <option value="Other Current Asset">Other Current Asset</option>
                        <option value="Employee Advance">Employee Advance</option>
                        <option value="TDS Receivable">TDS Receivable</option>
                      </select>
                    </div>
                  ) : (
                    <div style={{ animation: "fadeIn 0.2s ease-out" }}>
                      <label style={labelStyle}>Paid Through *</label>
                      <select value={depositTo} onChange={e => setDepositTo(e.target.value)} style={inputStyle} required>
                        <option value="Cash">Cash</option>
                        <option value="Petty Cash">Petty Cash</option>
                        <option value="Undeposited Funds">Undeposited Funds</option>
                        <option value="Other Current Liability">Other Current Liability</option>
                        <option value="Employee Reimbursements">Employee Reimbursements</option>
                        <option value="TDS Payable">TDS Payable</option>
                        <option value="Equity">Equity</option>
                        <option value="Capital Stock">Capital Stock</option>
                        <option value="Distributions">Distributions</option>
                        <option value="Dividends Paid">Dividends Paid</option>
                        <option value="Drawings">Drawings</option>
                        <option value="Investments">Investments</option>
                        <option value="Opening Balance Offset">Opening Balance Offset</option>
                        <option value="Owner's Equity">Owner's Equity</option>
                        <option value="Other Current Asset">Other Current Asset</option>
                        <option value="Employee Advance">Employee Advance</option>
                        <option value="TDS Receivable">TDS Receivable</option>
                      </select>
                    </div>
                  )}
                </div>

                {/* DEPOSIT TO (Only for Vendor Advance Tab, placed right above Reference Number) */}
                {activeFormTab === "Vendor Advance" && (
                  <div style={{ marginBottom: "20px", maxWidth: "450px" }}>
                    <label style={labelStyle}>Deposit To *</label>
                    <select 
                      value={advanceDepositTo} 
                      onChange={e => setAdvanceDepositTo(e.target.value)} 
                      style={inputStyle} 
                      required
                    >
                      <option value="Advance Tax">Advance Tax</option>
                      <option value="Employee Advance">Employee Advance</option>
                      <option value="Prepaid Expenses">Prepaid Expenses</option>
                      <option value="TDS Receivable">TDS Receivable</option>
                    </select>
                  </div>
                )}

                {/* REFERENCE NUMBER (Notes moved to bottom, with Deposit To appearing above Reference Number in Advance Tab) */}
                <div style={{ marginBottom: "24px", maxWidth: "450px" }}>
                  <label style={labelStyle}>Reference Number</label>
                  <input 
                    type="text" 
                    value={referenceNumber} 
                    onChange={e => setReferenceNumber(e.target.value)} 
                    style={inputStyle} 
                    placeholder="e.g. Txn ID, Check #"
                  />
                </div>

                {/* OUTSTANDING BILLS LIST (Only for Bill Payment Tab) */}
                {activeFormTab === "Bill Payment" && (
                  <div style={{ marginTop: "32px", marginBottom: "32px", animation: "fadeIn 0.3s ease-out" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
                      <h3 style={{ fontSize: "15px", fontWeight: "700", color: "#1c2434", margin: 0 }}>Outstanding Bills</h3>
                      <button 
                        type="button" 
                        onClick={() => {
                          setAppliedAmounts({});
                          setAmount("");
                        }}
                        style={{
                          background: "none",
                          border: "none",
                          color: "#006ee6",
                          fontSize: "12px",
                          fontWeight: "600",
                          cursor: "pointer",
                          textDecoration: "none"
                        }}
                      >
                        Clear Applied Amount
                      </button>
                    </div>
                    
                    {availableBills.length === 0 ? (
                      <div style={{ padding: "20px", background: "#f8fafc", border: "1px dashed #eaecf0", borderRadius: "8px", textAlign: "center", color: "#64748b", fontSize: "13px" }}>
                        No unpaid bills available for this vendor.
                      </div>
                    ) : (
                      <div style={{ border: "1px solid #eaecf0", borderRadius: "8px", overflow: "hidden", background: "#ffffff" }}>
                        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px", textAlign: "left" }}>
                          <thead>
                            <tr style={{ background: "#f9fafb", borderBottom: "1px solid #eaecf0", fontSize: "12px", fontWeight: "600", color: "#64748b" }}>
                              <th style={{ padding: "12px 16px" }}>Date</th>
                              <th style={{ padding: "12px 16px" }}>Bill#</th>
                              <th style={{ padding: "12px 16px" }}>PO#</th>
                              <th style={{ padding: "12px 16px", textAlign: "right" }}>Bill Amount</th>
                              <th style={{ padding: "12px 16px", textAlign: "right" }}>Amount Due</th>
                              <th style={{ padding: "12px 16px", textAlign: "center", width: "160px" }}>Payment Made on ⓘ</th>
                              <th style={{ padding: "12px 16px", textAlign: "right", width: "160px" }}>Payment</th>
                            </tr>
                          </thead>
                          <tbody>
                            {availableBills.map((b) => {
                              const isCurrentSelected = String(billId) === String(b.id);
                              const appliedVal = appliedAmounts[b.id] !== undefined ? appliedAmounts[b.id] : "";
                              
                              return (
                                <tr 
                                  key={b.id} 
                                  style={{ 
                                    borderBottom: "1px solid #eaecf0", 
                                    background: isCurrentSelected ? "#f0f6ff" : "transparent"
                                  }}
                                >
                                  {/* Date Column */}
                                  <td style={{ padding: "14px 16px" }}>
                                    <div style={{ color: "#1e293b", fontWeight: "500" }}>
                                      {new Date(b.bill_date).toLocaleDateString("en-GB")}
                                    </div>
                                    <div style={{ color: "#64748b", fontSize: "11px", marginTop: "2px" }}>
                                      Due Date: {new Date(b.due_date || b.bill_date).toLocaleDateString("en-GB")}
                                    </div>
                                  </td>

                                  {/* Bill# Column */}
                                  <td style={{ padding: "14px 16px", color: "#1e293b", fontWeight: "500" }}>
                                    {b.bill_number}
                                  </td>

                                  {/* PO# Column */}
                                  <td style={{ padding: "14px 16px", color: "#64748b" }}>
                                    {b.po_number || "—"}
                                  </td>

                                  {/* Bill Amount */}
                                  <td style={{ padding: "14px 16px", textAlign: "right", color: "#1e293b" }}>
                                    {parseFloat(b.total_amount || b.total || 0).toLocaleString("en-IN")}
                                  </td>

                                  {/* Amount Due */}
                                  <td style={{ padding: "14px 16px", textAlign: "right", color: "#1e293b" }}>
                                    {parseFloat(b.balance_due || 0).toLocaleString("en-IN")}
                                  </td>

                                  {/* Payment Made on Column */}
                                  <td style={{ padding: "10px 16px", textAlign: "center" }}>
                                    <input 
                                      type="date"
                                      value={paymentDate}
                                      onChange={(e) => setPaymentDate(e.target.value)}
                                      style={{
                                        padding: "6px 8px",
                                        borderRadius: "4px",
                                        border: "1px solid #d0d5dd",
                                        fontSize: "12px",
                                        color: "#344054",
                                        width: "100%",
                                        boxSizing: "border-box"
                                      }}
                                    />
                                  </td>

                                  {/* Payment Input Column */}
                                  <td style={{ padding: "10px 16px", textAlign: "right" }}>
                                    <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: "4px" }}>
                                      <input 
                                        type="number" 
                                        step="0.01"
                                        max={b.balance_due}
                                        value={appliedVal}
                                        onChange={(e) => {
                                          const val = e.target.value;
                                          setAppliedAmounts(prev => ({
                                            ...prev,
                                            [b.id]: val
                                          }));
                                          setBillId(b.id.toString());
                                          setAmount(val);
                                        }}
                                        placeholder="0"
                                        style={{
                                          width: "100%",
                                          padding: "6px 8px",
                                          borderRadius: "4px",
                                          border: "1px solid #d0d5dd",
                                          textAlign: "right",
                                          boxSizing: "border-box",
                                          background: "#ffffff",
                                          outline: "none",
                                          fontSize: "13px"
                                        }}
                                      />
                                      <button 
                                        type="button"
                                        onClick={() => {
                                          setAppliedAmounts(prev => ({
                                            ...prev,
                                            [b.id]: b.balance_due
                                          }));
                                          setBillId(b.id.toString());
                                          setAmount(b.balance_due);
                                        }}
                                        style={{
                                          background: "none",
                                          border: "none",
                                          color: "#006ee6",
                                          fontSize: "11px",
                                          cursor: "pointer",
                                          padding: 0
                                        }}
                                      >
                                        Pay in Full
                                      </button>
                                    </div>
                                  </td>
                                </tr>
                              );
                            })}

                            {/* Total Row */}
                            <tr style={{ background: "#f9fafb", fontWeight: "600", borderTop: "1px solid #eaecf0" }}>
                              <td colSpan={6} style={{ padding: "12px 16px", textAlign: "right", color: "#475569" }}>
                                Total :
                              </td>
                              <td style={{ padding: "12px 16px", textAlign: "right", color: "#1e293b" }}>
                                {parseFloat(amountUsed || 0).toFixed(2)}
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                    )}
                  </div>
                )}

                {/* CALCULATIONS & SUMMARY BLOCK (Only for Bill Payment Tab) */}
                {activeFormTab === "Bill Payment" && (
                  <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: "32px", animation: "fadeIn 0.3s ease-out" }}>
                    <div style={{
                      width: "100%",
                      maxWidth: "380px",
                      background: "#fffaf0",
                      border: "1px solid #fed7aa",
                      borderRadius: "8px",
                      padding: "20px",
                      boxShadow: "0 1px 2px rgba(0,0,0,0.02)"
                    }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px" }}>
                        <span style={{ color: "#475569", fontWeight: "500" }}>Amount Paid:</span>
                        <span style={{ color: "#1e293b", fontWeight: "600" }}>
                          {amountPaid.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </span>
                      </div>
                      
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px" }}>
                        <span style={{ color: "#475569", fontWeight: "500" }}>Amount used for Payments:</span>
                        <span style={{ color: "#1e293b", fontWeight: "600" }}>
                          {amountUsed.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </span>
                      </div>

                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px" }}>
                        <span style={{ color: "#475569", fontWeight: "500" }}>Amount Refunded:</span>
                        <span style={{ color: "#1e293b", fontWeight: "600" }}>
                          {amountRefunded.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </span>
                      </div>

                      <div style={{ display: "flex", justifyContent: "space-between", borderTop: "1px dashed #fed7aa", paddingTop: "12px", fontSize: "13px", fontWeight: "700" }}>
                        <span style={{ color: "#c2410c", display: "flex", alignItems: "center", gap: "6px" }}>
                          <span>⚠️</span> Amount in Excess:
                        </span>
                        <span style={{ color: "#c2410c" }}>
                          ₹ {amountInExcess.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </span>
                      </div>
                    </div>
                  </div>
                )}

                {/* NOTES AREA (Full Width at the bottom) */}
                <div style={{ marginBottom: "32px" }}>
                  <label style={{ ...labelStyle, marginBottom: "8px", fontWeight: "500", fontSize: "13px", color: "#1e293b" }}>
                    Notes (Internal use. Not visible to vendor)
                  </label>
                  <textarea 
                    value={notes} 
                    onChange={e => setNotes(e.target.value)} 
                    rows={4} 
                    style={{ ...inputStyle, resize: "vertical", width: "100%" }}
                    placeholder="Enter any internal notes about this payment..."
                  />
                </div>

                {/* BOTTOM ACTIONS */}
                <div style={{ display: "flex", gap: "12px", borderTop: "1px solid #eaecf0", paddingTop: "24px" }}>
                  <button 
                    type="button" 
                    onClick={(e) => handleSave(null, "Draft")}
                    disabled={loading} 
                    style={{
                      padding: "10px 18px",
                      background: "#ffffff",
                      color: "#344054",
                      border: "1px solid #d0d5dd",
                      borderRadius: "6px",
                      fontWeight: "600",
                      fontSize: "13px",
                      cursor: loading ? "not-allowed" : "pointer"
                    }}
                  >
                    Save as Draft
                  </button>
                  <button 
                    type="submit" 
                    disabled={loading} 
                    style={{
                      padding: "10px 18px",
                      background: "#006ee6",
                      color: "#ffffff",
                      border: "none",
                      borderRadius: "6px",
                      fontWeight: "600",
                      fontSize: "13px",
                      cursor: loading ? "not-allowed" : "pointer"
                    }}
                  >
                    {loading ? "Saving..." : "Save as Paid"}
                  </button>
                  <button type="button" onClick={() => navigate("/payments-made")} style={secondaryBtn}>Cancel</button>
                </div>

              </div>
            ) : (
              // Prompt to select vendor
              <div style={{ padding: "48px", border: "2px dashed #eaecf0", borderRadius: "8px", textAlign: "center", color: "#64748b", fontSize: "14px" }}>
                <div style={{ fontSize: "36px", marginBottom: "12px" }}>👤</div>
                <h4 style={{ margin: "0 0 6px 0", color: "#1e293b", fontWeight: "600" }}>Select a Vendor</h4>
                <p style={{ margin: 0 }}>Please choose a vendor above to view their details, load outstanding bills, and input payment details.</p>
              </div>
            )}

          </form>
        </div>

      </div>

      <style dangerouslySetInnerHTML={{ __html: `
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(4px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes slideDown {
          from { opacity: 0; height: 0; padding-top: 0; padding-bottom: 0; overflow: hidden; }
          to { opacity: 1; height: auto; }
        }
      `}} />
    </div>
  );
}

const inputStyle = { 
  width: "100%", 
  padding: "10px 12px", 
  borderRadius: "6px", 
  border: "1px solid #d0d5dd", 
  boxSizing: "border-box", 
  fontSize: "13px", 
  color: "#344054",
  outline: "none",
  background: "#ffffff",
  transition: "border-color 0.15s ease"
};

const labelStyle = { 
  display: "block", 
  marginBottom: "4px", 
  fontWeight: "600", 
  fontSize: "13px", 
  color: "#344054" 
};

const secondaryBtn = { 
  padding: "10px 18px", 
  background: "#ffffff", 
  color: "#344054", 
  border: "1px solid #d0d5dd", 
  borderRadius: "6px", 
  cursor: "pointer",
  fontWeight: "600",
  fontSize: "13px"
};

export default AddPaymentMade;
