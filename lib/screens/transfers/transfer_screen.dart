import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TransferOption(
            icon: Icons.swap_horiz_rounded,
            title: 'Virement interne',
            subtitle: 'Entre vos propres comptes',
            color: AppColors.primary,
            onTap: () => context.push('/transfers/internal'),
          ),
          _TransferOption(
            icon: Icons.send_rounded,
            title: 'Virement tiers',
            subtitle: 'Vers un autre membre',
            color: AppColors.accent,
            onTap: () => context.push('/transfers/peer'),
          ),
          _TransferOption(
            icon: Icons.phone_android_rounded,
            title: 'Mobile Money',
            subtitle: 'Orange Money, MTN MoMo, Wave',
            color: AppColors.success,
            onTap: () => context.push('/transfers/mobile-money'),
          ),
        ],
      ),
    );
  }
}

class _TransferOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TransferOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
