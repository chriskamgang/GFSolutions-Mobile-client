import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showQrFullscreen(BuildContext context, String data) {
    final user = context.read<AuthProvider>().user;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mon QR Code GFS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 8),
              Text(user?.fullName ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.clientNumber ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 15,
                    fontWeight: FontWeight.bold, letterSpacing: 2,
                  )),
              const SizedBox(height: 8),
              const Text('Présentez ce code à l\'agent ou callbox GFS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon espace')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${user?.firstName.isNotEmpty == true ? user!.firstName[0] : ''}${user?.lastName.isNotEmpty == true ? user!.lastName[0] : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (user?.clientNumber != null)
                    Text('N° ${user!.clientNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(user?.phone ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // QR Code card
          if (user?.qrCode != null || user?.clientNumber != null)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showQrFullscreen(context, user!.qrCode ?? user.clientNumber ?? ''),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: QrImageView(
                        data: user!.qrCode ?? user.clientNumber ?? '',
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mon QR Code GFS',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text('Montrez ce code à un agent ou callbox\npour déposer ou retirer de l\'argent.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Appuyer pour agrandir',
                              style: TextStyle(fontSize: 11, color: AppColors.primary)),
                        ),
                      ],
                    )),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Menu items
          _MenuItem(icon: Icons.credit_card, label: 'Mes credits', onTap: () => context.push('/credits')),
          _MenuItem(icon: Icons.savings, label: 'Tontine & Epargne', onTap: () => context.push('/savings')),
          _MenuItem(icon: Icons.notifications, label: 'Notifications', onTap: () => context.push('/notifications')),
          _MenuItem(icon: Icons.headset_mic, label: 'Support & Contact', onTap: () => context.push('/support/contact')),
          _MenuItem(icon: Icons.security, label: 'Securite & PIN', onTap: () => context.push('/profile/security')),

          // Language selector
          Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: const Text('Langue / Language', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(context.watch<LocaleProvider>().isFrench ? 'Francais' : 'English'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () {
                final locale = context.read<LocaleProvider>();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(locale.tr('language')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          value: 'fr',
                          groupValue: locale.languageCode,
                          title: const Text('Francais'),
                          onChanged: (v) {
                            locale.setLocale('fr');
                            Navigator.pop(ctx);
                          },
                        ),
                        RadioListTile<String>(
                          value: 'en',
                          groupValue: locale.languageCode,
                          title: const Text('English'),
                          onChanged: (v) {
                            locale.setLocale('en');
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Deconnexion'),
                    content: const Text('Voulez-vous vous deconnecter ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Deconnecter'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Se deconnecter', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Global Financial Solution v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
