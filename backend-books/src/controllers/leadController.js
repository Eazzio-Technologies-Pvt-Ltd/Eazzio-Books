const pool = require('../config/db');
const nodemailer = require('nodemailer');

const createLead = async (req, res) => {
  const { businessSize, currentTool, featureInterest, keyNeed, recommendedPlan, email } = req.body;

  // Basic validation
  if (!businessSize || !currentTool || !keyNeed || !recommendedPlan) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  try {
    const result = await pool.query(
      `INSERT INTO leads (business_size, current_tool, feature_interest, key_need, recommended_plan, email, source)
       VALUES ($1, $2, $3, $4, $5, $6, 'chatbot')
       RETURNING *`,
      [businessSize, currentTool, featureInterest || null, keyNeed, recommendedPlan, email || null]
    );

    const newLead = result.rows[0];

    // If an email was provided, send a confirmation email
    if (email) {
      try {
        const transporter = nodemailer.createTransport({
          host: process.env.SMTP_HOST || "smtp-relay.sendinblue.com",
          port: parseInt(process.env.SMTP_PORT || "587"),
          secure: false, // true for 465, false for other ports
          auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS,
          },
        });

        const subject = "Your Guide to Eazzio Books";
        const text = `Hi there,\n\nThank you for chatting with us!\n\nBased on your answers, we recommended the ${recommendedPlan} plan for your business.\n\nWe've attached our quick start guide (coming soon) and will be in touch shortly to see if you have any questions.\n\nBest regards,\nThe Eazzio Books Team`;
        
        await transporter.sendMail({
          from: process.env.FROM_EMAIL || "noreply@tinplate.com",
          to: email,
          subject: subject,
          text: text,
        });
      } catch (emailErr) {
        console.error("Failed to send lead confirmation email:", emailErr);
        // We don't fail the request if the email fails, we just log it
      }
    }

    res.status(201).json({ message: "Lead captured successfully", lead: newLead });
  } catch (err) {
    console.error("CREATE LEAD ERROR:", err);
    res.status(500).json({ message: "Server error capturing lead" });
  }
};

module.exports = {
  createLead
};
