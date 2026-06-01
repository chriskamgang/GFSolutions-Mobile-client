class Transaction {
  final String id;
  final String type; // DEPOSIT, WITHDRAWAL, TRANSFER, FEE, INTEREST
  final double amount;
  final double? fees;
  final String? description;
  final String? reference;
  final String status;
  final String? sourceAccountId;
  final String? destinationAccountId;
  final String? sourceAccountNumber;
  final String? destinationAccountNumber;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    this.fees,
    this.description,
    this.reference,
    required this.status,
    this.sourceAccountId,
    this.destinationAccountId,
    this.sourceAccountNumber,
    this.destinationAccountNumber,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case 'DEPOSIT': return 'Depot';
      case 'WITHDRAWAL': return 'Retrait';
      case 'TRANSFER': return 'Virement';
      case 'FEE': return 'Frais';
      case 'INTEREST': return 'Interets';
      case 'SALARY': return 'Salaire';
      default: return type;
    }
  }

  bool get isCredit => type == 'DEPOSIT' || type == 'INTEREST' || type == 'SALARY';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      fees: double.tryParse(json['fees']?.toString() ?? '0'),
      description: json['description'],
      reference: json['reference'],
      status: json['status'] ?? '',
      sourceAccountId: json['sourceAccountId'],
      destinationAccountId: json['destinationAccountId'],
      sourceAccountNumber: json['sourceAccount']?['accountNumber'],
      destinationAccountNumber: json['destinationAccount']?['accountNumber'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
