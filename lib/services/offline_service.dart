import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'api_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static const String _accountsBox = 'accounts_cache';
  static const String _transactionsBox = 'transactions_cache';
  static const String _creditsBox = 'credits_cache';
  static const String _notificationsBox = 'notifications_cache';
  static const String _pendingOpsBox = 'pending_operations';
  static const String _metaBox = 'cache_meta';

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription? _connectivitySub;
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_accountsBox),
      Hive.openBox(_transactionsBox),
      Hive.openBox(_creditsBox),
      Hive.openBox(_notificationsBox),
      Hive.openBox(_pendingOpsBox),
      Hive.openBox(_metaBox),
    ]);

    // Ecouter la connectivite
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _connectivityController.add(online);
        if (online) {
          syncPendingOperations();
        }
      }
    });

    // Check initial
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.any((r) => r != ConnectivityResult.none);
  }

  // --- Cache comptes ---
  Future<void> cacheAccounts(List<dynamic> accounts) async {
    final box = Hive.box(_accountsBox);
    await box.clear();
    await box.put('data', accounts);
    await _setLastSync(_accountsBox);
  }

  List<dynamic>? getCachedAccounts() {
    final box = Hive.box(_accountsBox);
    return box.get('data') as List<dynamic>?;
  }

  // --- Cache transactions ---
  Future<void> cacheTransactions(List<dynamic> transactions, {String? accountId}) async {
    final box = Hive.box(_transactionsBox);
    final key = accountId ?? 'recent';
    await box.put(key, transactions);
    await _setLastSync('$_transactionsBox:$key');
  }

  List<dynamic>? getCachedTransactions({String? accountId}) {
    final box = Hive.box(_transactionsBox);
    return box.get(accountId ?? 'recent') as List<dynamic>?;
  }

  // --- Cache credits ---
  Future<void> cacheCredits(List<dynamic> credits) async {
    final box = Hive.box(_creditsBox);
    await box.clear();
    await box.put('data', credits);
    await _setLastSync(_creditsBox);
  }

  List<dynamic>? getCachedCredits() {
    final box = Hive.box(_creditsBox);
    return box.get('data') as List<dynamic>?;
  }

  // --- Cache notifications ---
  Future<void> cacheNotifications(Map<String, dynamic> data) async {
    final box = Hive.box(_notificationsBox);
    await box.put('data', data);
    await _setLastSync(_notificationsBox);
  }

  Map<dynamic, dynamic>? getCachedNotifications() {
    final box = Hive.box(_notificationsBox);
    return box.get('data') as Map<dynamic, dynamic>?;
  }

  // --- Queue d'operations offline ---
  Future<void> addPendingOperation(Map<String, dynamic> operation) async {
    final box = Hive.box(_pendingOpsBox);
    final ops = (box.get('queue') as List?)?.cast<Map>() ?? [];
    operation['timestamp'] = DateTime.now().toIso8601String();
    operation['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    ops.add(operation);
    await box.put('queue', ops);
  }

  List<Map<dynamic, dynamic>> getPendingOperations() {
    final box = Hive.box(_pendingOpsBox);
    return (box.get('queue') as List?)?.cast<Map<dynamic, dynamic>>() ?? [];
  }

  int get pendingOperationsCount => getPendingOperations().length;

  Future<void> syncPendingOperations() async {
    if (!_isOnline) return;
    final box = Hive.box(_pendingOpsBox);
    final ops = getPendingOperations();
    if (ops.isEmpty) return;

    final api = ApiService();
    final failed = <Map<dynamic, dynamic>>[];

    for (final op in ops) {
      try {
        final method = op['method'] as String;
        final path = op['path'] as String;
        final data = op['data'] as Map?;

        switch (method) {
          case 'POST':
            await api.post(path, data: data);
            break;
          case 'PATCH':
            await api.patch(path, data: data);
            break;
          case 'PUT':
            await api.put(path, data: data);
            break;
        }
      } catch (_) {
        failed.add(op);
      }
    }

    await box.put('queue', failed);
  }

  // --- Meta ---
  Future<void> _setLastSync(String key) async {
    final box = Hive.box(_metaBox);
    await box.put('lastSync:$key', DateTime.now().toIso8601String());
  }

  DateTime? getLastSync(String key) {
    final box = Hive.box(_metaBox);
    final val = box.get('lastSync:$key') as String?;
    return val != null ? DateTime.tryParse(val) : null;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivityController.close();
  }
}
