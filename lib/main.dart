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
import 'screens/search_results_screen.dart';
import 'widgets/custom_search_bar.dart';
import 'models/app_user.dart';
import 'screens/role_selection_screen.dart';
import 'screens/mechanic_screens.dart';
import 'screens/shop_responses_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/schedule_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isMechanic ? 80 : 120,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isMechanic ? Colors.orangeAccent : Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.car,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMechanic ? 'CarFix Pro' : 'CarFix',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          isMechanic ? '정비사 관리 시스템' : 'AI 견적 시스템',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.settings,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _currentIndex = isMechanic ? 4 : 5),
                    ),
                  ],
                ),
                if (!isMechanic) ...[
                  const SizedBox(height: 12),
                  CustomSearchBar(
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchResultsScreen(query: value),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: isMechanic
                  ? [
                      _buildNavItem(0, '일정', LucideIcons.calendar),
                      _buildNavItem(1, '받은 요청', LucideIcons.inbox),
                      _buildNavItem(2, '리뷰 관리', LucideIcons.star),
                      _buildNavItem(3, '채팅', LucideIcons.messageCircle),
                    ]
                  : [
                      _buildNavItem(0, '홈', LucideIcons.home),
                      _buildNavItem(1, '견적 미리보기', LucideIcons.fileText),
                      _buildNavItem(2, '정비소 응답', LucideIcons.clipboardList),
                      _buildNavItem(3, '채팅', LucideIcons.messageCircle),
                      _buildNavItem(4, '근처 정비소', LucideIcons.mapPin),
                    ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.blueAccent : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blueAccent : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
