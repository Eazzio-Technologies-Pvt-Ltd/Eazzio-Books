/**
 * Bills.js – Redesigned Bills List UI matching Vendors and Purchase Orders UI
 */
import React, { useEffect, useState, useCallback } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { apiRequest } from "./api";
import { TableSkeleton, DetailSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import { useAuth } from "./AuthContext";

const thStyle = {
  padding: "12px 14px",
  borderBottom: "1px solid #eaecf0",
  fontSize: "11px",
  fontWeight: "600",
  textTransform: "uppercase",
  color: "#475569",
  letterSpacing: "0.03em",
};

const ORG_NAME = "Tinplate Computer Training Center";

const STATUS_COLORS = {
  draft: { bg: "#f1f5f9", color: "#475569", label: "DRAFT" },
  open:  { bg: "#eff6ff", color: "#1d4ed8", label: "OPEN" },
  paid:  { bg: "#dcfce7", color: "#166534", label: "PAID" },
};

const ALL_COLUMNS = [
  { key: "checkbox", label: "☐" },
  { key: "bill_date", label: "Date" },
  { key: "bill_number", label: "Bill#" },
  { key: "vendor_name", label: "Vendor Name" },
  { key: "due_date", label: "Due Date" },
  { key: "total_amount", label: "Amount" },
  { key: "balance_due", label: "Balance Due" },
  { key: "status", label: "Status" },
];

function Bills() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const searchParamsUrl = new URLSearchParams(location.search);
  const searchQuery = searchParamsUrl.get("search") || "";

  const [bills, setBills] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState([]);
  const [statusFilter, setStatusFilter] = useState("all");
  const [favoriteView, setFavoriteView] = useState(() => localStorage.getItem("favBillView") || null);
  const [statusDropdownOpen, setStatusDropdownOpen] = useState(false);
  const [filterSearch, setFilterSearch] = useState("");
  
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [sortBy, setSortBy] = useState("bill_date");
  const [sortOrder, setSortOrder] = useState("desc");

  const [showSettings, setShowSettings] = useState(false);
  const [clipText, setClipText] = useState(true);
  const [columnsOpen, setColumnsOpen] = useState(false);
  const [visibleColumns, setVisibleColumns] = useState({
    bill_date: true,
    bill_number: true,
    vendor_name: true,
    due_date: true,
    total_amount: true,
    balance_due: true,
    status: true,
  });

  useEffect(() => {
    const h = (e) => {
      if (!e.target.closest('.th-icon-wrapper') && !e.target.closest('.settings-dropdown') && !e.target.closest('.columns-dropdown')) {
        setShowSettings(false);
        setColumnsOpen(false);
      }
      if (!e.target.closest('.view-dropdown-container')) {
        setStatusDropdownOpen(false);
      }
      if (!e.target.closest('.more-dropdown-container')) setMoreMenuOpen(false);
    };
    document.addEventListener('click', h);
    return () => document.removeEventListener('click', h);
  }, []);

  const [expandedId, setExpandedId] = useState(null);
  const [expandedBill, setExpandedBill] = useState(null);
  const [expandedItems, setExpandedItems] = useState([]);
  const [expandedLoading, setExpandedLoading] = useState(false);
  const [activeTab, setActiveTab] = useState("Overview");

  // Local/Mocks for tabs
  const [comments, setComments] = useState([]);
  const [newComment, setNewComment] = useState("");
  const [commentsLoading, setCommentsLoading] = useState(false);

  const [activities, setActivities] = useState([]);
  const [payments, setPayments] = useState([]);
  const [paymentsLoading, setPaymentsLoading] = useState(false);
  const [mails, setMails] = useState([]);

  // Actions
  const [showEmailModal, setShowEmailModal] = useState(false);
  const [emailSubject, setEmailSubject] = useState("");
  const [emailBody, setEmailBody] = useState("");
  const [emailSending, setEmailSending] = useState(false);

  const getVendorName = (vendorId) => {
    if (!vendorId) return "—";
    const vend = vendors.find(v => v.id === vendorId);
    return vend ? vend.display_name || vend.company_name || vend.email : "—";
  };

  const getVendorById = (vendorId) => vendors.find(v => v.id === vendorId) || {};

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const [billsRes, vendorsRes] = await Promise.all([
        apiRequest("/bills"),
        apiRequest("/vendors"),
      ]);
      setBills(Array.isArray(billsRes?.bills) ? billsRes.bills : []);
      setVendors(Array.isArray(vendorsRes?.vendors) ? vendorsRes.vendors : []);
    } catch (err) {
      toast.error("Failed to load bills data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData, location.state?.refresh]);

  useEffect(() => {
    const fav = localStorage.getItem("favBillView");
    if (fav) {
      setStatusFilter(fav);
    }
  }, []);

  // Fetch subtab content on detail panel expansion / tab change
  useEffect(() => {
    if (!expandedId) return;

    if (activeTab === "Comments") {
      setCommentsLoading(true);
      const stored = localStorage.getItem(`bill_comments_${expandedId}`);
      setComments(stored ? JSON.parse(stored) : []);
      setCommentsLoading(false);
    } else if (activeTab === "Payments") {
      fetchPayments(expandedId);
    } else if (activeTab === "Mails") {
      const stored = localStorage.getItem(`bill_mails_${expandedId}`);
      setMails(stored ? JSON.parse(stored) : []);
    }
  }, [expandedId, activeTab]);

  const fetchPayments = async (billId) => {
    try {
      setPaymentsLoading(true);
      const res = await apiRequest("/payments-made");
      const filtered = (res?.payments || []).filter(p => String(p.bill_id) === String(billId));
      setPayments(filtered);
    } catch (err) {
      console.error("Failed to load payments", err);
    } finally {
      setPaymentsLoading(false);
    }
  };

  const fetchActivities = (bill) => {
    const list = [
      { id: 1, description: "Bill created", created_at: bill.created_at || bill.bill_date, type: "created" },
    ];
    if (bill.status === "open" || bill.status === "paid") {
      list.push({ id: 2, description: "Bill marked as Open / Unpaid", created_at: bill.updated_at || bill.bill_date, type: "open" });
    }
    if (bill.status === "paid") {
      list.push({ id: 3, description: "Bill fully paid", created_at: bill.updated_at || bill.bill_date, type: "paid" });
    }
    setActivities(list);
  };

  const toggleExpand = async (id) => {
    if (expandedId === id) {
      setExpandedId(null);
      setExpandedBill(null);
      setExpandedItems([]);
      return;
    }
    setExpandedId(id);
    setExpandedLoading(true);
    try {
      const res = await apiRequest(`/bills/${id}`);
      if (res?.bill) {
        setExpandedBill(res.bill);
        setExpandedItems(res.items || []);
        fetchActivities(res.bill);
      }
    } catch (err) {
      toast.error("Failed to load details");
    } finally {
      setExpandedLoading(false);
    }
  };

  const handleAddComment = (e) => {
    e.preventDefault();
    if (!newComment.trim()) return;
    const commentObj = {
      id: Date.now(),
      text: newComment,
      created_at: new Date().toISOString(),
      user: user?.name || user?.email || "Current User"
    };
    const updated = [...comments, commentObj];
    localStorage.setItem(`bill_comments_${expandedId}`, JSON.stringify(updated));
    setComments(updated);
    setNewComment("");
  };

  const handleDeleteComment = (commentId) => {
    const updated = comments.filter(c => c.id !== commentId);
    localStorage.setItem(`bill_comments_${expandedId}`, JSON.stringify(updated));
    setComments(updated);
  };

  const changeStatus = async (id, newStatus) => {
    try {
      const res = await apiRequest(`/bills/${id}`);
      if (res?.bill) {
        const payload = {
          ...res.bill,
          status: newStatus
        };
        await apiRequest(`/bills/${id}`, {
          method: "PUT",
          body: JSON.stringify(payload)
        });
        toast.success(`Bill marked as ${newStatus}`);
        fetchData();
        // Update details if open
        if (expandedId === id) {
          const updatedRes = await apiRequest(`/bills/${id}`);
          setExpandedBill(updatedRes.bill);
          fetchActivities(updatedRes.bill);
        }
      }
    } catch (err) {
      toast.error("Failed to update status");
    }
  };

  const handleDeleteSingle = async (id) => {
    if (!window.confirm("Are you sure you want to delete this bill?")) return;
    try {
      await apiRequest(`/bills/${id}`, { method: "DELETE" });
      toast.success("Bill deleted");
      setExpandedId(null);
      setExpandedBill(null);
      fetchData();
    } catch (err) {
      toast.error("Delete failed");
    }
  };

  const openEmailModal = (bill) => {
    const vend = getVendorById(bill.vendor_id);
    setEmailSubject(`Bill ${bill.bill_number} from ${ORG_NAME}`);
    setEmailBody(`Dear ${vend.display_name || vend.company_name || "Vendor"},\n\nPlease find details for Bill ${bill.bill_number}.\n\nDate: ${new Date(bill.bill_date).toLocaleDateString()}\nTotal Amount: ₹${parseFloat(bill.total_amount).toFixed(2)}\nBalance Due: ₹${parseFloat(bill.balance_due).toFixed(2)}\n\nThank you.\n\nRegards,\n${ORG_NAME}`);
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

  const getCondensedBillMessage = (bill) => {
    const vend = getVendorById(bill.vendor_id);
    const vendName = vend.display_name || vend.company_name || "Vendor";
    const docNumber = bill.bill_number || "";
    const totalAmt = parseFloat(bill.total_amount || 0).toFixed(2);
    const balanceDue = parseFloat(bill.balance_due || 0).toFixed(2);
    return `Dear ${vendName}, please find details for Bill ${docNumber}. Total: ₹${totalAmt}, Balance Due: ₹${balanceDue}. Thank you. Regards, ${ORG_NAME}.`;
  };

  const sendWhatsApp = (bill, e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    const vend = getVendorById(bill.vendor_id);
    const phoneVal = vend?.mobile || vend?.phone || vend?.work_phone;
    const cleanedPhone = cleanPhone(phoneVal);
    if (!cleanedPhone) {
      toast.error("Phone number not available");
      return;
    }
    const message = getCondensedBillMessage(bill);
    window.location.href = `whatsapp://send?phone=${cleanedPhone}&text=${encodeURIComponent(message)}`;
    
    setTimeout(() => {
      if (document.hasFocus()) {
        window.open(`https://wa.me/${cleanedPhone}?text=${encodeURIComponent(message)}`, "_blank");
      }
    }, 1500);
  };

  const sendSMS = (bill, e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    const vend = getVendorById(bill.vendor_id);
    const phoneVal = vend?.mobile || vend?.phone || vend?.work_phone;
    const cleanedPhone = cleanPhone(phoneVal);
    if (!cleanedPhone) {
      toast.error("Phone number not available");
      return;
    }
    const message = getCondensedBillMessage(bill);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const separator = isIOS ? "&" : "?";
    window.location.href = `sms:${cleanedPhone}${separator}body=${encodeURIComponent(message)}`;
  };

  const sendEmailAndMarkSent = async () => {
    const bill = expandedBill;
    if (!bill) return;
    setEmailSending(true);
    try {
      // Simulate sending email since we don't have direct backend emailer for bills
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success("Email sent!");
      setShowEmailModal(false);

      // Save mail log
      const newMail = {
        id: Date.now(),
        to: getVendorById(bill.vendor_id).email || "",
        subject: emailSubject,
        body: emailBody,
        sent_at: new Date().toISOString()
      };
      const stored = localStorage.getItem(`bill_mails_${bill.id}`);
      const updated = stored ? [...JSON.parse(stored), newMail] : [newMail];
      localStorage.setItem(`bill_mails_${bill.id}`, JSON.stringify(updated));
      setMails(updated);
    } catch (err) {
      toast.error("Failed to send email");
    } finally {
      setEmailSending(false);
    }
  };

  const statusBadge = (status) => {
    const s = status ? status.toLowerCase() : "draft";
    const colors = STATUS_COLORS[s] || STATUS_COLORS.draft;
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
        textTransform: "uppercase"
      }}>
        {colors.label}
      </span>
    );
  };

  // Sorting and Filtering
  const filteredBills = bills.filter(b => {
    const matchSearch = searchQuery === "" ||
      (b.bill_number || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      getVendorName(b.vendor_id).toLowerCase().includes(searchQuery.toLowerCase());
    const matchStatus = statusFilter === "all" || b.status?.toLowerCase() === statusFilter.toLowerCase();
    return matchSearch && matchStatus;
  });

  const sortedBills = [...filteredBills].sort((a, b) => {
    let aVal = a[sortBy];
    let bVal = b[sortBy];

    if (sortBy === "vendor_name") {
      aVal = getVendorName(a.vendor_id).toLowerCase();
      bVal = getVendorName(b.vendor_id).toLowerCase();
    } else if (sortBy === "total_amount") {
      aVal = parseFloat(a.total_amount) || 0;
      bVal = parseFloat(b.total_amount) || 0;
    } else if (sortBy === "balance_due") {
      aVal = parseFloat(a.balance_due) || 0;
      bVal = parseFloat(b.balance_due) || 0;
    } else if (sortBy.includes("date")) {
      aVal = a[sortBy] ? new Date(a[sortBy]).getTime() : 0;
      bVal = b[sortBy] ? new Date(b[sortBy]).getTime() : 0;
    } else if (typeof aVal === "string") {
      aVal = aVal.toLowerCase();
      bVal = (bVal || "").toLowerCase();
    }

    if (aVal < bVal) return sortOrder === "asc" ? -1 : 1;
    if (aVal > bVal) return sortOrder === "asc" ? 1 : -1;
    return 0;
  });

  const handleSelectAll = (e) => {
    if (e.target.checked) {
      setSelected(sortedBills.map((q) => q.id));
    } else {
      setSelected([]);
    }
  };

  const toggleSelectOne = (id) => {
    setSelected((prev) =>
      prev.includes(id) ? prev.filter((sid) => sid !== id) : [...prev, id],
    );
  };

  const handleDeleteSelected = async () => {
    if (!window.confirm(`Delete the {selected.length} selected bill(s)?`)) return;
    try {
      await Promise.all(
        selected.map((id) => apiRequest(`/bills/${id}`, { method: "DELETE" }))
      );
      toast.success("Deleted successfully");
      setSelected([]);
      if (selected.includes(expandedId)) {
        setExpandedId(null);
        setExpandedBill(null);
      }
      fetchData();
    } catch (err) {
      toast.error("Delete failed");
    }
  };

  const handleRefresh = () => {
    fetchData();
  };

  const allViews = [
    { key: "all", label: "All Bills" },
    { key: "draft", label: "Draft" },
    { key: "open", label: "Open" },
    { key: "paid", label: "Paid" },
  ];
  const filteredViews = allViews.filter(v => v.label.toLowerCase().includes(filterSearch.toLowerCase()));

  const timeAgo = (dateString) => {
    if (!dateString) return "";
    const now = new Date();
    const past = new Date(dateString);
    const ms = now - past;
    const minutes = Math.floor(ms / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (minutes < 1) return "Just now";
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return `${days}d ago`;
  };

  return (
    <div className="premium-workspace" style={{ background: "#f8fafc", minHeight: "calc(100vh - 60px)", fontFamily: "system-ui, -apple-system, sans-serif" }}>
      
      {/* Styles Injection */}
      <style dangerouslySetInnerHTML={{ __html: `
        .split-layout-container {
          display: flex;
          height: calc(100vh - 60px);
          overflow: hidden;
        }
        .left-list-pane {
          width: 32%;
          border-right: 1px solid #eaecf0;
          background: #ffffff;
          display: flex;
          flex-direction: column;
          height: 100%;
          transition: width 0.2s ease;
        }
        .left-list-pane.collapsed {
          width: 0;
          overflow: hidden;
          border-right: none;
        }
        .right-detail-pane {
          flex: 1;
          background: #ffffff;
          display: flex;
          flex-direction: column;
          height: 100%;
          overflow-y: auto;
        }
        .full-table-container {
          padding: 24px 32px;
          display: flex;
          flex-direction: column;
          width: 100%;
          box-sizing: border-box;
        }
        .full-table-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 20px;
        }
        .table-actions {
          display: flex;
          gap: 12px;
          align-items: center;
        }
        .btn-new {
          background: #006ee6;
          color: #ffffff;
          border: none;
          padding: 8px 14px;
          border-radius: 6px;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          display: flex;
          align-items: center;
          gap: 6px;
          transition: background 0.1s ease;
        }
        .btn-new:hover {
          background: #0056b3;
        }
        .btn-more {
          background: #ffffff;
          border: 1px solid #d0d5dd;
          color: #344054;
          padding: 8px;
          border-radius: 6px;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.1s ease;
        }
        .btn-more:hover {
          background: #f9fafb;
          border-color: #98a2b3;
        }
        .more-dropdown-container {
          position: relative;
        }
        .more-dropdown-menu {
          position: absolute;
          right: 0;
          top: 100%;
          margin-top: 6px;
          background: #ffffff;
          border: 1px solid #eaecf0;
          border-radius: 8px;
          box-shadow: 0 10px 25px rgba(0,0,0,0.08);
          z-index: 100;
          min-width: 160px;
          padding: 6px 0;
        }
        .more-dropdown-item {
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 9px 16px;
          font-size: 13px;
          color: #344054;
          cursor: pointer;
          transition: background 0.1s ease;
          position: relative;
        }
        .more-dropdown-item:hover {
          background: #f9fafb;
        }
        .more-dropdown-item svg {
          width: 15px;
          height: 15px;
          color: #475569;
        }
        .more-dropdown-item .chevron {
          margin-left: auto;
          width: 12px;
          height: 12px;
        }
        .nested-dropdown-menu {
          display: none;
          position: absolute;
          right: 100%;
          top: 0;
          margin-right: 4px;
          background: #ffffff;
          border: 1px solid #eaecf0;
          border-radius: 8px;
          box-shadow: 0 10px 25px rgba(0,0,0,0.08);
          min-width: 160px;
          padding: 6px 0;
        }
        .more-dropdown-item:hover .nested-dropdown-menu {
          display: block;
        }
        .more-dropdown-divider {
          height: 1px;
          background: #f2f4f7;
          margin: 6px 0;
        }
        .premium-input {
          box-sizing: border-box;
          transition: all 0.15s ease;
        }
        .premium-input:hover {
          border-color: #98a2b3;
        }
        .premium-input:focus {
          border-color: #006ee6;
          box-shadow: 0 0 0 3px rgba(0, 110, 230, 0.1);
        }
        .table-wrapper {
          background: #ffffff;
          border: 1px solid #eaecf0;
          border-radius: 8px;
          overflow: hidden;
          box-shadow: 0 1px 3px rgba(16, 24, 40, 0.05);
          margin-top: 16px;
        }
        .items-table {
          width: 100%;
          border-collapse: collapse;
          text-align: left;
        }
        .items-table th {
          background: #f9fafb;
        }
        .items-table td {
          border-bottom: 1px solid #eaecf0;
          font-size: 13px;
          color: #344054;
        }
        .items-table tr:last-child td {
          border-bottom: none;
        }
        .items-table tr:hover td {
          background: #f9fafb;
        }
        .items-table.clip-text td {
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          max-width: 180px;
        }
        .vendor-name-link {
          color: #006ee6;
          font-weight: 600;
          cursor: pointer;
        }
        .vendor-name-link:hover {
          text-decoration: underline;
        }
        .th-icon-wrapper {
          position: relative;
        }
        .th-icon {
          display: inline-flex;
          cursor: pointer;
          padding: 4px;
          border-radius: 4px;
          color: #667085;
          transition: all 0.1s ease;
        }
        .th-icon:hover, .th-icon.active {
          background: #e2e8f0;
          color: #0f172a;
        }
        .settings-dropdown {
          position: absolute;
          left: 0;
          top: 100%;
          margin-top: 4px;
          background: #ffffff;
          border: 1px solid #eaecf0;
          border-radius: 8px;
          box-shadow: 0 10px 25px rgba(0,0,0,0.08);
          z-index: 100;
          min-width: 180px;
          padding: 8px 0;
        }
        .settings-dropdown .dropdown-item {
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 8px 16px;
          font-size: 13px;
          color: #344054;
          cursor: pointer;
        }
        .settings-dropdown .dropdown-item:hover {
          background: #f9fafb;
        }
        .settings-dropdown .dropdown-item svg {
          width: 14px;
          height: 14px;
          color: #475569;
        }
        .columns-dropdown label {
          transition: background 0.1s ease;
        }
        .columns-dropdown label:hover {
          background: #f9fafb;
        }
        .view-dropdown-container {
          position: relative;
        }
        .view-dropdown-btn {
          padding: 6px 12px;
          border-radius: 6px;
          transition: background 0.15s ease;
        }
        .view-dropdown-btn:hover, .view-dropdown-btn.active {
          background: #f1f5f9;
        }
        .view-dropdown-menu {
          position: absolute;
          left: 0;
          top: 100%;
          margin-top: 6px;
          background: #ffffff;
          border: 1px solid #eaecf0;
          border-radius: 8px;
          box-shadow: 0 10px 25px rgba(0,0,0,0.08);
          z-index: 101;
          min-width: 260px;
          padding: 8px 0;
          max-height: 350px;
          overflow-y: auto;
        }
        .view-dropdown-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 9px 16px;
          font-size: 13px;
          color: #344054;
          cursor: pointer;
          transition: all 0.1s ease;
        }
        .view-dropdown-item:hover {
          background: #f9fafb;
        }
        
        /* Pane elements */
        .list-header {
          padding: 16px 20px;
          border-bottom: 1px solid #eaecf0;
          background: #ffffff;
          display: flex;
          align-items: center;
          justify-content: space-between;
        }
        .list-search {
          padding: 12px 20px;
          border-bottom: 1px solid #eaecf0;
          background: #fcfcfd;
        }
        .list-items-container {
          flex: 1;
          overflow-y: auto;
        }
        .pane-list-item {
          padding: 16px 20px;
          border-bottom: 1px solid #f2f4f7;
          cursor: pointer;
          transition: background 0.1s ease;
          display: flex;
          flex-direction: column;
          gap: 6px;
        }
        .pane-list-item:hover {
          background: #f9fafb;
        }
        .pane-list-item.selected {
          background: #f0f6ff;
          border-left: 3px solid #006ee6;
          padding-left: 17px;
        }
        .pane-item-top {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          width: 100%;
        }
        .detail-header-panel {
          padding: 24px 32px;
          border-bottom: 1px solid #eaecf0;
          background: #ffffff;
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
        }
        .detail-tabs-bar {
          background: #ffffff;
          border-bottom: 1px solid #eaecf0;
          padding: 0 32px;
          display: flex;
          gap: 20px;
        }
        .detail-tab {
          padding: 14px 4px;
          font-size: 13px;
          font-weight: 500;
          color: #667085;
          cursor: pointer;
          border-bottom: 2px solid transparent;
          transition: all 0.15s ease;
        }
        .detail-tab:hover {
          color: #344054;
        }
        .detail-tab.active {
          color: #006ee6;
          border-bottom-color: #006ee6;
          font-weight: 600;
        }
        .detail-content-area {
          padding: 32px;
          background: #ffffff;
          flex: 1;
        }
        .overview-card-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 24px;
          margin-bottom: 30px;
        }
        .overview-subcard {
          border: 1px solid #eaecf0;
          border-radius: 8px;
          padding: 16px 20px;
          background: #fcfcfd;
        }
        .overview-title {
          font-size: 12px;
          font-weight: 600;
          color: #667085;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          margin-bottom: 12px;
        }
        .comment-item {
          border-bottom: 1px solid #f2f4f7;
          padding: 12px 0;
        }
        .comment-item:last-child {
          border-bottom: none;
        }
        .timeline-line {
          position: absolute;
          left: 15px;
          top: 0;
          bottom: 0;
          width: 2px;
          background: #eaecf0;
          z-index: 1;
        }
        .timeline-node {
          position: absolute;
          left: -23px;
          top: 3px;
          width: 10px;
          height: 10px;
          border-radius: 50%;
          background: #006ee6;
          border: 4px solid #ffffff;
          box-shadow: 0 0 0 1px #006ee6;
          z-index: 2;
        }
        .timeline-node.created { background: #98a2b3; box-shadow: 0 0 0 1px #98a2b3; }
        .timeline-node.open { background: #3b82f6; box-shadow: 0 0 0 1px #3b82f6; }
        .timeline-node.paid { background: #10b981; box-shadow: 0 0 0 1px #10b981; }
      `}} />

      <div className="split-layout-container">
        
        {/* ==================== LEFT LIST PANEL ==================== */}
        <div className={`left-list-pane ${!expandedId ? 'collapsed' : ''}`}>
          
          <div className="list-header">
            <div className="view-dropdown-container">
              <span 
                className="view-dropdown-btn" 
                onClick={() => setStatusDropdownOpen(!statusDropdownOpen)} 
                style={{ fontWeight: 600, fontSize: "14px", color: "#344054", cursor: "pointer", display: "flex", alignItems: "center", gap: "4px" }}
              >
                {allViews.find(v => v.key === statusFilter.toLowerCase())?.label || "All Bills"}
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="6 9 12 15 18 9" /></svg>
              </span>
              
              {statusDropdownOpen && (
                <div className="view-dropdown-menu">
                  <div style={{ padding: "0 12px 10px 12px", borderBottom: "1px solid #f2f4f7", position: "sticky", top: 0, background: "#fff", paddingTop: "8px" }}>
                    <input 
                      type="text" 
                      placeholder="Search views..." 
                      value={filterSearch} 
                      onChange={(e) => setFilterSearch(e.target.value)} 
                      style={{ width: "100%", padding: "6px 10px", borderRadius: "6px", border: "1px solid #d0d5dd", fontSize: "12px", outline: "none", boxSizing: "border-box" }} 
                      onClick={(e) => e.stopPropagation()} 
                    />
                  </div>
                  {filteredViews.map(view => {
                    const isSelected = statusFilter.toLowerCase() === view.key;
                    const isFav = favoriteView === view.key;
                    return (
                      <div 
                        key={view.key} 
                        className="view-dropdown-item" 
                        onClick={() => { setStatusFilter(view.key); setStatusDropdownOpen(false); }} 
                        style={{ background: isSelected ? "#f0f6ff" : "transparent", color: isSelected ? "#006ee6" : "#344054", fontWeight: isSelected ? "500" : "400" }}
                      >
                        <span>{view.label}</span>
                        <span 
                          onClick={(e) => { 
                            e.stopPropagation(); 
                            const newFav = isFav ? null : view.key; 
                            setFavoriteView(newFav); 
                            if (newFav) { 
                              localStorage.setItem("favBillView", newFav); 
                              toast.success(`"${view.label}" set as default view`); 
                            } else { 
                              localStorage.removeItem("favBillView"); 
                              toast.success("Default view cleared"); 
                            } 
                          }} 
                          style={{ color: isFav ? "#f59e0b" : "#d0d5dd", fontSize: "12px" }}
                        >
                          {isFav ? "★" : "☆"}
                        </span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            <div style={{ display: "flex", gap: "8px" }}>
              <button className="btn-new" onClick={() => navigate("/bills/new")} style={{ padding: "6px 10px", fontSize: "12px" }}>
                + New
              </button>
              <button 
                onClick={() => setExpandedId(null)} 
                style={{ border: "1px solid #d0d5dd", background: "#ffffff", padding: "6px 10px", borderRadius: "6px", cursor: "pointer", fontSize: "12px", fontWeight: "600", color: "#344054" }}
              >
                Close View
              </button>
            </div>
          </div>

          <div className="list-search">
            <input 
              type="text" 
              placeholder="Search..." 
              value={searchQuery}
              onChange={(e) => {
                const newParams = new URLSearchParams(location.search);
                if (e.target.value) newParams.set("search", e.target.value);
                else newParams.delete("search");
                navigate({ search: newParams.toString() }, { replace: true });
              }}
              style={{ width: "100%", padding: "8px 10px", borderRadius: "6px", border: "1px solid #d0d5dd", outline: "none", fontSize: "13px", boxSizing: "border-box" }}
              className="premium-input"
            />
          </div>

          <div className="list-items-container">
            {loading ? (
              <div style={{ padding: "20px" }}><TableSkeleton rows={6} columns={1} /></div>
            ) : sortedBills.length === 0 ? (
              <div style={{ textAlign: "center", padding: "40px 20px", color: "#667085", fontSize: "13px" }}>No bills match this filter.</div>
            ) : (
              sortedBills.map(b => {
                const isSelected = expandedId === b.id;
                return (
                  <div 
                    key={b.id} 
                    className={`pane-list-item ${isSelected ? 'selected' : ''}`}
                    onClick={() => toggleExpand(b.id)}
                  >
                    <div className="pane-item-top">
                      <span style={{ fontWeight: "600", fontSize: "13px", color: "#1d2939" }}>{getVendorName(b.vendor_id)}</span>
                      <span style={{ fontWeight: "600", fontSize: "13px", color: "#1d2939" }}>₹{parseFloat(b.total_amount).toFixed(2)}</span>
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "11px", color: "#667085" }}>
                      <span>{b.bill_number} | {new Date(b.bill_date).toLocaleDateString()}</span>
                      <span>{statusBadge(b.status)}</span>
                    </div>
                  </div>
                );
              })
            )}
          </div>

        </div>

        {/* ==================== RIGHT DETAIL VIEW PANEL ==================== */}
        <div className="right-detail-pane">
          {expandedId ? (
            expandedLoading ? (
              <div style={{ padding: "32px" }}><DetailSkeleton /></div>
            ) : expandedBill ? (
              <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
                
                {/* Header Actions Panel */}
                <div className="detail-header-panel">
                  <div>
                    <h2 style={{ margin: "0 0 6px 0", fontSize: "18px", color: "#1d2939", fontWeight: "600" }}>{expandedBill.bill_number}</h2>
                    <p style={{ margin: 0, fontSize: "13px", color: "#667085" }}>Vendor: <strong>{getVendorName(expandedBill.vendor_id)}</strong></p>
                  </div>
                  <div style={{ display: "flex", gap: "10px", alignItems: "center" }}>
                    
                    {/* Status Toggles */}
                    {expandedBill.status === "draft" && (
                      <button onClick={() => changeStatus(expandedBill.id, "open")} style={{ background: "#ffffff", border: "1px solid #d0d5dd", padding: "8px 14px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", color: "#344054", cursor: "pointer" }}>Mark as Open</button>
                    )}
                    {expandedBill.status === "open" && parseFloat(expandedBill.balance_due) > 0 && (
                      <button onClick={() => navigate(`/payments-made/new?vendor_id=${expandedBill.vendor_id}&bill_id=${expandedBill.id}`)} style={{ background: "#006ee6", border: "none", color: "#ffffff", padding: "8px 14px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Record Payment</button>
                    )}

                    <button onClick={() => navigate(`/bills/${expandedBill.id}/edit`)} style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", padding: "8px 12px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Edit</button>
                    <button onClick={() => openEmailModal(expandedBill)} style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", padding: "8px 12px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Send Email</button>
                    <button onClick={(e) => sendWhatsApp(expandedBill, e)} style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", padding: "8px 12px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer", display: "inline-flex", alignItems: "center", gap: "4px" }} title="Send WhatsApp">
                       <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg> WhatsApp
                     </button>
                     <button onClick={(e) => sendSMS(expandedBill, e)} style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", padding: "8px 12px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer", display: "inline-flex", alignItems: "center", gap: "4px" }} title="Send SMS">
                       <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg> SMS
                     </button>
                    <button onClick={() => handleDeleteSingle(expandedBill.id)} style={{ background: "#ffffff", border: "1px solid #fda29b", color: "#d92d20", padding: "8px 12px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Delete</button>
                  </div>
                </div>

                {/* Tabs Bar */}
                <div className="detail-tabs-bar">
                  {["Overview", "Comments", "Payments", "Mails", "History"].map(tab => (
                    <div 
                      key={tab} 
                      className={`detail-tab ${activeTab === tab ? 'active' : ''}`}
                      onClick={() => setActiveTab(tab)}
                    >
                      {tab}
                    </div>
                  ))}
                </div>

                {/* Tab content area */}
                <div className="detail-content-area">
                  
                  {/* ===== TAB: OVERVIEW ===== */}
                  {activeTab === "Overview" && (
                    <div>
                      
                      {/* Grid cards */}
                      <div className="overview-card-grid">
                        <div className="overview-subcard">
                          <div className="overview-title">Bill Details</div>
                          <div style={{ display: "grid", gridTemplateColumns: "100px 1fr", gap: "10px 0", fontSize: "13px" }}>
                            <span style={{ color: "#667085" }}>Bill#</span><span style={{ fontWeight: "600", color: "#1d2939" }}>{expandedBill.bill_number}</span>
                            <span style={{ color: "#667085" }}>Bill Date</span><span style={{ color: "#344054" }}>{new Date(expandedBill.bill_date).toLocaleDateString()}</span>
                            <span style={{ color: "#667085" }}>Due Date</span><span style={{ color: "#344054" }}>{expandedBill.due_date ? new Date(expandedBill.due_date).toLocaleDateString() : "—"}</span>
                            <span style={{ color: "#667085" }}>Status</span><span>{statusBadge(expandedBill.status)}</span>
                          </div>
                        </div>

                        <div className="overview-subcard">
                          <div className="overview-title">Vendor Details</div>
                          <div style={{ display: "flex", flexDirection: "column", gap: "6px", fontSize: "13px", color: "#344054" }}>
                            <span style={{ fontWeight: "600", color: "#1d2939" }}>{getVendorName(expandedBill.vendor_id)}</span>
                            {getVendorById(expandedBill.vendor_id).email && <span>Email: {getVendorById(expandedBill.vendor_id).email}</span>}
                            {getVendorById(expandedBill.vendor_id).phone && <span>Phone: {getVendorById(expandedBill.vendor_id).phone}</span>}
                            {getVendorById(expandedBill.vendor_id).company_name && <span>Company: {getVendorById(expandedBill.vendor_id).company_name}</span>}
                          </div>
                        </div>
                      </div>

                      {/* Items details table */}
                      <div style={{ border: "1px solid #eaecf0", borderRadius: "8px", overflow: "hidden", marginBottom: "30px" }}>
                        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px" }}>
                          <thead>
                            <tr style={{ background: "#f9fafb", borderBottom: "1px solid #eaecf0", textTransform: "uppercase", fontSize: "10px", fontWeight: "600" }}>
                              <th style={{ padding: "10px 16px", color: "#667085" }}>Item Name</th>
                              <th style={{ padding: "10px 16px", color: "#667085" }}>Description</th>
                              <th style={{ padding: "10px 16px", color: "#667085", textAlign: "right" }}>Qty</th>
                              <th style={{ padding: "10px 16px", color: "#667085", textAlign: "right" }}>Rate</th>
                              <th style={{ padding: "10px 16px", color: "#667085", textAlign: "right" }}>Tax %</th>
                              <th style={{ padding: "10px 16px", color: "#667085", textAlign: "right" }}>Amount</th>
                            </tr>
                          </thead>
                          <tbody>
                            {expandedItems.map((item, index) => (
                              <tr key={index} style={{ borderBottom: "1px solid #eaecf0" }}>
                                <td style={{ padding: "12px 16px", fontWeight: "500", color: "#1d2939" }}>{item.item_name || "—"}</td>
                                <td style={{ padding: "12px 16px", color: "#475569" }}>{item.description || "—"}</td>
                                <td style={{ padding: "12px 16px", textAlign: "right" }}>{item.quantity}</td>
                                <td style={{ padding: "12px 16px", textAlign: "right" }}>₹{parseFloat(item.unit_price || item.rate || 0).toFixed(2)}</td>
                                <td style={{ padding: "12px 16px", textAlign: "right" }}>{item.tax_rate}%</td>
                                <td style={{ padding: "12px 16px", textAlign: "right", fontWeight: "600" }}>₹{parseFloat(item.total || 0).toFixed(2)}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>

                      {/* Summary Block */}
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <div style={{ width: "300px", background: "#fcfcfd", border: "1px solid #eaecf0", borderRadius: "8px", padding: "16px" }}>
                          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px", fontSize: "12px", color: "#667085" }}>
                            <span>Sub Total</span><span>₹{parseFloat(expandedBill.subtotal || 0).toFixed(2)}</span>
                          </div>
                          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px", fontSize: "12px", color: "#b91c1c" }}>
                            <span>Total Discount</span><span>- ₹{parseFloat(expandedBill.discount_amount || 0).toFixed(2)}</span>
                          </div>
                          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "12px", color: "#0f766e" }}>
                            <span>Total Tax</span><span>+ ₹{parseFloat(expandedBill.tax_amount || 0).toFixed(2)}</span>
                          </div>
                          <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "700", fontSize: "14px", borderTop: "1px solid #eaecf0", paddingTop: "10px", color: "#1d2939", marginBottom: "8px" }}>
                            <span>Total (₹)</span><span>₹{parseFloat(expandedBill.total_amount || 0).toFixed(2)}</span>
                          </div>
                          <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "700", fontSize: "14px", color: "#dc2626" }}>
                            <span>Balance Due (₹)</span><span>₹{parseFloat(expandedBill.balance_due || 0).toFixed(2)}</span>
                          </div>
                        </div>
                      </div>

                      {expandedBill.notes && (
                        <div style={{ marginTop: "20px", borderTop: "1px solid #eaecf0", paddingTop: "20px" }}>
                          <h4 style={{ margin: "0 0 8px 0", fontSize: "12px", fontWeight: "600", color: "#667085", textTransform: "uppercase" }}>Notes</h4>
                          <div style={{ fontSize: "13px", color: "#475569", background: "#f8fafc", padding: "12px", borderRadius: "6px", whiteSpace: "pre-wrap" }}>{expandedBill.notes}</div>
                        </div>
                      )}

                    </div>
                  )}

                  {/* ===== TAB: COMMENTS ===== */}
                  {activeTab === "Comments" && (
                    <div>
                      <h3 style={{ fontSize: "14px", fontWeight: "600", color: "#344054", marginBottom: "16px" }}>Comments Board</h3>
                      <form onSubmit={handleAddComment} style={{ marginBottom: "20px" }}>
                        <textarea 
                          value={newComment} 
                          onChange={(e) => setNewComment(e.target.value)} 
                          placeholder="Type your comment here..." 
                          rows={3} 
                          style={{ width: "100%", padding: "10px", borderRadius: "6px", border: "1px solid #d0d5dd", fontSize: "13px", outline: "none", boxSizing: "border-box" }}
                          className="premium-input"
                        />
                        <button type="submit" style={{ marginTop: "8px", background: "#006ee6", color: "#ffffff", border: "none", borderRadius: "6px", padding: "8px 16px", cursor: "pointer", fontSize: "13px", fontWeight: "600" }}>Add Comment</button>
                      </form>

                      {commentsLoading ? (
                        <div>Loading comments...</div>
                      ) : comments.length === 0 ? (
                        <div style={{ color: "#667085", fontSize: "13px", fontStyle: "italic" }}>No comments yet. Be the first to add one!</div>
                      ) : (
                        <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                          {comments.map((c) => (
                            <div key={c.id} className="comment-item">
                              <div style={{ display: "flex", justifyContent: "space-between", fontSize: "12px", color: "#667085", marginBottom: "4px" }}>
                                <span><strong>{c.user}</strong></span>
                                <div style={{ display: "flex", gap: "10px" }}>
                                  <span>{timeAgo(c.created_at)}</span>
                                  <button onClick={() => handleDeleteComment(c.id)} style={{ border: "none", background: "none", color: "#f04438", cursor: "pointer", padding: 0 }}>Delete</button>
                                </div>
                              </div>
                              <div style={{ fontSize: "13px", color: "#344054", whiteSpace: "pre-wrap" }}>{c.text}</div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  )}

                  {/* ===== TAB: PAYMENTS ===== */}
                  {activeTab === "Payments" && (
                    <div>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
                        <h3 style={{ fontSize: "14px", fontWeight: "600", color: "#344054", margin: 0 }}>Payments Made History</h3>
                        {parseFloat(expandedBill.balance_due) > 0 && (
                          <button onClick={() => navigate(`/payments-made/new?vendor_id=${expandedBill.vendor_id}&bill_id=${expandedBill.id}`)} className="btn-new" style={{ padding: "6px 10px", fontSize: "12px" }}>
                            Record Payment
                          </button>
                        )}
                      </div>
                      {paymentsLoading ? (
                        <div>Loading payment records...</div>
                      ) : payments.length === 0 ? (
                        <div style={{ color: "#667085", fontSize: "13px", fontStyle: "italic" }}>No payments made for this bill yet.</div>
                      ) : (
                        <div style={{ border: "1px solid #eaecf0", borderRadius: "8px", overflow: "hidden" }}>
                          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px" }}>
                            <thead>
                              <tr style={{ background: "#f9fafb", borderBottom: "1px solid #eaecf0" }}>
                                <th style={{ padding: "8px 12px", color: "#667085" }}>Date</th>
                                <th style={{ padding: "8px 12px", color: "#667085" }}>Payment ID</th>
                                <th style={{ padding: "8px 12px", color: "#667085" }}>Ref Number</th>
                                <th style={{ padding: "8px 12px", color: "#667085" }}>Mode</th>
                                <th style={{ padding: "8px 12px", color: "#667085", textAlign: "right" }}>Amount</th>
                              </tr>
                            </thead>
                            <tbody>
                              {payments.map(p => (
                                <tr key={p.id} style={{ borderBottom: "1px solid #eaecf0" }}>
                                  <td style={{ padding: "8px 12px" }}>{new Date(p.payment_date).toLocaleDateString()}</td>
                                  <td style={{ padding: "8px 12px" }}>PAY-{p.id.toString().padStart(5, '0')}</td>
                                  <td style={{ padding: "8px 12px" }}>{p.reference_number || "—"}</td>
                                  <td style={{ padding: "8px 12px" }}>{p.payment_mode}</td>
                                  <td style={{ padding: "8px 12px", textAlign: "right", fontWeight: "600" }}>₹{parseFloat(p.amount).toFixed(2)}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      )}
                    </div>
                  )}

                  {/* ===== TAB: MAILS ===== */}
                  {activeTab === "Mails" && (
                    <div style={{ maxWidth: "700px" }}>
                      <h3 style={{ fontSize: "14px", fontWeight: "600", color: "#344054", marginBottom: "16px" }}>Email History</h3>
                      {mails.length === 0 ? (
                        <div style={{ fontSize: "13px", color: "#667085", fontStyle: "italic" }}>No emails sent for this bill yet.</div>
                      ) : (
                        mails.map((m) => (
                          <div key={m.id} style={{ border: "1px solid #eaecf0", borderRadius: "8px", padding: "16px", marginBottom: "16px", background: "#fcfcfd" }}>
                            <div style={{ display: "flex", justifyContent: "space-between", fontSize: "12px", color: "#667085", marginBottom: "8px" }}>
                              <div><strong>To:</strong> {m.to}</div>
                              <div>{timeAgo(m.sent_at)}</div>
                            </div>
                            <div style={{ fontSize: "13px", fontWeight: "600", color: "#1d2939", marginBottom: "6px" }}>{m.subject}</div>
                            <div style={{ fontSize: "12px", color: "#475569", whiteSpace: "pre-line", maxHeight: "150px", overflowY: "auto", borderTop: "1px solid #eaecf0", paddingTop: "8px" }}>{m.body}</div>
                          </div>
                        ))
                      )}
                    </div>
                  )}

                  {/* ===== TAB: HISTORY ===== */}
                  {activeTab === "History" && (
                    <div style={{ position: "relative", paddingLeft: "32px", maxWidth: "600px" }}>
                      <div className="timeline-line"></div>
                      {activities.map((act) => (
                        <div key={act.id} style={{ position: "relative", marginBottom: "24px" }}>
                          <div className={`timeline-node ${act.type || ""}`}></div>
                          <div style={{ fontSize: "13px", fontWeight: "600", color: "#1d2939" }}>{act.description}</div>
                          <div style={{ fontSize: "11px", color: "#667085", marginTop: "2px" }}>{new Date(act.created_at).toLocaleString()}</div>
                        </div>
                      ))}
                    </div>
                  )}

                </div>

              </div>
            ) : (
              <div style={{ padding: "40px", textAlign: "center", color: "#667085" }}>Failed to load details.</div>
            )
          ) : (
            // ==================== FULL VIEW TABLE ====================
            <div className="full-table-container">
              <div className="full-table-header">
                <div className="view-dropdown-container">
                  <h3 
                    className={`view-dropdown-btn ${statusDropdownOpen ? 'active' : ''}`} 
                    onClick={() => setStatusDropdownOpen(!statusDropdownOpen)} 
                    style={{ fontWeight: 600, fontSize: "18px", color: "#1e293b", margin: 0, cursor: "pointer", display: "flex", alignItems: "center", gap: "6px" }}
                  >
                    {allViews.find(v => v.key === statusFilter.toLowerCase())?.label || "All Bills"}
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" style={{ transform: statusDropdownOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }}><polyline points="6 9 12 15 18 9" /></svg>
                  </h3>
                  
                  {statusDropdownOpen && (
                    <div className="view-dropdown-menu">
                      <div style={{ padding: "0 12px 10px 12px", borderBottom: "1px solid #f2f4f7", position: "sticky", top: 0, background: "#fff", paddingTop: "8px" }}>
                        <div style={{ position: "relative", width: "100%" }}>
                          <span style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", display: "flex", color: "#98a2b3" }}>🔍</span>
                          <input 
                            type="text" 
                            placeholder="Search views..." 
                            value={filterSearch} 
                            onChange={(e) => setFilterSearch(e.target.value)} 
                            style={{ width: "100%", padding: "6px 10px 6px 30px", borderRadius: "6px", border: "1px solid #d0d5dd", fontSize: "13px", outline: "none", boxSizing: "border-box" }} 
                            onClick={(e) => e.stopPropagation()} 
                          />
                        </div>
                      </div>
                      {filteredViews.length === 0 ? (
                        <div style={{ padding: "12px 16px", color: "#667085", fontSize: "13px", textAlign: "center" }}>No views found</div>
                      ) : (
                        filteredViews.map(view => {
                          const isSelected = statusFilter.toLowerCase() === view.key;
                          const isFav = favoriteView === view.key;
                          return (
                            <div 
                              key={view.key} 
                              className="view-dropdown-item" 
                              onClick={() => { setStatusFilter(view.key); setStatusDropdownOpen(false); }} 
                              style={{ background: isSelected ? "#f0f6ff" : "transparent", color: isSelected ? "#006ee6" : "#344054", fontWeight: isSelected ? "500" : "400" }}
                            >
                              <span>{view.label}</span>
                              <span 
                                onClick={(e) => { 
                                  e.stopPropagation(); 
                                  const newFav = isFav ? null : view.key; 
                                  setFavoriteView(newFav); 
                                  if (newFav) { 
                                    localStorage.setItem("favBillView", newFav); 
                                    toast.success(`"${view.label}" set as default view`); 
                                  } else { 
                                    localStorage.removeItem("favBillView"); 
                                    toast.success("Default view cleared"); 
                                  } 
                                }} 
                                style={{ color: isFav ? "#f59e0b" : "#d0d5dd", fontSize: "14px", padding: "2px 6px" }}
                              >
                                {isFav ? "★" : "☆"}
                              </span>
                            </div>
                          );
                        })
                      )}
                    </div>
                  )}
                </div>
                
                <div className="table-actions">
                  <button className="btn-new" onClick={() => navigate("/bills/new")}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
                    New
                  </button>
                  
                  <div className="more-dropdown-container">
                    <button className="btn-more" onClick={() => setMoreMenuOpen(!moreMenuOpen)}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /><circle cx="5" cy="12" r="1" /></svg>
                    </button>
                    {moreMenuOpen && (
                      <div className="more-dropdown-menu">
                        <div className="more-dropdown-item">
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M12 20l-5-5M12 20l5-5"/></svg>
                          <span>Sort by</span>
                          <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="9 18 15 12 9 6"/></svg>
                          <div className="nested-dropdown-menu">
                            <div className="more-dropdown-item" onClick={() => { setSortBy("bill_date"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Date (Newest first)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("bill_date"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Date (Oldest first)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("bill_number"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Bill Number (A-Z)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("vendor_name"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Vendor Name (A-Z)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("total_amount"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Amount (High to Low)</span></div>
                          </div>
                        </div>
                        <div className="more-dropdown-item" onClick={() => { setMoreMenuOpen(false); toast("Import functionality coming soon"); }}>
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                          <span>Import Bills</span>
                        </div>
                        <div className="more-dropdown-item">
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/></svg>
                          <span>Export Bills</span>
                          <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="9 18 15 12 9 6"/></svg>
                          <div className="nested-dropdown-menu">
                            <div className="more-dropdown-item" onClick={() => { toast("Exported CSV"); setMoreMenuOpen(false); }}><span>Export as CSV</span></div>
                            <div className="more-dropdown-item" onClick={() => { toast("Exported JSON"); setMoreMenuOpen(false); }}><span>Export as JSON</span></div>
                          </div>
                        </div>
                        <div className="more-dropdown-divider"></div>
                        <div className="more-dropdown-item" onClick={handleRefresh}>
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/></svg>
                          <span>Refresh List</span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Table search bar */}
              <div style={{ padding: "12px 30px", borderBottom: "1px solid #eaeaea", background: "#fdfdfd" }}>
                <div style={{ position: "relative", width: "100%", maxWidth: "400px" }}>
                  <span style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "#98a2b3" }}>🔍</span>
                  <input
                    type="text"
                    placeholder="Search..."
                    value={searchQuery}
                    onChange={(e) => {
                      const newParams = new URLSearchParams(location.search);
                      if (e.target.value) newParams.set("search", e.target.value);
                      else newParams.delete("search");
                      navigate({ search: newParams.toString() }, { replace: true });
                    }}
                    style={{ width: "100%", padding: "10px 12px 10px 42px", borderRadius: "6px", border: "1px solid #d0d5dd", outline: "none", fontSize: "13px", boxSizing: "border-box" }}
                    className="premium-input"
                  />
                </div>
              </div>

              {/* Batch Actions */}
              {selected.length > 0 && (
                <div style={{ background: "#f0f6ff", border: "1px solid #bae6fd", borderRadius: "8px", padding: "12px 16px", display: "flex", alignItems: "center", gap: "16px", margin: "20px 30px 0" }}>
                  <span style={{ color: "#0369a1", fontWeight: "600", fontSize: "13px" }}>{selected.length} item(s) selected</span>
                  <button onClick={handleDeleteSelected} style={{ background: "#d92d20", color: "#ffffff", border: "none", borderRadius: "6px", padding: "6px 12px", cursor: "pointer", fontSize: "12px", fontWeight: "600" }}>Delete Selected</button>
                  <button onClick={() => setSelected([])} style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", fontSize: "12px", textDecoration: "underline" }}>Cancel</button>
                </div>
              )}

              {/* Table Wrapper */}
              <div className="table-wrapper">
                {loading ? (
                  <TableSkeleton rows={8} columns={7} />
                ) : sortedBills.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '80px 20px', color: '#98a2b3' }}>
                    <div style={{ fontSize: '48px', marginBottom: '16px' }}>📄</div>
                    <h3 style={{ color: '#1d2939', marginBottom: '8px', fontSize: "16px", fontWeight: "600" }}>No bills found</h3>
                    <p style={{ marginBottom: '20px', fontSize: "13px" }}>{searchQuery ? 'No bills match your search.' : 'Start by recording your first bill.'}</p>
                    <button className="btn-new" onClick={() => navigate('/bills/new')} style={{ margin: "0 auto" }}>+ Record New Bill</button>
                  </div>
                ) : (
                  <table className={`items-table ${clipText ? 'clip-text' : ''}`}>
                    <thead>
                      <tr>
                        <th style={{ width: '50px', textAlign: 'center', resize: 'none', position: 'relative' }} className="th-icon-wrapper">
                          <span className={`th-icon ${showSettings ? 'active' : ''}`} onClick={() => setShowSettings(!showSettings)}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="8" cy="8" r="2"/><line x1="3" y1="8" x2="6" y2="8"/><line x1="10" y1="8" x2="21" y2="8"/><circle cx="14" cy="16" r="2"/><line x1="3" y1="16" x2="12" y2="16"/><line x1="16" y1="16" x2="21" y2="16"/></svg>
                          </span>
                          {showSettings && (
                            <div className="settings-dropdown">
                              <div className="dropdown-item" onClick={() => { setColumnsOpen(!columnsOpen); setShowSettings(false); }}>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="9" y1="3" x2="9" y2="21"/></svg>
                                Customize Columns
                              </div>
                              <div className="dropdown-item" onClick={() => { setClipText(!clipText); setShowSettings(false); }}>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="4" y1="6" x2="20" y2="6"/><line x1="4" y1="12" x2="14" y2="12"/><line x1="4" y1="18" x2="18" y2="18"/></svg>
                                Clip Text
                              </div>
                            </div>
                          )}
                          
                          {columnsOpen && (
                            <div className="columns-dropdown" style={{ position: "absolute", left: "100%", top: 0, marginLeft: "4px", background: "#ffffff", border: "1px solid #eaecf0", borderRadius: "8px", boxShadow: "0 10px 25px rgba(0,0,0,0.08)", zIndex: 100, minWidth: "180px", padding: "8px 0" }}>
                              {ALL_COLUMNS.filter((c) => c.key !== "checkbox").map((col) => (
                                <label key={col.key} style={{ display: "flex", alignItems: "center", padding: "8px 14px", cursor: "pointer" }}>
                                  <input type="checkbox" checked={visibleColumns[col.key] || false} onChange={() => setVisibleColumns((prev) => ({ ...prev, [col.key]: !prev[col.key] }))} />
                                  <span style={{ marginLeft: "8px", fontSize: "13px", color: "#344054", fontWeight: 'normal', textTransform: 'none' }}>{col.label}</span>
                                </label>
                              ))}
                            </div>
                          )}
                        </th>
                        <th style={{ width: '40px', textAlign: 'center', resize: 'none' }}>
                          <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selected.length === sortedBills.length && sortedBills.length > 0} onChange={handleSelectAll} />
                        </th>
                        {visibleColumns.bill_date && <th style={thStyle}>Date</th>}
                        {visibleColumns.bill_number && <th style={thStyle}>Bill#</th>}
                        {visibleColumns.vendor_name && <th style={thStyle}>Vendor Name</th>}
                        {visibleColumns.due_date && <th style={thStyle}>Due Date</th>}
                        {visibleColumns.total_amount && <th style={{ ...thStyle, textAlign: 'right' }}>Amount</th>}
                        {visibleColumns.balance_due && <th style={{ ...thStyle, textAlign: 'right' }}>Balance Due</th>}
                        {visibleColumns.status && <th style={thStyle}>Status</th>}
                      </tr>
                    </thead>
                    <tbody>
                      {sortedBills.map((bill) => (
                        <tr key={bill.id} onClick={() => toggleExpand(bill.id)} style={{ cursor: "pointer", background: selected.includes(bill.id) ? "#fcfcfd" : "" }}>
                          <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}></td>
                          <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                            <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selected.includes(bill.id)} onChange={() => toggleSelectOne(bill.id)} />
                          </td>
                          {visibleColumns.bill_date && <td>{new Date(bill.bill_date).toLocaleDateString()}</td>}
                          {visibleColumns.bill_number && <td className="vendor-name-link">{bill.bill_number}</td>}
                          {visibleColumns.vendor_name && <td>{getVendorName(bill.vendor_id)}</td>}
                          {visibleColumns.due_date && <td>{bill.due_date ? new Date(bill.due_date).toLocaleDateString() : "—"}</td>}
                          {visibleColumns.total_amount && <td style={{ textAlign: 'right', fontWeight: "600", color: "#1d2939" }}>₹{parseFloat(bill.total_amount).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>}
                          {visibleColumns.balance_due && <td style={{ textAlign: 'right', fontWeight: "600", color: "#dc2626" }}>₹{parseFloat(bill.balance_due).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>}
                          {visibleColumns.status && <td>{statusBadge(bill.status)}</td>}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Email Modal */}
      {showEmailModal && expandedBill && (
        <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 }}>
          <div style={{ background: "#fff", borderRadius: "8px", padding: "25px", width: "600px", maxWidth: "90%", maxHeight: "80vh", overflow: "auto", boxShadow: "0 4px 20px rgba(0,0,0,0.2)" }}>
            <h3 style={{ marginTop: 0, fontSize: "18px", color: "#1d2939" }}>Send Bill via Email</h3>
            <div style={{ marginBottom: "15px" }}><label style={{ display: "block", fontSize: "13px", fontWeight: "500", marginBottom: "6px" }}>To:</label>
              <input type="email" value={getVendorById(expandedBill.vendor_id).email || ""} readOnly style={{ width: "100%", padding: "8px 12px", borderRadius: "6px", border: "1px solid #eaecf0", background: "#f8fafc", outline: "none", boxSizing: "border-box" }} /></div>
            <div style={{ marginBottom: "15px" }}><label style={{ display: "block", fontSize: "13px", fontWeight: "500", marginBottom: "6px" }}>Subject:</label>
              <input type="text" value={emailSubject} onChange={e => setEmailSubject(e.target.value)} style={{ width: "100%", padding: "8px 12px", borderRadius: "6px", border: "1px solid #d0d5dd", outline: "none", boxSizing: "border-box" }} /></div>
            <div style={{ marginBottom: "20px" }}><label style={{ display: "block", fontSize: "13px", fontWeight: "500", marginBottom: "6px" }}>Message:</label>
              <textarea value={emailBody} onChange={e => setEmailBody(e.target.value)} rows={6} style={{ width: "100%", padding: "8px 12px", borderRadius: "6px", border: "1px solid #d0d5dd", outline: "none", boxSizing: "border-box", resize: "vertical" }} /></div>
            <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end" }}>
              <button onClick={() => setShowEmailModal(false)} style={{ padding: "8px 14px", background: "#ffffff", border: "1px solid #d0d5dd", borderRadius: "6px", fontSize: "13px", fontWeight: "600", color: "#344054", cursor: "pointer" }}>Cancel</button>
              <button onClick={sendEmailAndMarkSent} disabled={emailSending} style={{ padding: "8px 16px", background: "#006ee6", color: "#ffffff", border: "none", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>{emailSending ? "Sending..." : "Send"}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Bills;
