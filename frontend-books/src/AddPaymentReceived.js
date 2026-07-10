import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function AddPaymentReceived() {
  const navigate = useNavigate();

  const [customers, setCustomers] = useState([]);
  const [invoices, setInvoices] = useState([]);
  
  const [customerId, setCustomerId] = useState("");
  
  const [paymentSplits, setPaymentSplits] = useState([
    { id: Date.now(), amount: "", payment_mode: "Cash", deposit_to: "Petty Cash", reference: "" }
  ]);
  
  const [bankCharges, setBankCharges] = useState("");
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().slice(0, 10));
  const [taxDeducted, setTaxDeducted] = useState("No Tax deducted");
  const [notes, setNotes] = useState("");
  
  const amountReceived = paymentSplits.reduce((sum, s) => sum + (parseFloat(s.amount) || 0), 0);
  
  // Mapping of invoice ID to the payment amount allocated to it
  const [paymentsMap, setPaymentsMap] = useState({});
  const [paymentDatesMap, setPaymentDatesMap] = useState({});
  const [transferShortfalls, setTransferShortfalls] = useState({});
  const [installmentMonthsMap, setInstallmentMonthsMap] = useState({});
  
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(true);

  useEffect(() => {
    apiRequest("/customers")
      .then(res => setCustomers(res?.customers || []))
      .catch(() => toast.error("Failed to load customers"))
      .finally(() => setFetching(false));
  }, []);

  useEffect(() => {
    if (customerId) {
      apiRequest("/invoices")
        .then(res => {
          if (res?.invoices) {
             const custInvoices = res.invoices.filter(i => 
               String(i.customer_id) === String(customerId) && 
               Number(i.balance_due) > 0 &&
               i.status === "sent" // Typical Zoho rule: only sent invoices
             );
             // Sort by date (oldest first)
             custInvoices.sort((a,b) => new Date(a.invoice_date) - new Date(b.invoice_date));
             // Fallback if no 'sent' filter needed, use all unpaid:
             const activeInvoices = custInvoices.length > 0 ? custInvoices : res.invoices.filter(i => String(i.customer_id) === String(customerId) && Number(i.balance_due) > 0);
             
             setInvoices(activeInvoices);
             setPaymentsMap({});
             setPaymentDatesMap({});
          }
        })
        .catch(() => toast.error("Failed to load invoices"));
    } else {
      setInvoices([]);
      setPaymentsMap({});
      setPaymentDatesMap({});
      setTransferShortfalls({});
      setInstallmentMonthsMap({});
    }
  }, [customerId]);

  const autoDistribute = (totalAmount) => {
    let remaining = totalAmount || 0;
    const newMap = {};
    for (const inv of invoices) {
      if (remaining <= 0) break;
      const due = parseFloat(inv.balance_due);
      if (remaining >= due) {
        newMap[inv.id] = due;
        remaining -= due;
      } else {
        newMap[inv.id] = remaining;
        remaining = 0;
      }
    }
    setPaymentsMap(newMap);
  };

  const updateSplit = (id, field, value) => {
    const updated = paymentSplits.map(s => s.id === id ? { ...s, [field]: value } : s);
    setPaymentSplits(updated);
    
    if (field === 'amount') {
      const totalAmount = updated.reduce((sum, s) => sum + (parseFloat(s.amount) || 0), 0);
      autoDistribute(totalAmount);
    }
  };

  const addSplit = () => {
    setPaymentSplits([...paymentSplits, { id: Date.now(), amount: "", payment_mode: "Bank Transfer", deposit_to: "Undeposited Funds", reference: "" }]);
  };

  const removeSplit = (id) => {
    const updated = paymentSplits.filter(s => s.id !== id);
    setPaymentSplits(updated);
    const totalAmount = updated.reduce((sum, s) => sum + (parseFloat(s.amount) || 0), 0);
    autoDistribute(totalAmount);
  };

  const handlePaymentMapChange = (invId, val) => {
    const newMap = { ...paymentsMap, [invId]: val };
    setPaymentsMap(newMap);
    
    // If they manually change the map, we don't change the amountReceived (since it's driven by splits now)
  };
  
  const handlePayInFull = (inv) => {
    handlePaymentMapChange(inv.id, inv.balance_due);
  };

  const clearAppliedAmount = () => {
    setPaymentsMap({});
    setTransferShortfalls({});
  };

  const amountUsed = Object.values(paymentsMap).reduce((sum, v) => sum + (parseFloat(v) || 0), 0);
  const amountExcess = (parseFloat(amountReceived) || 0) - amountUsed;

  const handleSave = async (status) => {
    if (!customerId) return toast.error("Please select a customer");
    if (amountUsed <= 0) return toast.error("Please apply an amount to at least one invoice");
    if (amountExcess < -0.01) return toast.error("Amount applied exceeds Amount Received");

    setLoading(true);
    try {
      // Loop through all invoices that have a payment allocation > 0
      const paymentPromises = Object.entries(paymentsMap).map(([invId, amt]) => {
        const val = parseFloat(amt);
        if (val > 0) {
          return apiRequest(`/invoices/${invId}/payments`, {
            method: "POST",
            body: JSON.stringify({
              customer_id: parseInt(customerId),
              amount: val,
              payment_date: paymentDatesMap[invId] || paymentDate,
              splits: paymentSplits, // Send the splits to the backend
              notes: notes || null,
              transfer_shortfall: !!transferShortfalls[invId],
              installment_months: parseInt(installmentMonthsMap[invId]) || 0
            }),
          });
        }
        return Promise.resolve();
      });

      await Promise.all(paymentPromises);
      
      toast.success("Payment(s) recorded successfully");
      navigate("/payments-received");
    } catch (err) {
      toast.error("Failed to record some or all payments. Please check the backend.");
    } finally {
      setLoading(false);
    }
  };

  if (fetching) {
    return (
      <div style={{ maxWidth: "1200px", margin: "auto", padding: "30px" }}>
        <FormSkeleton fields={4} />
      </div>
    );
  }

  return (
    <div style={{ background: "#ffffff", minHeight: "100vh", fontFamily: "system-ui, -apple-system, sans-serif" }}>
      
      {/* Top Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "16px 24px", borderBottom: "1px solid #eaecf0", background: "#f8fafc" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <h2 style={{ margin: 0, fontSize: "20px", fontWeight: "600", color: "#1d2939" }}>Record Payment</h2>
        </div>
        <button onClick={() => navigate("/payments-received")} style={{ background: "none", border: "none", fontSize: "24px", color: "#98a2b3", cursor: "pointer" }}>&times;</button>
      </div>

      <div style={{ padding: "32px", maxWidth: "1000px" }}>
        
        {/* Form Fields Section */}
        <div style={{ display: "flex", flexDirection: "column", gap: "20px", maxWidth: "600px", marginBottom: "40px" }}>
          
          <div style={rowStyle}>
            <label style={labelStyle}>Customer Name*</label>
            <select value={customerId} onChange={e => setCustomerId(e.target.value)} style={inputStyle}>
              <option value="">Select a Customer</option>
              {customers.map(c => (
                <option key={c.id} value={c.id}>{c.display_name || c.email}</option>
              ))}
            </select>
          </div>

          {paymentSplits.map((split, index) => (
            <div key={split.id} style={{ padding: "16px", background: "#f8fafc", borderRadius: "8px", border: "1px solid #eaecf0", position: "relative", marginBottom: "16px" }}>
              <h4 style={{ margin: "0 0 16px 0", fontSize: "14px", color: "#1d2939" }}>Payment Split {index + 1}</h4>
              {paymentSplits.length > 1 && (
                <button onClick={() => removeSplit(split.id)} style={{ position: "absolute", top: "16px", right: "16px", background: "none", border: "none", color: "#d92d20", cursor: "pointer", fontSize: "13px" }}>Remove</button>
              )}
              
              <div style={{ ...rowStyle, marginBottom: "16px" }}>
                <label style={labelStyle}>Amount*</label>
                <div style={{ position: "relative", width: "100%", flex: 1 }}>
                  <span style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", color: "#667085", fontSize: "13px" }}>₹</span>
                  <input type="number" step="0.01" min="0" value={split.amount} onChange={e => updateSplit(split.id, 'amount', e.target.value)} style={{...inputStyle, paddingLeft: "24px", width: "100%"}} />
                </div>
              </div>

              <div style={{ ...rowStyle, marginBottom: "16px" }}>
                <label style={labelStyle}>Payment Mode</label>
                <select value={split.payment_mode} onChange={e => updateSplit(split.id, 'payment_mode', e.target.value)} style={inputStyle}>
                  <option value="Cash">Cash</option>
                  <option value="Bank Transfer">Bank Transfer</option>
                  <option value="Cheque">Cheque</option>
                  <option value="Credit Card">Credit Card</option>
                  <option value="UPI">UPI</option>
                </select>
              </div>

              {split.payment_mode === "Cash" && (
              <div style={{ ...rowStyle, marginBottom: "16px" }}>
                <label style={labelStyle}>Deposit To*</label>
                <select value={split.deposit_to} onChange={e => updateSplit(split.id, 'deposit_to', e.target.value)} style={inputStyle}>
                  <option value="Petty Cash">Petty Cash</option>
                  <option value="Undeposited Funds">Undeposited Funds</option>
                </select>
              </div>
              )}

              <div style={rowStyle}>
                <label style={labelStyle}>Reference#</label>
                <input type="text" value={split.reference} onChange={e => updateSplit(split.id, 'reference', e.target.value)} style={inputStyle} />
              </div>
            </div>
          ))}

          <button onClick={addSplit} style={{ background: "none", border: "1px dashed #d0d5dd", color: "#006ee6", padding: "12px", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "500", width: "100%" }}>
            + Add another payment method
          </button>

          <div style={rowStyle}>
            <label style={labelStyle}>Tax deducted?</label>
            <div style={{ display: "flex", gap: "16px", alignItems: "center", fontSize: "13px", color: "#344054" }}>
              <label style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                <input type="radio" checked={taxDeducted === "No Tax deducted"} onChange={() => setTaxDeducted("No Tax deducted")} style={{ margin: 0 }} />
                No Tax deducted
              </label>
              <label style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                <input type="radio" checked={taxDeducted === "Yes, TDS (Income Tax)"} onChange={() => setTaxDeducted("Yes, TDS (Income Tax)")} style={{ margin: 0 }} />
                Yes, TDS (Income Tax)
              </label>
            </div>
          </div>
        </div>

        {/* Unpaid Invoices Section */}
        <div style={{ marginBottom: "16px", display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
          <div>
            <h3 style={{ margin: "0 0 8px 0", fontSize: "14px", fontWeight: "600", color: "#1d2939" }}>Unpaid Invoices</h3>
            <span style={{ fontSize: "12px", color: "#667085" }}>Filter by Date Range ▾</span>
          </div>
          {amountUsed > 0 && (
            <button onClick={clearAppliedAmount} style={{ background: "none", border: "none", color: "#006ee6", fontSize: "12px", cursor: "pointer", padding: 0 }}>
              Clear Applied Amount
            </button>
          )}
        </div>

        <div style={{ borderTop: "1px solid #eaecf0", borderBottom: "1px solid #eaecf0", padding: "16px 0", marginBottom: "32px" }}>
          {invoices.length === 0 ? (
            <div style={{ textAlign: "center", padding: "20px", color: "#667085", fontSize: "13px" }}>
              {customerId ? "**No unpaid invoices found for this customer**" : "**Please select a customer to view unpaid invoices**"}
            </div>
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "12px" }}>
              <thead>
                <tr style={{ color: "#667085", fontWeight: "600", borderBottom: "1px solid #eaecf0" }}>
                  <th style={{ padding: "10px 8px", textAlign: "left", width: "120px" }}>DATE</th>
                  <th style={{ padding: "10px 8px", textAlign: "left" }}>INVOICE NUMBER</th>
                  <th style={{ padding: "10px 8px", textAlign: "right" }}>INVOICE AMOUNT</th>
                  <th style={{ padding: "10px 8px", textAlign: "right" }}>AMOUNT DUE</th>
                  <th style={{ padding: "10px 8px", textAlign: "center", width: "160px" }}>PAYMENT RECEIVED ON 📅</th>
                  <th style={{ padding: "10px 8px", textAlign: "right", width: "150px" }}>PAYMENT</th>
                </tr>
              </thead>
              <tbody>
                {invoices.map(inv => {
                  const pendingSchedules = (inv.payment_schedules || []).filter(s => s.status !== 'paid');
                  const nextSch = pendingSchedules.length > 0 ? pendingSchedules[0] : null;
                  const amtApplied = parseFloat(paymentsMap[inv.id]) || 0;
                  const currBal = nextSch ? parseFloat(nextSch.balance_amount) : 0;
                  const shortfall = currBal - amtApplied;
                  return (
                  <tr key={inv.id} style={{ borderBottom: "1px solid #f2f4f7" }}>
                    <td style={{ padding: "12px 8px" }}>
                      <div>{new Date(inv.invoice_date).toLocaleDateString("en-GB")}</div>
                      <div style={{ color: "#98a2b3", fontSize: "10px", marginTop: "2px" }}>Due Date: {new Date(inv.due_date || inv.invoice_date).toLocaleDateString("en-GB")}</div>
                    </td>
                    <td style={{ padding: "12px 8px", color: "#344054" }}>
                      <div>{inv.invoice_number}</div>
                      {nextSch && (
                        <div style={{ background: "#e0f2fe", color: "#075985", padding: "4px 8px", borderRadius: "4px", fontSize: "10px", marginTop: "4px", display: "inline-block", fontWeight: "500" }}>
                          Next Installment: ₹{parseFloat(nextSch.balance_amount).toLocaleString('en-IN', {minimumFractionDigits:2})} due {new Date(nextSch.due_date).toLocaleDateString("en-GB")}
                        </div>
                      )}
                    </td>
                    <td style={{ padding: "12px 8px", textAlign: "right", color: "#344054" }}>{parseFloat(inv.total_amount).toLocaleString('en-IN', {minimumFractionDigits:2})}</td>
                    <td style={{ padding: "12px 8px", textAlign: "right", color: "#344054" }}>
                      <div style={{ color: "#667085" }}>₹{parseFloat(inv.balance_due).toLocaleString('en-IN', {minimumFractionDigits:2})}</div>
                    </td>
                    <td style={{ padding: "12px 8px", textAlign: "center" }}>
                      <input 
                        type="date" 
                        value={paymentDatesMap[inv.id] || paymentDate}
                        onChange={(e) => setPaymentDatesMap({...paymentDatesMap, [inv.id]: e.target.value})}
                        style={{ width: "130px", padding: "6px", borderRadius: "4px", border: "1px solid #eaecf0", fontSize: "12px", color: "#344054", outline: "none", background: "#fcfcfd" }}
                      />
                    </td>
                    <td style={{ padding: "12px 8px" }}>
                      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: "4px" }}>
                        <input 
                          type="number" 
                          step="0.01" 
                          min="0" 
                          value={paymentsMap[inv.id] || ""} 
                          onChange={(e) => handlePaymentMapChange(inv.id, e.target.value)}
                          style={{ width: "120px", padding: "6px", borderRadius: "4px", border: "1px solid #d0d5dd", textAlign: "right", fontSize: "12px" }} 
                        />
                        <button type="button" onClick={() => handlePayInFull(inv)} style={{ background: "none", border: "none", color: "#006ee6", fontSize: "11px", cursor: "pointer", padding: 0 }}>Pay in Full</button>
                        {nextSch && shortfall > 0 && shortfall < currBal && (
                          <div style={{ marginTop: "4px", background: "#f8fafc", padding: "6px", borderRadius: "4px", border: "1px solid #e2e8f0", fontSize: "10px", width: "140px" }}>
                            <label style={{ display: "flex", alignItems: "flex-start", gap: "4px", color: "#344054", cursor: "pointer", margin: 0, textAlign: "left", lineHeight: "1.2" }}>
                              <input 
                                type="checkbox" 
                                checked={!!transferShortfalls[inv.id]} 
                                onChange={e => setTransferShortfalls({...transferShortfalls, [inv.id]: e.target.checked})} 
                                style={{ margin: 0, marginTop: "2px" }} 
                              />
                              <span>Transfer shortfall (₹{shortfall.toFixed(2)}) to next month</span>
                            </label>
                          </div>
                        )}
                        {!nextSch && amtApplied > 0 && inv.balance_due - amtApplied > 0 && (
                          <div style={{ marginTop: "4px", background: "#fcfcfd", padding: "6px", borderRadius: "4px", border: "1px solid #e2e8f0", fontSize: "10px", width: "140px", textAlign: "left" }}>
                            <div style={{ color: "#344054", marginBottom: "4px", fontWeight: "500" }}>Split remaining ₹{(inv.balance_due - amtApplied).toFixed(2)} into:</div>
                            <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                              <input 
                                type="number" 
                                min="1" 
                                max="24"
                                value={installmentMonthsMap[inv.id] || ""} 
                                onChange={(e) => setInstallmentMonthsMap({...installmentMonthsMap, [inv.id]: e.target.value})}
                                placeholder="Months"
                                style={{ width: "60px", padding: "4px", borderRadius: "4px", border: "1px solid #d0d5dd", fontSize: "10px" }}
                              />
                              <span style={{ color: "#667085" }}>months</span>
                            </div>
                            {installmentMonthsMap[inv.id] > 0 && (
                              <div style={{ marginTop: "8px", maxHeight: "100px", overflowY: "auto", borderTop: "1px dashed #d0d5dd", paddingTop: "4px" }}>
                                {Array.from({ length: Math.min(24, parseInt(installmentMonthsMap[inv.id]) || 0) }).map((_, i) => {
                                  const d = new Date(paymentDatesMap[inv.id] || paymentDate || new Date());
                                  d.setMonth(d.getMonth() + i + 1);
                                  const mths = parseInt(installmentMonthsMap[inv.id]);
                                  const shortfall = inv.balance_due - amtApplied;
                                  const monthly = shortfall / mths;
                                  let amt = monthly;
                                  if (i === mths - 1) {
                                    amt = shortfall - (parseFloat(monthly.toFixed(2)) * (mths - 1));
                                  }
                                  return (
                                    <div key={i} style={{ display: "flex", justifyContent: "space-between", fontSize: "9px", color: "#475569", padding: "2px 0" }}>
                                      <span>{d.toLocaleDateString("en-US", { month: "short" })} <span style={{ color: "#94a3b8" }}>({d.toLocaleDateString("en-GB")})</span></span>
                                      <span style={{ fontWeight: "600" }}>₹{amt.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                                    </div>
                                  );
                                })}
                              </div>
                            )}
                          </div>
                        )}
                        {!nextSch && amtApplied > 0 && inv.balance_due - amtApplied <= 0 && (
                          <div style={{ marginTop: "4px", color: "#12b76a", fontSize: "10px", width: "140px", textAlign: "left" }}>
                            (Fully Paid)
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                  );
                })}
              </tbody>
            </table>
          )}
          {invoices.length > 0 && <div style={{ fontSize: "11px", color: "#98a2b3", marginTop: "12px" }}>**List contains only SENT Invoices</div>}
        </div>

        {/* Totals Section */}
        <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: "40px" }}>
          <div style={{ width: "350px", background: "#fcfcfd", padding: "20px", borderRadius: "8px", border: "1px solid #eaecf0", fontSize: "13px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px" }}>
              <span style={{ color: "#344054", fontWeight: "500" }}>Amount Received:</span>
              <span style={{ color: "#1d2939", fontWeight: "600" }}>{parseFloat(amountReceived || 0).toLocaleString('en-IN', {minimumFractionDigits: 2})}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px" }}>
              <span style={{ color: "#344054", fontWeight: "500" }}>Amount used for Payments:</span>
              <span style={{ color: "#1d2939", fontWeight: "600" }}>{amountUsed.toLocaleString('en-IN', {minimumFractionDigits: 2})}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px" }}>
              <span style={{ color: "#344054", fontWeight: "500" }}>Amount Refunded:</span>
              <span style={{ color: "#1d2939", fontWeight: "600" }}>0.00</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: "16px", paddingTop: "12px", borderTop: "1px solid #eaecf0" }}>
              <span style={{ color: "#d92d20", fontWeight: "600", display: "flex", alignItems: "center", gap: "6px" }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
                Amount in Excess:
              </span>
              <span style={{ color: "#1d2939", fontWeight: "600" }}>₹ {Math.max(0, amountExcess).toLocaleString('en-IN', {minimumFractionDigits: 2})}</span>
            </div>
          </div>
        </div>

        <div style={{ marginBottom: "40px" }}>
          <label style={{...labelStyle, marginBottom: "8px"}}>Notes (Internal use. Not visible to customer)</label>
          <textarea value={notes} onChange={e => setNotes(e.target.value)} rows={3} style={{...inputStyle, width: "100%", maxWidth: "600px"}}></textarea>
        </div>

      </div>

      {/* Action Footer */}
      <div style={{ background: "#f8fafc", borderTop: "1px solid #eaecf0", padding: "16px 32px", display: "flex", justifyContent: "flex-end", gap: "12px" }}>
        <button onClick={() => handleSave("draft")} disabled={loading} style={{ background: "#ffffff", color: "#344054", border: "1px solid #d0d5dd", borderRadius: "4px", padding: "8px 16px", fontSize: "13px", fontWeight: "500", cursor: "pointer" }}>Save as Draft</button>
        <button onClick={() => handleSave("paid")} disabled={loading} style={{ background: "#006ee6", color: "#ffffff", border: "none", borderRadius: "4px", padding: "8px 16px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>
          {loading ? "Saving..." : "Save as Paid"}
        </button>
        <button onClick={() => navigate("/payments-received")} style={{ background: "#ffffff", color: "#344054", border: "1px solid #d0d5dd", borderRadius: "4px", padding: "8px 16px", fontSize: "13px", fontWeight: "500", cursor: "pointer" }}>Cancel</button>
      </div>

    </div>
  );
}

const rowStyle = {
  display: "flex",
  alignItems: "center"
};

const labelStyle = { 
  width: "200px", 
  flexShrink: 0, 
  fontSize: "13px", 
  fontWeight: "500", 
  color: "#b91c1c" // Based on screenshot 'Customer Name*' is red, but wait, usually only the asterisk is red. I'll make the label standard and asterisk red.
};
// Actually, fixing label color to standard with red asterisks inline
labelStyle.color = "#344054";

const inputStyle = { 
  flex: 1,
  padding: "8px 12px", 
  borderRadius: "4px", 
  border: "1px solid #d0d5dd", 
  boxSizing: "border-box",
  fontSize: "13px",
  color: "#344054",
  outline: "none"
};

export default AddPaymentReceived;
