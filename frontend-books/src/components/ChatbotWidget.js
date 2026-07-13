import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import './ChatbotWidget.css';

const ChatbotWidget = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [hasOpened, setHasOpened] = useState(false);
  const [messages, setMessages] = useState([]);
  const [isTyping, setIsTyping] = useState(false);
  const [currentState, setCurrentState] = useState('GREETING');
  const [answers, setAnswers] = useState({
    businessSize: '',
    currentTool: '',
    featureInterest: '',
    keyNeed: '',
    recommendedPlan: '',
  });
  const [emailInput, setEmailInput] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const messagesEndRef = useRef(null);
  const navigate = useNavigate();

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    if (isOpen) {
      setTimeout(scrollToBottom, 100);
    }
  }, [messages, isTyping, isOpen]);

  useEffect(() => {
    if (isOpen && messages.length === 0) {
      addBotMessage("Hi! I'm here to help you find the right plan for your business. Mind answering a couple quick questions?");
    }
  }, [isOpen]);

  useEffect(() => {
    const handleEsc = (e) => {
      if (e.key === 'Escape' && isOpen) {
        setIsOpen(false);
      }
    };
    window.addEventListener('keydown', handleEsc);
    return () => window.removeEventListener('keydown', handleEsc);
  }, [isOpen]);

  const addBotMessage = (text, delay = 500) => {
    setIsTyping(true);
    setTimeout(() => {
      setMessages(prev => [...prev, { text, sender: 'bot' }]);
      setIsTyping(false);
    }, delay);
  };

  const addUserMessage = (text) => {
    setMessages(prev => [...prev, { text, sender: 'user' }]);
  };

  const handleOptionClick = (option, nextState) => {
    addUserMessage(option);
    if (nextState === 'BUSINESS_SIZE') {
      setCurrentState('BUSINESS_SIZE');
      addBotMessage("How many people will use Eazzio Books?");
    } else if (nextState === 'END_NO_THANKS') {
      setCurrentState('END_NO_THANKS');
      addBotMessage("No problem! Feel free to browse around. I'll be here if you need me.");
    }
  };

  const handleBusinessSize = (size) => {
    addUserMessage(size);
    setAnswers(prev => ({ ...prev, businessSize: size }));
    setCurrentState('CURRENT_TOOL');
    addBotMessage("Are you currently using another accounting tool?");
  };

  const handleCurrentTool = (tool) => {
    addUserMessage(tool);
    setAnswers(prev => ({ ...prev, currentTool: tool }));
    setCurrentState('FEATURE_INTEREST');
    addBotMessage("Which Eazzio Books feature sounds most exciting to you?");
  };

  const handleFeatureInterest = (feature) => {
    addUserMessage(feature);
    setAnswers(prev => ({ ...prev, featureInterest: feature }));
    setCurrentState('KEY_NEED');
    addBotMessage("Got it! And what matters most to you right now?");
  };

  const handleKeyNeed = (need) => {
    addUserMessage(need);
    const updatedAnswers = { ...answers, keyNeed: need };
    
    let recommendedPlan = 'Standard Premium';
    let reason = "it includes all the core features you need to manage your finances effectively.";
    
    if (need === 'Basic invoicing' && updatedAnswers.businessSize === 'Just me') {
      recommendedPlan = 'Free';
      reason = "it has everything you need to send your first invoice without any cost.";
    } else if (need === 'Cash flow forecasting' || need === 'Inventory & purchases') {
      recommendedPlan = 'Standard Premium';
      reason = "it includes advanced forecasting and inventory tracking that Zoho Books doesn't have.";
    } else if (need === 'Team & reporting features' || updatedAnswers.businessSize === '6+ people') {
      recommendedPlan = 'Professional';
      reason = "it's built for teams with custom roles, advanced reporting, and full audit logs.";
    }

    updatedAnswers.recommendedPlan = recommendedPlan;
    setAnswers(updatedAnswers);
    
    setCurrentState('RECOMMENDATION');
    addBotMessage(`Based on what you told me, the **${recommendedPlan}** plan is your best bet because ${reason}`);
    setTimeout(() => {
      addBotMessage("Want us to send you a quick guide by email?", 800);
    }, 1500);
  };

  const handleEmailSubmit = async (e) => {
    e.preventDefault();
    if (!emailInput || !emailInput.includes('@')) return;
    
    setIsSubmitting(true);
    addUserMessage(`Send it to ${emailInput}`);
    
    try {
      const response = await fetch(`${process.env.REACT_APP_API_URL || 'http://localhost:5000/api'}/leads`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...answers, email: emailInput }),
      });
      
      if (response.ok) {
        setCurrentState('END_SUCCESS');
        addBotMessage("Thanks! We've sent the guide. You can check out the plan details or start a free trial now.");
      } else {
        throw new Error('Failed to submit');
      }
    } catch (err) {
      console.error(err);
      setCurrentState('END_SUCCESS');
      addBotMessage("Oops, something went wrong saving your email, but you can still check out the plans below!");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSkipEmail = () => {
    addUserMessage("No thanks, just show me the plan");
    setCurrentState('END_SUCCESS');
    addBotMessage("No problem! You can check out the plan details below.");
  };

  const handleRestart = () => {
    setMessages([]);
    setCurrentState('GREETING');
    setAnswers({ businessSize: '', currentTool: '', featureInterest: '', keyNeed: '', recommendedPlan: '' });
    addBotMessage("Hi! Let's start over. Mind answering a couple quick questions?");
  };

  const navigateToPlan = () => {
    if (answers.recommendedPlan === 'Free') {
      navigate('/register');
    } else {
      navigate('/pricing');
      window.scrollTo(0, 0);
    }
  };

  return (
    <div className="chatbot-widget-container">
      {!isOpen && !hasOpened && (
        <div className="chatbot-tooltip" onClick={() => { setIsOpen(true); setHasOpened(true); }}>
          Need help choosing a plan? 👋
        </div>
      )}
      <button
        onClick={() => { setIsOpen(!isOpen); setHasOpened(true); }}
        className="chatbot-toggle-btn"
        aria-label="Toggle chat"
      >
        {isOpen ? (
          <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
        ) : (
          <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"></path></svg>
        )}
        {!isOpen && !hasOpened && (
          <span className="chatbot-pulse-ring">
            <span className="chatbot-pulse-ring-inner"></span>
            <span className="chatbot-pulse-dot"></span>
          </span>
        )}
      </button>

      <div 
        role="dialog"
        aria-live="polite"
        className={`chatbot-panel ${isOpen ? 'open' : 'closed'}`}
      >
        <div className="chatbot-header">
          <div className="chatbot-header-info">
            <div className="chatbot-logo">E</div>
            <div>
              <h3 className="chatbot-title">Eazzio Books Guide</h3>
              <p className="chatbot-subtitle">Typically replies instantly</p>
            </div>
          </div>
          <button onClick={() => setIsOpen(false)} className="chatbot-close-btn">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <div className="chatbot-messages">
          {messages.map((msg, idx) => (
            <div key={idx} className={`chatbot-message-row ${msg.sender}`}>
              <div className={`chatbot-bubble ${msg.sender}`}>
                {msg.text.includes('**') ? (
                  <span dangerouslySetInnerHTML={{__html: msg.text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')}} />
                ) : (
                  msg.text
                )}
              </div>
            </div>
          ))}
          
          {isTyping && (
            <div className="chatbot-message-row bot">
              <div className="chatbot-typing">
                <div className="chatbot-typing-dot"></div>
                <div className="chatbot-typing-dot"></div>
                <div className="chatbot-typing-dot"></div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <div className="chatbot-input-area">
          {!isTyping && (
            <>
              {currentState === 'GREETING' && (
                <>
                  <button onClick={() => handleOptionClick("Sure, let's go", 'BUSINESS_SIZE')} className="chatbot-action-btn">Sure, let's go</button>
                  <button onClick={() => handleOptionClick("No thanks, I'll browse", 'END_NO_THANKS')} className="chatbot-action-btn secondary">No thanks, I'll browse</button>
                </>
              )}
              
              {currentState === 'BUSINESS_SIZE' && (
                <>
                  <button onClick={() => handleBusinessSize("Just me")} className="chatbot-action-btn">Just me</button>
                  <button onClick={() => handleBusinessSize("2–5 people")} className="chatbot-action-btn">2–5 people</button>
                  <button onClick={() => handleBusinessSize("6+ people")} className="chatbot-action-btn">6+ people</button>
                </>
              )}

              {currentState === 'CURRENT_TOOL' && (
                <>
                  <button onClick={() => handleCurrentTool("No, first time")} className="chatbot-action-btn">No, first time</button>
                  <button onClick={() => handleCurrentTool("Yes, switching from Zoho/Tally/Vyapar")} className="chatbot-action-btn">Yes, switching (Zoho/Tally/etc)</button>
                  <button onClick={() => handleCurrentTool("Yes, using spreadsheets")} className="chatbot-action-btn">Yes, using spreadsheets</button>
                </>
              )}

              {currentState === 'FEATURE_INTEREST' && (
                <>
                  <button onClick={() => handleFeatureInterest("Split Payments")} className="chatbot-action-btn">Split Payments across modes</button>
                  <button onClick={() => handleFeatureInterest("Installment Scheduler")} className="chatbot-action-btn">Auto-Installment Scheduler</button>
                  <button onClick={() => handleFeatureInterest("Petty Cash Tracking")} className="chatbot-action-btn">Petty Cash & Undeposited Funds</button>
                  <button onClick={() => handleFeatureInterest("Projected Income")} className="chatbot-action-btn">Projected Income Dashboard</button>
                </>
              )}

              {currentState === 'KEY_NEED' && (
                <>
                  <button onClick={() => handleKeyNeed("Basic invoicing")} className="chatbot-action-btn">Basic invoicing</button>
                  <button onClick={() => handleKeyNeed("Inventory & purchases")} className="chatbot-action-btn">Inventory & purchases</button>
                  <button onClick={() => handleKeyNeed("Cash flow forecasting")} className="chatbot-action-btn">Cash flow forecasting</button>
                  <button onClick={() => handleKeyNeed("Team & reporting features")} className="chatbot-action-btn">Team & reporting features</button>
                </>
              )}

              {currentState === 'RECOMMENDATION' && (
                <>
                  <form onSubmit={handleEmailSubmit} className="chatbot-email-form">
                    <input 
                      type="email" 
                      placeholder="Your email address" 
                      value={emailInput}
                      onChange={(e) => setEmailInput(e.target.value)}
                      className="chatbot-email-input"
                      required
                    />
                    <button type="submit" disabled={isSubmitting} className="chatbot-email-submit">
                      {isSubmitting ? '...' : 'Send it'}
                    </button>
                  </form>
                  <button onClick={handleSkipEmail} className="chatbot-text-btn">No thanks, just show me the plan</button>
                </>
              )}

              {currentState === 'END_SUCCESS' && (
                <>
                  <button onClick={navigateToPlan} className="chatbot-action-btn primary">
                    {answers.recommendedPlan === 'Free' ? 'Start Free Plan' : `Explore ${answers.recommendedPlan}`}
                  </button>
                  <button onClick={handleRestart} className="chatbot-text-btn">Restart questionnaire</button>
                </>
              )}

              {currentState === 'END_NO_THANKS' && (
                <button onClick={handleRestart} className="chatbot-text-btn" style={{color: '#2563eb'}}>I changed my mind, let's start</button>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default ChatbotWidget;
