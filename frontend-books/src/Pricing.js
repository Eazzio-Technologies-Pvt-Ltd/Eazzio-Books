import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTheme } from "./ThemeContext";
import { useAuth } from "./AuthContext";
import { apiRequest } from "./api";
import toast from "react-hot-toast";
import ChatbotWidget from "./components/ChatbotWidget";

/* ─── Razorpay helpers ───────────────────────────────────────────── */
const loadRazorpayScript = () =>
  new Promise((resolve) => {
    if (window.Razorpay) { resolve(true); return; }
    const s = document.createElement("script");
    s.src = "https://checkout.razorpay.com/v1/checkout.js";
    s.onload = () => resolve(true);
    s.onerror = () => resolve(false);
    document.body.appendChild(s);
  });

// Map frontend plan IDs → backend plan IDs
const BACKEND_PLAN_MAP = {
  "free": "free",
  "standard-premium": "premium",
  "professional": "professional",
};

/* ─── Plan data ─────────────────────────────────────────────────── */
const PLANS = [
  {
    id: "free",
    name: "Free",
    price: 0,
    tagline: "Everything you need to send your first invoice.",
    description: "No card, no trial countdown, no catch — just the essentials to see if Eazzio fits how you work.",
    badge: null,
    color: "#64748b",
    accentBg: "linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)",
    featuresTitle: "Includes:",
    features: [
      "Create and send professional invoices in minutes",
      "Track payments as customers pay you",
      "Manage your core customer list",
      "Record manual journal entries for basic bookkeeping",
      "A dashboard overview of where your money stands",
      "1 admin user, so you're fully in control from day one",
      "Community support to help you get unstuck",
    ],
    users: "1 User",
    support: "Community Support",
    cta: "Get started for free",
    ctaStyle: "filled",
  },
  {
    id: "standard-premium",
    name: "Standard Premium",
    price: 749,
    tagline: "Payments and forecasting, done right.",
    description: "Everything a growing business needs to run sales, purchases, inventory, and cash flow — with tools Zoho Books doesn't have.",
    badge: "Most Popular",
    color: "#2563eb",
    accentBg: "linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)",
    featuresTitle: "Includes:",
    features: [
      "Split a single payment across Cash, UPI, Bank, and Petty Cash — simultaneously",
      "Installment scheduler — auto-generates the full payment plan from one entry",
      "Due installment alerts with WhatsApp and email quick-actions",
      "Full financial reports — P&L, Balance Sheet, Cash Flow, Trial Balance",
      "Projected Income widget — see next month's expected receipts, today",
      "Projected Expense widget — know what's due before it hits your account",
      "WhatsApp payment reminders — one tap from the notification bell",
      "Dedicated Petty Cash ledger with live dashboard balance",
      "Dedicated Undeposited Funds ledger — nothing slips through",
      "Unlimited invoices, quotes, and sales orders",
      "Full vendor management — purchase orders, bills, vendor credits",
      "Complete inventory tracking with low-stock alerts",
      "Recurring invoices and recurring expenses",
      "Unlimited users with role-based access",
    ],
    users: "Unlimited Users",
    support: "Priority Support",
    cta: "Upgrade Now",
    ctaStyle: "filled",
  },
  {
    id: "professional",
    name: "Professional",
    price: 1499,
    tagline: "Built for the business that has an accountant.",
    description: "Bank reconciliation, project time-tracking, custom roles, and integrations — for teams that need more than invoicing.",
    badge: null,
    color: "#2563eb",
    accentBg: "linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)",
    featuresTitle: "Includes everything in Standard, plus:",
    features: [
      "Split a single payment across Cash, UPI, Bank, and Petty Cash — simultaneously",
      "Installment scheduler — auto-generates the full payment plan from one entry",
      "Due installment alerts with WhatsApp and email quick-actions",
      "Full financial reports — P&L, Balance Sheet, Cash Flow, Trial Balance",
      "Projected Income widget — see next month's expected receipts, today",
      "Bank reconciliation and currency adjustments",
      "Customer and vendor aging reports",
      "Projects and timesheets for time-based work",
      "Custom roles and permissions, plus a dedicated Accountant role",
      "API access & webhooks for custom integrations",
      "Advanced RBAC with full audit logs, custom fields & workflows",
      "Transaction locking & bulk updates",
      "Customer statements (per-customer account ledger)",
      "24/7 priority email and chat support",
    ],
    users: "Unlimited Users",
    support: "24/7 Priority Support",
    cta: "Upgrade Now",
    ctaStyle: "filled",
  },
];


/* ─── Helper: Check icon ─────────────────────────────────────────── */
function CheckIcon({ color }) {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 16 16"
      fill="none"
      style={{ flexShrink: 0, marginTop: "2px" }}
      aria-hidden="true"
    >
      <circle cx="8" cy="8" r="8" fill={color} fillOpacity="0.12" />
      <path
        d="M5 8.5l2 2 4-4"
        stroke={color}
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

/* ─── Main Component ─────────────────────────────────────────────── */
function Pricing() {
  const navigate = useNavigate();
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const { user, setUser } = useAuth();

  const [expandedPlans, setExpandedPlans] = useState({});
  const [payingPlanId, setPayingPlanId] = useState(null); // tracks which plan is processing

  /* ── Razorpay checkout handler ── */
  const handleUpgrade = async (frontendPlanId) => {
    const backendPlanId = BACKEND_PLAN_MAP[frontendPlanId];

    if (backendPlanId === "free") {
      toast("You are already on the Free Plan. Choose a paid plan to upgrade.", { icon: "ℹ️" });
      return;
    }

    setPayingPlanId(frontendPlanId);
    try {
      const scriptLoaded = await loadRazorpayScript();
      if (!scriptLoaded) {
        toast.error("Razorpay SDK failed to load. Please check your internet connection.");
        setPayingPlanId(null);
        return;
      }

      // 1. Create order on backend
      const data = await apiRequest("/subscription/create-order", {
        method: "POST",
        body: JSON.stringify({ plan_id: backendPlanId }),
      });

      if (!data || !data.success || !data.order) {
        toast.error(data?.message || "Failed to create checkout order.");
        setPayingPlanId(null);
        return;
      }

      const { order, keyId } = data;
      const plan = PLANS.find((p) => p.id === frontendPlanId);

      // 2. Open Razorpay checkout
      const options = {
        key: keyId,
        amount: order.amount,
        currency: order.currency,
        name: "Eazzio Books",
        description: `Subscribe to ${plan?.name || backendPlanId}`,
        order_id: order.id,
        prefill: {
          name: user?.full_name || "",
          email: user?.email || "",
        },
        theme: { color: plan?.color || "#2563eb" },
        handler: async (response) => {
          setPayingPlanId(frontendPlanId);
          try {
            // 3. Verify payment on backend
            const verifyRes = await apiRequest("/subscription/renew", {
              method: "POST",
              body: JSON.stringify({
                plan_id: backendPlanId,
                razorpay_order_id: response.razorpay_order_id,
                razorpay_payment_id: response.razorpay_payment_id,
                razorpay_signature: response.razorpay_signature,
              }),
            });

            if (verifyRes && verifyRes.success) {
              toast.success(`🎉 Upgraded to ${plan?.name}! Your subscription is active.`);
              // Update auth context so rest of app reflects new plan
              setUser((prev) => ({
                ...prev,
                plan_id: verifyRes.plan_id,
                subscription_expires_at: verifyRes.subscription_expires_at,
              }));
              navigate("/dashboard");
            } else {
              toast.error(verifyRes?.message || "Payment verification failed.");
            }
          } catch (err) {
            toast.error(err.message || "Failed to verify payment.");
          } finally {
            setPayingPlanId(null);
          }
        },
        modal: {
          ondismiss: () => {
            toast("Payment cancelled.", { icon: "❌" });
            setPayingPlanId(null);
          },
        },
      };

      const rzp = new window.Razorpay(options);
      rzp.open();
    } catch (err) {
      toast.error(err.message || "An error occurred during payment setup.");
      setPayingPlanId(null);
    }
  };

  const toggleExpand = (planId) => {
    setExpandedPlans((prev) => ({
      ...prev,
      [planId]: !prev[planId],
    }));
  };

  /* ── Inline style tokens (respect dark/light mode) ── */
  const page = {
    height: "100%",
    overflowY: "auto",
    display: "flex",
    flexDirection: "column",
    background: isDark ? "var(--bg-main, #0f172a)" : "#f8fafc",
    color: isDark ? "var(--text-primary, #f1f5f9)" : "#0f172a",
    fontFamily: "'Inter', 'Segoe UI', sans-serif",
  };

  const heroSection = {
    textAlign: "center",
    padding: "60px 24px 48px",
  };

  const backBtn = {
    display: "inline-flex",
    alignItems: "center",
    gap: "6px",
    background: "none",
    border: "none",
    color: "#2563eb",
    fontSize: "14px",
    fontWeight: "500",
    cursor: "pointer",
    marginBottom: "32px",
    padding: "6px 10px",
    borderRadius: "6px",
    transition: "background 0.15s",
  };

  /* ── CTA button styles ── */
  const ctaStyles = {
    filled: {
      background: "#2563eb",
      color: "#fff",
      border: "2px solid #2563eb",
      boxShadow: "0 4px 14px rgba(37,99,235,0.25)",
    },
    outline: {
      background: "transparent",
      color: "#dc2626",
      border: "2px solid #dc2626",
    },
    "outline-purple": {
      background: "transparent",
      color: "#7c3aed",
      border: "2px solid #7c3aed",
    },
  };

  return (
    <div style={page}>
      <style>{`
        .plans-container {
          display: flex;
          gap: 24px;
          overflow-x: auto;
          padding: 32px 24px;
          max-width: 1200px;
          margin: 0 auto;
          scroll-snap-type: x mandatory;
          -webkit-overflow-scrolling: touch;
          justify-content: flex-start;
          align-items: stretch;
        }
        @media (min-width: 1080px) {
          .plans-container {
            justify-content: center;
          }
        }
        .plans-container::-webkit-scrollbar {
          height: 8px;
        }
        .plans-container::-webkit-scrollbar-track {
          background: ${isDark ? "rgba(255,255,255,0.05)" : "#f1f5f9"};
          border-radius: 4px;
          margin: 0 24px;
        }
        .plans-container::-webkit-scrollbar-thumb {
          background: ${isDark ? "rgba(255,255,255,0.2)" : "#cbd5e1"};
          border-radius: 4px;
        }
        .plans-container::-webkit-scrollbar-thumb:hover {
          background: ${isDark ? "rgba(255,255,255,0.3)" : "#94a3b8"};
        }
        .plan-card {
          width: 320px;
          flex-shrink: 0;
          scroll-snap-align: center;
        }
        @media (max-width: 768px) {
          .plan-card {
            width: 280px;
          }
        }
      `}</style>
      {/* ── Hero ── */}
      <div style={{ textAlign: "center", padding: "4px 24px 0", flexShrink: 0 }}>
        <div style={{ marginBottom: "4px" }}>
          <button
            id="pricing-back-btn"
            style={{ ...backBtn, marginBottom: "0px", padding: "2px 8px", fontSize: "12px" }}
            onClick={() => navigate(-1)}
            onMouseEnter={(e) => (e.currentTarget.style.background = isDark ? "rgba(255,255,255,0.08)" : "#eff6ff")}
            onMouseLeave={(e) => (e.currentTarget.style.background = "none")}
          >
            ← Back to Dashboard
          </button>
        </div>

        {/* Eyebrow */}
        <div
          style={{
            display: "inline-block",
            background: "linear-gradient(90deg, #2563eb, #7c3aed)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            fontWeight: "700",
            fontSize: "11px",
            letterSpacing: "1px",
            textTransform: "uppercase",
            marginBottom: "4px",
          }}
        >
          Eazzio Books Pricing
        </div>

        <h1
          style={{
            fontSize: "clamp(18px, 4vw, 24px)",
            fontWeight: "800",
            margin: "0 0 4px",
            lineHeight: "1.1",
          }}
        >
          Simple Pricing for Every Business
        </h1>

        <p
          style={{
            fontSize: "13px",
            color: isDark ? "#94a3b8" : "#64748b",
            maxWidth: "600px",
            margin: "0 auto 8px",
            lineHeight: "1.3",
          }}
        >
          Choose the perfect Eazzio Books plan to manage your accounting, GST, inventory, invoicing, and business growth.
        </p>
      </div>

      {/* ── Pricing Plans ── */}
      <div className="plans-container">
        {PLANS.map((plan) => {
          const isPopular = plan.id === "standard-premium";

          const cardStyle = {
            position: "relative",
            borderRadius: "16px",
            border: isPopular
              ? (isDark ? "2px solid #3b82f6" : "2px solid #2563eb")
              : `1px solid ${isDark ? "rgba(255,255,255,0.12)" : "#e2e8f0"}`,
            background: isDark ? (isPopular ? "#1e3a6e" : "#1e293b") : "#fff",
            padding: "20px 24px",
            display: "flex",
            flexDirection: "column",
            gap: "0",
            boxShadow: isPopular
              ? (isDark ? "0 20px 50px rgba(37,99,235,0.25)" : "0 20px 50px rgba(37,99,235,0.15)")
              : (isDark ? "0 4px 20px rgba(0,0,0,0.3)" : "0 4px 20px rgba(0,0,0,0.04)"),
            transition: "transform 0.3s ease, box-shadow 0.3s ease",
          };

          return (
            <div
              key={plan.id}
              id={`pricing-card-${plan.id}`}
              className="plan-card"
              style={cardStyle}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = "translateY(-4px)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = "translateY(0)";
              }}
            >
                  {/* "Most Popular" badge */}
                  {plan.badge && (
                    <div
                      style={{
                        position: "absolute",
                        top: "-14px",
                        left: "50%",
                        transform: "translateX(-50%)",
                        background: "linear-gradient(90deg, #2563eb, #3b82f6)",
                        color: "#fff",
                        fontSize: "12px",
                        fontWeight: "700",
                        padding: "4px 16px",
                        borderRadius: "999px",
                        letterSpacing: "0.5px",
                        whiteSpace: "nowrap",
                        boxShadow: "0 4px 12px rgba(37,99,235,0.4)",
                      }}
                    >
                      ⭐ {plan.badge}
                    </div>
                  )}

                  {/* Plan name */}
                  <div
                    style={{
                      fontSize: "11px",
                      fontWeight: "800",
                      textTransform: "uppercase",
                      letterSpacing: "0.5px",
                      color: plan.color,
                      marginBottom: "2px",
                    }}
                  >
                    {plan.name}
                  </div>

                  {/* Tagline */}
                  {plan.tagline && (
                    <div
                      style={{
                        fontSize: "10px",
                        fontWeight: "600",
                        color: isDark ? "#7dd3fc" : plan.color,
                        marginBottom: "4px",
                        fontStyle: "italic",
                        opacity: 0.85,
                      }}
                    >
                      {plan.tagline}
                    </div>
                  )}

                  {/* Price */}
                  <div style={{ marginBottom: "8px", lineHeight: "1" }}>
                    <span
                      style={{
                        fontSize: "14px",
                        fontWeight: "700",
                        verticalAlign: "top",
                        lineHeight: "2",
                        color: isDark ? "#cbd5e1" : "#475569",
                        marginRight: "2px",
                      }}
                    >
                      ₹
                    </span>
                    <span
                      style={{
                        fontSize: "24px",
                        fontWeight: "900",
                        color: isDark ? "#f1f5f9" : "#0f172a",
                        letterSpacing: "-0.5px",
                      }}
                    >
                      {plan.price}
                    </span>
                    {plan.price !== 0 && (
                      <div
                        style={{
                          fontSize: "9px",
                          color: isDark ? "#94a3b8" : "#64748b",
                          marginTop: "2px",
                          fontWeight: "600",
                        }}
                      >
                        Price/Org/Month
                      </div>
                    )}
                  </div>

                  {/* Description */}
                  <p
                    style={{
                      fontSize: "11px",
                      color: isDark ? "#94a3b8" : "#64748b",
                      lineHeight: "1.3",
                      marginBottom: "8px",
                      minHeight: "28px",
                    }}
                  >
                    {plan.description}
                  </p>

                  {/* CTA button */}
                  <button
                    id={`pricing-cta-${plan.id}`}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = "scale(1.03)";
                      if (plan.ctaStyle === "filled") {
                        e.currentTarget.style.background = "#1d4ed8";
                        e.currentTarget.style.borderColor = "#1d4ed8";
                        e.currentTarget.style.boxShadow = "0 6px 20px rgba(37,99,235,0.35)";
                      } else {
                        e.currentTarget.style.background = "rgba(37,99,235,0.08)";
                      }
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = "scale(1)";
                      if (plan.ctaStyle === "filled") {
                        e.currentTarget.style.background = "#2563eb";
                        e.currentTarget.style.borderColor = "#2563eb";
                        e.currentTarget.style.boxShadow = "0 4px 14px rgba(37,99,235,0.25)";
                      } else {
                        e.currentTarget.style.background = "transparent";
                      }
                    }}
                    onMouseDown={(e) => {
                      e.currentTarget.style.transform = "scale(0.97)";
                    }}
                    onMouseUp={(e) => {
                      e.currentTarget.style.transform = "scale(1.03)";
                    }}
                    disabled={payingPlanId === plan.id}
                    onClick={(e) => {
                      e.stopPropagation();
                      handleUpgrade(plan.id);
                    }}
                    style={{
                      width: "100%",
                      padding: "6px 12px",
                      borderRadius: "8px",
                      fontSize: "11px",
                      fontWeight: "700",
                      cursor: payingPlanId === plan.id ? "not-allowed" : "pointer",
                      transition: "all 0.25s cubic-bezier(0.4, 0, 0.2, 1)",
                      marginBottom: "8px",
                      opacity: payingPlanId === plan.id ? 0.7 : 1,
                      ...ctaStyles[plan.ctaStyle],
                    }}
                  >
                    {payingPlanId === plan.id ? "Processing..." : plan.cta}
                  </button>

                  {/* Divider */}
                  <div
                    style={{
                      height: "1px",
                      background: isDark ? "rgba(255,255,255,0.08)" : "#e2e8f0",
                      marginBottom: "8px",
                    }}
                  />

                  {/* Feature list header */}
                  {plan.featuresTitle && (
                    <div
                      style={{
                        fontSize: "10px",
                        fontWeight: "700",
                        color: isDark ? "#cbd5e1" : "#0f172a",
                        marginBottom: "4px",
                        textAlign: "left",
                      }}
                    >
                      {plan.featuresTitle}
                    </div>
                  )}

                  {/* Feature list */}
                  <ul style={{ listStyle: "none", padding: 0, margin: 0, display: "flex", flexDirection: "column", gap: "2px" }}>
                    {plan.features.slice(0, 5).map((feat) => (
                      <li
                        key={feat}
                        style={{ display: "flex", alignItems: "flex-start", gap: "4px", fontSize: "10px", color: isDark ? "#cbd5e1" : "#374151" }}
                      >
                        <CheckIcon color={plan.color} />
                        <span style={{ textAlign: "left", lineHeight: "1.2" }}>{feat}</span>
                      </li>
                    ))}
                  </ul>

                  {/* Expandable features section */}
                  {plan.features.length > 5 && (
                    <div
                      style={{
                        maxHeight: expandedPlans[plan.id] ? "1000px" : "0px",
                        overflow: "hidden",
                        transition: "max-height 0.4s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.3s ease, margin-top 0.3s ease",
                        opacity: expandedPlans[plan.id] ? 1 : 0,
                        marginTop: expandedPlans[plan.id] ? "2px" : "0px",
                      }}
                    >
                      <ul style={{ listStyle: "none", padding: 0, margin: 0, display: "flex", flexDirection: "column", gap: "2px" }}>
                        {plan.features.slice(5).map((feat) => (
                          <li
                            key={feat}
                            style={{ display: "flex", alignItems: "flex-start", gap: "4px", fontSize: "10px", color: isDark ? "#cbd5e1" : "#374151" }}
                          >
                            <CheckIcon color={plan.color} />
                            <span style={{ textAlign: "left", lineHeight: "1.2" }}>{feat}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}

                  {/* Show More / Less button */}
                  {plan.features.length > 5 && (
                    <button
                      onClick={() => toggleExpand(plan.id)}
                      style={{
                        background: "none",
                        border: "none",
                        color: "#2563eb",
                        fontSize: "10px",
                        fontWeight: "600",
                        cursor: "pointer",
                        display: "flex",
                        alignItems: "center",
                        gap: "2px",
                        marginTop: "4px",
                        padding: "2px 0",
                        transition: "color 0.2s ease",
                      }}
                      onMouseEnter={(e) => e.currentTarget.style.color = "#1d4ed8"}
                      onMouseLeave={(e) => e.currentTarget.style.color = "#2563eb"}
                    >
                      {expandedPlans[plan.id] ? "Show less" : "Show more features"}
                      <span style={{
                        display: "inline-block",
                        transform: expandedPlans[plan.id] ? "rotate(-180deg)" : "rotate(0deg)",
                        transition: "transform 0.3s ease",
                        marginLeft: "2px",
                        fontWeight: "700"
                      }}>
                        ↓
                      </span>
                    </button>
                  )}

                  {/* Spacing to push footer down */}
                  <div style={{ marginTop: "auto" }} />

                  {/* Footer divider */}
                  <div
                    style={{
                      height: "1px",
                      background: isDark ? "rgba(255,255,255,0.08)" : "#e2e8f0",
                      marginBottom: "4px",
                    }}
                  />

                  {/* Card Footer info */}
                  <div
                    style={{
                      textAlign: "left",
                      fontSize: "9px",
                      color: isDark ? "#94a3b8" : "#64748b",
                      display: "flex",
                      flexDirection: "column",
                      gap: "2px",
                      fontWeight: "500",
                    }}
                  >
                    <div>{plan.users}</div>
                    <div>{plan.support}</div>
                  </div>
                </div>
              );
        })}
      </div>

      {/* ── Trust Section ── */}
      <div style={{ maxWidth: "1100px", margin: "12px auto 0", padding: "0 24px", display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: "12px", textAlign: "center", flexShrink: 0 }}>
        {[
          { icon: "🔒", title: "Enterprise-grade Security", desc: "Bank-level encryption" },
          { icon: "☁️", title: "99.9% Uptime", desc: "Reliable & always online" },
          { icon: "🔄", title: "Easy Migration", desc: "Seamless onboarding" },
          { icon: "💬", title: "Priority Support", desc: "We're here to help" },
        ].map((feat, i) => (
          <div key={i}>
            <div style={{ fontSize: "16px", marginBottom: "4px" }}>{feat.icon}</div>
            <div style={{ fontWeight: "700", color: isDark ? "#f1f5f9" : "#0f172a", marginBottom: "2px", fontSize: "10px" }}>{feat.title}</div>
            <div style={{ color: isDark ? "#94a3b8" : "#64748b", fontSize: "9px" }}>{feat.desc}</div>
          </div>
        ))}
      </div>

      {/* ── Enterprise CTA ── */}
      <div
        style={{
          maxWidth: "640px",
          margin: "12px auto 0",
          padding: "14px 24px",
          borderRadius: "12px",
          background: isDark ? "rgba(255,255,255,0.04)" : "#f8fafc",
          border: `1px solid ${isDark ? "rgba(255,255,255,0.08)" : "#e2e8f0"}`,
          textAlign: "center",
          flexShrink: 0,
        }}
      >
        <span style={{ fontSize: "12px", color: isDark ? "#94a3b8" : "#64748b" }}>
          Need a dedicated account manager, white-glove onboarding, or an SLA?{" "}
        </span>
        <a
          href="mailto:support@eazzio.com"
          style={{
            fontSize: "12px",
            fontWeight: "700",
            color: "#7c3aed",
            textDecoration: "none",
            whiteSpace: "nowrap",
          }}
          onMouseEnter={(e) => e.currentTarget.style.textDecoration = "underline"}
          onMouseLeave={(e) => e.currentTarget.style.textDecoration = "none"}
        >
          Talk to us →
        </a>
      </div>

      {/* ── Footer note ── */}
      <div
        style={{
          textAlign: "center",
          marginTop: "12px",
          marginBottom: "12px",
          fontSize: "10px",
          color: isDark ? "#64748b" : "#94a3b8",
          padding: "0 24px",
          flexShrink: 0,
        }}
      >
        Prices are exclusive of applicable GST.
        <br />
        <span style={{ marginTop: "4px", display: "inline-block" }}>
          Questions?{" "}
          <a
            href="mailto:support@eazzio.com"
            style={{ color: "#2563eb", textDecoration: "none", fontWeight: "600" }}
          >
            Contact us
          </a>
        </span>
      </div>
      
      <ChatbotWidget />
    </div>
  );
}

export default Pricing;
