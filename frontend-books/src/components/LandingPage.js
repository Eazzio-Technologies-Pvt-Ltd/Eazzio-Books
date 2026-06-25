import React, { useEffect, useState, useRef } from "react";
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

const AnimatedDashboard = () => {
  const [step, setStep] = useState(0);
  const containerRef = useRef(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && step === 0) {
          setTimeout(() => setStep(1), 400);
          setTimeout(() => setStep(2), 1200);
          setTimeout(() => setStep(3), 2000);
          setTimeout(() => setStep(4), 2800);
        }
      },
      { threshold: 0.3 }
    );

    if (containerRef.current) {
      observer.observe(containerRef.current);
    }
    return () => observer.disconnect();
  }, [step]);

  // Amounts
  const inc = step >= 1 ? 12450000 : 0; // ₹1.24 Cr
  const exp = step >= 2 ? 3950000 : 0;  // ₹39.5 L
  const prof = step >= 3 ? (inc - exp) : 0;
  const cash = step >= 4 ? prof + 250000 : 0;

  const formatCurrency = (val) => {
    return '₹' + val.toLocaleString('en-IN', { maximumFractionDigits: 0 });
  };

  return (
    <div className="hero-dashboard-mockup zoom-in-up" ref={containerRef}>
      <div className="mockup-sidebar">
        <div className="mockup-brand">
          <img src="/logo.png" alt="Eazzio Books" style={{ height: '24px', filter: 'brightness(0) invert(1)' }} />
        </div>
        <div className="mock-menu">
          <div className="mock-menu-item active">Dashboard</div>
          <div className="mock-menu-item">Invoices</div>
          <div className="mock-menu-item">Expenses</div>
          <div className="mock-menu-item">Banking</div>
          <div className="mock-menu-item">Reports</div>
        </div>
      </div>

      <div className="mockup-main-area">
        <div className="mockup-header">
          <div className="mockup-search-dark">Search transactions...</div>
          <div className="mockup-actions">
            <div className="mockup-avatar">EA</div>
          </div>
        </div>

        <div className="mockup-content">
          <div className="mockup-stats-grid">
            <div className="mockup-stat-card">
              <div className="stat-label">
                <span className="icon inc-icon">📈</span> Total Income
              </div>
              <div className={`stat-value font-mono ${step >= 1 ? 'slide-up' : 'hidden'}`}>
                {formatCurrency(inc)}
              </div>
              <div className="stat-sub">This Year</div>
            </div>

            <div className="mockup-stat-card">
              <div className="stat-label">
                <span className="icon exp-icon">📉</span> Total Expenses
              </div>
              <div className={`stat-value font-mono ${step >= 2 ? 'slide-up' : 'hidden'}`}>
                {formatCurrency(exp)}
              </div>
              <div className="stat-sub">This Year</div>
            </div>

            <div className="mockup-stat-card">
              <div className="stat-label">
                <span className="icon prof-icon">₹</span> Net Profit
              </div>
              <div className={`stat-value font-mono ${step >= 3 ? 'slide-up' : 'hidden'}`}>
                {formatCurrency(prof)}
              </div>
              <div className="stat-sub">This Year</div>
            </div>

            <div className="mockup-stat-card">
              <div className="stat-label">
                <span className="icon cash-icon">💳</span> Net Cash
              </div>
              <div className={`stat-value font-mono ${step >= 4 ? 'slide-up' : 'hidden'}`}>
                {formatCurrency(cash)}
              </div>
              <div className="stat-sub">Available balance</div>
            </div>
          </div>

          <div className="mockup-chart-section">
            <div className="chart-header">
              <h4>Monthly Overview</h4>
              <div className="chart-legend-dots">
                <span className="dot blue"></span> Income
                <span className="dot yellow"></span> Expense
              </div>
            </div>
            <div className="chart-bars-mockup">
              <div className="chart-bar-group"><div className="bar b-inc h-60"></div><div className="bar b-exp h-30"></div></div>
              <div className="chart-bar-group"><div className="bar b-inc h-80"></div><div className="bar b-exp h-40"></div></div>
              <div className="chart-bar-group"><div className="bar b-inc h-40"></div><div className="bar b-exp h-20"></div></div>
              <div className="chart-bar-group"><div className="bar b-inc h-90"></div><div className="bar b-exp h-50"></div></div>
              <div className="chart-bar-group"><div className="bar b-inc h-70"></div><div className="bar b-exp h-60"></div></div>
            </div>
          </div>
        </div>
      </div>

      {step >= 4 && (
        <div className="al-badge pop-in" style={{ bottom: '30px', right: '30px', position: 'absolute' }}>
          <span className="check-icon">✓</span> Matched with bank
        </div>
      )}
    </div>
  );
};

const LandingPage = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
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
          <img src="/logo.png" alt="Eazzio Books" style={{ height: '35px' }} />
        </div>

        {/* Mobile Menu Toggle */}
        <div className="mobile-menu-toggle" style={{ display: 'none' }} onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}>
          ☰
        </div>

        <div className={`nav-right-group ${isMobileMenuOpen ? 'mobile-open' : ''}`}>
          <div className="nav-links">
            <a href="#features" className="nav-link" onClick={() => setIsMobileMenuOpen(false)}>Features</a>
            <a href="#pricing" className="nav-link" onClick={() => setIsMobileMenuOpen(false)}>Pricing</a>
            <a href="#resources" className="nav-link" onClick={() => setIsMobileMenuOpen(false)}>Resources</a>
          </div>
          <div className="nav-actions">
            <button className="nav-signin" onClick={() => navigate("/login")}>Sign In</button>
            <button className="nav-signup" onClick={() => navigate("/register")}>Start for free</button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="hero-section">
        <div className={`hero-content-two-column ${isVisible ? "fade-in-up" : ""}`}>
          <div className="hero-text-col" style={{ position: 'relative' }}>
            <div style={{
              position: 'absolute',
              top: '-10%', left: '-10%', right: '-10%', bottom: '-10%',
              backgroundImage: "url('/eazzio-books-hero-illustration.svg')",
              backgroundSize: 'contain',
              backgroundPosition: 'center',
              backgroundRepeat: 'no-repeat',
              opacity: 0.25,
              zIndex: 0
            }}></div>
            <div style={{ position: 'relative', zIndex: 10 }}>
              <div className="hero-eyebrow font-mono">Built for Indian businesses</div>
              <h1 className="hero-title font-fraunces">
                Bookkeeping that reconciles itself.
              </h1>
              <p className="hero-subtitle">
                Invoices, expenses, and bank feeds matched automatically in real-time.
              </p>

              <div className="hero-buttons">
                <button className="btn-primary" onClick={() => navigate("/register")}>Start free trial</button>
                <button className="btn-secondary" onClick={() => document.getElementById('pricing').scrollIntoView({ behavior: 'smooth' })}>See pricing</button>
              </div>

              <div className="hero-stats">
                <div className="stat-chip font-mono">
                  <strong>2.4 Cr+</strong> reconciled monthly
                </div>
                <div className="stat-chip font-mono">
                  <strong>1,200+</strong> invoices generated
                </div>
                <div className="stat-chip font-mono">
                  <strong>100%</strong> GST ready
                </div>
              </div>
            </div>
          </div>

          <div className="hero-visual-col" style={{ position: 'relative', display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '40px', minHeight: '550px' }}>
            <AnimatedDashboard />
          </div>
        </div>
      </section>

      {/* How it works Section / Features */}
      <section id="features" className="how-it-works-section">
        <div className="hiw-container">
          <h2 className="hiw-title font-fraunces">Monthly Workflow</h2>
          <div className="hiw-grid">
            <div className="hiw-step">
              <div className="hiw-number font-mono">01</div>
              <h4 className="font-fraunces">Record transactions</h4>
              <p>Create invoices and log expenses as they happen with minimal data entry.</p>
            </div>
            <div className="hiw-step">
              <div className="hiw-number font-mono">02</div>
              <h4 className="font-fraunces">Reconcile with your bank</h4>
              <p>Connect your bank feeds to match transactions automatically.</p>
            </div>
            <div className="hiw-step">
              <div className="hiw-number font-mono">03</div>
              <h4 className="font-fraunces">Review your reports</h4>
              <p>Generate P&L, Balance Sheet, and tax summaries in one click.</p>
            </div>
            <div className="hiw-step">
              <div className="hiw-number font-mono">04</div>
              <h4 className="font-fraunces">Close the books</h4>
              <p>Lock your financial periods securely with full audit trails.</p>
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

      {/* Footer Section / Resources */}
      <footer id="resources" className="landing-footer-complex">

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