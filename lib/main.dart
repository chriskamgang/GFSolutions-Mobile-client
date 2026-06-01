import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/account_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/contribution_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/locale_provider.dart';
import 'services/offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await OfflineService().init();

  // Init locale before app starts
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  // Init auth before app starts
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(MyApp(authProvider: authProvider, localeProvider: localeProvider));
}

class MyApp extends StatefulWidget {
  final AuthProvider authProvider;
  final LocaleProvider localeProvider;
  const MyApp({super.key, required this.authProvider, required this.localeProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CreditProvider()),
        ChangeNotifierProvider(create: (_) => ContributionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: widget.localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (_, localeProvider, __) => MaterialApp.router(
          title: 'Global Financial Solution',
          theme: AppTheme.lightTheme,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
        ),
      ),
    );
  }
}
