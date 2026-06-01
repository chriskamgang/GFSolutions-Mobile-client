import 'package:flutter/material.dart';
import 'dart:async';
import '../services/offline_service.dart';
import '../config/theme.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOnline = true;
  late StreamSubscription _sub;
  final _offline = OfflineService();

  @override
  void initState() {
    super.initState();
    _isOnline = _offline.isOnline;
    _sub = _offline.onConnectivityChanged.listen((online) {
      setState(() => _isOnline = online);
      if (online && _offline.pendingOperationsCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronisation de ${_offline.pendingOperationsCount} operation(s)...'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: AppColors.error,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mode hors-ligne - Donnees en cache',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (_offline.pendingOperationsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_offline.pendingOperationsCount} en attente',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
