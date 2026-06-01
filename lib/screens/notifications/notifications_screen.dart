import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationProvider>().fetchNotifications();
  }

  static final _dateFmt = DateFormat('dd/MM HH:mm', 'fr_FR');

  IconData _getIcon(String? type) {
    switch (type) {
      case 'TRANSACTION': return Icons.swap_horiz;
      case 'CREDIT': return Icons.credit_card;
      case 'SECURITY': return Icons.security;
      case 'SYSTEM': return Icons.settings;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notifProvider.markAllRead(),
              child: const Text('Tout lire', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifProvider.fetchNotifications(),
        child: notifProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : notifProvider.notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text('Aucune notification', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: notifProvider.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = notifProvider.notifications[index];
                      return Container(
                        color: notif.isRead ? Colors.white : AppColors.accent.withValues(alpha: 0.05),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getIcon(notif.type), color: AppColors.primary, size: 22),
                          ),
                          title: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif.message, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_dateFmt.format(notif.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: notif.isRead ? null : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
