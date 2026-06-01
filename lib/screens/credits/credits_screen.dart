import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/credit_provider.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    context.read<CreditProvider>().fetchCredits();
  }

  @override
  Widget build(BuildContext context) {
    final creditProvider = context.watch<CreditProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes credits')),
      body: RefreshIndicator(
        onRefresh: () => creditProvider.fetchCredits(),
        child: creditProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.calculate_rounded,
                          label: 'Simuler un credit',
                          onTap: () => context.push('/credits/simulator'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.add_circle_outline,
                          label: 'Demander un credit',
                          onTap: () => context.push('/credits/request'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (creditProvider.credits.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.credit_card_off, size: 48, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text('Aucun credit en cours', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...creditProvider.credits.map((credit) {
                      final statusColors = {
                        'PENDING': Colors.orange,
                        'APPROVED': Colors.blue,
                        'DISBURSED': AppColors.accent,
                        'REPAYING': AppColors.primary,
                        'COMPLETED': AppColors.success,
                        'REJECTED': AppColors.error,
                      };
                      final color = statusColors[credit.status] ?? AppColors.textSecondary;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push('/credits/${credit.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(credit.reference, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(credit.statusLabel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Montant', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        Text('${_fmt.format(credit.amount)} F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Mensualite', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        Text('${_fmt.format(credit.monthlyPayment)} F', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                                if (credit.status == 'REPAYING') ...[
                                  const SizedBox(height: 12),
                                  LinearPercentIndicator(
                                    lineHeight: 8,
                                    percent: credit.progressPercent,
                                    backgroundColor: AppColors.border,
                                    progressColor: AppColors.success,
                                    barRadius: const Radius.circular(4),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${credit.paidInstallments}/${credit.totalInstallments} echeances payees',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
