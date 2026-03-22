import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'firebase_options.dart';
import 'utils/app_colors.dart';
import 'widgets/app_logo.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/member/member_dashboard_screen.dart';
import 'screens/member/payment_screen.dart';
import 'screens/member/payment_history_screen.dart';
import 'screens/member/profile_screen.dart';
import 'screens/events/events_screen.dart';
import 'screens/member/giving_summary_screen.dart';
import 'screens/member/id_card_screen.dart';
import 'services/notification_service.dart';

// ── Theme Notifier ──
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

final themeNotifier = ThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  runApp(const ChurchConnectApp());
}

class ChurchConnectApp extends StatefulWidget {
  const ChurchConnectApp({super.key});

  @override
  State<ChurchConnectApp> createState() => _ChurchConnectAppState();
}

class _ChurchConnectAppState extends State<ChurchConnectApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChurchConnect',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.themeMode,

      // Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/member-dashboard': (_) => const MemberDashboardScreen(),
        '/payment': (_) => const PaymentScreen(),
        '/payment-history': (_) => const PaymentHistoryScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/events': (_) => const EventsScreen(),
        '/giving-summary': (_) => const GivingSummaryScreen(),
        '/id-card': (_) => const IdCardScreen(),
        '/admin': (_) => const EventsScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/member-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElasticIn(
              duration: const Duration(milliseconds: 800),
              child: const AppLogo(size: 100),
            ),
            const SizedBox(height: 60),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeIn(
                    delay: const Duration(milliseconds: 800),
                    child: const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
