/**
 * PurchaseOrders.js – Redesigned Purchase Orders List UI matching Vendors UI
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

const tdStyle = {
  padding: "12px 14px",
  verticalAlign: "middle",
};

const STATUS_COLORS = {
  draft:     { bg: "#f1f5f9", color: "#475569", label: "DRAFT" },
  issued:    { bg: "#dcfce7", color: "#166534", label: "ISSUED" },
  billed:    { bg: "#eff6ff", color: "#1d4ed8", label: "BILLED" },
  cancelled: { bg: "#fef2f2", color: "#991b1b", label: "CANCELLED" },
};

const ALL_COLUMNS = [
  { key: "checkbox", label: "☐" },
  { key: "purchase_order_date", label: "Date" },
  { key: "purchase_order_number", label: "Purchase Order#" },
  { key: "reference_number", label: "Reference#" },
  { key: "vendor_name", label: "Vendor Name" },
  { key: "status", label: "Status" },
  { key: "total_amount", label: "Amount" },
  { key: "billed_status", label: "Billed Status" },
  { key: "delivery_date", label: "Delivery Date" },
  { key: "company_name", label: "Company Name" },
  { key: "received", label: "Received" },
  { key: "expected_delivery_date", label: "Expected Delivery Date" },
];

function PurchaseOrders() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const searchParamsUrl = new URLSearchParams(location.search);
  const searchQuery = searchParamsUrl.get("search") || "";

  const [purchaseOrders, setPurchaseOrders] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState([]);
  const [menuOpen, setMenuOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState("all");
  const [favoriteView, setFavoriteView] = useState(() => localStorage.getItem("favPOView") || null);
  const [statusDropdownOpen, setStatusDropdownOpen] = useState(false);
  const [filterSearch, setFilterSearch] = useState("");
  
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [sortBy, setSortBy] = useState("purchase_order_date");
  const [sortOrder, setSortOrder] = useState("desc");

  const [showSettings, setShowSettings] = useState(false);
  const [clipText, setClipText] = useState(true);
  const [columnsOpen, setColumnsOpen] = useState(false);
  const [visibleColumns, setVisibleColumns] = useState({
    purchase_order_date: true,
    purchase_order_number: true,
    reference_number: true,
    vendor_name: true,
    status: true,
    total_amount: true,
    billed_status: false,
    delivery_date: false,
    company_name: false,
    received: false,
    expected_delivery_date: false,
  });

  useEffect(() => {
    const h = (e) => {
      if (!e.target.closest('.th-icon-wrapper') && !e.target.closest('.settings-dropdown') && !e.target.closest('.columns-dropdown')) {
        setShowSettings(false);
        setColumnsOpen(false);
      }
      if (!e.target.closest('.view-dropdown-container')) {
        setMenuOpen(false);
        setStatusDropdownOpen(false);
      }
      if (!e.target.closest('.more-dropdown-container')) setMoreMenuOpen(false);
    };
    document.addEventListener('click', h);
    return () => document.removeEventListener('click', h);
  }, []);

  const [expandedId, setExpandedId] = useState(null);
  const [expandedPO, setExpandedPO] = useState(null);
  const [expandedItems, setExpandedItems] = useState([]);
  const [expandedLoading, setExpandedLoading] = useState(false);
  const [activeTab, setActiveTab] = useState("Overview");

  // Local/Mocks for tabs
  const [comments, setComments] = useState([]);
  const [newComment, setNewComment] = useState("");
  const [commentsLoading, setCommentsLoading] = useState(false);

  const [activities, setActivities] = useState([]);
  const [bills, setBills] = useState([]);
  const [billsLoading, setBillsLoading] = useState(false);
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

  const getVendorCompany = (vendorId) => {
    if (!vendorId) return "—";
    const vend = vendors.find(v => v.id === vendorId);
    return vend ? vend.company_name || vend.display_name || "—" : "—";
  };

  const getVendorById = (vendorId) => vendors.find(v => v.id === vendorId) || {};

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const [poRes, vendorsRes] = await Promise.all([
        apiRequest("/purchase-orders"),
        apiRequest("/vendors"),
      ]);
      setPurchaseOrders(Array.isArray(poRes?.purchase_orders) ? poRes.purchase_orders : []);
      setVendors(Array.isArray(vendorsRes?.vendors) ? vendorsRes.vendors : []);
    } catch (err) {
      toast.error("Failed to load data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData, location.state?.refresh]);

  useEffect(() => {
    const fav = localStorage.getItem("favPOView");
    if (fav) {
      setStatusFilter(fav);
    }
  }, []);

  const fetchComments = useCallback(async (poId) => {
    setCommentsLoading(true);
    try {
      const stored = localStorage.getItem(`po_comments_${poId}`);
      setComments(stored ? JSON.parse(stored) : []);
    } catch (err) {
      console.error(err);
    } finally {
      setCommentsLoading(false);
    }
  }, []);

  const handleAddComment = async () => {
    if (!newComment.trim() || !expandedId) return;
    const commentObj = {
      id: Date.now(),
      comment: newComment,
      created_at: new Date().toISOString(),
      user: { name: user?.name || "User" }
    };
    const updated = [...comments, commentObj];
    setComments(updated);
    localStorage.setItem(`po_comments_${expandedId}`, JSON.stringify(updated));
    setNewComment("");
    toast.success("Comment added");
  };

  const fetchBillsData = async (poId) => {
    setBillsLoading(true);
    try {
      const res = await apiRequest("/bills");
      if (res && res.bills) {
        const filtered = res.bills.filter(b => b.purchase_order_id === poId);
        setBills(filtered);
      }
    } catch (err) {
      console.error("Failed to fetch bills", err);
    } finally {
      setBillsLoading(false);
    }
  };

  const fetchActivities = useCallback(async (po) => {
    if (!po) return;
    const list = [
      { id: 1, description: "Purchase Order Created", created_at: po.purchase_order_date, type: "success" }
    ];
    if (po.expected_delivery_date) {
      list.push({ id: 2, description: `Expected delivery date set to ${new Date(po.expected_delivery_date).toLocaleDateString()}`, created_at: po.purchase_order_date, type: "primary" });
    }
    if (po.status === "Issued" || po.status === "Billed") {
      list.push({ id: 3, description: "Purchase Order Marked as Issued", created_at: new Date().toISOString(), type: "success" });
    }
    if (po.status === "Billed") {
      list.push({ id: 4, description: "Converted to Bill", created_at: new Date().toISOString(), type: "primary" });
    }
    if (po.status === "Cancelled") {
      list.push({ id: 5, description: "Purchase Order Cancelled", created_at: new Date().toISOString(), type: "warning" });
    }
    setActivities(list);
  }, []);

  const fetchMails = (poId) => {
    const stored = localStorage.getItem(`po_mails_${poId}`);
    setMails(stored ? JSON.parse(stored) : []);
  };

  const toggleExpand = async (id) => {
    if (expandedId === id) {
      setExpandedId(null);
      setExpandedPO(null);
      setExpandedItems([]);
      setActiveTab("Overview");
      setComments([]);
      setBills([]);
      setActivities([]);
      setMails([]);
      return;
    }
    setExpandedId(id);
    setExpandedLoading(true);
    setActiveTab("Overview");
    setComments([]);
    setBills([]);
    setActivities([]);
    setMails([]);
    try {
      const res = await apiRequest(`/purchase-orders/${id}`);
      if (res?.purchase_order) {
        setExpandedPO(res.purchase_order);
        setExpandedItems(res.items || []);
        fetchComments(id);
        fetchBillsData(id);
        fetchActivities(res.purchase_order);
        fetchMails(id);
      }
    } catch (err) {
      toast.error("Failed to load details");
      setExpandedId(null);
    } finally {
      setExpandedLoading(false);
    }
  };

  const changeStatus = async (poId, newStatus) => {
    try {
      await apiRequest(`/purchase-orders/${poId}`, { method: "PUT", body: JSON.stringify({ status: newStatus }) });
      toast.success(`Marked as ${newStatus}`);
      setPurchaseOrders(prev => prev.map(p => p.id === poId ? { ...p, status: newStatus } : p));
      if (expandedPO?.id === poId) {
        const updatedPO = { ...expandedPO, status: newStatus };
        setExpandedPO(updatedPO);
        fetchActivities(updatedPO);
      }
    } catch (err) {
      toast.error("Failed to update status");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this purchase order?")) return;
    try {
      await apiRequest(`/purchase-orders/${id}`, { method: "DELETE" });
      toast.success("Purchase Order deleted");
      if (expandedId === id) {
        setExpandedId(null);
        setExpandedPO(null);
        setExpandedItems([]);
      }
      fetchData();
    } catch (err) {
      toast.error("Delete failed");
    }
  };

  const handleConvertToBill = async (poId) => {
    if (!window.confirm("Convert this Purchase Order to a Bill?")) return;
    try {
      const res = await apiRequest(`/purchase-orders/${poId}/convert-to-bill`, { method: "POST" });
      if (res?.alreadyConverted) {
        toast("Already converted. Opening existing bill.", { icon: "ℹ️" });
        navigate(`/bills/${res.billId}`);
        return;
      }
      toast.success("Purchase Order converted to Bill!");
      setPurchaseOrders(prev => prev.map(p => p.id === poId ? { ...p, status: "Billed" } : p));
      if (expandedPO?.id === poId) {
        const updatedPO = { ...expandedPO, status: "Billed" };
        setExpandedPO(updatedPO);
        fetchActivities(updatedPO);
      }
      navigate(`/bills/${res.billId}`);
    } catch (err) {
      toast.error("Conversion failed");
    }
  };

  const openEmailModal = (po) => {
    const vend = getVendorById(po.vendor_id);
    const orgName = user?.organization_name || "My Organization";
    setEmailSubject(`Purchase Order ${po.purchase_order_number} from ${orgName}`);
    setEmailBody(`Dear ${vend.display_name || vend.company_name || "Vendor"},\n\nPlease find our Purchase Order attached.\n\nPurchase Order Number: ${po.purchase_order_number}\nTotal: ₹${parseFloat(po.total_amount).toFixed(2)}\n\nThank you.\n\nRegards,\n${orgName}`);
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

  const getCondensedPOMessage = (po) => {
    const vend = getVendorById(po.vendor_id);
    const vendName = vend.display_name || vend.company_name || "Vendor";
    const docNumber = po.purchase_order_number || "";
    const totalAmt = parseFloat(po.total_amount || 0).toFixed(2);
    const orgName = user?.organization_name || "My Organization";
    return `Dear ${vendName}, please find our Purchase Order ${docNumber}. Total: ₹${totalAmt}. Thank you. Regards, ${orgName}.`;
  };

  const sendWhatsApp = (po, e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    const vend = getVendorById(po.vendor_id);
    const phoneVal = vend?.mobile || vend?.phone || vend?.work_phone;
    const cleanedPhone = cleanPhone(phoneVal);
    if (!cleanedPhone) {
      toast.error("Phone number not available");
      return;
    }
    const message = getCondensedPOMessage(po);
    window.location.href = `whatsapp://send?phone=${cleanedPhone}&text=${encodeURIComponent(message)}`;
    
    setTimeout(() => {
      if (document.hasFocus()) {
        window.open(`https://wa.me/${cleanedPhone}?text=${encodeURIComponent(message)}`, "_blank");
      }
    }, 1500);
  };

  const sendSMS = (po, e) => {
    if (e && e.stopPropagation) e.stopPropagation();
    const vend = getVendorById(po.vendor_id);
    const phoneVal = vend?.mobile || vend?.phone || vend?.work_phone;
    const cleanedPhone = cleanPhone(phoneVal);
    if (!cleanedPhone) {
      toast.error("Phone number not available");
      return;
    }
    const message = getCondensedPOMessage(po);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const separator = isIOS ? "&" : "?";
    window.location.href = `sms:${cleanedPhone}${separator}body=${encodeURIComponent(message)}`;
  };

  const sendEmailAndMarkSent = async () => {
    const po = expandedPO;
    if (!po) return;
    setEmailSending(true);
    try {
      await apiRequest(`/purchase-orders/${po.id}/send`, {
        method: "POST",
        body: JSON.stringify({ to: getVendorById(po.vendor_id).email || "", subject: emailSubject, body: emailBody }),
      });
      toast.success("Email sent!");
      setShowEmailModal(false);

      // Save mail log
      const newMail = {
        id: Date.now(),
        to: getVendorById(po.vendor_id).email || "",
        subject: emailSubject,
        body: emailBody,
        sent_at: new Date().toISOString()
      };
      const stored = localStorage.getItem(`po_mails_${po.id}`);
      const updated = stored ? [...JSON.parse(stored), newMail] : [newMail];
      localStorage.setItem(`po_mails_${po.id}`, JSON.stringify(updated));
      setMails(updated);

      if (po.status === "Draft") changeStatus(po.id, "Issued");
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
  const filteredPOs = purchaseOrders.filter(po => {
    const matchSearch = searchQuery === "" ||
      (po.purchase_order_number || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      getVendorName(po.vendor_id).toLowerCase().includes(searchQuery.toLowerCase());
    const matchStatus = statusFilter === "all" || po.status?.toLowerCase() === statusFilter.toLowerCase();
    return matchSearch && matchStatus;
  });

  const sortedPOs = [...filteredPOs].sort((a, b) => {
    let aVal = a[sortBy];
    let bVal = b[sortBy];

    if (sortBy === "vendor_name") {
      aVal = getVendorName(a.vendor_id).toLowerCase();
      bVal = getVendorName(b.vendor_id).toLowerCase();
    } else if (sortBy === "company_name") {
      aVal = getVendorCompany(a.vendor_id).toLowerCase();
      bVal = getVendorCompany(b.vendor_id).toLowerCase();
    } else if (sortBy === "billed_status") {
      aVal = (a.billed_status || (a.status === 'Billed' ? 'Billed' : 'Unbilled')).toLowerCase();
      bVal = (b.billed_status || (b.status === 'Billed' ? 'Billed' : 'Unbilled')).toLowerCase();
    } else if (sortBy === "received") {
      aVal = (a.received || (a.status === 'Billed' ? 'Fully Received' : 'Not Received')).toLowerCase();
      bVal = (b.received || (b.status === 'Billed' ? 'Fully Received' : 'Not Received')).toLowerCase();
    } else if (sortBy === "total_amount") {
      aVal = parseFloat(a.total_amount) || 0;
      bVal = parseFloat(b.total_amount) || 0;
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
      setSelected(sortedPOs.map((q) => q.id));
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
    if (!window.confirm(`Delete the ${selected.length} selected item(s)?`)) return;
    try {
      await Promise.all(
        selected.map((id) => apiRequest(`/purchase-orders/${id}`, { method: "DELETE" }))
      );
      toast.success("Deleted successfully");
      setSelected([]);
      if (selected.includes(expandedId)) {
        setExpandedId(null);
        setExpandedPO(null);
      }
      fetchData();
    } catch (err) {
      toast.error("Delete failed");
    }
  };

  const handleRefresh = () => {
    fetchData();
    setMenuOpen(false);
  };

  const allViews = [
    { key: "all", label: "All Purchase Orders" },
    { key: "draft", label: "Draft" },
    { key: "issued", label: "Issued" },
    { key: "billed", label: "Billed" },
    { key: "cancelled", label: "Cancelled" },
  ];
  const filteredViews = allViews.filter(v => v.label.toLowerCase().includes(filterSearch.toLowerCase()));

  const timeAgo = (dateString) => {
    if (!dateString) return "";
    const now = new Date();
    const past = new Date(dateString);
    const diffMs = now - past;
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHr = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHr / 24);
    if (diffDay > 30) return `${Math.floor(diffDay / 30)} month(s) ago`;
    if (diffDay > 0) return `${diffDay} day(s) ago`;
    if (diffHr > 0) return `${diffHr} hour(s) ago`;
    if (diffMin > 0) return `${diffMin} minute(s) ago`;
    return "just now";
  };

  return (
    <div style={{ background: "#f8fafc", minHeight: "100vh", fontFamily: "system-ui, -apple-system, sans-serif", color: "#1d2939" }}>
      <style>{`
        .premium-input { border: 1px solid #d0d5dd; transition: border-color 0.15s ease, box-shadow 0.15s ease; }
        .premium-input:focus { border-color: #006ee6 !important; box-shadow: 0 0 0 4px rgba(0, 110, 230, 0.12) !important; }
        
        .full-table-container { background: #fff; display: flex; flex-direction: column; height: 100%; min-height: calc(100vh - 60px); margin: 0; }
        .full-table-header { padding: 15px 30px; border-bottom: 1px solid #eaeaea; display: flex; justify-content: space-between; align-items: center; }
        .table-actions { display: flex; gap: 10px; }
        .btn-new { background: #3b82f6; color: white; border: none; padding: 8px 16px; border-radius: 4px; font-size: 14px; cursor: pointer; display: flex; align-items: center; gap: 5px; font-weight: 500; }
        .btn-new:hover { background: #2563eb; }
        .btn-more { background: #f5f5f5; border: 1px solid #ddd; color: #555; border-radius: 4px; padding: 6px 12px; cursor: pointer; font-weight: bold; display: flex; align-items: center; justify-content: center; }
        
        .table-wrapper { flex: 1; overflow: auto; }
        .items-table { width: 100%; border-collapse: collapse; font-size: 13px; table-layout: fixed; }
        .items-table th { text-align: left; padding: 12px 15px; color: #64748b; font-weight: 600; border-bottom: 1px solid #e2e8f0; background: #ffffff; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; white-space: nowrap; resize: horizontal; overflow: hidden; text-overflow: ellipsis; }
        .items-table td { padding: 14px 15px; border-bottom: 1px solid #f8fafc; color: #334155; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .items-table tr:hover { background: #f1f5f9; }
        
        .vendor-name-link { color: #2563eb; cursor: pointer; font-weight: 500; }
        .vendor-name-link:hover { text-decoration: underline; }
        .th-icon-wrapper { overflow: visible !important; }
        .th-icon { display: inline-flex; align-items: center; justify-content: center; color: #aaa; cursor: pointer; transition: color 0.2s; }
        .th-icon:hover, .th-icon.active { color: #007bff; }
        
        .settings-dropdown { position: absolute; top: 30px; left: 10px; background: #fff; border: 1px solid #e0e0e0; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); z-index: 1000; width: 180px; padding: 6px; font-size: 13px; text-transform: none; font-weight: 500; text-align: left; letter-spacing: normal; }
        .dropdown-item { padding: 8px 12px; display: flex; align-items: center; justify-content: flex-start; gap: 10px; border-radius: 4px; cursor: pointer; color: #334155; transition: background 0.2s; }
        .dropdown-item:hover { background: #f1f5f9; color: #0f172a; }
        .dropdown-item svg { width: 16px; height: 16px; min-width: 16px; color: #64748b; }
        .items-table.clip-text td { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        
        .more-dropdown-container { position:relative; }
        .more-dropdown-menu { position:absolute; top:100%; right:0; margin-top:8px; background:#fff; border:1px solid #e2e8f0; border-radius:8px; box-shadow:0 10px 25px rgba(0,0,0,0.1); z-index:1000; width:250px; padding:8px 0; }
        .more-dropdown-item { position:relative; padding:10px 16px; display:flex; align-items:center; gap:12px; cursor:pointer; font-size:14px; color:#334155; transition:background 0.2s; }
        .more-dropdown-item:hover { background:#f8fafc; color:#0f172a; }
        .more-dropdown-item svg { width:16px; height:16px; color:#64748b; }
        .more-dropdown-divider { height:1px; background:#e2e8f0; margin:4px 0; }
        .more-dropdown-item span { flex:1; }
        .more-dropdown-item .chevron { width:14px; height:14px; }
        
        .nested-dropdown-menu { display:none; position:absolute; right:100%; top:-8px; margin-right:4px; background:#fff; border:1px solid #e2e8f0; border-radius:8px; box-shadow:0 10px 25px rgba(0,0,0,0.1); z-index:1001; min-width:200px; padding:8px 0; }
        .more-dropdown-item:hover > .nested-dropdown-menu { display:block; }
        
        .view-dropdown-container { position: relative; display: inline-block; }
        .view-dropdown-btn { display: flex; align-items: center; gap: 6px; cursor: pointer; padding: 6px 10px; border-radius: 6px; transition: background 0.2s; }
        .view-dropdown-btn:hover, .view-dropdown-btn.active { background: #f1f5f9; }
        .view-dropdown-menu { position: absolute; top: 100%; left: 0; margin-top: 4px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); z-index: 1000; width: 220px; padding: 8px 0; }
        .view-dropdown-item { padding: 10px 16px; display: flex; align-items: center; justify-content: space-between; cursor: pointer; font-size: 14px; color: #334155; transition: background 0.2s; }
        .view-dropdown-item:hover { background: #f8fafc; }
        
        .timeline-line { position: absolute; left: 17px; top: 8px; bottom: 8px; width: 2px; background: #eaecf0; }
        .timeline-node { position: absolute; left: 12px; top: 4px; width: 12px; height: 12px; border-radius: 50%; border: 2px solid #ffffff; box-shadow: 0 0 0 2px #d0d5dd; background: #ffffff; }
        .timeline-node.success { box-shadow: 0 0 0 2px #12b76a; background: #12b76a; }
        .timeline-node.warning { box-shadow: 0 0 0 2px #f79009; background: #f79009; }
        .timeline-node.primary { box-shadow: 0 0 0 2px #006ee6; background: #006ee6; }
        
        .action-icon-btn { border: 1px solid #d0d5dd; background: #ffffff; padding: 8px; border-radius: 6px; cursor: pointer; display: flex; align-items: center; justify-content: center; color: #475569; transition: all 0.15s ease; }
        .action-icon-btn:hover { border-color: #98a2b3; background: #f9fafb; color: #1d2939; }
        
        .list-item-selected { background-color: #f0f6ff !important; border-left: 3.5px solid #006ee6 !important; }
        .list-item-normal { border-left: 3.5px solid transparent; cursor: pointer; transition: background-color 0.15s ease; }
        .list-item-normal:hover { background-color: #f8fafc; }
        
        .tab-btn { background: none; border: none; border-bottom: 2px solid transparent; padding: 12px 16px; font-size: 14px; font-weight: 500; color: #667085; cursor: pointer; transition: all 0.15s; outline: none; }
        .tab-btn:hover { color: #1d2939; }
        .tab-btn.active { color: #006ee6; border-bottom-color: #006ee6; font-weight: 600; }
        
        .comment-box { border: 1px solid #eaecf0; border-radius: 8px; padding: 12px; background: #f9fafb; margin-bottom: 12px; }
        .comment-header { display: flex; justify-content: space-between; font-size: 12px; color: #667085; margin-bottom: 6px; }
        
        @media (max-width: 768px) {
          .expenses-main-container { flex-direction: column !important; }
          .expenses-left-pane { width: 100% !important; min-width: 100% !important; border-right: none !important; border-bottom: 1px solid #eaecf0 !important; height: 400px; flex: none !important; }
          .expenses-right-pane { width: 100% !important; }
        }
      `}</style>

      <div className="expenses-main-container" style={{ display: "flex", minHeight: "100vh" }}>
        
        {/* ==================== LEFT PANE (Only in Split View) ==================== */}
        {expandedId !== null && (
          <div className="expenses-left-pane" style={{ width: "320px", minWidth: "320px", borderRight: "1px solid #eaecf0", background: "#ffffff", display: "flex", flexDirection: "column" }}>
            
            {/* Left Header */}
            <div style={{ padding: "16px", borderBottom: "1px solid #eaecf0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ position: "relative", display: "inline-block" }} className="view-dropdown-container">
                <button 
                  onClick={() => setMenuOpen(!menuOpen)}
                  style={{ background: "none", border: "none", fontSize: "15px", fontWeight: "600", color: "#1d2939", cursor: "pointer", display: "flex", alignItems: "center", gap: "6px" }}
                >
                  {allViews.find(v => v.key === statusFilter.toLowerCase())?.label || "All Orders"}
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <polyline points="6 9 12 15 18 9"></polyline>
                  </svg>
                </button>
                
                {menuOpen && (
                  <div style={{ position: "absolute", left: 0, top: "100%", marginTop: "8px", background: "#ffffff", border: "1px solid #eaecf0", borderRadius: "8px", boxShadow: "0 10px 25px rgba(0,0,0,0.08)", zIndex: 100, minWidth: "180px" }}>
                    {allViews.map(view => (
                      <button 
                        key={view.key}
                        style={{ width: "100%", padding: "10px 14px", border: "none", background: "none", textAlign: "left", cursor: "pointer", fontSize: "13px", color: "#344054" }} 
                        onClick={() => { setStatusFilter(view.key); setMenuOpen(false); }}
                      >
                        {view.label}
                      </button>
                    ))}
                    <div style={{ borderTop: "1px solid #eaecf0", margin: "4px 0" }}></div>
                    <button style={{ width: "100%", padding: "10px 14px", border: "none", background: "none", textAlign: "left", cursor: "pointer", fontSize: "13px", color: "#344054" }} onClick={handleRefresh}>🔄 Refresh List</button>
                  </div>
                )}
              </div>

              <div>
                <button 
                  onClick={() => navigate("/purchase-orders/new")} 
                  style={{ background: "#006ee6", color: "#ffffff", border: "none", borderRadius: "6px", width: "28px", height: "28px", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", fontSize: "16px", fontWeight: "600" }}
                  title="Add Purchase Order"
                >
                  +
                </button>
              </div>
            </div>

            {/* Left Search Bar */}
            <div style={{ padding: "12px", borderBottom: "1px solid #eaecf0", background: "#f8fafc" }}>
              <div style={{ position: "relative", width: "100%" }}>
                <span style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", color: "#98a2b3", fontSize: "12px" }}>🔍</span>
                <input
                  type="text"
                  placeholder="Search orders..."
                  value={searchQuery}
                  onChange={(e) => {
                    const newParams = new URLSearchParams(location.search);
                    if (e.target.value) newParams.set("search", e.target.value);
                    else newParams.delete("search");
                    navigate({ search: newParams.toString() }, { replace: true });
                  }}
                  style={{ width: "100%", padding: "8px 8px 8px 30px", borderRadius: "6px", border: "1px solid #d0d5dd", fontSize: "13px", boxSizing: "border-box", outline: "none", background: "#ffffff" }}
                />
              </div>
            </div>

            {/* Left Scrollable List */}
            <div style={{ flex: 1, overflowY: "auto" }}>
              {sortedPOs.length === 0 ? (
                <div style={{ padding: "40px 16px", textAlign: "center", color: "#667085", fontSize: "13px" }}>No orders found.</div>
              ) : (
                sortedPOs.map((po) => {
                  const isSelected = expandedId === po.id;
                  return (
                    <div
                      key={po.id}
                      onClick={() => toggleExpand(po.id)}
                      className={isSelected ? "list-item-selected" : "list-item-normal"}
                      style={{ padding: "12px 16px", display: "flex", alignItems: "center", gap: "10px", borderBottom: "1px solid #eaecf0", background: "#ffffff" }}
                    >
                      <input 
                        type="checkbox" 
                        checked={selected.includes(po.id)} 
                        onChange={(e) => { e.stopPropagation(); toggleSelectOne(po.id); }} 
                        style={{ cursor: "pointer" }} 
                      />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: "13px", fontWeight: "600", color: "#1d2939", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                          {getVendorName(po.vendor_id)}
                        </div>
                        <div style={{ fontSize: "11px", color: "#667085", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", marginTop: "2px" }}>
                          {po.purchase_order_number} | {new Date(po.purchase_order_date).toLocaleDateString()}
                        </div>
                      </div>
                      <div style={{ textAlign: "right" }}>
                        <div style={{ fontSize: "13px", fontWeight: "600", color: "#344054" }}>
                          ₹{parseFloat(po.total_amount).toFixed(0)}
                        </div>
                        <div style={{ marginTop: "2px" }}>
                          {statusBadge(po.status)}
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        )}

        {/* ==================== RIGHT PANE / DETAIL OR FULL LIST ==================== */}
        <div className="expenses-right-pane" style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0 }}>
          
          {expandedId !== null ? (
            // ==================== DETAIL VIEW MODE ====================
            expandedLoading ? (
              <div style={{ padding: "40px" }}><DetailSkeleton /></div>
            ) : expandedPO ? (
              <div style={{ display: "flex", flexDirection: "column", height: "100vh", background: "#ffffff" }}>
                
                {/* Detail View Header */}
                <div style={{ padding: "16px 24px", borderBottom: "1px solid #eaecf0", display: "flex", justifyContent: "space-between", alignItems: "center", background: "#ffffff" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    <h2 style={{ margin: 0, fontSize: "18px", fontWeight: "600", color: "#1d2939" }}>
                      {expandedPO.purchase_order_number}
                    </h2>
                    {statusBadge(expandedPO.status)}
                  </div>

                  {/* Header Actions */}
                  <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                    <button 
                      onClick={() => navigate(`/purchase-orders/${expandedPO.id}/edit`)} 
                      style={{ padding: "8px 14px", background: "#ffffff", border: "1px solid #d0d5dd", borderRadius: "6px", fontSize: "13px", fontWeight: "600", color: "#344054", cursor: "pointer", outline: "none" }}
                    >
                      Edit
                    </button>
                    
                    <button onClick={() => openEmailModal(expandedPO)} className="action-icon-btn" title="Send Email">✉️</button>
                    <button onClick={(e) => sendWhatsApp(expandedPO, e)} className="action-icon-btn" title="Send WhatsApp">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg>
                    </button>
                    <button onClick={(e) => sendSMS(expandedPO, e)} className="action-icon-btn" title="Send SMS">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
                    </button>
                    <button onClick={() => navigate(`/purchase-orders/${expandedPO.id}/document`)} className="action-icon-btn" title="View Document">📄</button>
                    
                    {expandedPO.status !== "Issued" && expandedPO.status !== "Billed" && <button onClick={() => changeStatus(expandedPO.id, "Issued")} style={{ padding: "8px 14px", background: "#ecfdf5", border: "1px solid #a7f3d0", color: "#047857", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Issue</button>}
                    {expandedPO.status !== "Cancelled" && <button onClick={() => changeStatus(expandedPO.id, "Cancelled")} style={{ padding: "8px 14px", background: "#fef2f2", border: "1px solid #fecaca", color: "#b91c1c", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Cancel</button>}
                    {expandedPO.status !== "Cancelled" && expandedPO.status !== "Billed" && (
                      <button onClick={() => handleConvertToBill(expandedPO.id)} style={{ padding: "8px 14px", background: "#006ee6", color: "#ffffff", border: "none", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Convert to Bill</button>
                    )}

                    <button onClick={() => handleDelete(expandedPO.id)} className="action-icon-btn" title="Delete" style={{ color: "#d92d20" }}>🗑️</button>

                    <button 
                      onClick={() => setExpandedId(null)} 
                      style={{ background: "none", border: "none", cursor: "pointer", fontSize: "20px", color: "#98a2b3", display: "flex", padding: "4px", borderRadius: "4px" }}
                    >
                      &times;
                    </button>
                  </div>
                </div>

                {/* Tabs Bar */}
                <div style={{ padding: "0 24px", borderBottom: "1px solid #eaecf0", display: "flex", gap: "6px", background: "#ffffff" }}>
                  {["Overview", "Comments", "Bills", "Mails", "History"].map((tab) => (
                    <button 
                      key={tab} 
                      onClick={() => setActiveTab(tab)} 
                      className={`tab-btn ${activeTab === tab ? "active" : ""}`}
                    >
                      {tab}
                    </button>
                  ))}
                </div>

                {/* Tab Content Display Area */}
                <div style={{ flex: 1, overflowY: "auto", padding: "24px", background: "#ffffff" }}>
                  
                  {/* ===== TAB: OVERVIEW ===== */}
                  {activeTab === "Overview" && (
                    <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: "32px", alignItems: "start" }}>
                      
                      {/* Left Side Details */}
                      <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
                        <div>
                          <div style={{ fontSize: "12px", color: "#667085", fontWeight: "600", textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "4px" }}>Vendor Name</div>
                          <div style={{ fontSize: "16px", fontWeight: "600", color: "#1d2939" }}>{getVendorName(expandedPO.vendor_id)}</div>
                        </div>

                        {/* Order info card */}
                        <div style={{ border: "1px solid #eaecf0", borderRadius: "10px", padding: "20px", display: "flex", gap: "16px", background: "#fcfcfd" }}>
                          <div style={{ flex: 1, display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", fontSize: "13px" }}>
                            <div>
                              <span style={{ color: "#667085" }}>Date:</span>
                              <span style={{ marginLeft: "8px", fontWeight: "500", color: "#1d2939" }}>{new Date(expandedPO.purchase_order_date).toLocaleDateString()}</span>
                            </div>
                            <div>
                              <span style={{ color: "#667085" }}>Expected Delivery:</span>
                              <span style={{ marginLeft: "8px", fontWeight: "500", color: "#1d2939" }}>{expandedPO.expected_delivery_date ? new Date(expandedPO.expected_delivery_date).toLocaleDateString() : "—"}</span>
                            </div>
                            <div>
                              <span style={{ color: "#667085" }}>Reference #:</span>
                              <span style={{ marginLeft: "8px", fontWeight: "500", color: "#1d2939" }}>{expandedPO.reference_number || "—"}</span>
                            </div>
                            <div>
                              <span style={{ color: "#667085" }}>Delivery Method:</span>
                              <span style={{ marginLeft: "8px", fontWeight: "500", color: "#1d2939" }}>{expandedPO.delivery_method || "—"}</span>
                            </div>
                          </div>
                        </div>

                        {/* Item Table */}
                        <div>
                          <h4 style={{ margin: "0 0 12px 0", fontSize: "13px", color: "#475569", textTransform: "uppercase", letterSpacing: "0.03em", fontWeight: "600" }}>Items Ordered</h4>
                          <div style={{ border: "1px solid #eaecf0", borderRadius: "8px", overflow: "hidden" }}>
                            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px" }}>
                              <thead style={{ background: "#f8fafc" }}>
                                <tr>
                                  <th style={{ ...thStyle, padding: "10px" }}>Item Details</th>
                                  <th style={{ ...thStyle, padding: "10px", textAlign: "right" }}>Qty</th>
                                  <th style={{ ...thStyle, padding: "10px", textAlign: "right" }}>Rate</th>
                                  <th style={{ ...thStyle, padding: "10px", textAlign: "right" }}>Amount</th>
                                </tr>
                              </thead>
                              <tbody>
                                {expandedItems.map((item, idx) => (
                                  <tr key={idx} style={{ borderBottom: "1px solid #eaecf0" }}>
                                    <td style={{ ...tdStyle, padding: "12px 10px" }}>
                                      <div style={{ fontWeight: "500", color: "#1d2939" }}>{item.item_name || item.description}</div>
                                      <div style={{ fontSize: "11px", color: "#667085", marginTop: "2px" }}>{item.hsn_code ? `HSN: ${item.hsn_code}` : ""}</div>
                                    </td>
                                    <td style={{ ...tdStyle, padding: "12px 10px", textAlign: "right" }}>{item.quantity}</td>
                                    <td style={{ ...tdStyle, padding: "12px 10px", textAlign: "right" }}>₹{parseFloat(item.rate).toFixed(2)}</td>
                                    <td style={{ ...tdStyle, padding: "12px 10px", textAlign: "right", fontWeight: "500" }}>₹{((parseFloat(item.quantity) || 0) * (parseFloat(item.rate) || 0)).toFixed(2)}</td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                            <div style={{ background: "#f8fafc", padding: "16px 20px", display: "flex", justifyContent: "flex-end", borderTop: "1px solid #eaecf0" }}>
                              <div style={{ width: "250px", fontSize: "14px" }}>
                                <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "600", fontSize: "15px", color: "#1d2939" }}>
                                  <span>Total Amount</span>
                                  <span>₹{parseFloat(expandedPO.total_amount).toFixed(2)}</span>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>

                        {/* Notes and Terms */}
                        {(expandedPO.notes || expandedPO.terms_conditions) && (
                          <div style={{ border: "1px solid #eaecf0", borderRadius: "8px", background: "#fcfcfd", padding: "16px", display: "flex", flexDirection: "column", gap: "16px" }}>
                            {expandedPO.notes && (
                              <div>
                                <div style={{ fontSize: "11px", color: "#667085", fontWeight: "600" }}>NOTES</div>
                                <div style={{ fontSize: "13px", color: "#344054", marginTop: "4px", lineHeight: "1.5" }}>{expandedPO.notes}</div>
                              </div>
                            )}
                            {expandedPO.terms_conditions && (
                              <div>
                                <div style={{ fontSize: "11px", color: "#667085", fontWeight: "600" }}>TERMS & CONDITIONS</div>
                                <div style={{ fontSize: "13px", color: "#344054", marginTop: "4px", lineHeight: "1.5" }}>{expandedPO.terms_conditions}</div>
                              </div>
                            )}
                          </div>
                        )}

                      </div>

                      {/* Right Side Info */}
                      <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
                        <div style={{ background: "#f8fafc", border: "1px solid #eaecf0", borderRadius: "8px", padding: "16px", fontSize: "13px" }}>
                          <div style={{ fontWeight: "600", color: "#1d2939", marginBottom: "8px" }}>Status Overview:</div>
                          <div>PO current status is <strong style={{ textTransform: "capitalize", color: "#006ee6" }}>{expandedPO.status}</strong>.</div>
                        </div>

                        <div style={{ border: "1px solid #eaecf0", borderRadius: "8px", padding: "16px", background: "#ffffff" }}>
                          <h4 style={{ margin: "0 0 12px 0", fontSize: "12px", color: "#475569", textTransform: "uppercase", letterSpacing: "0.03em" }}>Vendor Contacts</h4>
                          <div style={{ fontSize: "13px", color: "#1d2939" }}>
                            <div style={{ fontWeight: "500", marginBottom: "4px" }}>{getVendorName(expandedPO.vendor_id)}</div>
                            <div style={{ color: "#667085" }}>{getVendorById(expandedPO.vendor_id).email || "No Email"}</div>
                            <div style={{ color: "#667085", marginTop: "2px" }}>{getVendorById(expandedPO.vendor_id).phone || "No Phone"}</div>
                          </div>
                        </div>
                      </div>

                    </div>
                  )}

                  {/* ===== TAB: COMMENTS ===== */}
                  {activeTab === "Comments" && (
                    <div style={{ maxWidth: "600px" }}>
                      <div style={{ marginBottom: "20px", display: "flex", gap: "10px" }}>
                        <input 
                          type="text" 
                          placeholder="Add a comment..." 
                          value={newComment} 
                          onChange={(e) => setNewComment(e.target.value)} 
                          style={{ flex: 1, padding: "8px 12px", borderRadius: "6px", border: "1px solid #d0d5dd", fontSize: "13px", outline: "none" }}
                          className="premium-input"
                        />
                        <button onClick={handleAddComment} style={{ padding: "8px 16px", background: "#006ee6", color: "#ffffff", border: "none", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Comment</button>
                      </div>
                      
                      {commentsLoading ? <div style={{ fontSize: "13px", color: "#667085" }}>Loading...</div> : comments.length === 0 ? (
                        <div style={{ fontSize: "13px", color: "#667085", fontStyle: "italic" }}>No comments yet.</div>
                      ) : (
                        comments.map((c) => (
                          <div key={c.id} className="comment-box">
                            <div className="comment-header">
                              <strong>{c.user?.name}</strong>
                              <span>{timeAgo(c.created_at)}</span>
                            </div>
                            <div style={{ fontSize: "13px", color: "#344054", whiteSpace: "pre-line" }}>{c.comment}</div>
                          </div>
                        ))
                      )}
                    </div>
                  )}

                  {/* ===== TAB: BILLS ===== */}
                  {activeTab === "Bills" && (
                    <div>
                      <h3 style={{ fontSize: "14px", fontWeight: "600", color: "#344054", marginBottom: "16px" }}>Converted Bills</h3>
                      {billsLoading ? <div style={{ fontSize: "13px", color: "#667085" }}>Loading bills...</div> : bills.length === 0 ? (
                        <div style={{ fontSize: "13px", color: "#667085", fontStyle: "italic" }}>
                          No bills created from this Purchase Order.
                          {expandedPO.status !== "Cancelled" && expandedPO.status !== "Billed" && (
                            <button onClick={() => handleConvertToBill(expandedPO.id)} style={{ background: "none", border: "none", color: "#006ee6", cursor: "pointer", fontWeight: "600", marginLeft: "6px", padding: 0, textDecoration: "underline" }}>Convert to Bill Now →</button>
                          )}
                        </div>
                      ) : (
                        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px" }}>
                          <thead>
                            <tr style={{ background: "#f9fafb", textAlign: "left" }}>
                              <th style={thStyle}>Bill Number</th>
                              <th style={thStyle}>Date</th>
                              <th style={thStyle}>Due Date</th>
                              <th style={thStyle}>Status</th>
                              <th style={{ ...thStyle, textAlign: "right" }}>Amount</th>
                            </tr>
                          </thead>
                          <tbody>
                            {bills.map(b => (
                              <tr key={b.id} style={{ borderBottom: "1px solid #eaecf0", cursor: "pointer" }} onClick={() => navigate(`/bills/${b.id}`)}>
                                <td style={{ ...tdStyle, color: "#006ee6", fontWeight: "500" }}>{b.bill_number}</td>
                                <td style={tdStyle}>{new Date(b.bill_date).toLocaleDateString()}</td>
                                <td style={tdStyle}>{new Date(b.due_date).toLocaleDateString()}</td>
                                <td style={tdStyle}>
                                  <span style={{ padding: "3px 8px", borderRadius: "4px", fontSize: "11px", fontWeight: "600", background: b.status === "Paid" ? "#dcfce7" : "#fffbeb", color: b.status === "Paid" ? "#166534" : "#b45309", textTransform: "uppercase" }}>
                                    {b.status}
                                  </span>
                                </td>
                                <td style={{ ...tdStyle, textAlign: "right", fontWeight: "600" }}>₹{parseFloat(b.total_amount).toFixed(2)}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      )}
                    </div>
                  )}

                  {/* ===== TAB: MAILS ===== */}
                  {activeTab === "Mails" && (
                    <div style={{ maxWidth: "700px" }}>
                      <h3 style={{ fontSize: "14px", fontWeight: "600", color: "#344054", marginBottom: "16px" }}>Email History</h3>
                      {mails.length === 0 ? (
                        <div style={{ fontSize: "13px", color: "#667085", fontStyle: "italic" }}>No emails sent for this order yet.</div>
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
                    {allViews.find(v => v.key === statusFilter.toLowerCase())?.label || "All Purchase Orders"}
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" style={{ transform: statusDropdownOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }}><polyline points="6 9 12 15 18 9" /></svg>
                  </h3>
                  
                  {statusDropdownOpen && (
                    <div className="view-dropdown-menu">
                      <div style={{ padding: "0 12px 10px 12px", borderBottom: "1px solid #f2f4f7", position: "sticky", top: 0, background: "#fff", paddingTop: "8px" }}>
                        <div style={{ position: "relative", width: "100%" }}>
                          <span style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", display: "flex" }}>
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#667085" strokeWidth="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                          </span>
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
                                    localStorage.setItem("favPOView", newFav); 
                                    toast.success(`"${view.label}" set as default view`); 
                                  } else { 
                                    localStorage.removeItem("favPOView"); 
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
                  <button className="btn-new" onClick={() => navigate("/purchase-orders/new")}>
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
                            <div className="more-dropdown-item" onClick={() => { setSortBy("purchase_order_date"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Date (Newest first)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("purchase_order_date"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Date (Oldest first)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("purchase_order_number"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>PO Number (A-Z)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("vendor_name"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Vendor Name (A-Z)</span></div>
                            <div className="more-dropdown-item" onClick={() => { setSortBy("total_amount"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Amount (High to Low)</span></div>
                          </div>
                        </div>
                        <div className="more-dropdown-item" onClick={() => { setMoreMenuOpen(false); toast("Import functionality coming soon"); }}>
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                          <span>Import POs</span>
                        </div>
                        <div className="more-dropdown-item">
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/></svg>
                          <span>Export POs</span>
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
                  <TableSkeleton rows={8} columns={6} />
                ) : sortedPOs.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '80px 20px', color: '#98a2b3' }}>
                    <div style={{ fontSize: '48px', marginBottom: '16px' }}>📄</div>
                    <h3 style={{ color: '#1d2939', marginBottom: '8px', fontSize: "16px", fontWeight: "600" }}>No orders found</h3>
                    <p style={{ marginBottom: '20px', fontSize: "13px" }}>{searchQuery ? 'No orders match your search.' : 'Start by creating your first purchase order.'}</p>
                    <button className="btn-new" onClick={() => navigate('/purchase-orders/new')} style={{ margin: "0 auto" }}>+ New Purchase Order</button>
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
                          <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selected.length === sortedPOs.length && sortedPOs.length > 0} onChange={handleSelectAll} />
                        </th>
                        {visibleColumns.purchase_order_date && <th style={thStyle}>Date</th>}
                        {visibleColumns.purchase_order_number && <th style={thStyle}>PO Number</th>}
                        {visibleColumns.reference_number && <th style={thStyle}>Reference#</th>}
                        {visibleColumns.vendor_name && <th style={thStyle}>Vendor Name</th>}
                        {visibleColumns.status && <th style={thStyle}>Status</th>}
                        {visibleColumns.total_amount && <th style={{ ...thStyle, textAlign: 'right' }}>Amount</th>}
                        {visibleColumns.billed_status && <th style={thStyle}>Billed Status</th>}
                        {visibleColumns.delivery_date && <th style={thStyle}>Delivery Date</th>}
                        {visibleColumns.company_name && <th style={thStyle}>Company Name</th>}
                        {visibleColumns.received && <th style={thStyle}>Received</th>}
                        {visibleColumns.expected_delivery_date && <th style={thStyle}>Expected Delivery Date</th>}
                      </tr>
                    </thead>
                    <tbody>
                      {sortedPOs.map((po) => (
                        <tr key={po.id} onClick={() => toggleExpand(po.id)} style={{ cursor: "pointer", background: selected.includes(po.id) ? "#fcfcfd" : "" }}>
                          <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}></td>
                          <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                            <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selected.includes(po.id)} onChange={() => toggleSelectOne(po.id)} />
                          </td>
                          {visibleColumns.purchase_order_date && <td>{new Date(po.purchase_order_date).toLocaleDateString()}</td>}
                          {visibleColumns.purchase_order_number && <td className="vendor-name-link">{po.purchase_order_number}</td>}
                          {visibleColumns.reference_number && <td>{po.reference_number || "—"}</td>}
                          {visibleColumns.vendor_name && <td>{getVendorName(po.vendor_id)}</td>}
                          {visibleColumns.status && <td>{statusBadge(po.status)}</td>}
                          {visibleColumns.total_amount && <td style={{ textAlign: 'right', fontWeight: "600", color: "#1d2939" }}>₹{parseFloat(po.total_amount).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>}
                          {visibleColumns.billed_status && <td>{po.billed_status || (po.status === 'Billed' ? 'Billed' : 'Unbilled')}</td>}
                          {visibleColumns.delivery_date && <td>{po.delivery_date ? new Date(po.delivery_date).toLocaleDateString() : "—"}</td>}
                          {visibleColumns.company_name && <td>{getVendorCompany(po.vendor_id)}</td>}
                          {visibleColumns.received && <td>{po.received || (po.status === 'Billed' ? 'Fully Received' : 'Not Received')}</td>}
                          {visibleColumns.expected_delivery_date && <td>{po.expected_delivery_date ? new Date(po.expected_delivery_date).toLocaleDateString() : "—"}</td>}
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
      {showEmailModal && expandedPO && (
        <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 }}>
          <div style={{ background: "#fff", borderRadius: "8px", padding: "25px", width: "600px", maxWidth: "90%", maxHeight: "80vh", overflow: "auto", boxShadow: "0 4px 20px rgba(0,0,0,0.2)" }}>
            <h3 style={{ marginTop: 0, fontSize: "18px", color: "#1d2939" }}>Send Purchase Order via Email</h3>
            <div style={{ marginBottom: "15px" }}><label style={{ display: "block", fontSize: "13px", fontWeight: "500", marginBottom: "6px" }}>To:</label>
              <input type="email" value={getVendorById(expandedPO.vendor_id).email || ""} readOnly style={{ width: "100%", padding: "8px 12px", borderRadius: "6px", border: "1px solid #eaecf0", background: "#f8fafc", outline: "none", boxSizing: "border-box" }} /></div>
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

export default PurchaseOrders;
