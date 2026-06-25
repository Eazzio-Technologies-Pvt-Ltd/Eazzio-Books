import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function AddInventoryMovement() {
  const navigate = useNavigate();
  const location = useLocation();

  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);
  const [items, setItems] = useState([]);
  
  const [itemId, setItemId] = useState("");
  const [movementType, setMovementType] = useState("stock_in");
  const [quantity, setQuantity] = useState("");
  const [reason, setReason] = useState("");
  const [referenceNumber, setReferenceNumber] = useState("");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    fetchItems();
  }, []);

  // Check if we came here from the Items page with a preselected item and type
  useEffect(() => {
    if (items.length > 0 && location.state) {
      if (location.state.itemId) setItemId(location.state.itemId.toString());
      if (location.state.type) setMovementType(location.state.type);
    }
  }, [items, location.state]);

  const fetchItems = async () => {
    try {
      const res = await apiRequest("/items");
      setItems(res?.items || []);
    } catch (err) {
      toast.error("Failed to load items");
    } finally {
      setInitialLoading(false);
    }
  };

  const selectedItem = items.find(i => i.id === parseInt(itemId));

  const handleSave = async (e) => {
    e.preventDefault();
    if (!itemId) return toast.error("Please select an item");
    
    const qty = parseFloat(quantity);
    if (!qty || qty <= 0) return toast.error("Quantity must be greater than 0");

    if (movementType === "stock_out" && selectedItem && qty > parseFloat(selectedItem.stock_quantity || 0)) {
      return toast.error(`Cannot stock out ${qty}. Current stock is only ${selectedItem.stock_quantity || 0}.`);
    }

    setLoading(true);
    try {
      const payload = {
        item_id: itemId,
        movement_type: movementType,
        quantity: qty,
        reason,
        reference_number: referenceNumber,
        notes
      };

      await apiRequest("/inventory/movements", { method: "POST", body: JSON.stringify(payload) });
      toast.success("Inventory adjusted successfully");
      navigate("/inventory-adjustments");
    } catch (err) {
      toast.error(err.message || "Failed to adjust inventory");
    } finally {
      setLoading(false);
    }
  };

  // Stock status calculation for selected item
  const currentStock = selectedItem ? parseFloat(selectedItem.stock_quantity || 0) : 0;
  const reorderLevel = selectedItem ? parseFloat(selectedItem.reorder_level || 0) : 0;
  const isLowStock = selectedItem ? currentStock <= reorderLevel : false;
  const statusColor = isLowStock ? "#d92d20" : "#12b76a";
  const statusBg = isLowStock ? "rgba(217, 45, 32, 0.08)" : "rgba(18, 183, 106, 0.08)";

  return (
    <div className="adjustment-container">
      {/* Style Injection */}
      <style dangerouslySetInnerHTML={{__html: `
        .adjustment-container {
          padding: 30px 20px;
          max-width: 850px;
          margin: auto;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        .premium-card {
          background: var(--bg-card);
          border: 1px solid var(--border-color);
          border-radius: 12px;
          box-shadow: var(--shadow-lg);
          padding: 32px;
          animation: fadeInUp 0.3s ease-out;
        }
        .form-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 28px;
          border-bottom: 1px solid var(--border-color);
          padding-bottom: 20px;
        }
        .header-title-container {
          display: flex;
          align-items: center;
          gap: 14px;
        }
        .header-icon {
          width: 44px;
          height: 44px;
          border-radius: 10px;
          background: rgba(0, 110, 230, 0.08);
          display: flex;
          align-items: center;
          justify-content: center;
          color: #006ee6;
        }
        .header-title {
          margin: 0;
          font-size: 20px;
          font-weight: 700;
          color: var(--text-primary);
        }
        .header-subtitle {
          margin: 2px 0 0 0;
          font-size: 13px;
          color: var(--text-muted);
        }
        .form-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 24px;
          margin-bottom: 24px;
        }
        .form-group-full {
          grid-column: span 2;
        }
        @media (max-width: 600px) {
          .form-grid {
            grid-template-columns: 1fr;
          }
          .form-group-full {
            grid-column: span 1;
          }
        }
        .premium-label {
          display: block;
          font-size: 13px;
          font-weight: 600;
          color: var(--text-secondary);
          margin-bottom: 8px;
        }
        .premium-input {
          width: 100%;
          padding: 11px 14px;
          border: 1px solid var(--border-color);
          border-radius: 8px;
          font-size: 14px;
          color: var(--text-primary);
          background: var(--bg-input);
          box-sizing: border-box;
          outline: none;
          transition: all 0.2s ease;
        }
        .premium-input:hover {
          border-color: var(--border-color-hover);
        }
        .premium-input:focus {
          border-color: #006ee6;
          box-shadow: 0 0 0 3px rgba(0, 110, 230, 0.15);
        }
        .segmented-control {
          display: flex;
          gap: 4px;
          background: var(--bg-hover);
          padding: 4px;
          border-radius: 8px;
          border: 1px solid var(--border-color);
          width: 100%;
          box-sizing: border-box;
        }
        .segmented-btn {
          flex: 1;
          padding: 9px 12px;
          border-radius: 6px;
          border: none;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s ease;
          background: transparent;
          color: var(--text-secondary);
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
        }
        .segmented-btn.active {
          background: #006ee6;
          color: #ffffff;
          box-shadow: 0 2px 4px rgba(0, 110, 230, 0.15);
        }
        .segmented-btn:not(.active):hover {
          background: rgba(0, 0, 0, 0.04);
        }
        [data-theme='dark'] .segmented-btn:not(.active):hover {
          background: rgba(255, 255, 255, 0.04);
        }
        .stock-card {
          background: var(--bg-hover);
          border: 1px solid var(--border-color);
          border-radius: 12px;
          padding: 16px 20px;
          margin-bottom: 24px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 20px;
          flex-wrap: wrap;
          animation: fadeInUp 0.3s ease-out;
        }
        .stock-card-left {
          display: flex;
          align-items: center;
          gap: 14px;
        }
        .stock-badge-icon {
          width: 42px;
          height: 42px;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .stock-details {
          display: flex;
          gap: 24px;
        }
        .stock-details-col {
          text-align: right;
        }
        .stock-details-col:not(:first-child) {
          border-left: 1px solid var(--border-color);
          padding-left: 24px;
        }
        .btn-group {
          display: flex;
          justify-content: flex-end;
          gap: 12px;
          margin-top: 28px;
          border-top: 1px solid var(--border-color);
          padding-top: 24px;
        }
        .btn-primary {
          padding: 11px 22px;
          background: #006ee6;
          color: #ffffff;
          border: none;
          border-radius: 8px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s ease;
          box-shadow: 0 2px 4px rgba(0, 110, 230, 0.1);
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }
        .btn-primary:hover:not(:disabled) {
          background: #0056b3;
          transform: translateY(-1px);
          box-shadow: 0 4px 8px rgba(0, 110, 230, 0.2);
        }
        .btn-primary:active:not(:disabled) {
          transform: translateY(0);
        }
        .btn-primary:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
        .btn-secondary {
          padding: 11px 22px;
          background: var(--bg-card);
          color: var(--text-secondary);
          border: 1px solid var(--border-color);
          border-radius: 8px;
          font-size: 14px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s ease;
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }
        .btn-secondary:hover {
          background: var(--bg-hover);
          border-color: var(--border-color-hover);
        }
        .input-unit-container {
          position: relative;
          display: flex;
          align-items: center;
          width: 100%;
        }
        .input-unit-badge {
          position: absolute;
          right: 14px;
          font-size: 12px;
          font-weight: 600;
          color: var(--text-muted);
          pointer-events: none;
        }
        @keyframes fadeInUp {
          from {
            opacity: 0;
            transform: translateY(10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      `}} />

      {initialLoading ? (
        <FormSkeleton fields={4} />
      ) : (
        <div className="premium-card">
          <div className="form-header">
            <div className="header-title-container">
              <div className="header-icon">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
                  <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
                  <line x1="12" y1="22.08" x2="12" y2="12"></line>
                </svg>
              </div>
              <div>
                <h2 className="header-title">New Inventory Adjustment</h2>
                <p className="header-subtitle">Adjust item quantities, record stock movements, or align current levels</p>
              </div>
            </div>
            <button type="button" onClick={() => navigate(-1)} className="btn-secondary" style={{ padding: "8px 14px", fontSize: "13px" }}>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <line x1="19" y1="12" x2="5" y2="12"></line>
                <polyline points="12 19 5 12 12 5"></polyline>
              </svg>
              Back
            </button>
          </div>

          <form onSubmit={handleSave}>
            <div className="form-grid">
              
              {/* Item selection */}
              <div>
                <label className="premium-label">Item *</label>
                <select value={itemId} onChange={e => setItemId(e.target.value)} className="premium-input" required>
                  <option value="">Select an Item</option>
                  {items.filter(i => i.item_type !== "Service").map(i => (
                    <option key={i.id} value={i.id}>{i.name} (SKU: {i.sku || "N/A"})</option>
                  ))}
                </select>
              </div>

              {/* Movement Type Segmented Control */}
              <div>
                <label className="premium-label">Movement Type *</label>
                <div className="segmented-control">
                  {[
                    { value: "stock_in", label: "Stock In", subtitle: "Increase" },
                    { value: "stock_out", label: "Stock Out", subtitle: "Decrease" },
                    { value: "adjustment", label: "Adjustment", subtitle: "Set value" }
                  ].map((opt) => (
                    <button
                      key={opt.value}
                      type="button"
                      onClick={() => setMovementType(opt.value)}
                      className={`segmented-btn ${movementType === opt.value ? 'active' : ''}`}
                    >
                      {opt.value === "stock_in" && (
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <line x1="12" y1="5" x2="12" y2="19"></line>
                          <polyline points="19 12 12 19 5 12"></polyline>
                        </svg>
                      )}
                      {opt.value === "stock_out" && (
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <line x1="12" y1="19" x2="12" y2="5"></line>
                          <polyline points="5 12 12 5 19 12"></polyline>
                        </svg>
                      )}
                      {opt.value === "adjustment" && (
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <line x1="5" y1="9" x2="19" y2="9"></line>
                          <line x1="5" y1="15" x2="19" y2="15"></line>
                        </svg>
                      )}
                      <span>{opt.label}</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Selected Item Stats Summary */}
            {selectedItem && (
              <div className="stock-card">
                <div className="stock-card-left">
                  <div className="stock-badge-icon" style={{ background: statusBg, color: statusColor }}>
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
                      <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
                      <line x1="12" y1="22.08" x2="12" y2="12"></line>
                    </svg>
                  </div>
                  <div>
                    <h4 style={{ margin: "0 0 3px 0", fontSize: "14px", fontWeight: "600", color: "var(--text-primary)" }}>
                      {selectedItem.name}
                    </h4>
                    <p style={{ margin: 0, fontSize: "12px", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "6px" }}>
                      <span>SKU: {selectedItem.sku || "N/A"}</span>
                      <span>•</span>
                      <span>Category: {selectedItem.category || "General"}</span>
                    </p>
                  </div>
                </div>
                
                <div className="stock-details">
                  <div className="stock-details-col">
                    <span style={{ display: "block", fontSize: "10px", color: "var(--text-muted)", textTransform: "uppercase", fontWeight: "600", letterSpacing: "0.05em", marginBottom: "3px" }}>Current Stock</span>
                    <span style={{ fontSize: "16px", fontWeight: "700", color: statusColor, display: "flex", alignItems: "center", justifyContent: "flex-end", gap: "6px" }}>
                      {currentStock} {selectedItem.unit}
                      {isLowStock && (
                        <span style={{
                          fontSize: "9px",
                          padding: "1px 5px",
                          background: "#fee4e2",
                          color: "#d92d20",
                          borderRadius: "6px",
                          fontWeight: "700"
                        }}>Low Stock</span>
                      )}
                    </span>
                  </div>
                  
                  <div className="stock-details-col">
                    <span style={{ display: "block", fontSize: "10px", color: "var(--text-muted)", textTransform: "uppercase", fontWeight: "600", letterSpacing: "0.05em", marginBottom: "3px" }}>Reorder Point</span>
                    <span style={{ fontSize: "16px", fontWeight: "700", color: "var(--text-primary)" }}>
                      {reorderLevel} {selectedItem.unit}
                    </span>
                  </div>

                  <div className="stock-details-col">
                    <span style={{ display: "block", fontSize: "10px", color: "var(--text-muted)", textTransform: "uppercase", fontWeight: "600", letterSpacing: "0.05em", marginBottom: "3px" }}>Unit Type</span>
                    <span style={{ fontSize: "14px", fontWeight: "600", color: "var(--text-secondary)" }}>
                      {selectedItem.unit || "N/A"}
                    </span>
                  </div>
                </div>
              </div>
            )}

            <div className="form-grid">
              {/* Quantity / Absolute Stock Level */}
              <div>
                <label className="premium-label">
                  {movementType === "adjustment" ? "New Absolute Stock Level" : "Quantity"} *
                </label>
                <div className="input-unit-container">
                  <input 
                    type="number" 
                    step="0.01" 
                    min="0.01" 
                    value={quantity} 
                    onChange={e => setQuantity(e.target.value)} 
                    className="premium-input" 
                    placeholder={movementType === "adjustment" ? "e.g. 150" : "e.g. 10"}
                    style={{ paddingRight: selectedItem ? "70px" : "14px" }}
                    required 
                  />
                  {selectedItem && (
                    <span className="input-unit-badge">
                      {selectedItem.unit || ""}
                    </span>
                  )}
                </div>
              </div>

              {/* Reference Number */}
              <div>
                <label className="premium-label">Reference Number</label>
                <input 
                  type="text" 
                  value={referenceNumber} 
                  onChange={e => setReferenceNumber(e.target.value)} 
                  className="premium-input" 
                  placeholder="e.g. ADJ-2026-001" 
                />
              </div>

              {/* Reason */}
              <div className="form-group-full">
                <label className="premium-label">Reason for Adjustment</label>
                <input 
                  type="text" 
                  value={reason} 
                  onChange={e => setReason(e.target.value)} 
                  className="premium-input" 
                  placeholder="e.g. Received from Supplier, Damaged Stock, Inventory Audit, Sample Given" 
                />
              </div>

              {/* Notes */}
              <div className="form-group-full">
                <label className="premium-label">Notes / Description</label>
                <textarea 
                  value={notes} 
                  onChange={e => setNotes(e.target.value)} 
                  rows={3} 
                  className="premium-input" 
                  placeholder="Provide additional details about this inventory movement..."
                  style={{ resize: "vertical" }}
                />
              </div>
            </div>

            {/* Actions Footer */}
            <div className="btn-group">
              <button type="button" onClick={() => navigate(-1)} className="btn-secondary">
                Cancel
              </button>
              <button type="submit" disabled={loading} className="btn-primary">
                {loading ? (
                  <>
                    <svg style={{ animation: "spin 1s linear infinite" }} width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <circle cx="12" cy="12" r="10" strokeDasharray="30" strokeDashoffset="10"></circle>
                    </svg>
                    Saving...
                  </>
                ) : (
                  <>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    Save Adjustment
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

export default AddInventoryMovement;
