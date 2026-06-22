/**
 * Register.js – RUPP Books-style multi-step registration page
 * Dependencies: apiRequest, react-router-dom, react-hot-toast
 */
import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { apiRequest } from "./api";
import toast from "react-hot-toast";
import "./Auth.css";

const PLANS = [
  { id: "free", name: "Free Plan", price: 0, description: "5 Invoices & 1 User limit. Basic modules.", color: "#64748b" },
  { id: "premium", name: "Standard Premium", price: 749, description: "Unlimited Invoices & Users. Inventory & GST Reports.", color: "#2563eb" },
  { id: "professional", name: "Professional", price: 1499, description: "Adds Projects & Recurring Invoices modules.", color: "#7c3aed" },
  { id: "enterprise", name: "Enterprise", price: 1999, description: "Adds Custom Roles & API integrations.", color: "#db2777" }
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

function Register() {
  const [step, setStep] = useState(1);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [organizationName, setOrganizationName] = useState("");
  const [selectedPlan, setSelectedPlan] = useState("free");
  const [loading, setLoading] = useState(false);

  const navigate = useNavigate();

  // Validate step 1 fields
  const validateStep1 = () => {
    if (!fullName || !email || !password || !confirmPassword || !organizationName) {
      toast.error("All fields are required");
      return false;
    }
    if (password.length < 6) {
      toast.error("Password must be at least 6 characters");
      return false;
    }
    if (password !== confirmPassword) {
      toast.error("Passwords do not match");
      return false;
    }
    return true;
  };

  const handleNextStep = () => {
    if (step === 1) {
      if (validateStep1()) {
        setStep(2);
      }
    } else if (step === 2) {
      setStep(3);
    }
  };

  const handlePrevStep = () => {
    setStep(prev => prev - 1);
  };

  const handleRegisterSubmit = async (paymentDetails = {}) => {
    setLoading(true);
    try {
      const data = await apiRequest("/register", {
        method: "POST",
        body: JSON.stringify({
          fullName,
          email,
          password,
          companyName: organizationName,
          plan_id: selectedPlan,
          ...paymentDetails
        }),
      });

      if (data && data.user) {
        toast.success(
          selectedPlan === "free"
            ? "Registration successful! Welcome aboard."
            : `Registration & ${PLANS.find(p => p.id === selectedPlan).name} activated successfully!`
        );
        navigate("/");
      } else {
        toast.error("Registration failed");
      }
    } catch (err) {
      toast.error(err.message || "Registration failed");
    } finally {
      setLoading(false);
    }
  };

  const handlePaymentAndRegister = async (e) => {
    e.preventDefault();
    if (selectedPlan === "free") {
      await handleRegisterSubmit();
      return;
    }

    setLoading(true);
    try {
      const scriptLoaded = await loadRazorpayScript();
      if (!scriptLoaded) {
        toast.error("Razorpay SDK failed to load. Please check your internet connection.");
        setLoading(false);
        return;
      }

      // 1. Create order
      const orderData = await apiRequest("/register/create-order", {
        method: "POST",
        body: JSON.stringify({ plan_id: selectedPlan })
      });

      if (!orderData || !orderData.success || !orderData.order) {
        toast.error(orderData?.message || "Failed to create payment order.");
        setLoading(false);
        return;
      }

      const { order, keyId } = orderData;
      const plan = PLANS.find(p => p.id === selectedPlan);

      // 2. Open Razorpay Checkout overlay
      const options = {
        key: keyId,
        amount: order.amount,
        currency: order.currency,
        name: "Eazzio Books",
        description: `Subscription for ${plan.name}`,
        order_id: order.id,
        prefill: {
          name: fullName,
          email: email
        },
        theme: {
          color: plan.color
        },
        handler: async function (response) {
          // 3. Register user with payment verification signatures
          await handleRegisterSubmit({
            razorpay_order_id: response.razorpay_order_id,
            razorpay_payment_id: response.razorpay_payment_id,
            razorpay_signature: response.razorpay_signature
          });
        },
        modal: {
          ondismiss: function () {
            toast.error("Registration payment cancelled.");
            setLoading(false);
          }
        }
      };

      const rzp = new window.Razorpay(options);
      rzp.open();
    } catch (err) {
      toast.error(err.message || "Checkout initialization failed.");
      setLoading(false);
    }
  };

  return (
    <div className="auth-page register-page">
      <div className="register-wrapper">
        <div className="register-brand" style={{ marginBottom: "15px" }}>
          <img src="/logo.png" alt="Logo" style={{ height: "70px", maxWidth: "100%", objectFit: "contain" }} />
        </div>

        {/* Stepper Header */}
        <div style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          maxWidth: "480px",
          margin: "0 auto 30px",
          position: "relative",
          zIndex: 1
        }}>
          {/* Progress Line */}
          <div style={{
            position: "absolute",
            top: "50%",
            left: 0,
            right: 0,
            height: "2px",
            background: "#334155",
            zIndex: -1,
            transform: "translateY(-50%)"
          }} />
          <div style={{
            position: "absolute",
            top: "50%",
            left: 0,
            width: step === 1 ? "0%" : step === 2 ? "50%" : "100%",
            height: "2px",
            background: "#2563eb",
            zIndex: -1,
            transform: "translateY(-50%)",
            transition: "width 0.3s ease"
          }} />

          {[1, 2, 3].map(s => (
            <div key={s} style={{
              width: "32px",
              height: "32px",
              borderRadius: "50%",
              background: step >= s ? "#2563eb" : "#1e293b",
              color: "#fff",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontWeight: "bold",
              fontSize: "14px",
              border: step >= s ? "2px solid #2563eb" : "2px solid #475569",
              transition: "all 0.3s ease",
              boxShadow: step === s ? "0 0 10px rgba(37, 99, 235, 0.5)" : "none"
            }}>
              {s}
            </div>
          ))}
        </div>

        <h1 className="register-title">
          {step === 1 ? "Create your account" : step === 2 ? "Choose subscription plan" : "Confirm details & checkout"}
        </h1>
        <p className="register-subtitle">
          {step === 1 ? "Get started with Eazzio Books in just a few minutes" : step === 2 ? "Select the tier that fits your organization" : "Complete checkout to activate your account"}
        </p>

        <div className="register-card" style={{ maxWidth: step === 2 ? "920px" : "760px", margin: "0 auto" }}>
          {step === 1 && (
            <div className="register-form">
              <div className="register-grid">
                <div className="auth-field">
                  <label htmlFor="register-name">Full Name</label>
                  <input
                    id="register-name"
                    type="text"
                    className="auth-input"
                    placeholder="John Doe"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    autoComplete="name"
                  />
                </div>

                <div className="auth-field">
                  <label htmlFor="register-email">Email Address</label>
                  <input
                    id="register-email"
                    type="email"
                    className="auth-input"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    autoComplete="email"
                  />
                </div>

                <div className="auth-field">
                  <label htmlFor="register-password">Password</label>
                  <input
                    id="register-password"
                    type="password"
                    className="auth-input"
                    placeholder="At least 6 characters"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    autoComplete="new-password"
                  />
                </div>

                <div className="auth-field">
                  <label htmlFor="register-confirm-password">Confirm Password</label>
                  <input
                    id="register-confirm-password"
                    type="password"
                    className="auth-input"
                    placeholder="Re-enter password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    autoComplete="new-password"
                  />
                </div>

                <div className="auth-field" style={{ gridColumn: "span 2" }}>
                  <label htmlFor="register-organization">Organization Name</label>
                  <input
                    id="register-organization"
                    type="text"
                    className="auth-input"
                    placeholder="Your Company Pvt Ltd"
                    value={organizationName}
                    onChange={(e) => setOrganizationName(e.target.value)}
                    autoComplete="organization"
                  />
                </div>
              </div>

              <button type="button" onClick={handleNextStep} className="auth-submit-btn register-submit">
                Continue to Plans
              </button>
            </div>
          )}

          {step === 2 && (
            <div>
              <div style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "20px",
                marginBottom: "30px"
              }}>
                {PLANS.map(plan => {
                  const isSelected = selectedPlan === plan.id;
                  return (
                    <div
                      key={plan.id}
                      onClick={() => setSelectedPlan(plan.id)}
                      style={{
                        border: isSelected ? `2px solid ${plan.color}` : "1px solid #e2e8f0",
                        borderRadius: "12px",
                        padding: "24px 16px",
                        cursor: "pointer",
                        background: isSelected ? "rgba(37, 99, 235, 0.03)" : "#fff",
                        transition: "all 0.2s ease",
                        position: "relative",
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        textAlign: "center"
                      }}
                    >
                      {isSelected && (
                        <div style={{
                          position: "absolute",
                          top: "-12px",
                          background: plan.color,
                          color: "#fff",
                          padding: "2px 10px",
                          borderRadius: "20px",
                          fontSize: "11px",
                          fontWeight: "bold"
                        }}>
                          Selected Plan
                        </div>
                      )}
                      <h3 style={{ margin: "5px 0 10px 0", color: "#1e293b", fontSize: "18px", fontWeight: "700" }}>{plan.name}</h3>
                      <div style={{ display: "flex", alignItems: "baseline", marginBottom: "15px" }}>
                        <span style={{ fontSize: "28px", fontWeight: "800", color: plan.color }}>₹{plan.price}</span>
                        <span style={{ color: "#64748b", fontSize: "13px", marginLeft: "4px" }}>/mo</span>
                      </div>
                      <p style={{ fontSize: "13px", color: "#475569", lineHeight: "1.5", margin: 0 }}>{plan.description}</p>
                    </div>
                  );
                })}
              </div>

              <div style={{ display: "flex", gap: "16px" }}>
                <button type="button" onClick={handlePrevStep} style={{
                  flex: 1,
                  height: "48px",
                  background: "transparent",
                  border: "1px solid #cbd5e1",
                  borderRadius: "8px",
                  fontSize: "15px",
                  fontWeight: "600",
                  cursor: "pointer",
                  color: "#475569"
                }}>
                  Back
                </button>
                <button type="button" onClick={handleNextStep} style={{
                  flex: 2,
                  height: "48px",
                  background: "#2563eb",
                  border: "none",
                  borderRadius: "8px",
                  color: "#fff",
                  fontSize: "15px",
                  fontWeight: "700",
                  cursor: "pointer"
                }}>
                  Continue to Checkout
                </button>
              </div>
            </div>
          )}

          {step === 3 && (
            <div style={{ textAlign: "center" }}>
              <div style={{
                background: "#f8fafc",
                borderRadius: "12px",
                padding: "24px",
                marginBottom: "30px",
                border: "1px solid #e2e8f0"
              }}>
                <h3 style={{ margin: "0 0 15px 0", fontSize: "18px", color: "#1e293b" }}>Order Summary</h3>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "10px" }}>
                  <span style={{ color: "#64748b" }}>Organization Name</span>
                  <span style={{ fontWeight: "600", color: "#1e293b" }}>{organizationName}</span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "10px" }}>
                  <span style={{ color: "#64748b" }}>Selected Tier</span>
                  <span style={{ fontWeight: "600", color: "#1e293b" }}>{PLANS.find(p => p.id === selectedPlan).name}</span>
                </div>
                <hr style={{ border: "none", borderTop: "1px solid #cbd5e1", margin: "15px 0" }} />
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
                  <span style={{ fontWeight: "bold", color: "#1e293b" }}>Total Due</span>
                  <span style={{ fontSize: "24px", fontWeight: "800", color: "#2563eb" }}>₹{PLANS.find(p => p.id === selectedPlan).price}</span>
                </div>
              </div>

              <div style={{ display: "flex", gap: "16px" }}>
                <button type="button" onClick={handlePrevStep} disabled={loading} style={{
                  flex: 1,
                  height: "48px",
                  background: "transparent",
                  border: "1px solid #cbd5e1",
                  borderRadius: "8px",
                  fontSize: "15px",
                  fontWeight: "600",
                  cursor: "pointer",
                  color: "#475569"
                }}>
                  Back
                </button>
                <button type="button" onClick={handlePaymentAndRegister} disabled={loading} style={{
                  flex: 2,
                  height: "48px",
                  background: "#2563eb",
                  border: "none",
                  borderRadius: "8px",
                  color: "#fff",
                  fontSize: "15px",
                  fontWeight: "700",
                  cursor: "pointer",
                  opacity: loading ? 0.7 : 1
                }}>
                  {loading ? "Processing..." : selectedPlan === "free" ? "Create Account" : "Pay & Create Account"}
                </button>
              </div>
            </div>
          )}

          <p className="register-bottom-text">
            Already have an account?{" "}
            <Link to="/" className="auth-link">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Register;