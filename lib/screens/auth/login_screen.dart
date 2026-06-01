import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _otpCode = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_identifierCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      if (!auth.requires2FA) {
        context.go('/');
      }
    } catch (e) {
      setState(() { _error = 'Identifiants incorrects'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _handle2FA(String code) async {
    if (code.length < 6) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.verify2FALogin(code);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      setState(() { _error = 'Code invalide'; _otpCode = ''; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: auth.requires2FA ? _build2FAStep() : _buildLoginStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginStep() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/logo.jpeg', width: 100, height: 100, fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          const Text('Global Financial Solution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Connectez-vous a votre compte', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
            ),

          TextFormField(
            controller: _identifierCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telephone ou code adherent',
              hintText: '+237... ou CLT-000001',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe ou PIN',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Se connecter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build2FAStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.security_rounded, size: 36, color: AppColors.accent),
        ),
        const SizedBox(height: 16),
        const Text('Verification 2FA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        const Text(
          'Entrez le code de votre application\nd\'authentification',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
          ),

        MaterialPinField(
          length: 6,
          onCompleted: _handle2FA,
          onChanged: (pin) => setState(() { _otpCode = pin; }),
          theme: MaterialPinTheme(
            cellSize: const Size(45, 55),
            shape: MaterialPinShape.outlined,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        if (_isLoading) const CircularProgressIndicator(color: AppColors.accent),

        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            context.read<AuthProvider>().cancelTwoFactor();
            setState(() { _error = null; _otpCode = ''; });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour'),
        ),
      ],
    );
  }
}
