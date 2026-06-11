import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_overlay.dart';

// Infos pays pour affichage (drapeau, indicatif, devise)
const _countryInfo = <String, Map<String, String>>{
  'CMR': {'flag': '\u{1F1E8}\u{1F1F2}', 'name': 'Cameroun', 'code': '237', 'currency': 'XAF'},
  'SEN': {'flag': '\u{1F1F8}\u{1F1F3}', 'name': 'Senegal', 'code': '221', 'currency': 'XOF'},
  'CIV': {'flag': '\u{1F1E8}\u{1F1EE}', 'name': "Cote d'Ivoire", 'code': '225', 'currency': 'XOF'},
  'BFA': {'flag': '\u{1F1E7}\u{1F1EB}', 'name': 'Burkina Faso', 'code': '226', 'currency': 'XOF'},
  'MLI': {'flag': '\u{1F1F2}\u{1F1F1}', 'name': 'Mali', 'code': '223', 'currency': 'XOF'},
  'BEN': {'flag': '\u{1F1E7}\u{1F1EF}', 'name': 'Benin', 'code': '229', 'currency': 'XOF'},
  'TGO': {'flag': '\u{1F1F9}\u{1F1EC}', 'name': 'Togo', 'code': '228', 'currency': 'XOF'},
  'NER': {'flag': '\u{1F1F3}\u{1F1EA}', 'name': 'Niger', 'code': '227', 'currency': 'XOF'},
  'COD': {'flag': '\u{1F1E8}\u{1F1E9}', 'name': 'RD Congo', 'code': '243', 'currency': 'CDF'},
  'COG': {'flag': '\u{1F1E8}\u{1F1EC}', 'name': 'Congo-Brazza', 'code': '242', 'currency': 'XAF'},
  'GAB': {'flag': '\u{1F1EC}\u{1F1E6}', 'name': 'Gabon', 'code': '241', 'currency': 'XAF'},
  'GIN': {'flag': '\u{1F1EC}\u{1F1F3}', 'name': 'Guinee', 'code': '224', 'currency': 'GNF'},
  'TCD': {'flag': '\u{1F1F9}\u{1F1E9}', 'name': 'Tchad', 'code': '235', 'currency': 'XAF'},
  'RCA': {'flag': '\u{1F1E8}\u{1F1EB}', 'name': 'Centrafrique', 'code': '236', 'currency': 'XAF'},
  'KEN': {'flag': '\u{1F1F0}\u{1F1EA}', 'name': 'Kenya', 'code': '254', 'currency': 'KES'},
  'UGA': {'flag': '\u{1F1FA}\u{1F1EC}', 'name': 'Ouganda', 'code': '256', 'currency': 'UGX'},
  'TZA': {'flag': '\u{1F1F9}\u{1F1FF}', 'name': 'Tanzanie', 'code': '255', 'currency': 'TZS'},
  'GHA': {'flag': '\u{1F1EC}\u{1F1ED}', 'name': 'Ghana', 'code': '233', 'currency': 'GHS'},
  'RWA': {'flag': '\u{1F1F7}\u{1F1FC}', 'name': 'Rwanda', 'code': '250', 'currency': 'RWF'},
  'ZMB': {'flag': '\u{1F1FF}\u{1F1F2}', 'name': 'Zambie', 'code': '260', 'currency': 'ZMW'},
};

// Couleurs par operateur
Color _providerColor(String code) {
  if (code.contains('MTN')) return const Color(0xFFFFCC00);
  if (code.contains('ORANGE')) return const Color(0xFFFF6600);
  if (code.contains('WAVE')) return const Color(0xFF1DC4E9);
  if (code.contains('MOOV')) return const Color(0xFF0066CC);
  if (code.contains('MPESA')) return const Color(0xFF4CAF50);
  if (code.contains('AIRTEL')) return const Color(0xFFE53935);
  if (code.contains('FREE')) return const Color(0xFF009688);
  if (code.contains('VODAFONE')) return const Color(0xFFE60000);
  if (code.contains('TIGO') || code.contains('TMONEY')) return const Color(0xFF003399);
  return AppColors.primary;
}

// Logo par operateur
String? _providerLogo(String code) {
  if (code.contains('MTN')) return 'assets/images/mtn_momo.jpeg';
  if (code.contains('ORANGE')) return 'assets/images/orange_money.png';
  return null;
}

class MobileMoneyScreen extends StatefulWidget {
  const MobileMoneyScreen({super.key});

  @override
  State<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends State<MobileMoneyScreen> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  Account? _selectedAccount;
  String? _selectedProvider;
  String? _selectedCountry;
  String _direction = 'DEPOSIT';
  bool _isLoading = false;
  bool _loadingProviders = true;
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  // Providers charges depuis le backend, groupes par pays
  Map<String, List<Map<String, dynamic>>> _providersByCountry = {};
  List<Map<String, dynamic>> _allProviders = [];

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    try {
      final response = await ApiService().get('/pawapay/client/availability');
      final providers = (response.data?['providers'] as List?) ?? [];
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final p in providers) {
        final country = p['country'] as String? ?? 'CMR';
        grouped.putIfAbsent(country, () => []);
        grouped[country]!.add(Map<String, dynamic>.from(p));
      }
      if (mounted) {
        setState(() {
          _allProviders = providers.cast<Map<String, dynamic>>();
          _providersByCountry = grouped;
          _loadingProviders = false;
          // Selectionner le premier pays par defaut
          if (grouped.isNotEmpty) {
            _selectedCountry = grouped.keys.first;
            _selectedProvider = grouped[_selectedCountry]!.first['code'];
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _loadingProviders = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les operateurs')),
        );
      }
    }
  }

  Map<String, String> get _currentCountryInfo {
    return _countryInfo[_selectedCountry] ?? {'flag': '', 'name': _selectedCountry ?? '', 'code': '', 'currency': 'FCFA'};
  }

  List<Map<String, dynamic>> get _currentProviders {
    return _providersByCountry[_selectedCountry] ?? [];
  }

  Future<void> _submit() async {
    if (_selectedAccount == null || _phoneCtrl.text.isEmpty || _selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    // Formater le numero avec l'indicatif du pays
    final countryCode = _currentCountryInfo['code'] ?? '237';
    String phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[\s\-\.]'), '');
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (!phone.startsWith(countryCode)) phone = '$countryCode$phone';

    setState(() { _isLoading = true; });
    try {
      final endpoint = _direction == 'DEPOSIT'
          ? '/pawapay/client/deposit'
          : '/pawapay/client/payout';

      final response = await ApiService().post(endpoint, data: {
        'accountId': _selectedAccount!.id,
        'phone': phone,
        'amount': amount,
        'provider': _selectedProvider,
        'agencyId': _selectedAccount!.agencyId ?? '',
      });

      if (!mounted) return;

      final paymentId = response.data?['paymentId'] ?? response.data?['withdrawalId'];
      _showPendingDialog(paymentId, amount);
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (errorMsg.contains('message:')) {
        errorMsg = errorMsg.split('message:').last.trim();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showPendingDialog(String? paymentId, double amount) {
    final currency = _currentCountryInfo['currency'] ?? 'FCFA';
    final countryName = _currentCountryInfo['name'] ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _direction == 'DEPOSIT' ? Icons.arrow_downward : Icons.arrow_upward,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _direction == 'DEPOSIT' ? 'Depot en cours' : 'Retrait en cours',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android, size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              _direction == 'DEPOSIT'
                  ? 'Confirmez le paiement sur votre telephone pour valider le depot.'
                  : 'Le transfert vers votre Mobile Money est en cours.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              '${_fmt.format(amount)} $currency',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            if (_selectedCountry != 'CMR') ...[
              const SizedBox(height: 8),
              Text(
                'Destination : $countryName',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AccountProvider>().fetchAccounts();
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    final countries = _providersByCountry.keys.toList();

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Transaction en cours...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Mobile Money')),
        body: _loadingProviders
            ? const Center(child: CircularProgressIndicator())
            : _allProviders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.signal_wifi_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun operateur Mobile Money disponible',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contactez votre agence pour activer le service.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Direction toggle
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildDirectionTab('DEPOSIT', 'Depot depuis MoMo', Icons.arrow_downward, AppColors.success),
                              _buildDirectionTab('WITHDRAW', 'Retrait vers MoMo', Icons.arrow_upward, AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Country selection (si plus d'un pays)
                      if (countries.length > 1) ...[
                        const Text('Pays', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: countries.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final code = countries[i];
                              final info = _countryInfo[code];
                              final isSelected = _selectedCountry == code;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCountry = code;
                                    _selectedProvider = _providersByCountry[code]!.first['code'];
                                    _phoneCtrl.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(info?['flag'] ?? '', style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        info?['name'] ?? code,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Operator selection
                      const Text('Operateur', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: _currentProviders.map((p) {
                          final code = p['code'] as String;
                          final name = p['name'] as String;
                          final isSelected = _selectedProvider == code;
                          final color = _providerColor(code);
                          final logo = _providerLogo(code);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() { _selectedProvider = code; }),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? color : AppColors.border,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    if (logo != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(logo, width: 44, height: 44, fit: BoxFit.contain),
                                      )
                                    else
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            name.substring(0, 1),
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? color : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 4),
                                      Icon(Icons.check_circle, color: color, size: 18),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Form card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Compte GFS', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Account>(
                                value: _selectedAccount,
                                decoration: const InputDecoration(hintText: 'Selectionner'),
                                items: accounts.map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text('${a.typeLabel} - ${_fmt.format(a.balance)} F'),
                                )).toList(),
                                onChanged: (v) => setState(() { _selectedAccount = v; }),
                              ),
                              const SizedBox(height: 16),
                              const Text('N\u00B0 Telephone Mobile Money', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Ex: 6XX XXX XXX',
                                  prefixIcon: const Icon(Icons.phone),
                                  prefixText: '+${_currentCountryInfo['code']} ',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Montant (${_currentCountryInfo['currency']})',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  suffixText: _currentCountryInfo['currency'],
                                ),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: Icon(_direction == 'WITHDRAW' ? Icons.arrow_upward : Icons.arrow_downward),
                          label: Text(
                            _direction == 'WITHDRAW'
                                ? 'Envoyer vers Mobile Money'
                                : 'Deposer depuis Mobile Money',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDirectionTab(String dir, String label, IconData icon, Color color) {
    final isSelected = _direction == dir;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _direction = dir; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }
}
