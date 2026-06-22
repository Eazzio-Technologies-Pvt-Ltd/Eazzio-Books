class GstCalculatorResult {
  final double subtotal;
  final double discountAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;
  final double totalAmount;
  final bool isIntraState;

  GstCalculatorResult({
    required this.subtotal,
    required this.discountAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
    required this.totalAmount,
    required this.isIntraState,
  });
}

class GstLineItem {
  final double quantity;
  final double unitPrice;
  final double taxRate; // e.g. 18.0 for 18%
  final double discount; // discount value
  final String discountType; // 'percentage' or 'flat'

  GstLineItem({
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.discount,
    required this.discountType,
  });
}

class GstCalculator {
  static GstCalculatorResult calculate({
    required String stateA,
    required String stateB,
    required List<GstLineItem> items,
  }) {
    final cleanStateA = stateA.trim().toLowerCase();
    final cleanStateB = stateB.trim().toLowerCase();
    final isIntraState = cleanStateA.isNotEmpty &&
        cleanStateB.isNotEmpty &&
        cleanStateA == cleanStateB;

    double subtotal = 0.0;
    double discountAmount = 0.0;
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;

    for (final item in items) {
      final lineGross = item.quantity * item.unitPrice;
      subtotal += lineGross;

      double itemDiscount = 0.0;
      if (item.discountType == 'percentage') {
        itemDiscount = lineGross * (item.discount / 100.0);
      } else {
        itemDiscount = item.discount;
      }
      discountAmount += itemDiscount;

      final taxableValue = lineGross - itemDiscount;
      final lineTax = taxableValue * (item.taxRate / 100.0);

      if (isIntraState) {
        cgstAmount += lineTax / 2.0;
        sgstAmount += lineTax / 2.0;
      } else {
        igstAmount += lineTax;
      }
    }

    final totalTax = cgstAmount + sgstAmount + igstAmount;
    final totalAmount = subtotal - discountAmount + totalTax;

    return GstCalculatorResult(
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
      cgstAmount: double.parse(cgstAmount.toStringAsFixed(2)),
      sgstAmount: double.parse(sgstAmount.toStringAsFixed(2)),
      igstAmount: double.parse(igstAmount.toStringAsFixed(2)),
      totalTax: double.parse(totalTax.toStringAsFixed(2)),
      totalAmount: double.parse(totalAmount.toStringAsFixed(2)),
      isIntraState: isIntraState,
    );
  }
}
