class BankAccount {
  final String name;
  final String accountNumber;
  final double balance;

  BankAccount({
    required this.name,
    required this.accountNumber,
    required this.balance,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      name: json['name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '—',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'account_number': accountNumber,
      'balance': balance,
    };
  }
}
