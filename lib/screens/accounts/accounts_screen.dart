import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/account_provider.dart';
import '../../widgets/balance_card.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _balanceHidden = false;
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    context.read<AccountProvider>().fetchAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes comptes'),
        actions: [
          IconButton(
            icon: Icon(_balanceHidden ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() { _balanceHidden = !_balanceHidden; }),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => accounts.fetchAccounts(),
        child: accounts.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  BalanceCard(
                    label: 'Solde total',
                    balance: accounts.totalBalance,
                    isHidden: _balanceHidden,
                    onToggleVisibility: () => setState(() { _balanceHidden = !_balanceHidden; }),
                  ),
                  const SizedBox(height: 24),
                  ...accounts.accounts.map((account) {
                    final colors = {
                      'CURRENT': AppColors.primary,
                      'SAVINGS': AppColors.success,
                      'TERM_DEPOSIT': AppColors.accent,
                    };
                    final color = colors[account.type] ?? AppColors.primary;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/accounts/${account.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  account.type == 'SAVINGS'
                                      ? Icons.savings_rounded
                                      : account.type == 'TERM_DEPOSIT'
                                          ? Icons.lock_clock_rounded
                                          : Icons.account_balance_wallet_rounded,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(account.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(account.accountNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _balanceHidden ? '*** ***' : '${_fmt.format(account.balance)} F',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: account.status == 'ACTIVE' ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      account.status == 'ACTIVE' ? 'Actif' : 'Inactif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: account.status == 'ACTIVE' ? AppColors.success : AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
