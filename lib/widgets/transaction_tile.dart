import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  static final _amountFormatter = NumberFormat('#,###', 'fr_FR');
  static final _dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  IconData get _icon {
    switch (transaction.type) {
      case 'DEPOSIT': return Icons.arrow_downward_rounded;
      case 'WITHDRAWAL': return Icons.arrow_upward_rounded;
      case 'TRANSFER': return Icons.swap_horiz_rounded;
      case 'FEE': return Icons.receipt_long_rounded;
      case 'INTEREST': return Icons.trending_up_rounded;
      case 'SALARY': return Icons.work_rounded;
      default: return Icons.circle;
    }
  }

  Color get _iconColor {
    if (transaction.isCredit) return AppColors.success;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final sign = transaction.isCredit ? '+' : '-';
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_icon, color: _iconColor, size: 22),
      ),
      title: Text(
        transaction.description ?? transaction.typeLabel,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _dateFormatter.format(transaction.createdAt),
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        '$sign${_amountFormatter.format(transaction.amount)} F',
        style: TextStyle(
          color: _iconColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
