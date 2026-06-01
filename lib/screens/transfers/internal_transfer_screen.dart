import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../widgets/loading_overlay.dart';

class InternalTransferScreen extends StatefulWidget {
  const InternalTransferScreen({super.key});

  @override
  State<InternalTransferScreen> createState() => _InternalTransferScreenState();
}

class _InternalTransferScreenState extends State<InternalTransferScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Account? _fromAccount;
  Account? _toAccount;
  bool _isLoading = false;
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  Future<void> _submit() async {
    if (_fromAccount == null || _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selectionnez les comptes')));
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les comptes doivent etre differents')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await context.read<AccountProvider>().makeInternalTransfer(
        fromAccountId: _fromAccount!.id,
        toAccountId: _toAccount!.id,
        amount: amount,
        description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Virement effectue avec succes'), backgroundColor: AppColors.success),
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
      message: 'Virement en cours...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Virement interne')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    const Text('Compte destination', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Account>(
                      value: _toAccount,
                      decoration: const InputDecoration(hintText: 'Selectionner'),
                      items: accounts.map((a) => DropdownMenuItem(
                        value: a,
                        child: Text('${a.typeLabel} - ${a.accountNumber}'),
                      )).toList(),
                      onChanged: (v) => setState(() { _toAccount = v; }),
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
                        labelText: 'Description (optionnel)',
                        hintText: 'Ex: Epargne mensuelle',
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
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmer le virement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
