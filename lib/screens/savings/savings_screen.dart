import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/contribution_provider.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  static final _fmt = NumberFormat('#,###', 'fr_FR');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    context.read<ContributionProvider>().fetchContributions();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContributionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tontine & Epargne')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchContributions(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : provider.contributions.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.savings_rounded, size: 64, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text('Aucune cotisation active', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Contactez votre agence pour adherer', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.contributions.length,
                    itemBuilder: (context, index) {
                      final contrib = provider.contributions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tontine ${contrib.typeLabel}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_fmt.format(contrib.amount)} F / jour',
                                      style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  CircularPercentIndicator(
                                    radius: 45,
                                    lineWidth: 8,
                                    percent: contrib.progressPercent,
                                    center: Text(
                                      '${(contrib.progressPercent * 100).toInt()}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    progressColor: AppColors.success,
                                    backgroundColor: AppColors.border,
                                    circularStrokeCap: CircularStrokeCap.round,
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _InfoRow('Collecte', '${_fmt.format(contrib.totalCollected)} F'),
                                        _InfoRow('Objectif', '${_fmt.format(contrib.targetAmount)} F'),
                                        _InfoRow('Debut', _dateFmt.format(contrib.startDate)),
                                        if (contrib.endDate != null) _InfoRow('Fin', _dateFmt.format(contrib.endDate!)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Calendrier des paiements
                              if (contrib.payments.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text('Historique cotisations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: contrib.payments.map((p) => Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${p.paidAt.day}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
