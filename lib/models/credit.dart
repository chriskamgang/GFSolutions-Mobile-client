class Credit {
  final String id;
  final String reference;
  final double amount;
  final double interestRate;
  final int durationMonths;
  final double monthlyPayment;
  final double remainingBalance;
  final String status; // PENDING, APPROVED, DISBURSED, REPAYING, COMPLETED, REJECTED
  final String? purpose;
  final DateTime? nextPaymentDate;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final int paidInstallments;
  final int totalInstallments;

  Credit({
    required this.id,
    required this.reference,
    required this.amount,
    required this.interestRate,
    required this.durationMonths,
    required this.monthlyPayment,
    required this.remainingBalance,
    required this.status,
    this.purpose,
    this.nextPaymentDate,
    required this.createdAt,
    this.approvedAt,
    this.disbursedAt,
    this.paidInstallments = 0,
    this.totalInstallments = 0,
  });

  String get statusLabel {
    switch (status) {
      case 'PENDING': return 'En attente';
      case 'APPROVED': return 'Approuve';
      case 'DISBURSED': return 'Decaisse';
      case 'REPAYING': return 'En cours';
      case 'COMPLETED': return 'Solde';
      case 'REJECTED': return 'Rejete';
      default: return status;
    }
  }

  double get progressPercent {
    if (totalInstallments == 0) return 0;
    return paidInstallments / totalInstallments;
  }

  factory Credit.fromJson(Map<String, dynamic> json) {
    return Credit(
      id: json['id'] ?? '',
      reference: json['reference'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      interestRate: double.tryParse(json['interestRate']?.toString() ?? '0') ?? 0,
      durationMonths: json['durationMonths'] ?? 0,
      monthlyPayment: double.tryParse(json['monthlyPayment']?.toString() ?? '0') ?? 0,
      remainingBalance: double.tryParse(json['remainingBalance']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? '',
      purpose: json['purpose'],
      nextPaymentDate: json['nextPaymentDate'] != null ? DateTime.tryParse(json['nextPaymentDate']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      approvedAt: json['approvedAt'] != null ? DateTime.tryParse(json['approvedAt']) : null,
      disbursedAt: json['disbursedAt'] != null ? DateTime.tryParse(json['disbursedAt']) : null,
      paidInstallments: json['paidInstallments'] ?? 0,
      totalInstallments: json['totalInstallments'] ?? json['durationMonths'] ?? 0,
    );
  }
}
