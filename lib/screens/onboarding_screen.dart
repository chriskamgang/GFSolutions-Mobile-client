import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _storage = const FlutterSecureStorage();

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.account_balance_rounded,
      title: 'Bienvenue sur GFS',
      subtitle:
          'Global Financial Solution — votre banque numerique de confiance au Cameroun, accessible partout et a tout moment.',
      gradientStart: Color(0xFF1B2A4A),
      gradientEnd: Color(0xFF2A4070),
    ),
    _OnboardingData(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Vos Comptes en Temps Reel',
      subtitle:
          'Consultez vos soldes, telechargeez vos releves et effectuez des depots ou retraits en quelques secondes.',
      gradientStart: Color(0xFF1B3060),
      gradientEnd: Color(0xFF1B2A4A),
    ),
    _OnboardingData(
      icon: Icons.swap_horiz_rounded,
      title: 'Transferts Instantanes',
      subtitle:
          'Envoyez de l\'argent via Orange Money, MTN MoMo ou par virement interne entre comptes GFS.',
      gradientStart: Color(0xFF243A6A),
      gradientEnd: Color(0xFF1A3050),
    ),
    _OnboardingData(
      icon: Icons.trending_up_rounded,
      title: 'Credits & Epargne',
      subtitle:
          'Simulez et demandez un credit en ligne. Epargnez facilement avec nos produits tontine et objectifs d\'epargne.',
      gradientStart: Color(0xFF1B2A4A),
      gradientEnd: Color(0xFF2E3E5C),
    ),
  ];

  Future<void> _finish() async {
    await _storage.write(key: 'onboarding_seen', value: 'true');
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),

          // Bouton "Passer"
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Passer',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Barre de progression + boutons en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: 28,
                bottom: MediaQuery.of(context).padding.bottom + 36,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicateurs de points
                  Row(
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? AppColors.accent
                              : Colors.white30,
                        ),
                      );
                    }),
                  ),

                  // Bouton Suivant / Commencer
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage < _pages.length - 1
                              ? 'Suivant'
                              : 'Commencer',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage < _pages.length - 1
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                      ],
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

// ---------- Donnees d'une slide ----------

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

// ---------- Ecran d'une slide ----------

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.gradientStart, data.gradientEnd],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Cercle avec icone
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo orange
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withAlpha(30),
                      ),
                    ),
                    Icon(
                      data.icon,
                      size: 72,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 52),

              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.65,
                ),
              ),

              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
