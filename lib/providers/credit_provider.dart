import 'package:flutter/material.dart';
import '../models/credit.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

class CreditProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Credit> _credits = [];
  bool _isLoading = false;

  List<Credit> get credits => _credits;
  List<Credit> get activeCredits => _credits.where((c) => c.status == 'REPAYING' || c.status == 'DISBURSED').toList();
  bool get isLoading => _isLoading;

  Future<void> fetchCredits() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/client-auth/credits');
      final list = response.data is List ? response.data : (response.data['data'] ?? []);
      _credits = (list as List).map((j) => Credit.fromJson(j)).toList();
      // Cache pour offline
      OfflineService().cacheCredits(list as List);
    } catch (_) {
      // En cas d'erreur reseau, charger depuis le cache
      final cached = OfflineService().getCachedCredits();
      if (cached != null && _credits.isEmpty) {
        _credits = cached.map((j) => Credit.fromJson(Map<String, dynamic>.from(j))).toList();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Credit?> getCreditDetail(String id) async {
    try {
      final response = await _api.get('/credits/$id');
      return Credit.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> simulate({
    required double amount,
    required int durationMonths,
    required double rate,
  }) async {
    final response = await _api.post('/credits/simulate', data: {
      'amount': amount,
      'durationMonths': durationMonths,
      'interestRate': rate,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getRepayments(String creditId) async {
    final response = await _api.get('/client-auth/credits/$creditId/repayments');
    return response.data;
  }

  Future<void> payRepayment({
    required String creditId,
    required String repaymentId,
    required String accountId,
  }) async {
    await _api.post('/client-auth/credits/$creditId/repay', data: {
      'repaymentId': repaymentId,
      'accountId': accountId,
    });
    await fetchCredits();
  }

  Future<void> submitRequest({
    required double amount,
    required int durationMonths,
    required String purpose,
    String? guarantorName,
    String? guarantorPhone,
  }) async {
    await _api.post('/credits/request', data: {
      'amount': amount,
      'durationMonths': durationMonths,
      'purpose': purpose,
      'guarantorName': guarantorName,
      'guarantorPhone': guarantorPhone,
    });
    await fetchCredits();
  }
}
