import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accountProvider = context.read<AccountProvider>();
    final notifProvider = context.read<NotificationProvider>();
    await Future.wait([
      accountProvider.fetchAccounts(),
      accountProvider.fetchRecentTransactions(),
      notifProvider.fetchNotifications(),
    ]);
  }

  static final _amountFormatter = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accounts = context.watch<AccountProvider>();
    final notifs = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (notifs.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: Text(
                            '${notifs.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  decoration: const BoxDecoration(color: AppColors.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${auth.user?.firstName ?? ''} !',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bienvenue sur votre espace',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Solde total
                  BalanceCard(
                    label: 'Solde total',
                    balance: accounts.totalBalance,
                    isHidden: _balanceHidden,
                    onToggleVisibility: () => setState(() { _balanceHidden = !_balanceHidden; }),
                    icon: Icons.account_balance,
                  ),
                  const SizedBox(height: 20),

                  // Quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickAction(icon: Icons.swap_horiz, label: 'Virement', onTap: () => context.push('/transfers/internal')),
                      _QuickAction(icon: Icons.send, label: 'Envoyer', onTap: () => context.push('/transfers/peer')),
                      _QuickAction(icon: Icons.phone_android, label: 'Mobile\nMoney', onTap: () => context.push('/transfers/mobile-money')),
                      _QuickAction(icon: Icons.credit_card, label: 'Credits', onTap: () => context.push('/credits')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Comptes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mes comptes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => context.go('/accounts'), child: const Text('Voir tout')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (accounts.isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  else
                    ...accounts.accounts.map((account) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => context.push('/accounts/${account.id}'),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            account.type == 'SAVINGS' ? Icons.savings : Icons.account_balance_wallet,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(account.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(account.accountNumber, style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          _balanceHidden ? '***' : '${_amountFormatter.format(account.balance)} F',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ),
                    )),
                  const SizedBox(height: 24),

                  // Transactions recentes
                  const Text('Transactions recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (accounts.recentTransactions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Aucune transaction', style: TextStyle(color: AppColors.textSecondary))),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: accounts.recentTransactions
                            .take(5)
                            .map((t) => TransactionTile(transaction: t))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accent, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
