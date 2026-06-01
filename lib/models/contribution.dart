class Contribution {
  final String id;
  final String type; // DAILY, WEEKLY, MONTHLY
  final double amount;
  final double totalCollected;
  final double targetAmount;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final List<ContributionPayment> payments;

  Contribution({
    required this.id,
    required this.type,
    required this.amount,
    required this.totalCollected,
    required this.targetAmount,
    required this.status,
    required this.startDate,
    this.endDate,
    this.payments = const [],
  });

  double get progressPercent {
    if (targetAmount == 0) return 0;
    return (totalCollected / targetAmount).clamp(0, 1);
  }

  String get typeLabel {
    switch (type) {
      case 'DAILY': return 'Quotidienne';
      case 'WEEKLY': return 'Hebdomadaire';
      case 'MONTHLY': return 'Mensuelle';
      default: return type;
    }
  }

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] ?? '',
      type: json['type'] ?? 'DAILY',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      totalCollected: double.tryParse(json['totalCollected']?.toString() ?? '0') ?? 0,
      targetAmount: double.tryParse(json['targetAmount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      payments: (json['payments'] as List?)
          ?.map((p) => ContributionPayment.fromJson(p))
          .toList() ?? [],
    );
  }
}

class ContributionPayment {
  final String id;
  final double amount;
  final DateTime paidAt;

  ContributionPayment({required this.id, required this.amount, required this.paidAt});

  factory ContributionPayment.fromJson(Map<String, dynamic> json) {
    return ContributionPayment(
      id: json['id'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paidAt: DateTime.tryParse(json['paidAt'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
