class StatementTransaction {
  final String date;
  final String type;
  final String reference;
  final double debit;
  final double credit;
  final double balance;

  StatementTransaction({
    required this.date,
    required this.type,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  factory StatementTransaction.fromJson(Map<String, dynamic> json) {
    return StatementTransaction(
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'Invoice',
      reference: json['reference'] as String? ?? '',
      debit: (json['debit'] as num? ?? 0).toDouble(),
      credit: (json['credit'] as num? ?? 0).toDouble(),
      balance: (json['balance'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'type': type,
      'reference': reference,
      'debit': debit,
      'credit': credit,
      'balance': balance,
    };
  }
}

class CustomerStatement {
  final double openingBalance;
  final double closingBalance;
  final List<StatementTransaction> transactions;

  CustomerStatement({
    required this.openingBalance,
    required this.closingBalance,
    required this.transactions,
  });

  factory CustomerStatement.fromJson(Map<String, dynamic> json) {
    return CustomerStatement(
      openingBalance: (json['opening_balance'] as num? ?? 0).toDouble(),
      closingBalance: (json['closing_balance'] as num? ?? 0).toDouble(),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((e) => StatementTransaction.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }
}
