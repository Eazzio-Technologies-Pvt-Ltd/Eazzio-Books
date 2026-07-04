import React, { useEffect, useState } from "react";
import { useAuth } from "./AuthContext";
import { useNavigate } from "react-router-dom";
import { apiRequest } from "./api";
import { CardSkeleton } from "./components/skeletons";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer,
  BarChart, Bar, Legend, PieChart, Pie, Cell
} from 'recharts';
import { IndianRupee, CreditCard, TrendingUp, TrendingDown } from 'lucide-react';
import "./Dashboard.css";

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

function Dashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const currentDate = new Date();
  const [selectedMonth, setSelectedMonth] = useState(currentDate.getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(currentDate.getFullYear());
  const [draftMonth, setDraftMonth] = useState(currentDate.getMonth() + 1);
  const [draftYear, setDraftYear] = useState(currentDate.getFullYear());
  const [isApplying, setIsApplying] = useState(false);
  const [financeData, setFinanceData] = useState(null);
  const [projectedData, setProjectedData] = useState(null);
  const [projectedExpensesData, setProjectedExpensesData] = useState(null);
  const [loading, setLoading] = useState(true);

  const handleApply = () => {
    setIsApplying(true);
    setTimeout(() => {
      setSelectedMonth(draftMonth);
      setSelectedYear(draftYear);
      setIsApplying(false);
    }, 600); // Artificial delay to show loading as requested
  };

  const monthNames = [
    { value: 1, label: "January" }, { value: 2, label: "February" }, { value: 3, label: "March" },
    { value: 4, label: "April" }, { value: 5, label: "May" }, { value: 6, label: "June" },
    { value: 7, label: "July" }, { value: 8, label: "August" }, { value: 9, label: "September" },
    { value: 10, label: "October" }, { value: 11, label: "November" }, { value: 12, label: "December" }
  ];
  const years = [currentDate.getFullYear() - 1, currentDate.getFullYear(), currentDate.getFullYear() + 1];

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        // We use the same endpoint, which now provides chartData alongside top_summary
        const res = await apiRequest(`/dashboard/monthly-finance-summary?month=${selectedMonth}&year=${selectedYear}`);
        setFinanceData(res);
      } catch (err) {
        console.error("Failed to load dashboard data:", err);
      } finally {
        setLoading(false);
      }
    };

    const fetchProjectedPayments = async () => {
      try {
        const res = await apiRequest(`/accounts/projected-payments?month=${selectedMonth}&year=${selectedYear}`);
        if (res) {
          setProjectedData(res);
        } else {
          setProjectedData({ error: "Empty response from server" });
        }
      } catch (err) {
        console.error("Failed to load projected payments:", err);
        setProjectedData({ error: err.message || "API request failed" });
      }
    };

    const fetchProjectedExpenses = async () => {
      try {
        const res = await apiRequest(`/accounts/projected-expenses?month=${selectedMonth}&year=${selectedYear}`);
        if (res) {
          setProjectedExpensesData(res);
        } else {
          setProjectedExpensesData({ error: "Empty response from server" });
        }
      } catch (err) {
        console.error("Failed to load projected expenses:", err);
        setProjectedExpensesData({ error: err.message || "API request failed" });
      }
    };

    fetchDashboardData();
    fetchProjectedPayments();
    fetchProjectedExpenses();
  }, [selectedMonth, selectedYear]);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: user?.default_currency || 'INR' }).format(amount || 0);
  };

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div style={{ background: '#fff', padding: '10px', border: '1px solid #e5e7eb', borderRadius: '6px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' }}>
          <p style={{ margin: '0 0 5px 0', fontWeight: 'bold' }}>{label}</p>
          {payload.map((entry, index) => (
            <p key={index} style={{ color: entry.color, margin: '0 0 3px 0', fontSize: '13px' }}>
              {entry.name}: {formatCurrency(entry.value)}
            </p>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="dashboard-container">
      {/* Welcome section */}
      <section className="dash-welcome">
        <div className="dash-welcome-content">
          <div>
            <h1 className="dash-welcome-title">
              Welcome back, {user?.organization_name || user?.email?.split("@")[0] || "User"}
            </h1>
            <p className="dash-welcome-sub">
              Here is your financial overview.
            </p>
          </div>
        </div>
      </section>

      {loading && !financeData ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px', marginTop: '20px' }}>
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
      ) : !financeData ? (
        <div className="dash-loading">Error loading dashboard data. Please refresh.</div>
      ) : (
        <>
          {/* TOP OVERALL SUMMARY CARDS */}
          <section className="dash-stats-grid">
            <div className="dash-stat-card">
              <div className="dash-stat-header">
                <div className="dash-stat-icon receivables"><IndianRupee size={20} /></div>
                <p>Total Receivables</p>
              </div>
              <div className="dash-stat-content">
                <h3>{formatCurrency(financeData.top_summary?.total_receivables || 0)}</h3>
                <span className="dash-stat-trend trend-down" style={{ fontWeight: 'bold', background: '#fffbeb', color: '#b45309', padding: '2px 6px', borderRadius: '4px' }}>Current Financial Year</span>
              </div>
            </div>

            <div className="dash-stat-card">
              <div className="dash-stat-header">
                <div className="dash-stat-icon payables"><CreditCard size={20} /></div>
                <p>Total Payables</p>
              </div>
              <div className="dash-stat-content">
                <h3>{formatCurrency(financeData.top_summary?.total_payables || 0)}</h3>
                <span className="dash-stat-trend trend-down" style={{ fontWeight: 'bold', background: '#fffbeb', color: '#b45309', padding: '2px 6px', borderRadius: '4px' }}>Current Financial Year</span>
              </div>
            </div>

            <div className="dash-stat-card">
              <div className="dash-stat-header">
                <div className="dash-stat-icon income"><TrendingUp size={20} /></div>
                <p>Total Income</p>
              </div>
              <div className="dash-stat-content">
                <h3>{formatCurrency(financeData.top_summary?.total_income || 0)}</h3>
                <span className="dash-stat-trend trend-up" style={{ fontWeight: 'bold', background: '#ecfdf5', color: '#047857', padding: '2px 6px', borderRadius: '4px' }}>Current Financial Year</span>
              </div>
            </div>

            <div className="dash-stat-card">
              <div className="dash-stat-header">
                <div className="dash-stat-icon expenses"><TrendingDown size={20} /></div>
                <p>Total Expenses</p>
              </div>
              <div className="dash-stat-content">
                <h3>{formatCurrency(financeData.top_summary?.total_expenses || 0)}</h3>
                <span className="dash-stat-trend" style={{ fontWeight: 'bold', background: '#fef2f2', color: '#b91c1c', padding: '2px 6px', borderRadius: '4px' }}>Current Financial Year</span>
              </div>
            </div>
          </section>

          {/* MONTHLY OVERVIEW SECTION */}
          <section className="dash-monthly-overview">
            <div className="dash-section-header">
              <h3 className="section-title" style={{ margin: 0, padding: '4px 8px', background: '#e0e7ff', color: '#4f46e5', borderRadius: '4px', display: 'inline-block' }}>Monthly Overview</h3>
              <div className="dash-welcome-filters">
                <select
                  value={draftMonth}
                  onChange={(e) => setDraftMonth(Number(e.target.value))}
                  className="dash-filter-select"
                >
                  {monthNames.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}
                </select>
                <select
                  value={draftYear}
                  onChange={(e) => setDraftYear(Number(e.target.value))}
                  className="dash-filter-select"
                >
                  {years.map(y => <option key={y} value={y}>{y}</option>)}
                </select>
                <button
                  onClick={handleApply}
                  disabled={isApplying}
                  style={{ padding: '6px 12px', background: '#3b82f6', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '13px', marginLeft: '10px' }}
                >
                  {isApplying ? 'Loading...' : 'Apply'}
                </button>
              </div>
            </div>
            <div className="monthly-overview-grid">
              <div className="mo-card">
                <p className="mo-label">BUSINESS VALUE</p>
                <h4 className="mo-amount income-color">{formatCurrency(financeData.selected_month?.income_received)}</h4>
              </div>
              <div className="mo-card">
                <p className="mo-label">EXPENSES</p>
                <h4 className="mo-amount expense-color">{formatCurrency(financeData.selected_month?.expenses)}</h4>
              </div>
              <div className="mo-card">
                <p className="mo-label">PROFIT</p>
                <h4 className={`mo-amount ${financeData.selected_month?.profit >= 0 ? 'income-color' : 'expense-color'}`}>
                  {formatCurrency(financeData.selected_month?.profit)}
                </h4>
              </div>
              <div className="mo-card">
                <p className="mo-label">NET CASH</p>
                <h4 className="mo-amount cash-color">{formatCurrency(financeData.selected_month?.net_cash_position)}</h4>
              </div>
            </div>
          </section>

          {/* THREE-COLUMN PROJECTIONS */}
          <section className="dash-projections-grid">

            {/* 1. Projected Income */}
            <div className="dash-widget-card proj-card" onClick={() => navigate('/projected-payments')}>
              <h3 className="widget-title">
                <span>Projected Income {projectedData && !projectedData.error && `(${monthNames.find(m => m.value === projectedData.projected_month)?.label} ${projectedData.projected_year})`}</span>
                <span className="view-link">View &rarr;</span>
              </h3>
              <div style={{ padding: '5px 0' }}>
                {projectedData ? (
                  projectedData.error ? (
                    <div className="widget-empty"><p>Error: {projectedData.error}</p></div>
                  ) : (
                    <>
                      <h4 className="proj-amount income-color">
                        {formatCurrency(projectedData.total_projected_payment)}
                      </h4>
                      {projectedData.bills && projectedData.bills.length > 0 ? (
                        projectedData.bills.slice(0, 3).map((bill, idx) => (
                          <div key={idx} className="proj-list-item">
                            <div>
                              <p className="proj-list-title">{bill.vendor_name || 'Customer'}</p>
                            </div>
                            <div className="proj-list-amount">{formatCurrency(bill.pending_amount)}</div>
                          </div>
                        ))
                      ) : (
                        <p style={{ fontSize: "13px", color: "#64748b" }}>No projected income.</p>
                      )}
                    </>
                  )
                ) : (
                  <div className="widget-empty"><p>Loading projection...</p></div>
                )}
              </div>
            </div>

            {/* 2. Projected Expense */}
            <div className="dash-widget-card proj-card" onClick={() => navigate('/projected-expenses')}>
              <h3 className="widget-title">
                <span>Projected Expense {projectedExpensesData && !projectedExpensesData.error && `(${monthNames.find(m => m.value === projectedExpensesData.projected_month)?.label} ${projectedExpensesData.projected_year})`}</span>
                <span className="view-link">View &rarr;</span>
              </h3>
              <div style={{ padding: '5px 0' }}>
                {projectedExpensesData ? (
                  projectedExpensesData.error ? (
                    <div className="widget-empty"><p>Error: {projectedExpensesData.error}</p></div>
                  ) : (
                    <>
                      <h4 className="proj-amount expense-color">
                        {formatCurrency(projectedExpensesData.total_projected_expense)}
                      </h4>
                      {projectedExpensesData.expenses && projectedExpensesData.expenses.length > 0 ? (
                        projectedExpensesData.expenses.slice(0, 3).map((exp, idx) => (
                          <div key={idx} className="proj-list-item">
                            <div>
                              <p className="proj-list-title">{exp.reference_number || 'Expense'}</p>
                            </div>
                            <div className="proj-list-amount">{formatCurrency(exp.pending_amount)}</div>
                          </div>
                        ))
                      ) : (
                        <p style={{ fontSize: "13px", color: "#64748b" }}>No projected expenses.</p>
                      )}
                    </>
                  )
                ) : (
                  <div className="widget-empty"><p>Loading projection...</p></div>
                )}
              </div>
            </div>
          </section>


        </>
      )}
    </div>
  );
}

export default Dashboard;