import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTheme } from "./ThemeContext";

/* ─── Plan data ─────────────────────────────────────────────────── */
const PLANS = [
  {
    id: "free",
    name: "Free Plan",
    price: 0,
    description: "Basic features to get started",
    badge: null,
    color: "#64748b",
    accentBg: "linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%)",
    featuresTitle: "Includes:",
    features: [
      "Basic invoice",
      "Tracking payments",
      "1 user access",
      "Basic customer management",
      "Manual journal entries",
      "Dashboard overview"
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
    description: "Advanced features for growing businesses",
    badge: null,
    color: "#2563eb",
    accentBg: "linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)",
    featuresTitle: "Includes:",
    features: [
      "Automated payment reminders",
      "Complete inventory",
      "GST tracking reporting",
      "Unlimited invoices & quotes",
      "Customer & vendor management",
      "Sales orders & purchase orders",
      "Delivery challans & credit notes",
      "Bank reconciliation"
    ],
    users: "Unlimited Users",
    support: "Priority Support",
    cta: "Start 14 Days Trial",
    ctaStyle: "filled",
  },
  {
    id: "professional",
    name: "Professional",
    price: 1499,
    description: "Comprehensive features for established businesses",
    badge: "Most Popular",
    color: "#2563eb",
    accentBg: "linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)",
    featuresTitle: "Includes everything in Standard, plus:",
    features: [
      "Advanced workflow automation",
      "Multi-currency support",
      "Custom roles & permissions",
      "Time tracking & timesheets",
      "Reports: P&L, Balance Sheet, Cash Flow",
      "Priority email & chat support"
    ],
    users: "Unlimited Users",
    support: "24/7 Priority Support",
    cta: "Start 14 Days Trial",
    ctaStyle: "filled",
  },
  {
    id: "enterprise",
    name: "Enterprise",
    price: 1999,
    description: "Ultimate power and control for large organizations",
    badge: null,
    color: "#7c3aed",
    accentBg: "linear-gradient(135deg, #f5f3ff 0%, #ede9fe 100%)",
    featuresTitle: "Includes everything in Professional, plus:",
    features: [
      "Dedicated account manager",
      "Custom integrations & API",
      "Advanced analytics & reporting",
      "Advanced RBAC & audit logs",
      "Custom fields & workflows",
      "API access & webhooks"
    ],
    users: "Unlimited Users",
    support: "Dedicated Support",
    cta: "Start 14 Days Trial",
    ctaStyle: "filled",
  }
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

  const [expandedPlans, setExpandedPlans] = useState({});
  const [activeIndex, setActiveIndex] = useState(2); // Default to Professional
  const [touchStart, setTouchStart] = useState(null);

  const toggleExpand = (planId) => {
    setExpandedPlans((prev) => ({
      ...prev,
      [planId]: !prev[planId],
    }));
  };

  const handleTouchStart = (e) => setTouchStart(e.touches[0].clientX);
  const handleTouchEnd = (e) => {
    if (!touchStart) return;
    const touchEnd = e.changedTouches[0].clientX;
    const distance = touchStart - touchEnd;
    if (distance > 50 && activeIndex < PLANS.length - 1) setActiveIndex(activeIndex + 1);
    if (distance < -50 && activeIndex > 0) setActiveIndex(activeIndex - 1);
    setTouchStart(null);
  };

  /* ── Inline style tokens (respect dark/light mode) ── */
  const page = {
    height: "calc(100vh - 50px)",
    overflow: "hidden",
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
        .carousel-wrapper {
          --card-width: 300px;
          position: relative;
          width: 100%;
          max-width: 1300px;
          margin: 0 auto;
          overflow: visible;
          padding: 0;
          flex: 1;
          display: flex;
          align-items: center;
        }
        .carousel-anchor {
          width: 100%;
          transform: translateX(50%);
        }
        .carousel-track {
          display: flex;
          align-items: stretch;
          width: max-content;
          gap: 24px;
          transition: transform 0.4s cubic-bezier(0.25, 1, 0.5, 1);
          transform: translateX(calc(-1 * ((var(--card-width) + 24px) * var(--active-index) + var(--card-width) / 2)));
        }
        .carousel-card {
          width: var(--card-width);
          flex-shrink: 0;
          transition: all 0.4s cubic-bezier(0.25, 1, 0.5, 1);
        }
        .carousel-nav-btn {
          position: absolute;
          top: 50%;
          transform: translateY(-50%);
          width: 48px;
          height: 48px;
          border-radius: 50%;
          background: #fff;
          border: 1px solid #e2e8f0;
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          z-index: 10;
          color: #2563eb;
          transition: all 0.2s;
        }
        .carousel-nav-btn:hover:not(:disabled) {
          background: #f8fafc;
          box-shadow: 0 6px 16px rgba(0,0,0,0.15);
          transform: translateY(-50%) scale(1.05);
        }
        .carousel-nav-btn:disabled {
          opacity: 0.3;
          cursor: not-allowed;
        }
        @media (max-width: 768px) {
          .carousel-wrapper {
            --card-width: 300px;
          }
          .carousel-nav-btn {
            display: none;
          }
        }
      `}</style>
      {/* ── Hero ── */}
      <div style={{ textAlign: "center", padding: "4px 24px 0", flexShrink: 0 }}>
        <div style={{ marginBottom: "4px" }}>
          <button
            id="pricing-back-btn"
            style={{...backBtn, marginBottom: "0px", padding: "2px 8px", fontSize: "12px"}}
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

      {/* ── Pricing Carousel ── */}
      <div className="carousel-wrapper">
        <button
          className="carousel-nav-btn"
          style={{ left: "16px" }}
          onClick={() => setActiveIndex(Math.max(0, activeIndex - 1))}
          disabled={activeIndex === 0}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"></polyline></svg>
        </button>
        <button
          className="carousel-nav-btn"
          style={{ right: "16px" }}
          onClick={() => setActiveIndex(Math.min(PLANS.length - 1, activeIndex + 1))}
          disabled={activeIndex === PLANS.length - 1}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"></polyline></svg>
        </button>

        <div className="carousel-anchor" onTouchStart={handleTouchStart} onTouchEnd={handleTouchEnd}>
          <div className="carousel-track" style={{ "--active-index": activeIndex }}>
            {PLANS.map((plan, index) => {
              const isActive = index === activeIndex;

              const cardStyle = {
                position: "relative",
                borderRadius: "16px",
                border: isActive
                  ? (isDark ? "2.5px solid #3b82f6" : "2.5px solid #2563eb")
                  : `1px solid ${isDark ? "rgba(255,255,255,0.08)" : "#e2e8f0"}`,
                background: isDark ? (isActive ? "#1e3a6e" : "#1e293b") : "#fff",
                padding: "12px 16px",
                display: "flex",
                flexDirection: "column",
                gap: "0",
                boxShadow: isActive
                  ? (isDark ? "0 25px 65px rgba(37,99,235,0.25)" : "0 25px 65px rgba(37,99,235,0.2)")
                  : (isDark ? "0 10px 30px rgba(0,0,0,0.3)" : "0 10px 30px rgba(0,0,0,0.04)"),
                transform: isActive ? "scale(1)" : "scale(0.95)",
                opacity: isActive ? 1 : 0.6,
                zIndex: isActive ? 2 : 1,
                cursor: isActive ? "default" : "pointer",
              };

              return (
                <div
                  key={plan.id}
                  id={`pricing-card-${plan.id}`}
                  className="carousel-card"
                  style={cardStyle}
                  onClick={() => !isActive && setActiveIndex(index)}
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
                style={{
                  width: "100%",
                  padding: "6px 12px",
                  borderRadius: "8px",
                  fontSize: "11px",
                  fontWeight: "700",
                  cursor: "pointer",
                  transition: "all 0.25s cubic-bezier(0.4, 0, 0.2, 1)",
                  marginBottom: "8px",
                  ...ctaStyles[plan.ctaStyle],
                }}
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
                onClick={() => {
                  navigate("/register");
                }}
              >
                {plan.cta}
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
        </div>
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
        All plans include a{" "}
        <strong style={{ color: isDark ? "#94a3b8" : "#64748b" }}>14-day free trial</strong>.
        No credit card required. &nbsp;·&nbsp; Prices are exclusive of applicable GST.
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
    </div>
  );
}

export default Pricing;
