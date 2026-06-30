import React, { useEffect, useState, useCallback } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { apiRequest } from "./api";
import { DetailSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function PaymentDetail() {
  const { id } = useParams();
  const navigate = useNavigate();

  // Active payment details
  const [payment, setPayment] = useState(null);
  const [customer, setCustomer] = useState(null);
  const [fetching, setFetching] = useState(true);
  const [orgInfo, setOrgInfo] = useState({ name: "", address: "", email: "", phone: "", logo: "" });

  // Master list state
  const [paymentsList, setPaymentsList] = useState([]);
  const [customersList, setCustomersList] = useState([]);
  const [listLoading, setListLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [statusDropdownOpen, setStatusDropdownOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState("all");

  const fetchMasterList = useCallback(async () => {
    try {
      setListLoading(true);
      const [payRes, customersRes] = await Promise.all([
        apiRequest("/payments"),
        apiRequest("/customers")
      ]);
      setPaymentsList(Array.isArray(payRes?.payments) ? payRes.payments : []);
      setCustomersList(Array.isArray(customersRes?.customers) ? customersRes.customers : []);
    } catch (err) {
      console.error("Failed to load list data", err);
    } finally {
      setListLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchMasterList();
  }, [fetchMasterList]);

  useEffect(() => {
    const fetchPaymentDetails = async () => {
      try {
        setFetching(true);
        const res = await apiRequest(`/payments/${id}`);
        if (!res?.payment) {
          toast.error("Payment not found");
          navigate("/payments-received");
          return;
        }
        setPayment(res.payment);

        if (res.payment.customer_id) {
          const custRes = await apiRequest(`/customers/${res.payment.customer_id}`);
          if (custRes?.customer) setCustomer(custRes.customer);
        }

        const orgRes = await apiRequest("/organization-settings");
        if (orgRes?.settings) {
          setOrgInfo({
            name: orgRes.settings.organization_name || "",
            address: orgRes.settings.address || "",
            email: orgRes.settings.organization_email || "",
            phone: orgRes.settings.organization_phone || "",
            logo: orgRes.settings.logo_url || ""
          });
        }
      } catch (err) {
        toast.error("Failed to load Payment details");
      } finally {
        setFetching(false);
      }
    };
    fetchPaymentDetails();
  }, [id, navigate]);

  const getCustomerName = (customerId) => {
    if (!customerId) return "—";
    const cust = customersList.find((c) => c.id === customerId);
    return cust ? cust.display_name || [cust.first_name, cust.last_name].filter(Boolean).join(" ") || cust.email : "—";
  };

  const handleDelete = async () => {
    if (!window.confirm("Delete this payment?")) return;
    try {
      await apiRequest(`/payments/${id}`, { method: "DELETE" });
      toast.success("Payment deleted");
      navigate("/payments-received");
    } catch (err) {
      toast.error("Delete failed");
    }
  };

  const cleanPhone = (phoneNum) => {
    if (!phoneNum) return "";
    const cleaned = phoneNum.toString().replace(/\D/g, "");
    if (cleaned.length === 10) {
      return "91" + cleaned;
    }
    return cleaned;
  };

  const getCondensedMessage = () => {
    const customerName = customer?.display_name || "Customer";
    const payNumber = payment?.id ? `PR-${payment.id.toString().padStart(5, '0')}` : "";
    const totalAmt = parseFloat(payment?.amount || 0).toFixed(2);
    const businessName = orgInfo?.name || "our business";
    return `Dear ${customerName}, we have received your payment of ₹${totalAmt} (Receipt: ${payNumber}). Thank you! Regards, ${businessName}.`;
  };

  const sendWhatsApp = (e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    const phoneVal = customer?.mobile || customer?.phone || customer?.work_phone;
    const cleanedPhone = cleanPhone(phoneVal);
    if (!cleanedPhone) {
      toast.error("Phone number not available");
      return;
    }
    const message = getCondensedMessage();
    window.location.href = `whatsapp://send?phone=${cleanedPhone}&text=${encodeURIComponent(message)}`;
    
    setTimeout(() => {
      if (document.hasFocus()) {
        window.open(`https://wa.me/${cleanedPhone}?text=${encodeURIComponent(message)}`, "_blank");
      }
    }, 1500);
  };

  const sendSMS = (e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    const phoneVal = customer?.mobile || customer?.phone || customer?.work_phone;
    const cleanedPhone = cleanPhone(phoneVal);
    if (!cleanedPhone) {
      toast.error("Phone number not available");
      return;
    }
    const message = getCondensedMessage();
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const separator = isIOS ? "&" : "?";
    window.location.href = `sms:${cleanedPhone}${separator}body=${encodeURIComponent(message)}`;
  };

  const sendEmail = (e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    if (!customer?.email) {
      toast.error("Customer email not available");
      return;
    }
    const payNumber = payment?.id ? `PR-${payment.id.toString().padStart(5, '0')}` : "";
    const subject = `Payment Receipt ${payNumber} from ${orgInfo.name}`;
    const message = `Dear ${customer?.display_name || "Customer"},\n\nWe have received your payment of ₹${parseFloat(payment?.amount || 0).toFixed(2)} on ${new Date(payment?.payment_date).toLocaleDateString("en-GB")}.\n\nThank you for your business!\n\nRegards,\n${orgInfo.name}`;
    window.location.href = `mailto:${customer.email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(message)}`;
  };

  const filteredList = paymentsList.filter((p) => {
    if (statusFilter !== "all" && p.status !== statusFilter) return false;
    const customerName = getCustomerName(p.customer_id).toLowerCase();
    const payNumber = (p.id ? `PR-${p.id.toString().padStart(5, '0')}` : "").toLowerCase();
    const query = searchQuery.toLowerCase();
    return customerName.includes(query) || payNumber.includes(query);
  });

  const sortedList = [...filteredList].sort((a, b) => new Date(b.payment_date).getTime() - new Date(a.payment_date).getTime());

  let totalWords = "";
  try {
    const total = parseFloat(payment?.amount) || 0;
    const words = require("number-to-words").toWords(Math.floor(total));
    totalWords = words.charAt(0).toUpperCase() + words.slice(1);
  } catch (e) {
    totalWords = payment ? parseFloat(payment.amount).toFixed(0) : "";
  }

  const ribbonColor = "#5cb85c"; // Green PAID color matching screenshot

  return (
    <div className="invoice-split-container" style={{ display: "flex", height: "100vh", background: "#ffffff", fontFamily: "system-ui, -apple-system, sans-serif", overflow: "hidden" }}>
      
      {/* Styles Injection */}
      <style dangerouslySetInnerHTML={{__html: `
        .toolbar-btn { display: flex; align-items: center; gap: 6px; padding: 6px 12px; border: 1px solid #d0d5dd; background: #ffffff; border-radius: 6px; font-size: 12px; font-weight: 500; color: #344054; cursor: pointer; transition: all 0.15s ease; outline: none; }
        .toolbar-btn:hover { background: #f9fafb; border-color: #98a2b3; }
        .dropdown-item { display: flex; align-items: center; width: 100%; padding: 8px 14px; border: none; background: none; text-align: left; cursor: pointer; font-size: 13px; color: #344054; outline: none; transition: background 0.1s ease; }
        .dropdown-item:hover { background: #f4f5f7; }
        .detail-row { display: flex; margin-bottom: 20px; align-items: flex-end; }
        .detail-label { width: 150px; font-size: 13px; color: #475569; }
        .detail-value { flex: 1; font-size: 13px; font-weight: 500; color: #1e293b; border-bottom: 1px dashed #cbd5e1; padding-bottom: 2px; }
        
        @media print {
          @page { size: A4 portrait; margin: 15mm; }
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; background: #fff !important; }
          body * { visibility: hidden; }
          
          .printable-a4, .printable-a4 * { visibility: visible; }
          
          .printable-a4 { 
            position: absolute !important; 
            left: 0 !important; 
            top: 0 !important; 
            width: 100% !important; 
            max-width: 100% !important;
            box-sizing: border-box !important;
            margin: 0 !important; 
            padding: 0 !important; 
            box-shadow: none !important; 
            background: #ffffff !important;
          }
          
          .print-hide { display: none !important; }
          
          .invoice-split-container, .right-pane, .scroll-area {
            height: auto !important;
            overflow: visible !important;
            position: static !important;
            display: block !important;
          }
        }
      `}} />

      {/* LEFT PANE */}
      <div className="print-hide" style={{ width: "350px", borderRight: "1px solid #eaecf0", display: "flex", flexDirection: "column", height: "100%" }}>
        
        {/* Header toolbar */}
        <div style={{ padding: "16px", borderBottom: "1px solid #eaecf0", display: "flex", justifyContent: "space-between", alignItems: "center", position: "relative" }}>
          <div>
            <h3 
              onClick={() => setStatusDropdownOpen(!statusDropdownOpen)}
              style={{ fontSize: "15px", fontWeight: "600", color: "#1d2939", margin: 0, display: "flex", alignItems: "center", gap: "6px", cursor: "pointer" }}
            >
              All Received Payments
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#667085" strokeWidth="2" style={{ transform: statusDropdownOpen ? "rotate(180deg)" : "none", transition: "transform 0.15s ease" }}>
                <polyline points="6 9 12 15 18 9"></polyline>
              </svg>
            </h3>

            {statusDropdownOpen && (
              <div style={{ position: "absolute", left: "16px", top: "100%", marginTop: "4px", background: "#ffffff", border: "1px solid #eaecf0", borderRadius: "8px", boxShadow: "0 10px 30px rgba(16, 24, 40, 0.08)", zIndex: 1000, width: "200px", padding: "8px 0" }}>
                <div onClick={() => { setStatusFilter("all"); setStatusDropdownOpen(false); }} style={{ padding: "8px 16px", background: statusFilter === "all" ? "#f0f9ff" : "transparent", cursor: "pointer", fontSize: "13px", color: statusFilter === "all" ? "#0ba5ec" : "#344054" }}>All Payments</div>
              </div>
            )}
          </div>
          <button 
            onClick={() => navigate("/payments-received/new")}
            style={{ padding: "6px 10px", background: "#0ba5ec", color: "#ffffff", border: "none", borderRadius: "4px", fontSize: "11px", fontWeight: "600", cursor: "pointer" }}
          >
            + New
          </button>
        </div>

        {/* Search inside left list */}
        <div style={{ padding: "10px 16px", borderBottom: "1px solid #eaecf0" }}>
          <div style={{ position: "relative", width: "100%" }}>
            <span style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", display: "flex" }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#667085" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            </span>
            <input
              type="text"
              placeholder="Search in Payments..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ width: "100%", padding: "8px 10px 8px 32px", borderRadius: "4px", border: "1px solid #d0d5dd", fontSize: "12px", outline: "none", boxSizing: "border-box", color: "#344054" }}
            />
          </div>
        </div>

        {/* Compact List */}
        <div style={{ flex: 1, overflowY: "auto", background: "#fcfcfd" }}>
          {listLoading ? (
            <div style={{ padding: "20px", textAlign: "center", color: "#667085", fontSize: "13px" }}>Loading list...</div>
          ) : sortedList.length === 0 ? (
            <div style={{ padding: "40px 20px", textAlign: "center", color: "#667085", fontSize: "13px" }}>No payments found</div>
          ) : (
            sortedList.map((p) => {
              const isSelected = String(p.id) === String(id);
              return (
                <div
                  key={p.id}
                  onClick={() => navigate(`/payments-received/${p.id}`)}
                  style={{
                    padding: "12px 16px", borderBottom: "1px solid #eaecf0", cursor: "pointer",
                    background: isSelected ? "#f0f9ff" : "#ffffff", borderLeft: isSelected ? "3px solid #0ba5ec" : "3px solid transparent",
                    transition: "all 0.1s ease",
                  }}
                >
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
                    <span style={{ fontWeight: "500", fontSize: "13px", color: isSelected ? "#0ba5ec" : "#344054", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "180px" }}>
                      {getCustomerName(p.customer_id)}
                    </span>
                    <span style={{ fontWeight: "600", fontSize: "13px", color: "#1d2939" }}>
                      ₹{parseFloat(p.amount).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "6px" }}>
                    <span style={{ fontSize: "11px", color: "#667085" }}>
                      {p.id} &bull; {new Date(p.payment_date).toLocaleDateString("en-GB")}
                    </span>
                    <span style={{ fontSize: "10px", fontWeight: "600", color: "#15803d", textTransform: "uppercase" }}>
                      PAID <span style={{ color: "#667085", fontWeight: "normal", marginLeft: "4px", textTransform: "capitalize" }}>{p.payment_mode}</span>
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* RIGHT PANE (DOCUMENT DETAILS) */}
      <div className="right-pane" style={{ flex: 1, display: "flex", flexDirection: "column", height: "100%", background: "#f2f4f7", overflow: "hidden" }}>
        {fetching ? (
          <div style={{ padding: "40px" }}><DetailSkeleton /></div>
        ) : !payment ? (
          <div style={{ padding: "40px", textAlign: "center", color: "#667085" }}>Failed to load Payment details.</div>
        ) : (
          <>
            {/* Top Toolbar */}
            <div className="print-hide" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 24px", borderBottom: "1px solid #eaecf0", background: "#ffffff" }}>
              <h2 style={{ fontSize: "16px", fontWeight: "600", color: "#1d2939", margin: 0 }}>
                {payment.id}
              </h2>
              
              <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
                <button className="toolbar-btn" title="Edit">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg> Edit
                </button>

                <button onClick={sendEmail} className="toolbar-btn" title="Send Email">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg> Email
                </button>

                <button onClick={sendWhatsApp} className="toolbar-btn" title="Send WhatsApp">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg> WhatsApp
                </button>

                <button onClick={sendSMS} className="toolbar-btn" title="Send SMS">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg> SMS
                </button>

                <button onClick={() => window.print()} className="toolbar-btn">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg> PDF/Print <span style={{fontSize:"10px", marginLeft:"4px"}}>▼</span>
                </button>

                <button className="toolbar-btn">Refund</button>

                {/* More Menu */}
                <div style={{ position: "relative" }}>
                  <button onClick={() => { setMoreMenuOpen(!moreMenuOpen); }} className="toolbar-btn">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="1"></circle><circle cx="19" cy="12" r="1"></circle><circle cx="5" cy="12" r="1"></circle></svg>
                  </button>
                  {moreMenuOpen && (
                    <div style={{ position: "absolute", right: 0, top: "100%", marginTop: "6px", background: "#ffffff", border: "1px solid #eaecf0", borderRadius: "8px", boxShadow: "0 10px 30px rgba(16, 24, 40, 0.08)", zIndex: 1000, minWidth: "150px", padding: "6px 0" }}>
                      <button onClick={() => { setMoreMenuOpen(false); handleDelete(); }} className="dropdown-item" style={{ color: "#d92d20" }}>Delete</button>
                    </div>
                  )}
                </div>

                <button onClick={() => navigate("/payments-received")} style={{ border: "none", background: "none", cursor: "pointer", fontSize: "20px", color: "#98a2b3", marginLeft: "8px" }}>&times;</button>
              </div>
            </div>

            {/* Document Scrollable Area */}
            <div className="scroll-area" style={{ flex: 1, overflowY: "auto", padding: "32px", display: "flex", justifyContent: "center" }}>
              
              {/* Document Container */}
              <div className="printable-a4" style={{ width: "800px", background: "#ffffff", boxShadow: "0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06)", position: "relative", minHeight: "1123px", padding: "60px 48px" }}>
                
                {/* Diagonal Status Ribbon */}
                <div className="print-hide" style={{ position: "absolute", top: 0, left: 0, width: "130px", height: "130px", overflow: "hidden", zIndex: 10 }}>
                  <div style={{ background: ribbonColor, color: "#fff", textAlign: "center", padding: "6px", transform: "rotate(-45deg)", position: "absolute", top: "25px", left: "-35px", width: "170px", fontWeight: "700", fontSize: "12px", letterSpacing: "1px" }}>
                    PAID
                  </div>
                </div>

                {/* Organization Details (matching screenshot) */}
                <div style={{ textAlign: "left", marginBottom: "60px", marginLeft: "40px" }}>
                  <h3 style={{ margin: "0 0 15px 0", fontSize: "18px", color: "#000", fontWeight: "700", fontFamily: "serif" }}>
                    {orgInfo.name}
                  </h3>
                  <div style={{ color: "#666", fontSize: "13px", lineHeight: "1.6" }}>
                    {orgInfo.address && <div style={{ whiteSpace: "pre-wrap" }}>{orgInfo.address}</div>}
                    {orgInfo.phone && <div>{orgInfo.phone}</div>}
                    {orgInfo.email && <div>{orgInfo.email}</div>}
                  </div>
                </div>

                {/* Title */}
                <div style={{ textAlign: "center", marginBottom: "60px" }}>
                  <h1 style={{ fontSize: "18px", color: "#475569", fontWeight: "400", letterSpacing: "1px", fontFamily: "serif" }}>
                    PAYMENT RECEIPT
                  </h1>
                </div>

                {/* Main Content Area */}
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "80px", marginLeft: "40px" }}>
                  
                  {/* Left Side Details */}
                  <div style={{ width: "450px" }}>
                    <div className="detail-row">
                      <div className="detail-label">Payment Date</div>
                      <div className="detail-value">{new Date(payment.payment_date).toLocaleDateString("en-GB")}</div>
                    </div>
                    <div className="detail-row">
                      <div className="detail-label">Reference Number</div>
                      <div className="detail-value">{payment.reference || ""}</div>
                    </div>
                    <div className="detail-row">
                      <div className="detail-label">Payment Mode</div>
                      <div className="detail-value" style={{ textTransform: "capitalize" }}>{payment.payment_mode}</div>
                    </div>
                    <div className="detail-row" style={{ marginTop: "40px" }}>
                      <div className="detail-label" style={{ width: "180px" }}>Amount Received In Words</div>
                      <div className="detail-value" style={{ fontWeight: "700", borderBottom: "1px solid #cbd5e1" }}>
                        Indian Rupee {totalWords} Only
                      </div>
                    </div>
                  </div>

                  {/* Right Side Amount Box */}
                  <div style={{ background: "#7cb342", color: "#fff", padding: "20px 30px", height: "fit-content", minWidth: "150px", textAlign: "center" }}>
                    <div style={{ fontSize: "13px", marginBottom: "10px" }}>Amount Received</div>
                    <div style={{ fontSize: "24px" }}>
                      ₹{parseFloat(payment.amount).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </div>
                  </div>
                </div>

                {/* Bottom Section */}
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginTop: "100px", marginLeft: "40px" }}>
                  <div style={{ width: "300px" }}>
                    <div style={{ fontSize: "13px", color: "#475569", marginBottom: "16px" }}>Received From</div>
                    <div style={{ fontSize: "15px", color: "#006ee6", fontWeight: "600" }}>{getCustomerName(payment.customer_id)}</div>
                  </div>

                  <div style={{ textAlign: "center", width: "200px" }}>
                    <div style={{ color: "#475569", fontSize: "13px", marginBottom: "40px" }}>Authorized Signature</div>
                    <div style={{ borderTop: "1px solid #cbd5e1", width: "100%" }}></div>
                  </div>
                </div>

              </div>
            </div>

          </>
        )}
      </div>
    </div>
  );
}

export default PaymentDetail;
