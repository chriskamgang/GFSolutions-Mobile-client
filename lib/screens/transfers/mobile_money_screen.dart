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
  String _operator = 'ORANGE_CMR';
  String _direction = 'WITHDRAW'; // WITHDRAW = MF -> MoMo, DEPOSIT = MoMo -> MF
  bool _isLoading = false;
  // ignore: unused_field
  String? _pendingPaymentId;
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  final _operators = [
    {'value': 'ORANGE_CMR', 'label': 'Orange Money', 'color': const Color(0xFFFF6600)},
    {'value': 'MTN_MOMO_CMR', 'label': 'MTN MoMo', 'color': const Color(0xFFFFCC00)},
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

    // Formater le numero : ajouter 237 si besoin
    String phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[\s\-\.]'), '');
    if (phone.startsWith('6') || phone.startsWith('2')) {
      if (!phone.startsWith('237')) phone = '237$phone';
    }
    if (phone.startsWith('+')) phone = phone.substring(1);

    setState(() { _isLoading = true; });
    try {
      final endpoint = _direction == 'DEPOSIT'
          ? '/pawapay/client/deposit'
          : '/pawapay/client/payout';

      final response = await ApiService().post(endpoint, data: {
        'accountId': _selectedAccount!.id,
        'phone': phone,
        'amount': amount,
        'provider': _operator,
        'agencyId': _selectedAccount!.agencyId ?? '',
      });

      if (!mounted) return;

      final paymentId = response.data?['paymentId'] ?? response.data?['withdrawalId'];
      setState(() { _pendingPaymentId = paymentId; });

      // Afficher le dialogue d'attente de confirmation
      _showPendingDialog(paymentId);
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (errorMsg.contains('message:')) {
        errorMsg = errorMsg.split('message:').last.trim();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showPendingDialog(String? paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _direction == 'DEPOSIT' ? Icons.arrow_downward : Icons.arrow_upward,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(_direction == 'DEPOSIT' ? 'Depot en cours' : 'Retrait en cours'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android, size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              _direction == 'DEPOSIT'
                  ? 'Confirmez le paiement sur votre telephone pour valider le depot.'
                  : 'Le transfert vers votre Mobile Money est en cours.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '${_fmt.format(double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0)} FCFA',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AccountProvider>().fetchAccounts();
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
