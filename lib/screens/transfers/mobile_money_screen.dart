import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_overlay.dart';

class MobileMoneyScreen extends StatefulWidget {
  const MobileMoneyScreen({super.key});

  @override
  State<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends State<MobileMoneyScreen> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  Account? _selectedAccount;
  String _operator = 'ORANGE_MONEY';
  String _direction = 'WITHDRAW'; // WITHDRAW = MF -> MoMo, DEPOSIT = MoMo -> MF
  bool _isLoading = false;
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  final _operators = [
    {'value': 'ORANGE_MONEY', 'label': 'Orange Money', 'color': const Color(0xFFFF6600)},
    {'value': 'MTN_MOMO', 'label': 'MTN MoMo', 'color': const Color(0xFFFFCC00)},
    {'value': 'WAVE', 'label': 'Wave', 'color': const Color(0xFF1DC4E9)},
  ];

  Future<void> _submit() async {
    if (_selectedAccount == null || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remplissez tous les champs')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await ApiService().post('/transactions/mobile-money', data: {
        'accountId': _selectedAccount!.id,
        'phone': _phoneCtrl.text.trim(),
        'amount': amount,
        'operator': _operator,
        'direction': _direction,
      });
      if (!mounted) return;
      await context.read<AccountProvider>().fetchAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation Mobile Money reussie !'), backgroundColor: AppColors.success),
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
      message: 'Transaction en cours...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Mobile Money')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Direction toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _direction = 'WITHDRAW'; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _direction == 'WITHDRAW' ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Retrait vers MoMo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _direction == 'WITHDRAW' ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _direction = 'DEPOSIT'; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _direction == 'DEPOSIT' ? AppColors.success : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Depot depuis MoMo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _direction == 'DEPOSIT' ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Operator selection
            const Text('Operateur', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _operators.map((op) {
                final isSelected = _operator == op['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _operator = op['value'] as String; }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? (op['color'] as Color).withValues(alpha: 0.15) : Colors.white,
                        border: Border.all(
                          color: isSelected ? op['color'] as Color : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        op['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? op['color'] as Color : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Compte GFS', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Account>(
                      value: _selectedAccount,
                      decoration: const InputDecoration(hintText: 'Selectionner'),
                      items: accounts.map((a) => DropdownMenuItem(
                        value: a,
                        child: Text('${a.typeLabel} - ${_fmt.format(a.balance)} F'),
                      )).toList(),
                      onChanged: (v) => setState(() { _selectedAccount = v; }),
                    ),
                    const SizedBox(height: 16),
                    const Text('N° Telephone Mobile Money', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '6XX XXX XXX',
                        prefixIcon: Icon(Icons.phone),
                        prefixText: '+237 ',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: Icon(_direction == 'WITHDRAW' ? Icons.arrow_upward : Icons.arrow_downward),
                label: Text(_direction == 'WITHDRAW' ? 'Retirer vers Mobile Money' : 'Deposer depuis Mobile Money'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
