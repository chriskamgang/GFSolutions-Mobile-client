import 'package:flutter/material.dart';

class Repayment {
  final String id;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;
  final double penalty;
  final double moratoireAmount;
  final String status; // PENDING, PAID, PARTIAL, OVERDUE, WRITTEN_OFF
  final DateTime? paidAt;
  final double remainingToPay;

  Repayment({
    required this.id,
    required this.dueDate,
    required this.amount,
    required this.paidAmount,
    required this.penalty,
    required this.moratoireAmount,
    required this.status,
    this.paidAt,
    required this.remainingToPay,
  });

  String get statusLabel {
    switch (status) {
      case 'PAID': return 'Payee';
      case 'PENDING': return 'A payer';
      case 'PARTIAL': return 'Partielle';
      case 'OVERDUE': return 'En retard';
      case 'WRITTEN_OFF': return 'Radiee';
      default: return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PAID': return const Color(0xFF27AE60);
      case 'PENDING': return const Color(0xFFF5A623);
      case 'PARTIAL': return const Color(0xFF3498DB);
      case 'OVERDUE': return const Color(0xFFE74C3C);
      default: return const Color(0xFF7F8C8D);
    }
  }

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'] ?? '',
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paidAmount: double.tryParse(json['paidAmount']?.toString() ?? '0') ?? 0,
      penalty: double.tryParse(json['penalty']?.toString() ?? '0') ?? 0,
      moratoireAmount: double.tryParse(json['moratoireAmount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? '',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      remainingToPay: double.tryParse(json['remainingToPay']?.toString() ?? '0') ?? 0,
    );
  }
}
