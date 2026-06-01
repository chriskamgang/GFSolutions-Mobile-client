import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/credit.dart';
import '../../models/repayment.dart';
import '../../models/account.dart';
import '../../providers/credit_provider.dart';
import '../../providers/account_provider.dart';

class RepaymentScreen extends StatefulWidget {
  final String creditId;
  const RepaymentScreen({super.key, required this.creditId});

  @override
  State<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends State<RepaymentScreen> {
  Credit? _credit;
  List<Repayment> _repayments = [];
  bool _loading = true;
  bool _paying = false;
  static final _fmt = NumberFormat('#,###', 'fr_FR');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final creditProvider = context.read<CreditProvider>();
      final credit = await creditProvider.getCreditDetail(widget.creditId);
      final data = await creditProvider.getRepayments(widget.creditId);
      final list = data is Map && data.containsKey('data') ? data['data'] : (data is List ? data : []);
      final repayments = (list as List).map((j) => Repayment.fromJson(j)).toList();
      setState(() {
        _credit = credit;
        _repayments = repayments;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showPayBottomSheet(Repayment repayment) {
    final accounts = context.read<AccountProvider>().accounts;
    Account? selectedAccount = accounts.isNotEmpty ? accounts.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payer une echeance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),

                  // Montant
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Montant a payer', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '${_fmt.format(repayment.remainingToPay)} F',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (repayment.penalty > 0) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Dont penalites : ${_fmt.format(repayment.penalty)} F',
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],

                  if (repayment.moratoireAmount > 0) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Dont moratoire : ${_fmt.format(repayment.moratoireAmount)} F',
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Compte a debiter
                  const Text('Compte a debiter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Account>(
                    value: selectedAccount,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                    ),
                    items: accounts.map((a) => DropdownMenuItem(
                      value: a,
                      child: Text('${a.typeLabel} - ${_fmt.format(a.balance)} F', style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (val) => setSheetState(() => selectedAccount = val),
                  ),

                  const SizedBox(height: 24),

                  // Bouton confirmer
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _paying || selectedAccount == null
                          ? null
                          : () => _confirmPayment(repayment, selectedAccount!, ctx),
                      child: _paying
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Confirmer le paiement'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmPayment(Repayment repayment, Account account, BuildContext sheetContext) async {
    setState(() => _paying = true);
    try {
      await context.read<CreditProvider>().payRepayment(
        creditId: widget.creditId,
        repaymentId: repayment.id,
        accountId: account.id,
      );
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement effectue avec succes'),
            backgroundColor: AppColors.success,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes echeances')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _credit == null
              ? const Center(child: Text('Credit non trouve'))
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Resume credit
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Resume du credit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _credit!.reference,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              _SummaryRow('Montant emprunte', '${_fmt.format(_credit!.amount)} F'),
                              _SummaryRow('Reste a payer', '${_fmt.format(_credit!.remainingBalance)} F', valueColor: AppColors.error),
                              _SummaryRow('Echeances payees', '${_credit!.paidInstallments} / ${_credit!.totalInstallments}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Titre liste
                      Text(
                        'Echeancier (${_repayments.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),

                      // Liste echeances
                      if (_repayments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text('Aucune echeance trouvee', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ..._repayments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final r = entry.value;
                          return _RepaymentTile(
                            index: index + 1,
                            repayment: r,
                            fmt: _fmt,
                            dateFmt: _dateFmt,
                            onPay: (r.status == 'PENDING' || r.status == 'OVERDUE' || r.status == 'PARTIAL')
                                ? () => _showPayBottomSheet(r)
                                : null,
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _RepaymentTile extends StatelessWidget {
  final int index;
  final Repayment repayment;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final VoidCallback? onPay;

  const _RepaymentTile({
    required this.index,
    required this.repayment,
    required this.fmt,
    required this.dateFmt,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: numero + date + badge statut
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dateFmt.format(repayment.dueDate),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: repayment.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    repayment.statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: repayment.statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Montant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text('${fmt.format(repayment.amount)} F', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),

            // Penalites
            if (repayment.penalty > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Penalites', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  Text('${fmt.format(repayment.penalty)} F', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error)),
                ],
              ),
            ],

            // Moratoire
            if (repayment.moratoireAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Moratoire', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  Text('${fmt.format(repayment.moratoireAmount)} F', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error)),
                ],
              ),
            ],

            // Reste a payer (si partiel)
            if (repayment.status == 'PARTIAL') ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reste a payer', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                  Text('${fmt.format(repayment.remainingToPay)} F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent)),
                ],
              ),
            ],

            // Bouton payer
            if (onPay != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.payment, size: 18),
                  label: Text('Payer ${fmt.format(repayment.remainingToPay)} F'),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            // Date de paiement
            if (repayment.paidAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Paye le ${dateFmt.format(repayment.paidAt!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.success),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
