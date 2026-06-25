import React, { useState, useEffect, useRef } from "react";
import { useNavigate, useParams, useLocation } from "react-router-dom";
import { apiRequest } from "./api";
import toast from "react-hot-toast";

function AddExpense() {
  const navigate = useNavigate();
  const { id } = useParams();
  const location = useLocation();
  const isEdit = !!id;
  
  const [vendorId, setVendorId] = useState("");
  const [category, setCategory] = useState("");
  const [amount, setAmount] = useState("");
  const [expenseDate, setExpenseDate] = useState(new Date().toISOString().slice(0, 10));
  const [description, setDescription] = useState("");
  const [reference, setReference] = useState("");
  const [paidThrough, setPaidThrough] = useState("Petty Cash");
  
  const [vendors, setVendors] = useState([]);
  const [saving, setSaving] = useState(false);
  
  const [activeTab, setActiveTab] = useState("Record Expense");
  const [showMileagePref, setShowMileagePref] = useState(false);
  const [showEmployeeModal, setShowEmployeeModal] = useState(false);
  const [isAddingEmployee, setIsAddingEmployee] = useState(false);
  const [employees, setEmployees] = useState([{ name: 'utsargtiwary', email: 'utsargtiwary55@gmail.com' }]);
  const [newEmpEmail, setNewEmpEmail] = useState("");
  const [newEmpName, setNewEmpName] = useState("");
  const [selectedEmployee, setSelectedEmployee] = useState("");
  const [calcMileageUsing, setCalcMileageUsing] = useState("distance");
  const [startReading, setStartReading] = useState("");
  const [endReading, setEndReading] = useState("");
  const [distance, setDistance] = useState("");
  const [mileageRate, setMileageRate] = useState(20);
  const [showEditRate, setShowEditRate] = useState(false);
  const [tempRate, setTempRate] = useState(20);
  const fileInputRef = useRef(null);
  const [file, setFile] = useState(null);
  const [bulkRows, setBulkRows] = useState(
    Array.from({ length: 8 }, () => ({
      date: "", account: "", amount: "", paidThrough: "", vendor: "", project: "", billable: false
    }))
  );

  useEffect(() => {
    const fetchDropdowns = async () => {
      try {
        const venRes = await apiRequest("/vendors");
        setVendors(venRes?.vendors || []);
      } catch (err) {
        console.error("Error fetching dropdowns:", err);
      }
    };
    fetchDropdowns();
  }, []);

  useEffect(() => {
    if (isEdit) {
      const fetchExpense = async () => {
        try {
          const res = await apiRequest(`/expenses/${id}`);
          if (res && res.expense) {
            const exp = res.expense;
            setVendorId(exp.vendor_id || "");
            setCategory(exp.category || "");
            setAmount(exp.amount || "");
            setExpenseDate(exp.expense_date ? exp.expense_date.slice(0, 10) : new Date().toISOString().slice(0, 10));
            setDescription(exp.description || "");
            setReference(exp.reference || "");
            setPaidThrough(exp.paid_through || "Petty Cash");
          }
        } catch (err) {
          toast.error("Failed to load expense details");
        }
      };
      fetchExpense();
    }
  }, [id, isEdit]);
  useEffect(() => {
    if (location.state?.cloneFrom) {
      const clone = location.state.cloneFrom;
      setVendorId(clone.vendor_id || "");
      setCategory(clone.category || "");
      setAmount(clone.amount || "");
      setExpenseDate(new Date().toISOString().slice(0, 10));
      setDescription(clone.description || "");
      setReference(clone.reference || "");
      setPaidThrough(clone.paid_through || "Petty Cash");
    }
  }, [location.state]);

  const handleSave = async (isNew = false) => {
    if (activeTab === 'Bulk Add Expenses') {
      const validRows = bulkRows.filter(r => r.amount && r.account && r.date && r.paidThrough);
      if (validRows.length === 0) return toast.error("Please fill at least one valid row completely");
      
      setSaving(true);
      try {
        await Promise.all(validRows.map(row => apiRequest("/expenses", {
          method: "POST",
          body: JSON.stringify({
            vendor_id: row.vendor || null,
            category: row.account,
            amount: parseFloat(row.amount),
            expense_date: row.date,
            status: "paid",
            paid_through: row.paidThrough
          }),
        })));
        toast.success("Expenses recorded successfully!");
        if (isNew) {
          setBulkRows(Array.from({ length: 8 }, () => ({
            date: "", account: "", amount: "", paidThrough: "", vendor: "", project: "", billable: false
          })));
          setActiveTab("Record Expense");
        } else {
          navigate("/expenses");
        }
      } catch (err) {
        toast.error("Failed to record some expenses");
      } finally {
        setSaving(false);
      }
      return;
    }

    let currentCategory = category;

    if (!amount || parseFloat(amount) <= 0) return toast.error("Enter a valid amount");
    if (!currentCategory) return toast.error("Select an expense account");
    if (!expenseDate) return toast.error("Select a date");
    
    setSaving(true);
    try {
      const url = isEdit ? `/expenses/${id}` : "/expenses";
      const method = isEdit ? "PUT" : "POST";
      await apiRequest(url, {
        method: method,
        body: JSON.stringify({
          vendor_id: vendorId || null,
          category: currentCategory,
          amount: parseFloat(amount),
          expense_date: expenseDate,
          description,
          reference,
          status: "paid",
          paid_through: paidThrough
        }),
      });
      toast.success(isEdit ? "Expense updated successfully!" : "Expense recorded successfully!");
      if (isNew) {
         setVendorId("");
         setCategory("");
         setAmount("");
         setExpenseDate(new Date().toISOString().slice(0, 10));
         setDescription("");
         setReference("");
         setPaidThrough("Petty Cash");
         setFile(null);
         if (fileInputRef.current) {
           fileInputRef.current.value = "";
         }
         setDistance("");
         setStartReading("");
         setEndReading("");
         setSelectedEmployee("");
         setBulkRows(
           Array.from({ length: 8 }, () => ({
             date: "", account: "", amount: "", paidThrough: "", vendor: "", project: "", billable: false
           }))
         );
         
         // Switch to next tab sequentially
         if (activeTab === "Record Expense") {
           setActiveTab("Bulk Add Expenses");
         }
      } else {
         navigate("/expenses");
      }
    } catch (err) {
      toast.error(err.message || "Failed to record expense");
    } finally {
      setSaving(false);
    }
  };

  const handleFileSelect = (e) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0]);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 64px)', background: '#f9fafb' }}>
      
      {/* Tabs Header */}
      <div style={{ background: '#fff', padding: isEdit ? '20px 30px' : '15px 30px 0', borderBottom: '1px solid #e5e7eb' }}>
        {isEdit ? (
          <h2 style={{ margin: 0, fontSize: '20px', fontWeight: '500', color: '#111827' }}>Edit Expense</h2>
        ) : (
          <>
            <h2 style={{ margin: '0 0 15px 0', fontSize: '20px', fontWeight: '500', color: '#111827', display: 'none' }}>New Expense</h2>
            <div style={{ display: 'flex', gap: '30px' }}>
              {['Record Expense', 'Bulk Add Expenses'].map(tab => (
                <div 
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  style={{ 
                    paddingBottom: '12px', 
                    cursor: 'pointer',
                    color: activeTab === tab ? '#2563eb' : '#6b7280',
                    borderBottom: activeTab === tab ? '2px solid #2563eb' : '2px solid transparent',
                    fontSize: '14px',
                    fontWeight: activeTab === tab ? '500' : '400'
                  }}
                >
                  {tab}
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Form Content */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '30px' }}>
        {activeTab === 'Record Expense' && (
          <div style={{ display: 'flex', gap: '40px', maxWidth: '1200px' }}>
            
            {/* Left Form Area */}
          <div style={{ flex: '1', maxWidth: '700px' }}>
            
            {/* Date */}
            <div style={rowStyle}>
              <div style={labelContainerStyle}>
                <label style={redLabelStyle}>Date<span style={reqStyle}>*</span></label>
              </div>
              <div style={inputContainerStyle}>
                <input type="date" value={expenseDate} onChange={e => setExpenseDate(e.target.value)} style={inputFieldStyle} />
              </div>
            </div>

            {/* Expense Account */}
            <div style={rowStyle}>
              <div style={labelContainerStyle}>
                <label style={redLabelStyle}>Expense Account<span style={reqStyle}>*</span></label>
              </div>
              <div style={inputContainerStyle}>
                <select value={category} onChange={e => setCategory(e.target.value)} style={inputFieldStyle}>
                  <option value="">Select an account</option>
                  <optgroup label="Cost Of Goods Sold">
                    <option value="Cost of Goods Sold">Cost of Goods Sold</option>
                    <option value="Job Costing">Job Costing</option>
                    <option value="Labor">Labor</option>
                    <option value="Materials">Materials</option>
                    <option value="Subcontractor">Subcontractor</option>
                  </optgroup>
                  <optgroup label="Expense">
                    <option value="Advertising And Marketing">Advertising And Marketing</option>
                    <option value="Automobile Expense">Automobile Expense</option>
                    <option value="Bad Debt">Bad Debt</option>
                    <option value="Bank Fees and Charges">Bank Fees and Charges</option>
                    <option value="Consultant Expense">Consultant Expense</option>
                    <option value="Contract Assets">Contract Assets</option>
                    <option value="Credit Card Charges">Credit Card Charges</option>
                    <option value="Depreciation And Amortisation">Depreciation And Amortisation</option>
                    <option value="Depreciation Expense">Depreciation Expense</option>
                    <option value="Fuel/Mileage Expenses">Fuel/Mileage Expenses</option>
                    <option value="IT and Internet Expenses">IT and Internet Expenses</option>
                    <option value="Janitorial Expense">Janitorial Expense</option>
                    <option value="Lodging">Lodging</option>
                    <option value="Meals and Entertainment">Meals and Entertainment</option>
                    <option value="Merchandise">Merchandise</option>
                    <option value="Office Supplies">Office Supplies</option>
                    <option value="Other Expenses">Other Expenses</option>
                    <option value="Postage">Postage</option>
                    <option value="Printing and Stationery">Printing and Stationery</option>
                    <option value="Purchase Discounts">Purchase Discounts</option>
                    <option value="Raw Materials And Consumables">Raw Materials And Consumables</option>
                    <option value="Rent Expense">Rent Expense</option>
                    <option value="Repairs and Maintenance">Repairs and Maintenance</option>
                    <option value="Salaries and Employee Wages">Salaries and Employee Wages</option>
                    <option value="Telephone Expense">Telephone Expense</option>
                    <option value="Transportation Expense">Transportation Expense</option>
                    <option value="Travel Expense">Travel Expense</option>
                  </optgroup>
                  <optgroup label="Non Current Liability">
                    <option value="Construction Loans">Construction Loans</option>
                    <option value="Mortgages">Mortgages</option>
                  </optgroup>
                  <optgroup label="Other Current Liability">
                    <option value="Employee Reimbursements">Employee Reimbursements</option>
                    <option value="Tax Payable">Tax Payable</option>
                    <option value="TDS Payable">TDS Payable</option>
                  </optgroup>
                  <optgroup label="Fixed Asset">
                    <option value="Furniture and Equipment">Furniture and Equipment</option>
                  </optgroup>
                  <optgroup label="Other Current Asset">
                    <option value="Advance Tax">Advance Tax</option>
                    <option value="Employee Advance">Employee Advance</option>
                    <option value="Prepaid Expenses">Prepaid Expenses</option>
                    <option value="TDS Receivable">TDS Receivable</option>
                  </optgroup>
                </select>
                <div style={{ marginTop: '5px', color: '#2563eb', fontSize: '13px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="8" y1="6" x2="21" y2="6"></line><line x1="8" y1="12" x2="21" y2="12"></line><line x1="8" y1="18" x2="21" y2="18"></line><line x1="3" y1="6" x2="3.01" y2="6"></line><line x1="3" y1="12" x2="3.01" y2="12"></line><line x1="3" y1="18" x2="3.01" y2="18"></line></svg>
                  Itemize
                </div>
              </div>
            </div>

            {/* Amount */}
            <div style={rowStyle}>
              <div style={labelContainerStyle}>
                <label style={redLabelStyle}>Amount<span style={reqStyle}>*</span></label>
              </div>
              <div style={{ ...inputContainerStyle, display: 'flex' }}>
                <select style={{ ...inputFieldStyle, width: '80px', borderRight: 'none', borderRadius: '4px 0 0 4px', backgroundColor: '#f9fafb' }}>
                  <option>INR</option>
                </select>
                <input type="number" placeholder="0.00" value={amount} onChange={e => setAmount(e.target.value)} style={{ ...inputFieldStyle, flex: 1, borderRadius: '0 4px 4px 0' }} />
              </div>
            </div>

            <hr style={{ border: 'none', borderTop: '1px dashed #e5e7eb', margin: '30px 0' }} />

            {/* Paid Through */}
            <div style={rowStyle}>
              <div style={labelContainerStyle}>
                <label style={redLabelStyle}>Paid Through<span style={reqStyle}>*</span></label>
              </div>
              <div style={inputContainerStyle}>
                <select value={paidThrough} onChange={e => setPaidThrough(e.target.value)} style={inputFieldStyle}>
                  <optgroup label="Cash">
                    <option value="Petty Cash">Petty Cash</option>
                    <option value="Undeposited Funds">Undeposited Funds</option>
                  </optgroup>
                  <optgroup label="Other Current Asset">
                    <option value="Advance Tax">Advance Tax</option>
                    <option value="Employee Advance">Employee Advance</option>
                    <option value="Prepaid Expenses">Prepaid Expenses</option>
                    <option value="TDS Receivable">TDS Receivable</option>
                  </optgroup>
                  <optgroup label="Fixed Asset">
                    <option value="Furniture and Equipment">Furniture and Equipment</option>
                  </optgroup>
                  <optgroup label="Other Current Liability">
                    <option value="Employee Reimbursements">Employee Reimbursements</option>
                    <option value="TDS Payable">TDS Payable</option>
                  </optgroup>
                  <optgroup label="Non Current Liability">
                    <option value="Construction Loans">Construction Loans</option>
                    <option value="Mortgages">Mortgages</option>
                  </optgroup>
                  <optgroup label="Equity">
                    <option value="Capital Stock">Capital Stock</option>
                    <option value="Distributions">Distributions</option>
                    <option value="Dividends Paid">Dividends Paid</option>
                    <option value="Drawings">Drawings</option>
                    <option value="Investments">Investments</option>
                    <option value="Opening Balance Offset">Opening Balance Offset</option>
                    <option value="Owner's Equity">Owner's Equity</option>
                  </optgroup>
                </select>
              </div>
            </div>

            {/* Vendor */}
            <div style={rowStyle}>
              <div style={labelContainerStyle}>
                <label style={blackLabelStyle}>Vendor</label>
              </div>
              <div style={{ ...inputContainerStyle, display: 'flex' }}>
                <select value={vendorId} onChange={e => setVendorId(e.target.value)} style={{ ...inputFieldStyle, flex: 1, borderRadius: '4px 0 0 4px' }}>
                  <option value="">Select an account</option>
                  {vendors.map(v => <option key={v.id} value={v.id}>{v.display_name}</option>)}
                </select>
                <button style={{ background: '#3b82f6', border: 'none', width: '36px', borderRadius: '0 4px 4px 0', color: '#fff', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                </button>
              </div>
            </div>

            {/* Invoice# */}
            <div style={rowStyle}>
              <div style={labelContainerStyle}>
                <label style={blackLabelStyle}>Invoice#</label>
              </div>
              <div style={inputContainerStyle}>
                <input type="text" value={reference} onChange={e => setReference(e.target.value)} style={inputFieldStyle} />
              </div>
            </div>

            {/* Notes */}
            <div style={rowStyle}>
              <div style={labelContainerStyle}>
                <label style={blackLabelStyle}>Notes</label>
              </div>
              <div style={inputContainerStyle}>
                <textarea 
                  placeholder="Max. 500 characters" 
                  value={description} 
                  onChange={e => setDescription(e.target.value)} 
                  maxLength={500}
                  style={{ ...inputFieldStyle, minHeight: '80px', resize: 'vertical' }} 
                />
              </div>
            </div>



          </div>

          {/* Right Receipt Upload Area */}
          <div style={{ width: '300px' }}>
            <div 
              style={{ 
                background: '#fff', 
                border: '1px dashed #d1d5db', 
                borderRadius: '8px', 
                padding: '40px 20px', 
                textAlign: 'center',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              {/* Receipt Icon / Illustration */}
              <div style={{ width: '60px', height: '60px', background: '#1e3a8a', borderRadius: '12px', marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', position: 'relative' }}>
                <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: '40%', background: '#3b82f6', clipPath: 'polygon(0 100%, 0 40%, 30% 0%, 70% 50%, 100% 10%, 100% 100%)' }}></div>
                <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: '50%', background: '#60a5fa', clipPath: 'polygon(0 100%, 0 60%, 40% 10%, 80% 60%, 100% 40%, 100% 100%)', opacity: 0.8 }}></div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="#fff" style={{ position: 'absolute', top: '15px', right: '15px' }}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
              </div>
              
              <h3 style={{ margin: '0 0 5px 0', fontSize: '15px', fontWeight: '600', color: '#111827' }}>Drag or Drop your Receipts</h3>
              <p style={{ margin: '0 0 20px 0', fontSize: '12px', color: '#6b7280' }}>Maximum file size allowed is 10MB</p>
              
              <button 
                onClick={() => fileInputRef.current && fileInputRef.current.click()}
                style={{ 
                  background: '#f3f4f6', 
                  border: '1px solid #e5e7eb', 
                  borderRadius: '4px', 
                  padding: '8px 16px', 
                  color: '#374151', 
                  fontSize: '13px', 
                  fontWeight: '500', 
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px'
                }}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="17 8 12 3 7 8"></polyline><line x1="12" y1="3" x2="12" y2="15"></line></svg>
                {file ? file.name.substring(0, 15) + "..." : "Upload your Files"}
              </button>
              <input type="file" ref={fileInputRef} onChange={handleFileSelect} style={{ display: 'none' }} />
            </div>
          </div>
        </div>
        )}



        {activeTab === 'Bulk Add Expenses' && (
          <div style={{ maxWidth: '100%', overflowX: 'auto', padding: '10px 0' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '1100px' }}>
              <thead>
                <tr>
                  <th style={{ padding: '10px', textAlign: 'center', width: '30px', color: '#6b7280' }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><line x1="3" y1="9" x2="21" y2="9"></line><line x1="9" y1="21" x2="9" y2="9"></line></svg>
                  </th>
                  <th style={{ padding: '10px', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#ef4444' }}>DATE*</th>
                  <th style={{ padding: '10px', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#ef4444' }}>EXPENSE ACCOUNT*</th>
                  <th style={{ padding: '10px', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#ef4444' }}>AMOUNT*</th>
                  <th style={{ padding: '10px', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#ef4444' }}>PAID THROUGH*</th>
                  <th style={{ padding: '10px', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#6b7280' }}>VENDOR</th>

                  <th style={{ padding: '10px', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#6b7280' }}>PROJECTS</th>
                  <th style={{ padding: '10px', textAlign: 'center', fontSize: '11px', fontWeight: '600', color: '#6b7280' }}>BILLABLE</th>
                  <th style={{ padding: '10px', width: '30px' }}></th>
                </tr>
              </thead>
              <tbody>
                {bulkRows.map((row, index) => (
                  <tr key={index} style={{ borderBottom: '1px solid transparent' }}>
                    <td style={{ padding: '5px' }}></td>
                    <td style={{ padding: '5px' }}>
                      <input type="date" value={row.date} onChange={(e) => {
                        const newRows = [...bulkRows];
                        newRows[index].date = e.target.value;
                        setBulkRows(newRows);
                      }} style={{ width: '100%', padding: '6px', border: '1px solid #d1d5db', borderRadius: '4px', fontSize: '13px', boxSizing: 'border-box' }} />
                    </td>
                    <td style={{ padding: '5px' }}>
                      <select value={row.account} onChange={(e) => {
                        const newRows = [...bulkRows];
                        newRows[index].account = e.target.value;
                        setBulkRows(newRows);
                      }} style={{ width: '100%', padding: '6px', border: '1px solid #d1d5db', borderRadius: '4px', fontSize: '13px', boxSizing: 'border-box', background: '#fff' }}>
                        <option value="">Select an account</option>
                        <optgroup label="Cost Of Goods Sold">
                          <option value="Cost of Goods Sold">Cost of Goods Sold</option>
                          <option value="Job Costing">Job Costing</option>
                          <option value="Labor">Labor</option>
                          <option value="Materials">Materials</option>
                          <option value="Subcontractor">Subcontractor</option>
                        </optgroup>
                        <optgroup label="Expense">
                          <option value="Advertising And Marketing">Advertising And Marketing</option>
                          <option value="Automobile Expense">Automobile Expense</option>
                          <option value="Bad Debt">Bad Debt</option>
                          <option value="Bank Fees and Charges">Bank Fees and Charges</option>
                          <option value="Consultant Expense">Consultant Expense</option>
                          <option value="Contract Assets">Contract Assets</option>
                          <option value="Credit Card Charges">Credit Card Charges</option>
                          <option value="Depreciation And Amortisation">Depreciation And Amortisation</option>
                          <option value="Depreciation Expense">Depreciation Expense</option>
                          <option value="Fuel/Mileage Expenses">Fuel/Mileage Expenses</option>
                          <option value="IT and Internet Expenses">IT and Internet Expenses</option>
                          <option value="Janitorial Expense">Janitorial Expense</option>
                          <option value="Lodging">Lodging</option>
                          <option value="Meals and Entertainment">Meals and Entertainment</option>
                          <option value="Merchandise">Merchandise</option>
                          <option value="Office Supplies">Office Supplies</option>
                          <option value="Other Expenses">Other Expenses</option>
                          <option value="Postage">Postage</option>
                          <option value="Printing and Stationery">Printing and Stationery</option>
                          <option value="Purchase Discounts">Purchase Discounts</option>
                          <option value="Raw Materials And Consumables">Raw Materials And Consumables</option>
                          <option value="Rent Expense">Rent Expense</option>
                          <option value="Repairs and Maintenance">Repairs and Maintenance</option>
                          <option value="Salaries and Employee Wages">Salaries and Employee Wages</option>
                          <option value="Telephone Expense">Telephone Expense</option>
                          <option value="Transportation Expense">Transportation Expense</option>
                          <option value="Travel Expense">Travel Expense</option>
                        </optgroup>
                        <optgroup label="Non Current Liability">
                          <option value="Construction Loans">Construction Loans</option>
                          <option value="Mortgages">Mortgages</option>
                        </optgroup>
                        <optgroup label="Other Current Liability">
                          <option value="Employee Reimbursements">Employee Reimbursements</option>
                          <option value="Tax Payable">Tax Payable</option>
                          <option value="TDS Payable">TDS Payable</option>
                        </optgroup>
                        <optgroup label="Fixed Asset">
                          <option value="Furniture and Equipment">Furniture and Equipment</option>
                        </optgroup>
                        <optgroup label="Other Current Asset">
                          <option value="Advance Tax">Advance Tax</option>
                          <option value="Employee Advance">Employee Advance</option>
                          <option value="Prepaid Expenses">Prepaid Expenses</option>
                          <option value="TDS Receivable">TDS Receivable</option>
                        </optgroup>
                      </select>
                    </td>
                    <td style={{ padding: '5px' }}>
                      <div style={{ display: 'flex' }}>
                        <select style={{ padding: '6px', border: '1px solid #d1d5db', borderRight: 'none', borderRadius: '4px 0 0 4px', fontSize: '13px', background: '#f9fafb', boxSizing: 'border-box' }}><option>INR</option></select>
                        <input type="number" placeholder="0.00" value={row.amount} onChange={(e) => {
                          const newRows = [...bulkRows];
                          newRows[index].amount = e.target.value;
                          setBulkRows(newRows);
                        }} style={{ width: '100%', padding: '6px', border: '1px solid #d1d5db', borderRadius: '0 4px 4px 0', fontSize: '13px', boxSizing: 'border-box' }} />
                      </div>
                    </td>
                    <td style={{ padding: '5px' }}>
                      <select value={row.paidThrough} onChange={(e) => {
                        const newRows = [...bulkRows];
                        newRows[index].paidThrough = e.target.value;
                        setBulkRows(newRows);
                      }} style={{ width: '100%', padding: '6px', border: '1px solid #d1d5db', borderRadius: '4px', fontSize: '13px', boxSizing: 'border-box', background: '#fff' }}>
                        <option value="">Select an account</option>
                        <optgroup label="Cash">
                          <option value="Petty Cash">Petty Cash</option>
                          <option value="Undeposited Funds">Undeposited Funds</option>
                        </optgroup>
                        <optgroup label="Other Current Asset">
                          <option value="Advance Tax">Advance Tax</option>
                          <option value="Employee Advance">Employee Advance</option>
                          <option value="Prepaid Expenses">Prepaid Expenses</option>
                          <option value="TDS Receivable">TDS Receivable</option>
                        </optgroup>
                        <optgroup label="Fixed Asset">
                          <option value="Furniture and Equipment">Furniture and Equipment</option>
                        </optgroup>
                        <optgroup label="Other Current Liability">
                          <option value="Employee Reimbursements">Employee Reimbursements</option>
                          <option value="TDS Payable">TDS Payable</option>
                        </optgroup>
                        <optgroup label="Non Current Liability">
                          <option value="Construction Loans">Construction Loans</option>
                          <option value="Mortgages">Mortgages</option>
                        </optgroup>
                        <optgroup label="Equity">
                          <option value="Capital Stock">Capital Stock</option>
                          <option value="Distributions">Distributions</option>
                          <option value="Dividends Paid">Dividends Paid</option>
                          <option value="Drawings">Drawings</option>
                          <option value="Investments">Investments</option>
                          <option value="Opening Balance Offset">Opening Balance Offset</option>
                          <option value="Owner's Equity">Owner's Equity</option>
                        </optgroup>
                      </select>
                    </td>
                    <td style={{ padding: '5px' }}>
                      <select value={row.vendor} onChange={(e) => {
                        const newRows = [...bulkRows];
                        newRows[index].vendor = e.target.value;
                        setBulkRows(newRows);
                      }} style={{ width: '100%', padding: '6px', border: '1px solid #d1d5db', borderRadius: '4px', fontSize: '13px', boxSizing: 'border-box', background: '#fff' }}>
                        <option value=""></option>
                        {vendors.map(v => <option key={v.id} value={v.id}>{v.display_name}</option>)}
                      </select>
                    </td>

                    <td style={{ padding: '5px' }}>
                      <select value={row.project} onChange={(e) => {
                        const newRows = [...bulkRows];
                        newRows[index].project = e.target.value;
                        setBulkRows(newRows);
                      }} style={{ width: '100%', padding: '6px', border: '1px solid #d1d5db', borderRadius: '4px', fontSize: '13px', boxSizing: 'border-box', background: '#fff' }}>
                        <option value=""></option>
                      </select>
                    </td>
                    <td style={{ padding: '5px', textAlign: 'center' }}>
                      <input type="checkbox" checked={row.billable} onChange={(e) => {
                        const newRows = [...bulkRows];
                        newRows[index].billable = e.target.checked;
                        setBulkRows(newRows);
                      }} style={{ width: '14px', height: '14px', cursor: 'pointer', accentColor: '#3b82f6' }} />
                    </td>
                    <td style={{ padding: '5px', textAlign: 'center', color: '#9ca3af', cursor: 'pointer', fontSize: '18px', fontWeight: 'bold' }}>
                      &#8942;
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div style={{ marginTop: '30px', marginLeft: '10px' }}>
              <button 
                type="button" 
                onClick={() => setBulkRows(prev => [...prev, { date: "", account: "", amount: "", paidThrough: "", vendor: "", project: "", billable: false }])}
                style={{ background: 'none', border: 'none', color: '#2563eb', fontSize: '14px', fontWeight: '500', cursor: 'pointer', padding: 0, display: 'flex', alignItems: 'center', gap: '5px' }}
              >
                <span style={{ fontSize: '16px' }}>+</span> Add More Expenses
              </button>
            </div>
          </div>
        )}



        {/* Manage Employees Modal */}
        {showEmployeeModal && (
          <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0, 0, 0, 0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ background: '#fff', borderRadius: '8px', boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)', width: '100%', maxWidth: '600px', maxHeight: '90vh', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
              
              {/* Header */}
              <div style={{ padding: '20px 30px', borderBottom: '1px solid #e5e7eb', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h2 style={{ margin: 0, color: '#111827', fontSize: '20px', fontWeight: '400' }}>Manage Employees</h2>
                <button onClick={() => { setShowEmployeeModal(false); setIsAddingEmployee(false); }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', fontSize: '20px' }}>
                  &#x2715;
                </button>
              </div>

              {/* Body */}
              <div style={{ padding: '20px 30px', overflowY: 'auto' }}>
                
                {/* Add New Section */}
                <div style={{ paddingBottom: '15px', borderBottom: '1px solid #e5e7eb' }}>
                  {!isAddingEmployee ? (
                    <button onClick={() => setIsAddingEmployee(true)} style={{ background: 'none', border: 'none', color: '#2563eb', fontSize: '15px', fontWeight: '500', cursor: 'pointer', padding: 0 }}>
                      + Add New Employee
                    </button>
                  ) : (
                    <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
                      <div>
                        <input 
                          type="text" 
                          list="employee-add-list"
                          placeholder="Select or type to add" 
                          value={newEmpEmail}
                          onChange={e => setNewEmpEmail(e.target.value)}
                          style={{ ...inputFieldStyle, width: '200px' }} 
                        />
                        <datalist id="employee-add-list">
                          {employees.map((emp, index) => (
                            <option key={index} value={emp.email || emp.name} />
                          ))}
                        </datalist>
                      </div>
                      <input 
                        type="text" 
                        placeholder="Name" 
                        value={newEmpName}
                        onChange={e => setNewEmpName(e.target.value)}
                        style={{ ...inputFieldStyle, flex: 1 }} 
                      />
                      <button 
                        type="button"
                        onClick={(e) => {
                          e.preventDefault();
                          if (newEmpEmail || newEmpName) {
                            setEmployees(prev => [...prev, { email: newEmpEmail, name: newEmpName }]);
                            setNewEmpEmail("");
                            setNewEmpName("");
                            setIsAddingEmployee(false);
                          }
                        }} 
                        style={{ background: '#3b82f6', color: '#fff', border: 'none', padding: '8px 20px', borderRadius: '4px', fontSize: '14px', fontWeight: '500', cursor: 'pointer' }}
                      >
                        Save
                      </button>
                    </div>
                  )}
                </div>

                {/* Employee List */}
                <div style={{ padding: '15px 0', color: '#374151', fontSize: '15px' }}>
                  {employees.map((emp, index) => (
                    <div key={index} style={{ marginBottom: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>{emp.name || emp.email} {emp.email && emp.name ? `(${emp.email})` : ''}</div>
                      <button 
                        onClick={() => {
                          setEmployees(prev => prev.filter((_, i) => i !== index));
                          if (selectedEmployee === String(index)) {
                            setSelectedEmployee("");
                          } else if (selectedEmployee && Number(selectedEmployee) > index) {
                            setSelectedEmployee(String(Number(selectedEmployee) - 1));
                          }
                        }}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', padding: '0 5px' }}
                        title="Delete Employee"
                      >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                      </button>
                    </div>
                  ))}
                </div>

              </div>

            </div>
          </div>
        )}
      </div>

      {/* Bottom Action Bar */}
      <div style={{ background: '#fff', borderTop: '1px solid #e5e7eb', padding: '15px 30px', display: 'flex', gap: '10px', position: 'sticky', bottom: 0 }}>
        <button onClick={() => handleSave(false)} disabled={saving} style={{ background: '#3b82f6', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '4px', fontSize: '13px', fontWeight: '500', cursor: 'pointer' }}>
          {saving ? 'Saving...' : 'Save'}
        </button>
        {!isEdit && (
          <button onClick={() => handleSave(true)} disabled={saving} style={{ background: '#f3f4f6', color: '#374151', border: '1px solid #d1d5db', padding: '8px 16px', borderRadius: '4px', fontSize: '13px', fontWeight: '500', cursor: 'pointer' }}>
            Save and New (Alt+N)
          </button>
        )}
        <button onClick={() => navigate("/expenses")} disabled={saving} style={{ background: '#fff', color: '#374151', border: '1px solid transparent', padding: '8px 16px', borderRadius: '4px', fontSize: '13px', fontWeight: '500', cursor: 'pointer' }}>
          Cancel
        </button>
      </div>

    </div>
  );
}

// --- Styles ---
const rowStyle = { display: 'flex', marginBottom: '20px', alignItems: 'flex-start' };
const labelContainerStyle = { width: '180px', paddingTop: '8px' };
const inputContainerStyle = { flex: 1, maxWidth: '400px' };
const inputFieldStyle = { width: '100%', padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: '4px', fontSize: '14px', outline: 'none', boxSizing: 'border-box', fontFamily: 'inherit', color: '#111827' };
const reqStyle = { color: '#ef4444', marginLeft: '2px' };

const redLabelStyle = { color: '#ef4444', fontSize: '13px' };
const blackLabelStyle = { color: '#111827', fontSize: '13px' };

export default AddExpense;
