import 'package:flutter/material.dart';
import '../models/contribution.dart';
import '../services/api_service.dart';

class ContributionProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Contribution> _contributions = [];
  bool _isLoading = false;

  List<Contribution> get contributions => _contributions;
  bool get isLoading => _isLoading;

  Future<void> fetchContributions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/contributions/my');
      final list = response.data is List ? response.data : (response.data['data'] ?? []);
      _contributions = (list as List).map((j) => Contribution.fromJson(j)).toList();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}
