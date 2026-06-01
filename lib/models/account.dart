class Account {
  final String id;
  final String accountNumber;
  final String type; // CURRENT, SAVINGS, TERM_DEPOSIT
  final double balance;
  final String status;
  final String? clientId;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.accountNumber,
    required this.type,
    required this.balance,
    required this.status,
    this.clientId,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case 'CURRENT': return 'Compte Courant';
      case 'SAVINGS': return 'Compte Epargne';
      case 'TERM_DEPOSIT': return 'Depot a Terme';
      default: return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'CURRENT': return 'wallet';
      case 'SAVINGS': return 'savings';
      case 'TERM_DEPOSIT': return 'lock';
      default: return 'account_balance';
    }
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      type: json['type'] ?? 'CURRENT',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'ACTIVE',
      clientId: json['clientId'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
