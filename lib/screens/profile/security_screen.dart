import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _has2FA = false;
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  bool _changingPwd = false;
  bool _settingPin = false;
  String? _savedPin;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final localAuth = LocalAuthentication();
    final canBio = await localAuth.canCheckBiometrics;
    final bioEnabled = await StorageService.isBiometricEnabled();
    final pin = await StorageService.getPin();
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;

    setState(() {
      _biometricAvailable = canBio;
      _biometricEnabled = bioEnabled;
      _savedPin = pin;
      _has2FA = user?.twoFactorEnabled ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final localAuth = LocalAuthentication();
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Activez la biometrie',
      );
      if (!authenticated) return;
    }
    await StorageService.setBiometricEnabled(value);
    setState(() { _biometricEnabled = value; });
  }

  Future<void> _changePassword() async {
    if (_currentPwdCtrl.text.isEmpty || _newPwdCtrl.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remplissez tous les champs')));
      return;
    }
    setState(() { _changingPwd = true; });
    try {
      await AuthService().changePassword(
        currentPassword: _currentPwdCtrl.text,
        newPassword: _newPwdCtrl.text,
      );
      if (!mounted) return;
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe modifie !'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur changement mot de passe'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() { _changingPwd = false; });
    }
  }

  Future<void> _savePin(String pin) async {
    await StorageService.savePin(pin);
    setState(() { _savedPin = pin; _settingPin = false; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code PIN enregistre !'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Securite')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PIN section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Code PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_savedPin != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Active', style: TextStyle(color: AppColors.success, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Code a 4 chiffres pour un acces rapide', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (_settingPin)
                    MaterialPinField(
                      length: 4,
                      obscureText: true,
                      onCompleted: _savePin,
                      onChanged: (_) {},
                      theme: MaterialPinTheme(
                        cellSize: const Size(50, 50),
                        shape: MaterialPinShape.outlined,
                      ),
                      keyboardType: TextInputType.number,
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() { _settingPin = true; }),
                        child: Text(_savedPin != null ? 'Modifier le PIN' : 'Configurer un PIN'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Biometric
          if (_biometricAvailable)
            Card(
              child: SwitchListTile(
                title: const Text('Empreinte digitale / Face ID', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Acces rapide par biometrie', style: TextStyle(fontSize: 12)),
                value: _biometricEnabled,
                activeTrackColor: AppColors.accent,
                secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                onChanged: _toggleBiometric,
              ),
            ),
          const SizedBox(height: 12),

          // 2FA
          Card(
            child: ListTile(
              leading: const Icon(Icons.security, color: AppColors.primary),
              title: const Text('Authentification 2FA', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_has2FA ? 'Active - Google Authenticator' : 'Non active', style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_has2FA ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _has2FA ? 'ON' : 'OFF',
                  style: TextStyle(color: _has2FA ? AppColors.success : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Change password
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentPwdCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe actuel', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPwdCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nouveau mot de passe', prefixIcon: Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changingPwd ? null : _changePassword,
                      child: _changingPwd
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Modifier'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
