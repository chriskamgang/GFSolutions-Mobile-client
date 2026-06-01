import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

class AccountProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Account> _accounts = [];
  List<Transaction> _recentTransactions = [];
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  List<Transaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;

  double get totalBalance => _accounts.fold(0, (sum, a) => sum + a.balance);

  Future<void> fetchAccounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/client-auth/accounts');
      final list = response.data is List ? response.data : (response.data['data'] ?? []);
      _accounts = (list as List).map((j) => Account.fromJson(j)).toList();
      // Cache pour offline
      OfflineService().cacheAccounts(list as List);
    } catch (_) {
      // En cas d'erreur reseau, charger depuis le cache
      final cached = OfflineService().getCachedAccounts();
      if (cached != null && _accounts.isEmpty) {
        _accounts = cached.map((j) => Account.fromJson(Map<String, dynamic>.from(j))).toList();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRecentTransactions({int limit = 10}) async {
    try {
      final response = await _api.get('/client-auth/transactions', params: {'limit': limit});
      final list = response.data is List ? response.data : (response.data['data'] ?? []);
      _recentTransactions = (list as List).map((j) => Transaction.fromJson(j)).toList();
      // Cache pour offline
      OfflineService().cacheTransactions(list as List);
      notifyListeners();
    } catch (_) {
      // En cas d'erreur reseau, charger depuis le cache
      final cached = OfflineService().getCachedTransactions();
      if (cached != null && _recentTransactions.isEmpty) {
        _recentTransactions = cached.map((j) => Transaction.fromJson(Map<String, dynamic>.from(j))).toList();
        notifyListeners();
      }
    }
  }

  Future<List<Transaction>> fetchAccountTransactions(String accountId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get('/client-auth/transactions', params: {
        'accountId': accountId,
        'page': page,
        'limit': limit,
      });
      final list = response.data is List ? response.data : (response.data['data'] ?? []);
      return (list as List).map((j) => Transaction.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> makeInternalTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
  }) async {
    await _api.post('/transactions/transfer', data: {
      'sourceAccountId': fromAccountId,
      'destinationAccountId': toAccountId,
      'amount': amount,
      'description': description ?? 'Virement interne',
    });
    await fetchAccounts();
  }

  Future<void> makePeerTransfer({
    required String fromAccountId,
    required String toAccountNumber,
    required double amount,
    String? description,
  }) async {
    await _api.post('/transactions/transfer', data: {
      'sourceAccountId': fromAccountId,
      'destinationAccountNumber': toAccountNumber,
      'amount': amount,
      'description': description ?? 'Virement tiers',
    });
    await fetchAccounts();
  }
}
