import React, { useState, useEffect } from "react";
import { apiRequest } from "./api";
import { DetailSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function ProfitAndLoss() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  const fetchData = async () => {
    setLoading(true);
    try {
      let url = "/reports/pnl";
      const params = [];
      if (startDate) params.push(`start_date=${startDate}`);
      if (endDate) params.push(`end_date=${endDate}`);
      if (params.length > 0) url += "?" + params.join("&");

      const res = await apiRequest(url);
      setData(res);
    } catch (err) {
      toast.error("Failed to fetch Profit & Loss");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleExportCSV = () => {
    if (!data) {
      toast.error("No data to export");
      return;
    }

    const otherIncomeKeywords = ["interest", "discount", "dividend", "rent", "commission", "late fee", "other", "non-operating", "refund"];
    const isOtherIncome = (accName) => {
      if (!accName) return false;
      const name = accName.toLowerCase();
      return otherIncomeKeywords.some(keyword => name.includes(keyword));
    };

    const incomeAccounts = data?.income?.accounts || [];
    const operatingIncomeAccounts = incomeAccounts.filter(acc => !isOtherIncome(acc.account_name));
    const otherIncomeAccounts = incomeAccounts.filter(acc => isOtherIncome(acc.account_name));

    const totalOperating = operatingIncomeAccounts.reduce((sum, acc) => sum + (parseFloat(acc.balance) || 0), 0);
    const totalOther = otherIncomeAccounts.reduce((sum, acc) => sum + (parseFloat(acc.balance) || 0), 0);
    
    let csv = "Account Name,Balance (INR)\n";
    csv += "--- A) REVENUE FROM OPERATIONS ---\n";
    operatingIncomeAccounts.forEach(acc => {
      csv += `"${acc.account_name}",${parseFloat(acc.balance).toFixed(2)}\n`;
    });
    csv += `"Total Revenue from Operations",${totalOperating.toFixed(2)}\n\n`;

    csv += "--- B) OTHER INCOME ---\n";
    otherIncomeAccounts.forEach(acc => {
      csv += `"${acc.account_name}",${parseFloat(acc.balance).toFixed(2)}\n`;
    });
    csv += `"Total Other Income",${totalOther.toFixed(2)}\n\n`;
    
    csv += `"Total Incomes (A + B)",${parseFloat(data.income.total).toFixed(2)}\n\n`;
    
    csv += "--- OPERATING EXPENSES ---\n";
    data.expense.accounts.forEach(acc => {
      csv += `"${acc.account_name}",${parseFloat(acc.balance).toFixed(2)}\n`;
    });
    csv += `"Total Operating Expenses",${parseFloat(data.expense.total).toFixed(2)}\n\n`;
    
    csv += `"${data.net_profit >= 0 ? 'Net Profit' : 'Net Loss'}",${parseFloat(data.net_profit).toFixed(2)}\n`;

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `Profit_And_Loss_${startDate || 'all'}_to_${endDate || 'all'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div style={{ padding: "30px", maxWidth: "1000px", margin: "auto" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
        <h2>Profit and Loss</h2>
        <div style={{ display: "flex", gap: "10px" }} className="print-hide">
          <button onClick={handleExportCSV} style={primaryBtn}>Download CSV</button>
          <button onClick={() => window.print()} style={secondaryBtn}>Print / Save PDF</button>
        </div>
      </div>

      <div style={{ display: "flex", gap: "15px", marginBottom: "30px", background: "#f8fafc", padding: "15px", borderRadius: "8px", border: "1px solid #e2e8f0", alignItems: "flex-end" }}>
        <div>
          <label style={labelStyle}>Start Date</label>
          <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} style={inputStyle} />
        </div>
        <div>
          <label style={labelStyle}>End Date</label>
          <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} style={inputStyle} />
        </div>
        <button onClick={fetchData} style={primaryBtn}>Refresh</button>
      </div>

      <div style={{ background: "#fff", padding: "40px", borderRadius: "8px", boxShadow: "0 1px 3px rgba(0,0,0,0.1)" }}>
        {loading ? (
          <DetailSkeleton />
        ) : !data ? (
          <p style={{ textAlign: "center", padding: "40px", color: "#64748b" }}>No data found.</p>
        ) : (
          <div>
            {/* INCOME */}
            {(() => {
              const otherIncomeKeywords = ["interest", "discount", "dividend", "rent", "commission", "late fee", "other", "non-operating", "refund"];
              const isOtherIncome = (accName) => {
                if (!accName) return false;
                const name = accName.toLowerCase();
                return otherIncomeKeywords.some(keyword => name.includes(keyword));
              };

              const incomeAccounts = data?.income?.accounts || [];
              const operatingIncomeAccounts = incomeAccounts.filter(acc => !isOtherIncome(acc.account_name));
              const otherIncomeAccounts = incomeAccounts.filter(acc => isOtherIncome(acc.account_name));

              const totalOperating = operatingIncomeAccounts.reduce((sum, acc) => sum + (parseFloat(acc.balance) || 0), 0);
              const totalOther = otherIncomeAccounts.reduce((sum, acc) => sum + (parseFloat(acc.balance) || 0), 0);

              return (
                <div>
                  <h3 style={{ color: "#065f46", borderBottom: "1px solid #e2e8f0", paddingBottom: "10px" }}>Incomes</h3>
                  
                  {/* A) Revenue from Operations */}
                  <div style={{ marginBottom: "15px" }}>
                    <h4 style={{ color: "#0f766e", margin: "15px 0 5px 0", fontSize: "14px", fontWeight: "600" }}>A) Revenue from Operations</h4>
                    <table style={tableStyle}>
                      <tbody>
                        {operatingIncomeAccounts.length > 0 ? (
                          operatingIncomeAccounts.map((acc, idx) => (
                            <tr key={idx}>
                              <td style={{ ...tdStyle, paddingLeft: "15px" }}>{acc.account_name}</td>
                              <td style={{ ...tdStyle, textAlign: "right" }}>{parseFloat(acc.balance).toFixed(2)}</td>
                            </tr>
                          ))
                        ) : (
                          <tr>
                            <td style={{ ...tdStyle, paddingLeft: "15px", color: "#64748b", fontStyle: "italic" }}>No revenue from operations accounts found.</td>
                            <td style={{ ...tdStyle, textAlign: "right", color: "#64748b" }}>0.00</td>
                          </tr>
                        )}
                      </tbody>
                      <tfoot>
                        <tr style={{ fontWeight: "bold" }}>
                          <td style={{ ...tdStyle, paddingLeft: "15px" }}>Total Revenue from Operations</td>
                          <td style={{ ...tdStyle, textAlign: "right" }}>₹{totalOperating.toFixed(2)}</td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>

                  {/* B) Other Income */}
                  <div style={{ marginBottom: "15px" }}>
                    <h4 style={{ color: "#0f766e", margin: "15px 0 5px 0", fontSize: "14px", fontWeight: "600" }}>B) Other Income</h4>
                    <table style={tableStyle}>
                      <tbody>
                        {otherIncomeAccounts.length > 0 ? (
                          otherIncomeAccounts.map((acc, idx) => (
                            <tr key={idx}>
                              <td style={{ ...tdStyle, paddingLeft: "15px" }}>{acc.account_name}</td>
                              <td style={{ ...tdStyle, textAlign: "right" }}>{parseFloat(acc.balance).toFixed(2)}</td>
                            </tr>
                          ))
                        ) : (
                          <tr>
                            <td style={{ ...tdStyle, paddingLeft: "15px", color: "#64748b", fontStyle: "italic" }}>No other income accounts found.</td>
                            <td style={{ ...tdStyle, textAlign: "right", color: "#64748b" }}>0.00</td>
                          </tr>
                        )}
                      </tbody>
                      <tfoot>
                        <tr style={{ fontWeight: "bold" }}>
                          <td style={{ ...tdStyle, paddingLeft: "15px" }}>Total Other Income</td>
                          <td style={{ ...tdStyle, textAlign: "right" }}>₹{totalOther.toFixed(2)}</td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>

                  {/* Total Incomes */}
                  <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "bold", fontSize: "15px", padding: "10px 0", borderTop: "2px solid #cbd5e1", borderBottom: "2px solid #cbd5e1", color: "#065f46", marginBottom: "20px" }}>
                    <span>Total Incomes (A + B)</span>
                    <span>₹{parseFloat(data.income.total).toFixed(2)}</span>
                  </div>
                </div>
              );
            })()}

            <h3 style={{ color: "#2563eb", borderBottom: "1px solid #e2e8f0", paddingBottom: "10px", marginTop: "30px" }}>Gross Profit</h3>
            <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "bold", fontSize: "18px", padding: "10px 0" }}>
              <span>Total Gross Profit</span>
              <span>₹{parseFloat(data.income.total).toFixed(2)}</span>
            </div>

            {/* EXPENSES */}
            <h3 style={{ color: "#dc2626", borderBottom: "1px solid #e2e8f0", paddingBottom: "10px", marginTop: "30px" }}>Operating Expenses</h3>
            <table style={tableStyle}>
              <tbody>
                {data.expense.accounts.map((acc, idx) => (
                  <tr key={idx}>
                    <td style={tdStyle}>{acc.account_name}</td>
                    <td style={{...tdStyle, textAlign: "right"}}>{parseFloat(acc.balance).toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr>
                  <td style={{...tdStyle, fontWeight: "bold"}}>Total Operating Expenses</td>
                  <td style={{...tdStyle, textAlign: "right", fontWeight: "bold"}}>₹{parseFloat(data.expense.total).toFixed(2)}</td>
                </tr>
              </tfoot>
            </table>

            {/* NET PROFIT */}
            <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "bold", fontSize: "20px", padding: "20px", marginTop: "40px", background: data.net_profit >= 0 ? "#ecfdf5" : "#fef2f2", color: data.net_profit >= 0 ? "#065f46" : "#991b1b", borderRadius: "8px" }}>
              <span>{data.net_profit >= 0 ? "Net Profit" : "Net Loss"}</span>
              <span>₹{parseFloat(data.net_profit).toFixed(2)}</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

const inputStyle = { padding: "8px", borderRadius: "4px", border: "1px solid #ccc" };
const labelStyle = { display: "block", marginBottom: "5px", fontWeight: "500", fontSize: "12px", color: "#64748b" };
const primaryBtn = { padding: "8px 16px", background: "#4a90e2", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer", fontWeight: "bold", height: "35px" };
const secondaryBtn = { padding: "8px 16px", background: "#fff", color: "#333", border: "1px solid #ccc", borderRadius: "4px", cursor: "pointer", fontWeight: "500" };
const tableStyle = { width: "100%", borderCollapse: "collapse", marginBottom: "10px" };
const tdStyle = { padding: "10px 0", borderBottom: "1px solid #f1f5f9" };

export default ProfitAndLoss;
