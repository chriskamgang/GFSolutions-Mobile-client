import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/offline_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _api = ApiService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/client-auth/notifications', params: {'limit': 30});
      final data = response.data;
      final list = data['data'] is List ? data['data'] : [];
      _notifications = (list as List).map((j) => AppNotification.fromJson(j)).toList();
      _unreadCount = data['unreadCount'] ?? 0;
      // Cache pour offline
      OfflineService().cacheNotifications(Map<String, dynamic>.from(data));
    } catch (_) {
      // En cas d'erreur reseau, charger depuis le cache
      final cached = OfflineService().getCachedNotifications();
      if (cached != null && _notifications.isEmpty) {
        final list = cached['data'] is List ? cached['data'] : [];
        _notifications = (list as List).map((j) => AppNotification.fromJson(Map<String, dynamic>.from(j))).toList();
        _unreadCount = (cached['unreadCount'] as int?) ?? 0;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    try {
      final userId = await StorageService.getUserId();
      await _api.patch('/notifications/read-all', data: {'targetId': userId});
      _unreadCount = 0;
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id, title: n.title, message: n.message,
        type: n.type, isRead: true, createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (_) {}
  }
}
