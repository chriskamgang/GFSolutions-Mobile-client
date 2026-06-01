import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/credit.dart';
import '../../providers/credit_provider.dart';

class CreditDetailScreen extends StatefulWidget {
  final String creditId;
  const CreditDetailScreen({super.key, required this.creditId});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  Credit? _credit;
  bool _loading = true;
  static final _fmt = NumberFormat('#,###', 'fr_FR');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final credit = await context.read<CreditProvider>().getCreditDetail(widget.creditId);
    setState(() { _credit = credit; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail du credit')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _credit == null
              ? const Center(child: Text('Credit non trouve'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Progress circle
                    Center(
                      child: CircularPercentIndicator(
                        radius: 80,
                        lineWidth: 12,
                        percent: _credit!.progressPercent,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${(_credit!.progressPercent * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('rembourse', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        progressColor: AppColors.success,
                        backgroundColor: AppColors.border,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Key info cards
                    Row(
                      children: [
                        Expanded(child: _InfoCard(label: 'Capital emprunte', value: '${_fmt.format(_credit!.amount)} F')),
                        const SizedBox(width: 8),
                        Expanded(child: _InfoCard(label: 'Reste a payer', value: '${_fmt.format(_credit!.remainingBalance)} F', valueColor: AppColors.error)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _InfoCard(label: 'Mensualite', value: '${_fmt.format(_credit!.monthlyPayment)} F')),
                        const SizedBox(width: 8),
                        Expanded(child: _InfoCard(label: 'Taux', value: '${_credit!.interestRate}% / an')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _InfoCard(label: 'Duree', value: '${_credit!.durationMonths} mois')),
                        const SizedBox(width: 8),
                        Expanded(child: _InfoCard(
                          label: 'Prochaine echeance',
                          value: _credit!.nextPaymentDate != null ? _dateFmt.format(_credit!.nextPaymentDate!) : '-',
                          valueColor: AppColors.accent,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Informations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            _DetailRow('Reference', _credit!.reference),
                            _DetailRow('Statut', _credit!.statusLabel),
                            _DetailRow('Objet', _credit!.purpose ?? '-'),
                            _DetailRow('Echeances payees', '${_credit!.paidInstallments} / ${_credit!.totalInstallments}'),
                            if (_credit!.approvedAt != null) _DetailRow('Approuve le', _dateFmt.format(_credit!.approvedAt!)),
                            if (_credit!.disbursedAt != null) _DetailRow('Decaisse le', _dateFmt.format(_credit!.disbursedAt!)),
                            _DetailRow('Demande le', _dateFmt.format(_credit!.createdAt)),
                          ],
                        ),
                      ),
                    ),
                    if (_credit!.status == 'DISBURSED' || _credit!.status == 'REPAYING' || _credit!.status == 'ACTIVE')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/credits/${_credit!.id}/repayments'),
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Voir mes echeances'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
