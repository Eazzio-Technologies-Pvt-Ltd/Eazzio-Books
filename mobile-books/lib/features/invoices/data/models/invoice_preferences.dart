class InvoicePreferences {
  final bool showGstin;
  final bool showPan;
  final bool showHsn;
  final bool showPaymentMode;
  final bool showDueDate;
  final bool showTerms;
  final bool showSignature;
  final bool showCgstSgst;

  InvoicePreferences({
    this.showGstin = false,
    this.showPan = false,
    this.showHsn = false,
    this.showPaymentMode = false,
    this.showDueDate = true,
    this.showTerms = true,
    this.showSignature = true,
    this.showCgstSgst = false,
  });

  factory InvoicePreferences.fromJson(Map<String, dynamic> json) {
    return InvoicePreferences(
      showGstin: json['show_gstin'] as bool? ?? false,
      showPan: json['show_pan'] as bool? ?? false,
      showHsn: json['show_hsn'] as bool? ?? false,
      showPaymentMode: json['show_payment_mode'] as bool? ?? false,
      showDueDate: json['show_due_date'] as bool? ?? true,
      showTerms: json['show_terms'] as bool? ?? true,
      showSignature: json['show_signature'] as bool? ?? true,
      showCgstSgst: json['show_cgst_sgst'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_gstin': showGstin,
      'show_pan': showPan,
      'show_hsn': showHsn,
      'show_payment_mode': showPaymentMode,
      'show_due_date': showDueDate,
      'show_terms': showTerms,
      'show_signature': showSignature,
      'show_cgst_sgst': showCgstSgst,
    };
  }

  InvoicePreferences copyWith({
    bool? showGstin,
    bool? showPan,
    bool? showHsn,
    bool? showPaymentMode,
    bool? showDueDate,
    bool? showTerms,
    bool? showSignature,
    bool? showCgstSgst,
  }) {
    return InvoicePreferences(
      showGstin: showGstin ?? this.showGstin,
      showPan: showPan ?? this.showPan,
      showHsn: showHsn ?? this.showHsn,
      showPaymentMode: showPaymentMode ?? this.showPaymentMode,
      showDueDate: showDueDate ?? this.showDueDate,
      showTerms: showTerms ?? this.showTerms,
      showSignature: showSignature ?? this.showSignature,
      showCgstSgst: showCgstSgst ?? this.showCgstSgst,
    );
  }
}
