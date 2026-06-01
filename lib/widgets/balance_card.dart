import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class BalanceCard extends StatelessWidget {
  final String label;
  final double balance;
  final bool isHidden;
  final VoidCallback? onToggleVisibility;
  final IconData icon;
  final Color? color;

  const BalanceCard({
    super.key,
    required this.label,
    required this.balance,
    this.isHidden = false,
    this.onToggleVisibility,
    this.icon = Icons.account_balance_wallet,
    this.color,
  });

  static final _formatter = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color ?? AppColors.primary,
            (color ?? AppColors.primary).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              if (onToggleVisibility != null)
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isHidden ? '*** *** FCFA' : '${_formatter.format(balance)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
