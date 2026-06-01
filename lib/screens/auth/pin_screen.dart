import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/theme.dart';
import '../../services/storage_service.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _localAuth = LocalAuthentication();
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final isEnabled = await StorageService.isBiometricEnabled();
      final canAuth = await _localAuth.canCheckBiometrics;
      setState(() { _biometricAvailable = isEnabled && canAuth; });
      if (_biometricAvailable) _authenticateWithBiometric();
    } catch (_) {}
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour acceder a votre compte',
      );
      if (authenticated && mounted) {
        context.go('/');
      }
    } catch (_) {}
  }

  Future<void> _verifyPin(String pin) async {
    final savedPin = await StorageService.getPin();
    if (pin == savedPin) {
      if (mounted) context.go('/');
    } else {
      setState(() { _error = 'Code PIN incorrect'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('Entrez votre code PIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ),

                MaterialPinField(
                  length: 4,
                  obscureText: true,
                  onCompleted: _verifyPin,
                  onChanged: (_) => setState(() { _error = null; }),
                  theme: MaterialPinTheme(
                    cellSize: const Size(55, 55),
                    shape: MaterialPinShape.circle,
                  ),
                  keyboardType: TextInputType.number,
                ),

                if (_biometricAvailable) ...[
                  const SizedBox(height: 24),
                  IconButton(
                    onPressed: _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint, size: 48, color: AppColors.primary),
                  ),
                  const Text('Empreinte digitale', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
