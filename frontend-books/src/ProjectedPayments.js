import React, { useEffect, useState } from "react";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

const STATUS_COLORS = {
  draft:          { bg: "#f1f5f9", color: "#475569", label: "DRAFT" },
  sent:           { bg: "#fffbeb", color: "#b45309", label: "SENT" },
  unpaid:         { bg: "#fffbeb", color: "#b45309", label: "UNPAID" },
  pending:        { bg: "#fffbeb", color: "#b45309", label: "PENDING" },
  partially_paid: { bg: "#eff6ff", color: "#1d4ed8", label: "PARTIALLY PAID" },
  paid:           { bg: "#f0fdf4", color: "#15803d", label: "PAID" },
  overdue:        { bg: "#fef2f2", color: "#b91c1c", label: "OVERDUE" },
  cancelled:      { bg: "#f1f5f9", color: "#475569", label: "CANCELLED" },
};

function ProjectedPayments() {
  const [data, setData] = useState({ bills: [], total_projected_payment: 0, projected_month: null, projected_year: null });
  const [loading, setLoading] = useState(true);
  const [sentAlerts, setSentAlerts] = useState({});

  const fetchProjectedPayments = async () => {
    try {
      setLoading(true);
      const res = await apiRequest("/accounts/projected-payments");
      if (res) {
        setData(res);
      }
    } catch (error) {
      toast.error("Failed to load projected payments");
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProjectedPayments();
  }, []);

  const getMonthName = (monthNumber) => {
    const date = new Date();
    date.setMonth(monthNumber - 1);
    return date.toLocaleString("en-US", { month: "long" });
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      minimumFractionDigits: 2,
    }).format(amount || 0);
  };

  const statusBadge = (status) => {
    const statusKey = status?.toLowerCase().replace(' ', '_') || 'draft';
    const colors = STATUS_COLORS[statusKey] || STATUS_COLORS.draft;
    return (
      <span style={{
        padding: "3px 8px",
        borderRadius: "4px",
        fontSize: "11px",
        fontWeight: "600",
        background: colors.bg,
        color: colors.color,
        letterSpacing: "0.03em",
        display: "inline-block",
      }}>
        {colors.label}
      </span>
    );
  };

  return (
    <div style={{ padding: "30px 40px", background: "#f8fafc", minHeight: "100vh" }}>
      <style>{`
        .items-table {
          width: 100%;
          border-collapse: collapse;
          font-size: 13px;
          table-layout: auto;
        }
        .items-table th {
          text-align: left;
          padding: 12px 15px;
          color: #64748b;
          font-weight: 600;
          border-bottom: 1px solid #e2e8f0;
          background: #ffffff;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 0.5px;
        }
        .items-table td {
          padding: 14px 15px;
          border-bottom: 1px solid #f8fafc;
          color: #334155;
        }
        .items-table tr:hover {
          background: #f1f5f9;
        }
        .table-responsive {
          background: #fff;
          border-radius: 8px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          overflow-x: auto;
          border: 1px solid #e2e8f0;
        }
      `}</style>
      {/* Header Section */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: "30px" }}>
        <div>
          <h2 style={{ margin: "0 0 8px 0", color: "#111827", fontSize: "24px" }}>Projected Payment</h2>
          <p style={{ margin: 0, color: "#6b7280", fontSize: "14px" }}>
            Unpaid and pending invoices projected for {" "}
            <span style={{ fontWeight: "600", color: "#374151" }}>
              {data.projected_month ? `${getMonthName(data.projected_month)} ${data.projected_year}` : "Next Month"}
            </span>
          </p>
        </div>
        
        <div style={{ textAlign: "right", background: "#f8fafc", padding: "15px 25px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
          <p style={{ margin: "0 0 4px 0", color: "#64748b", fontSize: "13px", textTransform: "uppercase", fontWeight: "600", letterSpacing: "0.5px" }}>Total Projected</p>
          <h3 style={{ margin: 0, color: "#0f172a", fontSize: "28px" }}>
            {formatCurrency(data.total_projected_payment)}
          </h3>
        </div>
      </div>

      {/* Table Section */}
      <div style={{ background: "#fff", borderRadius: "8px", boxShadow: "0 1px 3px rgba(0,0,0,0.1)", overflow: "hidden", border: "1px solid #e2e8f0" }}>
        {loading ? (
          <div style={{ padding: "20px" }}>
            <TableSkeleton columns={7} rows={5} />
          </div>
        ) : data.bills.length === 0 ? (
          <div style={{ textAlign: "center", padding: "60px 20px", color: "#6b7280" }}>
            <svg style={{ margin: "auto", display: "block", marginBottom: "15px", color: "#9ca3af" }} width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path strokeLinecap="round" strokeLinejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <p style={{ margin: 0, fontSize: "16px" }}>No projected payments found.</p>
            <p style={{ margin: "5px 0 0 0", fontSize: "14px" }}>All current invoices are paid or written off.</p>
          </div>
        ) : (
          <div className="table-responsive">
            <table className="items-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Invoice Number</th>
                  <th>Customer Name</th>
                  <th>Due Date</th>
                  <th>Status</th>
                  <th style={{ textAlign: "right" }}>Total Amount</th>
                  <th style={{ textAlign: "right" }}>Pending Amount</th>
                  <th style={{ textAlign: "center", width: "100px" }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.bills.map((bill) => (
                  <tr key={bill.bill_id}>
                    <td>{new Date(bill.bill_date).toLocaleDateString()}</td>
                    <td style={{ color: "#2563eb", fontWeight: "500" }}>{bill.bill_number}</td>
                    <td>{bill.vendor_name || "—"}</td>
                    <td>{new Date(bill.due_date).toLocaleDateString()}</td>
                    <td style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                      {sentAlerts[bill.bill_id] ? (
                        <div style={{ color: "#16a34a", display: "flex", alignItems: "center" }} title="Notification Sent">
                          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                        </div>
                      ) : (
                        statusBadge(bill.status)
                      )}
                    </td>
                    <td style={{ textAlign: "right", color: "#64748b" }}>{formatCurrency(bill.total_amount)}</td>
                    <td style={{ textAlign: "right", fontWeight: "600", color: "#111827" }}>{formatCurrency(bill.pending_amount)}</td>
                    <td style={{ textAlign: "center" }}>
                      <div style={{ display: "flex", gap: "8px", justifyContent: "center" }}>
                        <button
                            onClick={() => {
                              const formattedAmount = parseFloat(bill.pending_amount).toLocaleString('en-IN', {minimumFractionDigits: 2});
                              const dueDate = new Date(bill.due_date).toLocaleDateString("en-GB");
                              const msg = `Dear ${bill.vendor_name},\n\nThis is a gentle reminder that a payment of Rs. ${formattedAmount} for Invoice ${bill.bill_number} is scheduled to be due on ${dueDate}.\n\nWe kindly request you to process the payment on or before the due date.\n\nThank you for your continued business!`;
                              const phone = bill.customer_mobile || bill.customer_phone || "";
                              const cleanPhone = String(phone).replace(/\D/g, "");
                              const target = cleanPhone.length === 10 ? `91${cleanPhone}` : cleanPhone;
                              if (!target) {
                                toast.error("Customer phone number is missing.");
                                return;
                              }
                              setSentAlerts(prev => ({ ...prev, [bill.bill_id]: true }));
                              window.open(`https://wa.me/${target}?text=${encodeURIComponent(msg)}`, "_blank");
                            }}
                            title="Send via WhatsApp"
                            style={{ background: "none", border: "none", cursor: "pointer", color: "#25D366", padding: "4px" }}
                          >
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg>
                          </button>
                          <button
                            onClick={() => {
                              const formattedAmount = parseFloat(bill.pending_amount).toLocaleString('en-IN', {minimumFractionDigits: 2});
                              const dueDate = new Date(bill.due_date).toLocaleDateString("en-GB");
                              const msg = `Dear ${bill.vendor_name},\n\nThis is a gentle reminder that a payment of Rs. ${formattedAmount} for Invoice ${bill.bill_number} is scheduled to be due on ${dueDate}.\n\nWe kindly request you to process the payment on or before the due date to ensure uninterrupted services.\n\nThank you for your continued business!`;
                              if (!bill.customer_email) {
                                toast.error("Customer email is missing.");
                                return;
                              }
                              setSentAlerts(prev => ({ ...prev, [bill.bill_id]: true }));
                              window.location.href = `mailto:${bill.customer_email}?subject=Payment Reminder: Invoice ${bill.bill_number}&body=${encodeURIComponent(msg)}`;
                            }}
                            title="Send via Email"
                            style={{ background: "none", border: "none", cursor: "pointer", color: "#3b82f6", padding: "4px" }}
                          >
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>
                          </button>
                        </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default ProjectedPayments;
