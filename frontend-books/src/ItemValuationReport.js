import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiRequest } from './api';
import toast from 'react-hot-toast';

export default function ItemValuationReport() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchValuation = async () => {
      try {
        const res = await apiRequest('/items');
        if (res.items) {
          const trackedItems = res.items.filter(item => item.is_inventory_tracked);
          setItems(trackedItems);
        }
      } catch (err) {
        toast.error('Failed to load valuation data');
      } finally {
        setLoading(false);
      }
    };
    fetchValuation();
  }, []);

  const totalInventoryValue = items.reduce((sum, item) => {
    const qty = parseFloat(item.stock_quantity) || 0;
    const rate = parseFloat(item.current_valuation_rate) || parseFloat(item.cost_price) || 0;
    return sum + (qty * rate);
  }, 0);

  const formatCurrency = (val) => {
    return "₹" + parseFloat(val || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

  return (
    <div style={{ padding: '30px', background: '#f8fafc', minHeight: 'calc(100vh - 60px)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '24px' }}>
        <div>
          <h2 style={{ margin: 0, fontSize: '24px', color: '#1e293b' }}>Inventory Valuation Summary</h2>
          <p style={{ margin: '5px 0 0 0', color: '#64748b', fontSize: '14px' }}>Real-time weighted average valuation of your stock.</p>
        </div>
        <div style={{ background: '#fff', padding: '15px 25px', borderRadius: '8px', border: '1px solid #e2e8f0', boxShadow: '0 2px 4px rgba(0,0,0,0.02)', textAlign: 'right' }}>
          <div style={{ fontSize: '13px', color: '#64748b', textTransform: 'uppercase', fontWeight: '600', marginBottom: '4px' }}>Total Inventory Value</div>
          <div style={{ fontSize: '24px', color: '#0f172a', fontWeight: 'bold' }}>{formatCurrency(totalInventoryValue)}</div>
        </div>
      </div>

      <div style={{ background: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0', flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {loading ? (
          <div style={{ padding: '20px', color: '#64748b' }}>Loading report...</div>
        ) : items.length === 0 ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>
            <p style={{ fontSize: '16px' }}>No inventory tracked items found.</p>
          </div>
        ) : (
          <div style={{ overflow: 'auto', flex: 1 }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead style={{ position: 'sticky', top: 0, background: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
                <tr>
                  <th style={thStyle}>Item Name</th>
                  <th style={thStyle}>SKU</th>
                  <th style={{ ...thStyle, textAlign: 'right' }}>Stock on Hand</th>
                  <th style={{ ...thStyle, textAlign: 'right' }}>Valuation Rate</th>
                  <th style={{ ...thStyle, textAlign: 'right' }}>Inventory Value</th>
                </tr>
              </thead>
              <tbody>
                {items.map(item => {
                  const qty = parseFloat(item.stock_quantity) || 0;
                  const rate = parseFloat(item.current_valuation_rate) || parseFloat(item.cost_price) || 0;
                  const value = qty * rate;
                  
                  return (
                    <tr key={item.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                      <td style={{ ...tdStyle, color: '#2563eb', cursor: 'pointer', fontWeight: '500' }} onClick={() => navigate('/items')}>
                        {item.name}
                      </td>
                      <td style={tdStyle}>{item.sku || '—'}</td>
                      <td style={{ ...tdStyle, textAlign: 'right', fontWeight: '600' }}>
                        {qty} {item.unit}
                      </td>
                      <td style={{ ...tdStyle, textAlign: 'right' }}>
                        {formatCurrency(rate)}
                      </td>
                      <td style={{ ...tdStyle, textAlign: 'right', fontWeight: 'bold', color: '#334155' }}>
                        {formatCurrency(value)}
                      </td>
                    </tr>
                  );
                })}
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
