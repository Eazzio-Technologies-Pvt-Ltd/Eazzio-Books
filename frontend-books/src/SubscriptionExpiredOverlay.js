import React, { useState } from "react";
import { apiRequest } from "./api";
import { useAuth } from "./AuthContext";
import toast from "react-hot-toast";

const PLANS = [
  { id: "premium", name: "Standard Premium", price: 749, color: "#2563eb", glow: "rgba(37, 99, 235, 0.15)" },
  { id: "professional", name: "Professional", price: 1499, color: "#7c3aed", glow: "rgba(124, 58, 237, 0.15)" },
  { id: "enterprise", name: "Enterprise", price: 1999, color: "#db2777", glow: "rgba(219, 39, 119, 0.15)" }
];

const loadRazorpayScript = () => {
  return new Promise((resolve) => {
    if (window.Razorpay) {
      resolve(true);
      return;
    }
    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
};

export default function SubscriptionExpiredOverlay({ onRenewed }) {
  const { user, setUser } = useAuth();
  const [selectedPlan, setSelectedPlan] = useState("premium");
  const [loading, setLoading] = useState(false);

  const handleLogout = async () => {
    try {
      await apiRequest("/logout", { method: "POST" });
    } catch (e) {
      console.error("Logout error", e);
    }
    setUser(null);
    window.location.href = "/";
  };

  const handleRenew = async () => {
    setLoading(true);
    try {
      const scriptLoaded = await loadRazorpayScript();
      if (!scriptLoaded) {
        toast.error("Razorpay SDK failed to load. Please check your internet connection.");
        setLoading(false);
        return;
      }

      // 1. Create order
      const data = await apiRequest("/subscription/create-order", {
        method: "POST",
        body: JSON.stringify({ plan_id: selectedPlan })
      });

      if (!data || !data.success || !data.order) {
        toast.error(data?.message || "Failed to create checkout order.");
        setLoading(false);
        return;
      }

      const { order, keyId } = data;

      // 2. Open Razorpay checkout overlay
      const options = {
        key: keyId,
        amount: order.amount,
        currency: order.currency,
        name: "Eazzio Books",
        description: `Renew Subscription to ${PLANS.find(p => p.id === selectedPlan).name}`,
        order_id: order.id,
        prefill: {
          name: user?.full_name || "",
          email: user?.email || ""
        },
        theme: {
          color: PLANS.find(p => p.id === selectedPlan).color
        },
        handler: async function (response) {
          setLoading(true);
          try {
            // 3. Verify payment on backend
            const verifyRes = await apiRequest("/subscription/renew", {
              method: "POST",
              body: JSON.stringify({
                plan_id: selectedPlan,
                razorpay_order_id: response.razorpay_order_id,
                razorpay_payment_id: response.razorpay_payment_id,
                razorpay_signature: response.razorpay_signature
              })
            });

            if (verifyRes && verifyRes.success) {
              toast.success("Subscription renewed successfully!");
              
              // Update user auth context
              setUser(prev => ({
                ...prev,
                plan_id: verifyRes.plan_id,
                subscription_expires_at: verifyRes.subscription_expires_at
              }));

              if (onRenewed) {
                onRenewed();
              }
            } else {
              toast.error(verifyRes?.message || "Payment verification failed.");
            }
          } catch (err) {
            toast.error(err.message || "Failed to verify renewal payment.");
          } finally {
            setLoading(false);
          }
        },
        modal: {
          ondismiss: function () {
            toast.error("Renewal payment cancelled.");
            setLoading(false);
          }
        }
      };

      const rzp = new window.Razorpay(options);
      rzp.open();
    } catch (err) {
      toast.error(err.message || "An error occurred during payment setup.");
      setLoading(false);
    }
  };

  return (
    <div style={{
      position: "fixed",
      top: 0,
      left: 0,
      width: "100vw",
      height: "100vh",
      background: "rgba(15, 23, 42, 0.95)",
      backdropFilter: "blur(8px)",
      zIndex: 999999,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      fontFamily: "'Inter', sans-serif",
      color: "#f8fafc",
      padding: "20px",
      boxSizing: "border-box"
    }}>
      <div style={{
        background: "#1e293b",
        border: "1px solid #334155",
        borderRadius: "16px",
        padding: "40px",
        maxWidth: "680px",
        width: "100%",
        boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.5)",
        textAlign: "center",
        boxSizing: "border-box"
      }}>
        {/* Warning Icon Badge */}
        <div style={{
          display: "inline-flex",
          alignItems: "center",
          justifyContent: "center",
          width: "64px",
          height: "64px",
          borderRadius: "50%",
          background: "rgba(239, 68, 68, 0.1)",
          border: "2px solid #ef4444",
          color: "#ef4444",
          fontSize: "32px",
          marginBottom: "20px",
          fontWeight: "bold"
        }}>
          !
        </div>

        <h2 style={{ fontSize: "28px", fontWeight: "800", margin: "0 0 10px 0", color: "#f1f5f9" }}>
          Subscription Expired
        </h2>
        <p style={{ fontSize: "16px", color: "#94a3b8", margin: "0 0 30px 0", lineHeight: "1.5" }}>
          Your organization's subscription plan has expired. To restore access and continue managing your books, please select a plan and renew.
        </p>

        {/* Pricing Cards Row */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: "16px",
          marginBottom: "35px"
        }}>
          {PLANS.map(plan => {
            const isSelected = selectedPlan === plan.id;
            return (
              <div 
                key={plan.id}
                onClick={() => setSelectedPlan(plan.id)}
                style={{
                  border: isSelected ? `2px solid ${plan.color}` : "1px solid #334155",
                  background: isSelected ? plan.glow : "#0f172a",
                  borderRadius: "12px",
                  padding: "20px 10px",
                  cursor: "pointer",
                  transition: "all 0.2s ease",
                  transform: isSelected ? "translateY(-4px)" : "none",
                  boxShadow: isSelected ? `0 10px 20px -10px ${plan.color}` : "none"
                }}
              >
                <div style={{ fontSize: "14px", fontWeight: "600", color: "#94a3b8", marginBottom: "8px" }}>
                  {plan.name}
                </div>
                <div style={{ fontSize: "22px", fontWeight: "800", color: isSelected ? plan.color : "#f1f5f9" }}>
                  ₹{plan.price}
                </div>
                <div style={{ fontSize: "12px", color: "#64748b", marginTop: "4px" }}>
                  per month
                </div>
              </div>
            );
          })}
        </div>

        {/* Action Buttons */}
        <div style={{
          display: "flex",
          flexDirection: "column",
          gap: "12px"
        }}>
          <button
            onClick={handleRenew}
            disabled={loading}
            style={{
              padding: "14px 24px",
              background: PLANS.find(p => p.id === selectedPlan).color,
              color: "#fff",
              border: "none",
              borderRadius: "8px",
              fontSize: "16px",
              fontWeight: "700",
              cursor: "pointer",
              transition: "opacity 0.2s",
              opacity: loading ? 0.7 : 1
            }}
          >
            {loading ? "Processing..." : "Pay & Renew Now"}
          </button>
          
          <button
            onClick={handleLogout}
            disabled={loading}
            style={{
              padding: "12px 24px",
              background: "transparent",
              color: "#94a3b8",
              border: "1px solid #334155",
              borderRadius: "8px",
              fontSize: "14px",
              fontWeight: "600",
              cursor: "pointer",
              transition: "all 0.2s"
            }}
            onMouseEnter={(e) => {
              e.target.style.color = "#f1f5f9";
              e.target.style.borderColor = "#475569";
            }}
            onMouseLeave={(e) => {
              e.target.style.color = "#94a3b8";
              e.target.style.borderColor = "#334155";
            }}
          >
            Log Out
          </button>
        </div>
      </div>
    </div>
  );
}
