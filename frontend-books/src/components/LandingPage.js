import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import RuppLogo from "./RuppLogo";
import "./LandingPage.css";

const pricingPlans = [
  {
    id: "free",
    name: "FREE PLAN",
    price: "0",
    description: "Basic features to get started",
    button: "Get started for free",
    featuresTitle: "Includes:",
    features: [
      { text: "Basic invoice" },
      { text: "Tracking payments" },
      { text: "1 user access" }
    ],
    support: "Community Support",
    users: "1 User"
  },
  {
    id: "premium",
    name: "STANDARD PREMIUM",
    price: "749",
    isPaid: true,
    description: "Advanced features for growing businesses",
    button: "Start 14 Days Trial",
    featuresTitle: "Includes:",
    features: [
      { text: "Automated payment reminders" },
      { text: "Complete inventory" },
      { text: "GST tracking reporting" }
    ],
    support: "Priority Support",
    users: "Unlimited Users"
  },
  {
    id: "professional",
    name: "PROFESSIONAL",
    price: "1499",
    isPaid: true,
    description: "Comprehensive features for established businesses",
    button: "Start 14 Days Trial",
    featuresTitle: "Includes everything in Standard, plus:",
    features: [
      { text: "Advanced workflow automation" },
      { text: "Multi-currency support" },
      { text: "Custom roles & permissions" }
    ],
    support: "24/7 Priority Support",
    users: "Unlimited Users"
  },
  {
    id: "enterprise",
    name: "ENTERPRISE",
    price: "1999",
    isPaid: true,
    description: "Ultimate power and control for large organizations",
    button: "Start 14 Days Trial",
    featuresTitle: "Includes everything in Professional, plus:",
    features: [
      { text: "Dedicated account manager" },
      { text: "Custom integrations & API" },
      { text: "Advanced analytics & reporting" }
    ],
    support: "Dedicated Support",
    users: "Unlimited Users"
  }
];

const LandingPage = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [pricingTab, setPricingTab] = useState('started');
  const [isAnnual, setIsAnnual] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    // Trigger entrance animations after mount
    setIsVisible(true);
  }, []);

  return (
    <div className="landing-page">
      {/* Top Navbar */}
      <nav className={`landing-navbar ${isVisible ? "slide-down" : ""}`}>
        <div className="nav-logo" style={{ display: 'flex', alignItems: 'center' }}>
          <RuppLogo height={40} />
        </div>
        <div className="nav-links">
          <a href="#features" className="nav-link">Features</a>
          <a href="#pricing" className="nav-link">Pricing</a>

          <a href="#resources" className="nav-link">Resources</a>
        </div>
        <div className="nav-actions">
          <button className="nav-signin" onClick={() => navigate("/login")}>Sign In</button>
          <button className="nav-signup" onClick={() => navigate("/register")}>Start for free</button>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="hero-section">
        {/* Floating Background Cards for Animation */}
        <div className="floating-cards-container">
          <div className={`floating-card detailed-card card-left-1 ${isVisible ? "animate-float-1" : ""}`}>
            <div className="detailed-card-header">
              <div className="paint-can-icon"></div>
            </div>
            <div className="detailed-card-body">
              <div className="d-title">Zylker paint</div>
              <div className="d-price">₹200.00 <span className="d-tag">12312</span></div>
              <div className="d-list">
                <div className="d-row"><span>Opening stock</span> <strong>210.00</strong></div>
                <div className="d-row"><span>Stock in Hand</span> <strong>150.00</strong></div>
                <div className="d-row"><span>Committed Stock</span> <strong>100.00</strong></div>
                <div className="d-row"><span>Available for Sale</span> <strong>50.00</strong></div>
              </div>
            </div>
          </div>

          <div className={`floating-card detailed-card card-right-1 ${isVisible ? "animate-float-3" : ""}`}>
            <div className="detailed-card-title">P & L Report</div>
            <div className="d-list">
              <div className="d-section-title">INCOME</div>
              <div className="d-row"><span>Sales</span> <span>₹200,000</span></div>
              <div className="d-row"><span>Services</span> <span>₹200,000</span></div>
              <div className="d-row"><span>Others</span> <span>₹200,000</span></div>
              <div className="d-section-title mt-2">EXPENSES</div>
              <div className="d-row"><span>Accounting</span> <span>₹200,000</span></div>
              <div className="d-row"><span>Marketing</span> <span>₹200,000</span></div>
              <div className="d-row"><span>Employees</span> <span>₹200,000</span></div>
            </div>
          </div>
        </div>

        {/* Hero Content */}
        <div className={`hero-content ${isVisible ? "fade-in-up" : ""}`}>
          <h1 className="hero-title">
            Comprehensive accounting platform<br />
            for growing businesses
          </h1>

          <p className="hero-subtitle">
            Manage end-to-end accounting — from invoicing to inventory & payroll with the best accounting software in India.
          </p>

          <div className="hero-buttons">
            <button className="btn-primary" onClick={() => navigate("/register")}>Start my free trial</button>
            <button className="btn-secondary" onClick={() => navigate("/login")}>Request a demo</button>
          </div>
        </div>

        {/* Hero Image / Dashboard Mockup */}
        <div className={`hero-dashboard-mockup ${isVisible ? "zoom-in-up" : ""}`} style={{ background: "#f8fafc", padding: "24px", borderRadius: "12px", border: "1px solid #e2e8f0", boxShadow: "0 20px 40px rgba(0,0,0,0.1)", textAlign: "left", maxWidth: "1000px", margin: "0 auto" }}>
          
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "24px" }}>
            <div>
              <h3 style={{ margin: "0 0 5px 0", fontSize: "20px", color: "#1e293b", fontWeight: "600" }}>Welcome back, Eazzio</h3>
              <p style={{ margin: 0, fontSize: "14px", color: "#64748b" }}>Here is your financial overview.</p>
            </div>
            <div style={{ display: "flex", gap: "10px", alignItems: "center" }}>
              <div style={{ width: "36px", height: "36px", borderRadius: "50%", background: "#0ba5ec", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: "bold", fontSize: "14px" }}>EA</div>
            </div>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "16px", marginBottom: "24px" }}>
            <div style={{ background: "#fff", padding: "16px", borderRadius: "8px", border: "1px solid #e2e8f0", boxShadow: "0 1px 2px rgba(0,0,0,0.05)" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px" }}>
                <div style={{ width: "28px", height: "28px", borderRadius: "6px", background: "#f0fdf4", color: "#15803d", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "14px" }}>₹</div>
                <div style={{ fontSize: "13px", color: "#475569", fontWeight: "500" }}>Total Receivables</div>
              </div>
              <div style={{ fontSize: "20px", fontWeight: "700", color: "#1d2939", marginBottom: "4px" }}>₹1,24,500.00</div>
              <div style={{ fontSize: "12px", color: "#d92d20", fontWeight: "500" }}>Unpaid Invoices</div>
            </div>
            <div style={{ background: "#fff", padding: "16px", borderRadius: "8px", border: "1px solid #e2e8f0", boxShadow: "0 1px 2px rgba(0,0,0,0.05)" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px" }}>
                <div style={{ width: "28px", height: "28px", borderRadius: "6px", background: "#fef2f2", color: "#b91c1c", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "14px" }}>💳</div>
                <div style={{ fontSize: "13px", color: "#475569", fontWeight: "500" }}>Total Payables</div>
              </div>
              <div style={{ fontSize: "20px", fontWeight: "700", color: "#1d2939", marginBottom: "4px" }}>₹45,200.00</div>
              <div style={{ fontSize: "12px", color: "#d92d20", fontWeight: "500" }}>Unpaid Bills</div>
            </div>
            <div style={{ background: "#fff", padding: "16px", borderRadius: "8px", border: "1px solid #e2e8f0", boxShadow: "0 1px 2px rgba(0,0,0,0.05)" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px" }}>
                <div style={{ width: "28px", height: "28px", borderRadius: "6px", background: "#eff6ff", color: "#1d4ed8", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "14px" }}>📈</div>
                <div style={{ fontSize: "13px", color: "#475569", fontWeight: "500" }}>Total Income</div>
              </div>
              <div style={{ fontSize: "20px", fontWeight: "700", color: "#1d2939", marginBottom: "4px" }}>₹8,50,000.00</div>
              <div style={{ fontSize: "12px", color: "#039855", fontWeight: "500" }}>All Time</div>
            </div>
            <div style={{ background: "#fff", padding: "16px", borderRadius: "8px", border: "1px solid #e2e8f0", boxShadow: "0 1px 2px rgba(0,0,0,0.05)" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px" }}>
                <div style={{ width: "28px", height: "28px", borderRadius: "6px", background: "#f8fafc", color: "#475569", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "14px" }}>📉</div>
                <div style={{ fontSize: "13px", color: "#475569", fontWeight: "500" }}>Total Expenses</div>
              </div>
              <div style={{ fontSize: "20px", fontWeight: "700", color: "#1d2939", marginBottom: "4px" }}>₹3,20,000.00</div>
              <div style={{ fontSize: "12px", color: "#475569", fontWeight: "500" }}>All Time</div>
            </div>
          </div>

          <div style={{ background: "#fff", padding: "20px", borderRadius: "8px", border: "1px solid #e2e8f0", boxShadow: "0 1px 2px rgba(0,0,0,0.05)" }}>
             <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
               <h4 style={{ margin: "0", fontSize: "15px", color: "#1d2939", fontWeight: "600" }}>Monthly Overview</h4>
               <div style={{ padding: "4px 12px", background: "#f1f5f9", borderRadius: "4px", fontSize: "13px", color: "#475569", border: "1px solid #e2e8f0" }}>June 2026</div>
             </div>
             
             <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "16px" }}>
                <div style={{ borderRight: "1px solid #f1f5f9" }}>
                  <div style={{ fontSize: "12px", color: "#64748b", marginBottom: "6px", fontWeight: "600", letterSpacing: "0.5px" }}>INCOME</div>
                  <div style={{ fontSize: "18px", fontWeight: "700", color: "#039855" }}>₹1,50,000.00</div>
                </div>
                <div style={{ borderRight: "1px solid #f1f5f9" }}>
                  <div style={{ fontSize: "12px", color: "#64748b", marginBottom: "6px", fontWeight: "600", letterSpacing: "0.5px" }}>EXPENSES</div>
                  <div style={{ fontSize: "18px", fontWeight: "700", color: "#d92d20" }}>₹45,000.00</div>
                </div>
                <div style={{ borderRight: "1px solid #f1f5f9" }}>
                  <div style={{ fontSize: "12px", color: "#64748b", marginBottom: "6px", fontWeight: "600", letterSpacing: "0.5px" }}>PROFIT</div>
                  <div style={{ fontSize: "18px", fontWeight: "700", color: "#039855" }}>₹1,05,000.00</div>
                </div>
                <div>
                  <div style={{ fontSize: "12px", color: "#64748b", marginBottom: "6px", fontWeight: "600", letterSpacing: "0.5px" }}>NET CASH</div>
                  <div style={{ fontSize: "18px", fontWeight: "700", color: "#0ba5ec" }}>₹1,05,000.00</div>
                </div>
             </div>
          </div>

        </div>
      </section>

      {/* Thematic Divider */}
      <div className="white-line-divider"></div>

      {/* Pricing Section */}
      <section id="pricing" className="pricing-section">
        <div className="pricing-header-blue">
          <h2>The Perfect Balance<br />of Features and Affordability</h2>

          <div className="pricing-benefits">
            <span className="benefit-item"><span className="check-icon-white">✓</span> Compliance-driven</span>
            <span className="benefit-item"><span className="check-icon-white">✓</span> Simple and intuitive UI</span>
            <span className="benefit-item"><span className="check-icon-white">✓</span> Reliable online support</span>
          </div>

          <div className="advanced-cards-container" style={{ justifyContent: 'center', marginTop: '40px' }}>
            {pricingPlans.map((plan, index) => (
              <div className="advanced-card" key={index} style={{ maxWidth: '400px' }}>
                <div className="ac-header">
                  <h4>{plan.name}</h4>
                  <p className="ac-desc">{plan.description}</p>
                  <div className="ac-price-box">
                    <div className="ac-price">
                      <span className="ac-currency">₹</span>
                      <span className="ac-amount animate-up">
                        {plan.price}
                      </span>
                    </div>
                    {plan.price !== "0" && <p className="ac-billed">Price/Org/Month</p>}
                  </div>
                  {plan.isPaid ? (
                    <button
                      className="p-btn advanced-btn"
                      onClick={() => navigate('/register', { state: { planId: 'premium', price: plan.price } })}
                    >
                      {plan.button}
                    </button>
                  ) : (
                    <button
                      className="p-btn advanced-btn"
                      onClick={() => navigate('/register')}
                    >
                      {plan.button}
                    </button>
                  )}
                </div>
                <div className="ac-features">
                  <div className="ac-f-title">{plan.featuresTitle}</div>
                  <ul>
                    {plan.features.map((f, i) => (
                      <li key={i}>
                        <span className="check-icon-black">✓</span>
                        <span className="f-text">{f.text}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <div className="ac-footer">
                  <div className="ac-users">{plan.users}</div>
                  <div className="ac-support">{plan.support}</div>
                </div>
              </div>
            ))}
          </div>

        </div>
      </section>

      {/* Migration Banner */}
      <section className="migration-banner">
        <div className="banner-content">
          <div className="banner-icon">🚀</div>
          <div className="banner-text">
            <strong>Migrate to Eazzio Books.</strong>
            <p>Now you can easily move from other accounting solutions to Eazzio Books!</p>
          </div>
          <button className="banner-btn">Contact us →</button>
        </div>
      </section>

      {/* Dark Testimonial Section */}
      <section className="dark-section">
        <div className="dark-section-header">
          <h2>Make the switch to the future of business accounting</h2>
        </div>
        <div className="testimonial-container">
          <div className="testimonial-cards">
            <div className="t-card">
              <div className="t-avatar"></div>
              <div className="t-info">
                <h4>One accounting solution for multiple outlets</h4>
                <p>SHARMA HANDLOOM, DIRECTOR</p>
              </div>
            </div>
            <div className="t-card">
              <div className="t-avatar"></div>
              <div className="t-info">
                <h4>User friendly, comprehensive, and highly compliant</h4>
                <p>TARUN KUMAR SAIN, DIRECTOR</p>
              </div>
            </div>
          </div>
          <div className="testimonial-highlight">
            <h1>"</h1>
            <h2>I TRUST EAZZIO BOOKS FOR BUSINESS</h2>
          </div>
        </div>
      </section>

      {/* Privacy Section */}
      <section className="privacy-section">
        <div className="privacy-icon">🔒</div>
        <h2>Choose privacy.<br />Choose Eazzio.</h2>
        <p>
          At Eazzio, we take pride in our perpetual efforts to surpass all expectations in providing security and privacy to our customers in this increasingly connected world.
        </p>
        <div className="security-badges">
          <div className="sec-badge bsi-iso">
            <span className="bsi-logo">bsi.</span>
            <div className="sec-text">
              <strong>ISO<br />9001:2015</strong>
              <span>Quality Management System</span>
            </div>
            <div className="sec-bottom">FS 724104</div>
          </div>
          <div className="sec-badge aicpa">
            <strong>AICPA</strong>
            <span>SOC</span>
          </div>
          <div className="sec-badge gdpr">
            <span className="stars">★ ★ ★</span>
            <strong>GDPR</strong>
            <span className="stars">★ ★ ★</span>
          </div>
          <div className="sec-badge bsi-iso-large">
            <span className="bsi-logo">bsi.</span>
            <div className="sec-columns">
              <div className="sec-col">
                <strong>ISO/IEC<br />27017</strong>
                <span>Security Controls for Cloud Services</span>
              </div>
              <div className="sec-col">
                <strong>ISO/IEC<br />27018</strong>
                <span>Protection of Personally identifiable information</span>
              </div>
            </div>
            <div className="sec-bottom" style={{ left: '50px' }}>CLOUD 714132 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; PII 714133</div>
          </div>
        </div>
      </section>

      {/* Footer Section */}
      <footer className="landing-footer-complex">

        {/* Pre-footer Grid */}
        <div className="pre-footer-grid">
          <div className="pf-col">
            <div className="pf-icon">⌛</div>
            <h4>Free trial</h4>
            <p>Start with a 14-day free trial to experience effortless accounting.</p>
            <button className="pf-btn">Start Trial</button>
          </div>
          <div className="pf-col">
            <div className="pf-icon">💻</div>
            <h4>Demo organization</h4>
            <p>Explore Eazzio Books features without using your real business data.</p>
            <button className="pf-btn">Explore Demo Account</button>
          </div>
          <div className="pf-col">
            <div className="pf-icon">📋</div>
            <h4>Plans and pricing</h4>
            <p>Compare plans and features and find the best fit for your needs!</p>
            <button className="pf-btn">View all plans</button>
          </div>
          <div className="pf-col">
            <div className="pf-icon">🖥️</div>
            <h4>Webinar</h4>
            <p>Join us online for a live webinar to make the best out of Eazzio Books.</p>
            <button className="pf-btn">Show All Webinars</button>
          </div>
        </div>

        {/* Main Footer Links */}
        <div className="main-footer-grid">
          {/* Left Column (Contact & Apps) */}
          <div className="mf-left-col">
            <div className="mf-section-title">CONTACT US ON</div>
            <div className="contact-item">
              <span className="c-icon">📞</span>
              <div>
                <div className="c-title">Mon - Fri (9:00AM to 7:00PM)</div>
                <div className="c-desc">18005726671</div>
              </div>
            </div>
            <div className="contact-item">
              <span className="c-icon">✉️</span>
              <div>
                <div className="c-title">Mail Us</div>
                <div className="c-desc">support.india@eazzio.com</div>
              </div>
            </div>

            <div className="mf-section-title mt-8">AVAILABLE ON</div>
            <div className="app-buttons">
              <button className="app-btn">Apple Store</button>
              <button className="app-btn">Google Play</button>
            </div>

            <div className="mf-section-title mt-8">AVAILABLE ON DESKTOP APP</div>
            <button className="app-btn">Microsoft Store</button>

            <div className="mf-section-title mt-8">FEATURED APP</div>
            <div className="featured-app-card">
              <span className="f-icon">🛍️</span>
              <div>
                <div className="f-title">Eazzio Commerce</div>
                <a href="#learn" className="f-link">LEARN MORE</a>
              </div>
            </div>

            <div className="mf-section-title mt-8">CONNECT WITH US</div>
            <div className="social-icons">
              <span>𝕏</span>
              <span>📸</span>
              <span>▶️</span>
              <span>💼</span>
            </div>
          </div>

          {/* Middle Column (Product Help & Resources) */}
          <div className="mf-mid-col">
            <div className="mf-section-title border-bottom-title">PRODUCT HELP & RESOURCES</div>
            <div className="mf-mid-grid">
              <div className="mf-links-group">
                <div className="mf-group-title">ABOUT EAZZIO BOOKS</div>
                <ul>
                  <li><a href="#what">What is Eazzio Books?</a></li>
                  <li><a href="#features">All Features</a></li>
                  <li><a href="#gst">GST Accounting</a></li>
                  <li><a href="#pricing">Pricing</a></li>
                  <li><a href="#customers">Customers</a></li>
                  <li><a href="#integrations">Integrations</a></li>
                  <li><a href="#accountant">Accountant Program</a></li>
                  <li><a href="#partner">Register as a Partner</a></li>
                  <li><a href="#training">Training & Certification</a></li>
                </ul>
              </div>
              <div className="mf-links-group">
                <div className="mf-group-title">HELPFUL RESOURCES</div>
                <ul>
                  <li><a href="#help">Help Documentation</a></li>
                  <li><a href="#api">Developers API</a></li>
                  <li><a href="#faq">FAQs</a></li>
                  <li><a href="#videos">Product Videos</a></li>
                  <li><a href="#webinars">Webinars</a></li>
                  <li><a href="#blogs">Blogs</a></li>
                  <li><a href="#forums">Forums</a></li>
                  <li><a href="#whats-new">What's New</a></li>
                  <li><a href="#find-accountant">Find an Accountant</a></li>
                </ul>
              </div>
              <div className="mf-links-group">
                <div className="mf-group-title">CONNECTED BANKING PARTNERS</div>
                <ul>
                  <li><a href="#scb">Standard Chartered Bank</a></li>
                  <li><a href="#kotak">Kotak Mahindra Bank</a></li>
                  <li><a href="#hsbc">HSBC Bank</a></li>
                </ul>
              </div>
            </div>

            <div className="mf-section-title border-bottom-title mt-8">OTHER RESOURCES</div>
            <div className="mf-other-links">
              <a href="#free">Free Accounting Software</a>
              <a href="#bookkeeping">Bookkeeping Software</a>
              <a href="#spreadsheet">Accounting for Spreadsheet Users</a>
              <a href="#crm">CRM Accounting Software</a>
            </div>
          </div>

          {/* Right Column (Learning Hub & Free Tools) */}
          <div className="mf-right-col">
            <div className="mf-section-title border-bottom-title">LEARNING HUB</div>
            <div className="mf-links-group">
              <ul>
                <li><a href="#gst-resources">GST Resources</a></li>
                <li><a href="#guides">Essential Business Guides</a></li>
                <li><a href="#dictionary">Accounting Dictionary</a></li>
                <li><a href="#what-is-acc">What is Accounting Software?</a></li>
              </ul>
            </div>

            <div className="mf-section-title border-bottom-title mt-8">FREE TOOLS</div>
            <div className="mf-links-group">
              <ul>
                <li><a href="#hsn">HSN/SAC Finder</a></li>
                <li><a href="#invoice">Invoice Generator</a></li>
                <li><a href="#quote">Quote Generator</a></li>
                <li><a href="#calc">GST Calculator</a></li>
              </ul>
            </div>
          </div>
        </div>

        {/* App Ecosystem Banner */}
        <div className="ecosystem-banner">
          <p>Other Eazzio Finance & Operations Apps</p>
          <div className="ecosystem-logos">
            <span>⚙️ Eazzio ERP</span>
            <span>💸 Eazzio Expense</span>
            <span>💳 Eazzio Billing</span>
            <span>📦 Eazzio Inventory</span>
            <span>💰 Eazzio Payroll</span>
            <span>⚗️ Eazzio Practice</span>
            <span>🛍️ RUP Commerce</span>
          </div>
        </div>

        {/* Footer Bottom Bar */}
        <div className="footer-bottom-bar">
          <div className="fb-links">
            <a href="#contact">Contact</a>
            <a href="#security">Security</a>
            <a href="#compliance">Compliance</a>
            <a href="#ipr">IPR Complaints</a>
            <a href="#anti-spam">Anti-spam Policy</a>
            <a href="#tos">Terms of Service</a>
            <a href="#privacy">Privacy Policy</a>
            <a href="#trademark">Trademark Policy</a>
            <a href="#cookie">Cookie Policy</a>
            <a href="#gdpr">GDPR Compliance</a>
            <a href="#abuse">Abuse Policy</a>
          </div>
          <p className="copyright">&copy; {new Date().getFullYear()}, Eazzio Corporation Pvt. Ltd. All Rights Reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;