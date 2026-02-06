import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/theme_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/estimate_provider.dart';
import 'services/auth_service.dart';
import 'services/service_center_service.dart';
import 'screens/home_screen.dart';
import 'screens/estimate_preview_screen.dart';
import 'screens/nearby_shops_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'models/app_user.dart';
import 'screens/role_selection_screen.dart';
import 'screens/mechanic_screens.dart';
import 'screens/shop_responses_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/schedule_screen.dart';
import 'utils/mechanic_design.dart';
import 'utils/consumer_design.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  // Initialize Firebase (assumes google-services.json / GoogleService-Info.plist are present)
  await Firebase.initializeApp();

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => EstimateProvider()..initialize()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ServiceCenterService>(create: (_) => ServiceCenterService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CarFix - AI 견적 시스템',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE2E8F0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        dividerColor: const Color(0xFF334155),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return StreamBuilder<AppUser?>(
            stream: authService.appUserStream,
            builder: (context, appUserSnapshot) {
              if (appUserSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final appUser = appUserSnapshot.data;
              if (appUser == null || appUser.role == UserRole.none) {
                return const RoleSelectionScreen();
              }

              return MainLayout(appUser: appUser);
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  final AppUser appUser;
  const MainLayout({super.key, required this.appUser});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.appUser.role == UserRole.consumer) {
        Provider.of<ShopProvider>(context, listen: false).initialize();
      }
    });
  }

  List<Widget> get _screens {
    if (widget.appUser.role == UserRole.mechanic) {
      return [
        ScheduleScreen(appUser: widget.appUser),
        ReceivedRequestsScreen(appUser: widget.appUser),
        ReviewManagementScreen(appUser: widget.appUser),
        const ChatScreen(),
        const SettingsScreen(),
      ];
    } else {
      return [
        const HomeScreen(),
        const EstimatePreviewScreen(),
        const ShopResponsesScreen(),
        const ChatScreen(),
        const NearbyShopsScreen(),
        const SettingsScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMechanic = widget.appUser.role == UserRole.mechanic;

    final consumerHeader = ConsumerHeader(
      onSettingsTap: () => setState(() => _currentIndex = 5),
    );

    PreferredSizeWidget? mechanicAppBar;
    if (isMechanic) {
      mechanicAppBar = PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: MechanicColor.primary50.withValues(alpha: 0.8),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 16,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: OverflowBox(
                        minWidth: 100,
                        maxWidth: 100,
                        minHeight: 100,
                        maxHeight: 100,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/app_logo_orange_void.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: 140,
                    height: 48,
                    alignment: Alignment.centerLeft,
                    child: OverflowBox(
                      maxWidth: 300,
                      maxHeight: 100,
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/logo_orange.png',
                        height: 66,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.settings,
                      color: MechanicColor.primary700,
                    ),
                    onPressed: () => setState(() => _currentIndex = 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isMechanic
          ? MechanicColor.background
          : ConsumerColor.background,
      appBar: isMechanic ? mechanicAppBar : consumerHeader,
      body: isMechanic
          ? WrenchBackground(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            )
          : SearchBackground(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
      bottomNavigationBar: isMechanic
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 28,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, '일정', LucideIcons.calendar),
                  _buildNavItem(1, '받은 요청', LucideIcons.inbox),
                  _buildNavItem(2, '리뷰 관리', LucideIcons.star),
                  _buildNavItem(3, '채팅', LucideIcons.messageCircle),
                ],
              ),
            )
          : ConsumerBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    bool isActive = _currentIndex == index;
    final isMechanic = widget.appUser.role == UserRole.mechanic;

    // CarFix Pro Orange Theme
    final activeColor = isMechanic
        ? MechanicColor
              .primary600 // Using Design Token
        : Colors.blueAccent;
    final activeBgColor = isMechanic
        ? MechanicColor
              .primary100 // Using Design Token
        : Colors.blue.withValues(alpha: 0.1);
    final inactiveColor = Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? activeBgColor : Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
