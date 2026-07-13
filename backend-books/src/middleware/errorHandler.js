const errorHandler = (err, req, res, next) => {
  console.error("GLOBAL ERROR HANDLER:", err);

  // PostgreSQL Foreign Key or Restrict Violation
  if (err.code === '23503' || err.code === '23001' || (err.message && err.message.includes('violates RESTRICT setting'))) {
    let message = "Cannot delete: this record is in use.";
    
    // Customize messages based on the specific RESTRICT constraints we applied
    if (err.constraint) {
      if (err.constraint.includes("journal_entry_lines_account_id")) {
        message = "Cannot delete: this account has journal entries.";
      } else if (err.constraint.includes("currency_adjustments_account_id")) {
        message = "Cannot delete: this account has currency adjustments.";
      } else if (err.constraint.includes("purchase_orders_vendor_id")) {
        message = "Cannot delete: this vendor has purchase orders.";
      } else if (err.constraint.includes("purchase_order_items_item_id")) {
        message = "Cannot delete: this item is used in purchase orders.";
      } else if (err.constraint.includes("users_role_id")) {
        message = "Cannot delete: there are users assigned to this role.";
      } else if (err.constraint.includes("organizations_owner_id")) {
        message = "Cannot delete: this user is the owner of an organization. Transfer ownership first.";
      } else if (err.constraint.includes("credit_note_applications_user_id") || 
                 err.constraint.includes("purchase_orders_user_id") || 
                 err.constraint.includes("taxes_user_id")) {
        message = "Cannot delete: this user has created financial records (Credit Notes, POs, or Taxes) and must be preserved for the audit trail. Please deactivate the user instead.";
      }
    }

    return res.status(400).json({ message });
  }

  // Generic fallback
  res.status(500).json({ message: err.message || "Server error" });
};

module.exports = errorHandler;
