import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential = await authService.signInWithGoogle();

      if (userCredential == null && mounted) {
        // Login failed or cancelled
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 취소되었거나 실패했습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Section
              // Logo Section
              Material(
                elevation: 10,
                shadowColor: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 123,
                  height: 123,
                  child: Image.asset(
                    'assets/images/app_logo_blue_void_right.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Image.asset(
                    'assets/images/logo_blue_right.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI 기반 차량 견적 시스템',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Login Button Section
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Simple existing icon or text as placeholder for Google Logo
                            // In real app, we would use an asset image for Google Logo
                            const Icon(
                              LucideIcons.chrome,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Google로 계속하기',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class TopLeftTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomRightTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
