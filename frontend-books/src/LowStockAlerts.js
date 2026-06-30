import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiRequest } from './api';
import toast from 'react-hot-toast';

export default function LowStockAlerts() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchLowStock = async () => {
      try {
        const res = await apiRequest('/items/low-stock');
        setItems(res.items || []);
      } catch (err) {
        toast.error('Failed to load low stock items');
      } finally {
        setLoading(false);
      }
    };
    fetchLowStock();
  }, []);

  return (
    <div style={{ padding: '30px', background: '#f8fafc', minHeight: 'calc(100vh - 60px)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h2 style={{ margin: 0, fontSize: '24px', color: '#1e293b' }}>Low Stock Alerts</h2>
          <p style={{ margin: '5px 0 0 0', color: '#64748b', fontSize: '14px' }}>Items that have fallen to or below their reorder level.</p>
        </div>
      </div>

      <div style={{ background: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0', flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {loading ? (
          <div style={{ padding: '20px', color: '#64748b' }}>Loading...</div>
        ) : items.length === 0 ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" style={{ marginBottom: '10px', color: '#94a3b8' }}>
              <path d="M22 12h-4l-3 9L9 3l-3 9H2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <p style={{ fontSize: '16px' }}>All good! No items are currently low on stock.</p>
          </div>
        ) : (
          <div style={{ overflow: 'auto', flex: 1 }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead style={{ position: 'sticky', top: 0, background: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
                <tr>
                  <th style={thStyle}>Item Name</th>
                  <th style={thStyle}>SKU</th>
                  <th style={thStyle}>Current Stock</th>
                  <th style={thStyle}>Reorder Level</th>
                  <th style={thStyle}>Action</th>
                </tr>
              </thead>
              <tbody>
                {items.map(item => (
                  <tr key={item.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <td style={{ ...tdStyle, color: '#2563eb', cursor: 'pointer', fontWeight: '500' }} onClick={() => navigate('/items')}>
                      {item.name}
                    </td>
                    <td style={tdStyle}>{item.sku || '—'}</td>
                    <td style={{ ...tdStyle, fontWeight: 'bold', color: '#dc2626' }}>
                      {item.stock_quantity}
                    </td>
                    <td style={tdStyle}>{item.reorder_level}</td>
                    <td style={tdStyle}>
                      <button onClick={() => navigate('/purchase-orders/new')} style={orderBtnStyle}>
                        Create PO
                      </button>
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

const thStyle = { padding: '12px 16px', fontSize: '12px', textTransform: 'uppercase', color: '#64748b', fontWeight: '600' };
const tdStyle = { padding: '16px', fontSize: '14px', color: '#334155' };
const orderBtnStyle = { padding: '6px 12px', background: '#3b82f6', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '12px', fontWeight: '500' };
