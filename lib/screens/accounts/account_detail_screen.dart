import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/account_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/transaction_tile.dart';

class AccountDetailScreen extends StatefulWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  bool _balanceHidden = false;
  List<Transaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() { _loading = true; });
    final txns = await context.read<AccountProvider>().fetchAccountTransactions(widget.accountId);
    setState(() { _transactions = txns; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>();
    final account = accounts.accounts.where((a) => a.id == widget.accountId).firstOrNull;

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail du compte')),
        body: const Center(child: Text('Compte non trouve')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(account.typeLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Releve PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF en cours...')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BalanceCard(
              label: account.typeLabel,
              balance: account.balance,
              isHidden: _balanceHidden,
              onToggleVisibility: () => setState(() { _balanceHidden = !_balanceHidden; }),
              color: account.type == 'SAVINGS' ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(label: 'N° Compte', value: account.accountNumber),
                    _InfoChip(label: 'Statut', value: account.status == 'ACTIVE' ? 'Actif' : 'Inactif'),
                    _InfoChip(label: 'Ouvert le', value: DateFormat('dd/MM/yyyy').format(account.createdAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Historique des transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.accent),
              ))
            else if (_transactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucune transaction', style: TextStyle(color: AppColors.textSecondary))),
                ),
              )
            else
              Card(
                child: Column(
                  children: _transactions.map((t) => TransactionTile(transaction: t)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
