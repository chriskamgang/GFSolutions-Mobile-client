import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../widgets/loading_overlay.dart';

class PeerTransferScreen extends StatefulWidget {
  const PeerTransferScreen({super.key});

  @override
  State<PeerTransferScreen> createState() => _PeerTransferScreenState();
}

class _PeerTransferScreenState extends State<PeerTransferScreen> {
  final _accountNumberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Account? _fromAccount;
  bool _isLoading = false;
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  Future<void> _submit() async {
    if (_fromAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selectionnez un compte source')));
      return;
    }
    final destNumber = _accountNumberCtrl.text.trim();
    if (destNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez le numero de compte destinataire')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le virement'),
        content: Text('Envoyer ${_fmt.format(amount)} FCFA vers le compte $destNumber ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() { _isLoading = true; });
    try {
      await context.read<AccountProvider>().makePeerTransfer(
        fromAccountId: _fromAccount!.id,
        toAccountNumber: destNumber,
        amount: amount,
        description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Virement effectue !'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Envoi en cours...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Virement tiers')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Envoyez de l\'argent vers le compte d\'un autre membre de Global Financial Solution.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Compte source', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Account>(
                      value: _fromAccount,
                      decoration: const InputDecoration(hintText: 'Selectionner'),
                      items: accounts.map((a) => DropdownMenuItem(
                        value: a,
                        child: Text('${a.typeLabel} - ${_fmt.format(a.balance)} F'),
                      )).toList(),
                      onChanged: (v) => setState(() { _fromAccount = v; }),
                    ),
                    const SizedBox(height: 16),
                    const Text('N° Compte destinataire', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountNumberCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Ex: MF-001234',
                        prefixIcon: Icon(Icons.account_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Montant (FCFA)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0', suffixText: 'FCFA'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Motif (optionnel)',
                        hintText: 'Ex: Remboursement',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Envoyer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
