/**
 * PurchaseOrderDetail.js – High-Fidelity A4 Purchase Order Document View
 */
import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

// Organization info is fetched dynamically

const STATUS_COLORS = {
  Draft:     { bg: "#e2e3e5", color: "#383d41" },
  Issued:    { bg: "#d4edda", color: "#155724" },
  Billed:    { bg: "#d1ecf1", color: "#0c5460" },
  Cancelled: { bg: "#f8d7da", color: "#721c24" },
};

function PurchaseOrderDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [po, setPO] = useState(null);
  const [items, setItems] = useState([]);
  const [vendor, setVendor] = useState(null);
  const [loading, setLoading] = useState(true);
  const [orgInfo, setOrgInfo] = useState({ name: "", address: "", email: "", country: "", logo: "" });

  // Email modal
  const [showEmailModal, setShowEmailModal] = useState(false);
  const [emailTo, setEmailTo] = useState("");
  const [emailSubject, setEmailSubject] = useState("");
  const [emailBody, setEmailBody] = useState("");
  const [sendingEmail, setSendingEmail] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const poRes = await apiRequest(`/purchase-orders/${id}`);
        if (poRes?.purchase_order) {
          setPO(poRes.purchase_order);
          setItems(poRes.items || []);

          if (poRes.purchase_order.vendor_id) {
            const vendRes = await apiRequest(`/vendors/${poRes.purchase_order.vendor_id}`);
            if (vendRes?.vendor) setVendor(vendRes.vendor);
          }

          const orgRes = await apiRequest("/organization-settings");
          if (orgRes?.settings) {
            setOrgInfo({
              name: orgRes.settings.organization_name || "",
              address: orgRes.settings.address || "",
              email: orgRes.settings.organization_email || "",
              country: orgRes.settings.country || "",
              logo: orgRes.settings.logo_url || ""
            });
          }
        }
      } catch (err) {
        toast.error("Failed to load Purchase Order details");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [id]);

  if (loading) return <div style={{ padding: "40px" }}><FormSkeleton fields={5} /></div>;
  if (!po) return <div style={{ padding: "40px", textAlign: "center" }}>Purchase Order not found</div>;

  const changeStatus = async (newStatus) => {
    try {
      await apiRequest(`/purchase-orders/${id}`, { method: "PUT", body: JSON.stringify({ status: newStatus }) });
      toast.success(`Marked as ${newStatus}`);
      setPO({ ...po, status: newStatus });
    } catch (err) {
      toast.error("Failed to update status");
    }
  };

  const handleConvertToBill = async () => {
    if (!window.confirm("Convert this Purchase Order to a Bill?")) return;
    try {
      const res = await apiRequest(`/purchase-orders/${id}/convert-to-bill`, { method: "POST" });
      if (res?.alreadyConverted) {
        toast("Already converted. Opening existing bill.", { icon: "ℹ️" });
        navigate(`/bills/${res.billId}`);
        return;
      }
      toast.success("Converted to Bill!");
      setPO(prev => ({ ...prev, status: "Billed" }));
      navigate(`/bills/${res.billId}`);
    } catch (err) {
      toast.error("Conversion failed");
    }
  };

  const handleReceive = async () => {
    if (!window.confirm("Mark this Purchase Order as Received? This will increase stock for tracked items.")) return;
    try {
      await apiRequest(`/purchase-orders/${id}/receive`, { method: "POST" });
      toast.success("Purchase Order received! Stock updated.");
      setPO(prev => ({ ...prev, status: "Received" }));
    } catch (err) {
      toast.error("Failed to mark as received");
    }
  };

  const openEmailModal = () => {
    setEmailTo(vendor?.email || "");
    setEmailSubject(`Purchase Order ${po.purchase_order_number} from ${orgInfo.name}`);
    setEmailBody(`Dear ${vendor?.display_name || vendor?.company_name || "Vendor"},\n\nPlease find our Purchase Order attached.\n\nPurchase Order Number: ${po.purchase_order_number}\nTotal: ₹${parseFloat(po.total_amount).toFixed(2)}\n\nThank you.\n\nRegards,\n${orgInfo.name}`);
    setShowEmailModal(true);
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
    const vendName = vendor?.display_name || vendor?.company_name || "Vendor";
    const docNumber = po?.purchase_order_number || "";
    const totalAmt = parseFloat(po?.total_amount || 0).toFixed(2);
    const businessName = orgInfo?.name || "our business";
    return `Dear ${vendName}, please find our Purchase Order ${docNumber} from ${businessName}. Total: ₹${totalAmt}. Thank you. Regards, ${businessName}.`;
  };

  const sendWhatsApp = (e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    const phoneVal = vendor?.mobile || vendor?.phone || vendor?.work_phone;
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
    const phoneVal = vendor?.mobile || vendor?.phone || vendor?.work_phone;
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

  const sendEmail = async () => {
    if (!emailTo) { toast.error("Recipient email is required"); return; }
    setSendingEmail(true);
    try {
      await apiRequest(`/purchase-orders/${id}/send`, {
        method: "POST",
        body: JSON.stringify({ to: emailTo, subject: emailSubject, body: emailBody })
      });
      toast.success("Email sent successfully!");
      setShowEmailModal(false);
      if (po.status === "Draft") changeStatus("Issued");
    } catch (err) {
      toast.error("Failed to send email");
    } finally {
      setSendingEmail(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  const calcSubtotal = () => items.reduce((sum, item) => sum + (parseFloat(item.quantity) || 0) * (parseFloat(item.rate) || 0), 0);
  const calcTotalDiscount = () => items.reduce((sum, item) => {
    const qty = parseFloat(item.quantity) || 0;
    const rate = parseFloat(item.rate) || 0;
    const disc = parseFloat(item.discount) || 0;
    if (item.discount_type === "percent") return sum + (qty * rate * disc / 100);
    return sum + disc;
  }, 0);
  const calcTotalTax = () => items.reduce((sum, item) => {
    const qty = parseFloat(item.quantity) || 0;
    const rate = parseFloat(item.rate) || 0;
    let amt = qty * rate;
    const disc = parseFloat(item.discount) || 0;
    if (item.discount_type === "percent") amt -= amt * (disc / 100);
    else amt -= disc;
    return sum + (amt * ((parseFloat(item.tax_rate) || 0) / 100));
  }, 0);

  const subtotal = calcSubtotal();
  const totalDiscount = calcTotalDiscount();
  const totalTax = calcTotalTax();
  const grandTotal = parseFloat(po.total_amount) || (subtotal - totalDiscount + totalTax);

  const badgeColor = STATUS_COLORS[po.status] || STATUS_COLORS.Draft;

  return (
    <div style={{ padding: "30px", background: "#f1f5f9", minHeight: "100vh" }}>
      {/* Top Action Bar */}
      <div className="no-print" style={{ maxWidth: "850px", margin: "auto", display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", background: "#fff", padding: "15px 25px", borderRadius: "8px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "15px" }}>
          <button onClick={() => navigate("/purchase-orders")} style={{ background: "none", border: "none", fontSize: "20px", cursor: "pointer", color: "#64748b" }}>←</button>
          <h2 style={{ margin: 0, fontSize: "20px" }}>{po.purchase_order_number}</h2>
          <span style={{ padding: "5px 12px", borderRadius: "20px", fontSize: "13px", fontWeight: "600", background: badgeColor.bg, color: badgeColor.color, textTransform: "uppercase" }}>
            {po.status}
          </span>
        </div>
        <div style={{ display: "flex", gap: "10px" }}>
          <button onClick={openEmailModal} style={actionBtn}>✉️ Email</button>
          <button onClick={sendWhatsApp} style={actionBtn} title="Send WhatsApp">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ marginRight: "4px", verticalAlign: "middle" }}><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg> WhatsApp
          </button>
          <button onClick={sendSMS} style={actionBtn} title="Send SMS">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ marginRight: "4px", verticalAlign: "middle" }}><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg> SMS
          </button>
          <button onClick={handlePrint} style={actionBtn}>🖨️ Print / PDF</button>
          <button onClick={() => navigate(`/purchase-orders/${id}/edit`)} style={actionBtn}>✏️ Edit</button>
          {po.status !== "Billed" && po.status !== "Cancelled" && po.status !== "Received" && (
            <button onClick={handleConvertToBill} style={{ ...actionBtn, background: "#28a745", color: "#fff", borderColor: "#28a745" }}>🔄 Convert to Bill</button>
          )}
          {po.status === "Draft" && <button onClick={() => changeStatus("Issued")} style={actionBtn}>Mark Issued</button>}
          {(po.status === "Draft" || po.status === "Issued") && (
            <button onClick={handleReceive} style={{ ...actionBtn, background: "#0284c7", color: "#fff", borderColor: "#0284c7" }}>📥 Mark as Received</button>
          )}
          {po.status !== "Cancelled" && <button onClick={() => changeStatus("Cancelled")} style={{ ...actionBtn, color: "#e74c3c" }}>Cancel</button>}
        </div>
      </div>

      {/* A4 Document Container */}
      <div className="printable-a4" style={{ maxWidth: "850px", margin: "auto", background: "#fff", padding: "50px", boxShadow: "0 4px 15px rgba(0,0,0,0.1)", borderRadius: "2px" }}>
        {/* Ribbon for status */}
        {po.status === "Cancelled" && (
          <div style={{ textAlign: "center", color: "#e74c3c", fontWeight: "bold", border: "2px dashed #e74c3c", padding: "10px", marginBottom: "20px", textTransform: "uppercase", letterSpacing: "2px" }}>
            CANCELLED
          </div>
        )}
        {po.status === "Billed" && (
          <div style={{ textAlign: "center", color: "#0c5460", background: "#d1ecf1", fontWeight: "bold", padding: "10px", marginBottom: "20px", textTransform: "uppercase", letterSpacing: "2px" }}>
            BILLED
          </div>
        )}

        {/* Header */}
        <div className="print-hide" style={{ display: "flex", gap: "10px", padding: "15px 30px", background: "#fff", borderBottom: "1px solid #e2e8f0", alignItems: "center" }}>
          <div>
            <h1 style={{ margin: "0 0 10px 0", color: "#333", fontSize: "28px" }}>PURCHASE ORDER</h1>
            <div style={{ fontSize: "14px", color: "#555" }}>
              <strong># {po.purchase_order_number}</strong><br />
              Date: {new Date(po.purchase_order_date).toLocaleDateString()}<br />
              {po.expected_delivery_date && <>Expected Delivery: {new Date(po.expected_delivery_date).toLocaleDateString()}<br /></>}
              {po.reference_number && <>Ref: {po.reference_number}</>}
            </div>
          </div>
          <div style={{ textAlign: "right", fontSize: "14px", color: "#555" }}>
            {orgInfo.logo && <img src={orgInfo.logo} alt="Logo" style={{ maxHeight: "60px", marginBottom: "10px", objectFit: "contain" }} />}
            <h2 style={{ margin: "0 0 5px 0", color: "#333", fontSize: "18px" }}>{orgInfo.name}</h2>
            <div style={{ whiteSpace: "pre-wrap" }}>{orgInfo.address}</div>
            <div>{orgInfo.country}</div>
            <div>{orgInfo.email}</div>
          </div>
        </div>

        {/* Addresses */}
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "40px" }}>
          <div style={{ width: "45%" }}>
            <h3 style={{ margin: "0 0 10px 0", fontSize: "14px", color: "#777", textTransform: "uppercase", borderBottom: "1px solid #eee", paddingBottom: "5px" }}>Vendor</h3>
            <div style={{ fontSize: "14px", color: "#333", lineHeight: "1.6" }}>
              <strong>{vendor?.display_name || vendor?.company_name || "—"}</strong><br />
              {vendor?.email && <>{vendor.email}<br /></>}
              {vendor?.phone && <>{vendor.phone}<br /></>}
              {vendor?.billing_address && <>{vendor.billing_address}<br /></>}
            </div>
          </div>
        </div>

        {/* Items Table */}
        <table style={{ width: "100%", borderCollapse: "collapse", marginBottom: "30px", fontSize: "14px" }}>
          <thead>
            <tr style={{ background: "#333", color: "#fff" }}>
              <th style={{ padding: "12px", textAlign: "left" }}>#</th>
              <th style={{ padding: "12px", textAlign: "left" }}>Item & Description</th>
              <th style={{ padding: "12px", textAlign: "right" }}>Qty</th>
              <th style={{ padding: "12px", textAlign: "right" }}>Rate</th>
              <th style={{ padding: "12px", textAlign: "right" }}>Amount</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item, idx) => (
              <tr key={idx} style={{ borderBottom: "1px solid #eee" }}>
                <td style={{ padding: "12px", textAlign: "left" }}>{idx + 1}</td>
                <td style={{ padding: "12px", textAlign: "left" }}>
                  <strong>{item.item_name || "Item"}</strong>
                  {item.description && <div style={{ fontSize: "12px", color: "#777", marginTop: "4px" }}>{item.description}</div>}
                </td>
                <td style={{ padding: "12px", textAlign: "right" }}>{parseFloat(item.quantity).toFixed(2)}</td>
                <td style={{ padding: "12px", textAlign: "right" }}>{parseFloat(item.rate).toFixed(2)}</td>
                <td style={{ padding: "12px", textAlign: "right" }}>₹{((parseFloat(item.quantity) || 0) * (parseFloat(item.rate) || 0)).toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Totals Box */}
        <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: "40px" }}>
          <div style={{ width: "350px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: "14px" }}>
              <span>Sub Total</span><span>₹{subtotal.toFixed(2)}</span>
            </div>
            {totalDiscount > 0 && (
              <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: "14px", color: "#e74c3c" }}>
                <span>Discount</span><span>- ₹{totalDiscount.toFixed(2)}</span>
              </div>
            )}
            {totalTax > 0 && (
              <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontSize: "14px", color: "#2980b9" }}>
                <span>Tax</span><span>+ ₹{totalTax.toFixed(2)}</span>
              </div>
            )}
            <div style={{ display: "flex", justifyContent: "space-between", padding: "12px 0", fontSize: "18px", fontWeight: "bold", borderTop: "2px solid #333", marginTop: "5px" }}>
              <span>Total</span><span>₹{grandTotal.toFixed(2)}</span>
            </div>
          </div>
        </div>

        {/* Footer Notes */}
        {po.notes && (
          <div style={{ marginBottom: "20px", fontSize: "13px", color: "#555" }}>
            <strong>Notes:</strong><br />
            <div style={{ marginTop: "5px", whiteSpace: "pre-wrap" }}>{po.notes}</div>
          </div>
        )}
        {po.terms_conditions && (
          <div style={{ marginBottom: "20px", fontSize: "13px", color: "#555" }}>
            <strong>Terms & Conditions:</strong><br />
            <div style={{ marginTop: "5px", whiteSpace: "pre-wrap" }}>{po.terms_conditions}</div>
          </div>
        )}

        <div style={{ marginTop: "60px", textAlign: "right", color: "#333", fontSize: "14px" }}>
          <div>_________________________</div>
          <div style={{ marginTop: "10px" }}>Authorized Signature</div>
        </div>
      </div>

      {/* Email Modal */}
      {showEmailModal && (
        <div style={modalOverlay}>
          <div style={modalBox}>
            <h3 style={{ marginTop: 0 }}>Email Purchase Order</h3>
            <div style={{ marginBottom: "15px" }}>
              <label><strong>To:</strong></label>
              <input type="email" value={emailTo} onChange={e => setEmailTo(e.target.value)} style={inputStyle} />
            </div>
            <div style={{ marginBottom: "15px" }}>
              <label><strong>Subject:</strong></label>
              <input type="text" value={emailSubject} onChange={e => setEmailSubject(e.target.value)} style={inputStyle} />
            </div>
            <div style={{ marginBottom: "20px" }}>
              <label><strong>Message:</strong></label>
              <textarea value={emailBody} onChange={e => setEmailBody(e.target.value)} rows={6} style={inputStyle} />
            </div>
            <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end" }}>
              <button onClick={() => setShowEmailModal(false)} style={cancelBtnStyle} disabled={sendingEmail}>Cancel</button>
              <button onClick={sendEmail} style={primaryBtn} disabled={sendingEmail}>
                {sendingEmail ? "Sending..." : "Send Email"}
              </button>
            </div>
          </div>
        </div>
      )}

      <style>{`
        @media print {
          body * { visibility: hidden; }
          .printable-a4, .printable-a4 * { visibility: visible; }
          .printable-a4 { position: absolute; left: 0; top: 0; width: 100%; box-shadow: none; padding: 0; }
          .no-print { display: none !important; }
        }
      `}</style>
    </div>
  );
}

const actionBtn = { padding: "8px 15px", background: "#fff", border: "1px solid #cbd5e1", borderRadius: "5px", cursor: "pointer", fontSize: "13px", fontWeight: "500", color: "#334155" };
const inputStyle = { width: "100%", padding: "8px", borderRadius: "5px", border: "1px solid #ccc", boxSizing: "border-box", fontSize: "14px" };
const primaryBtn = { padding: "10px 20px", background: "#4a90e2", color: "#fff", border: "none", borderRadius: "5px", cursor: "pointer", fontWeight: "500" };
const cancelBtnStyle = { padding: "10px 20px", background: "#ccc", color: "#333", border: "none", borderRadius: "5px", cursor: "pointer" };
const modalOverlay = { position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 };
const modalBox = { background: "#fff", borderRadius: "8px", padding: "25px", width: "600px", maxWidth: "90%", maxHeight: "80vh", overflow: "auto", boxShadow: "0 4px 20px rgba(0,0,0,0.2)" };

export default PurchaseOrderDetail;
