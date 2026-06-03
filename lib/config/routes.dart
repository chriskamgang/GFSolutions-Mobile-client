import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/accounts/accounts_screen.dart';
import '../screens/accounts/account_detail_screen.dart';
import '../screens/transfers/transfer_screen.dart';
import '../screens/transfers/internal_transfer_screen.dart';
import '../screens/transfers/peer_transfer_screen.dart';
import '../screens/transfers/mobile_money_screen.dart';
import '../screens/credits/credits_screen.dart';
import '../screens/credits/credit_detail_screen.dart';
import '../screens/credits/credit_simulator_screen.dart';
import '../screens/credits/credit_request_screen.dart';
import '../screens/credits/repayment_screen.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/support/messages_screen.dart';
import '../screens/support/contact_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/security_screen.dart';
import '../widgets/main_shell.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final loc = state.matchedLocation;
      const publicRoutes = ['/splash', '/onboarding', '/login', '/pin'];

      if (!isAuthenticated && !publicRoutes.contains(loc)) return '/login';
      if (isAuthenticated && (loc == '/login' || loc == '/pin')) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/pin', builder: (_, __) => const PinScreen()),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/accounts', builder: (_, __) => const AccountsScreen()),
          GoRoute(
            path: '/accounts/:id',
            builder: (_, state) => AccountDetailScreen(accountId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/transfers', builder: (_, __) => const TransferScreen()),
          GoRoute(path: '/transfers/internal', builder: (_, __) => const InternalTransferScreen()),
          GoRoute(path: '/transfers/peer', builder: (_, __) => const PeerTransferScreen()),
          GoRoute(path: '/transfers/mobile-money', builder: (_, __) => const MobileMoneyScreen()),
          GoRoute(path: '/credits', builder: (_, __) => const CreditsScreen()),
          GoRoute(
            path: '/credits/:id',
            builder: (_, state) => CreditDetailScreen(creditId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/credits/:id/repayments',
            builder: (_, state) => RepaymentScreen(creditId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/credits/simulator', builder: (_, __) => const CreditSimulatorScreen()),
          GoRoute(path: '/credits/request', builder: (_, __) => const CreditRequestScreen()),
          GoRoute(path: '/savings', builder: (_, __) => const SavingsScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/support/messages', builder: (_, __) => const MessagesScreen()),
          GoRoute(path: '/support/contact', builder: (_, __) => const ContactScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/profile/security', builder: (_, __) => const SecurityScreen()),
        ],
      ),
    ],
  );
}
