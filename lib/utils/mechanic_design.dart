import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';

class MechanicColor {
  static const Color primary50 = Color(0xFFFFF7ED);
  static const Color primary100 = Color(0xFFFFEDD5);
  static const Color primary200 = Color(0xFFFED7AA);
  static const Color primary300 = Color(0xFFFDBA74);
  static const Color primary400 = Color(0xFFFB923C);
  static const Color primary500 = Color(0xFFF97316);
  static const Color primary600 = Color(0xFFEA580C);
  static const Color primary700 = Color(0xFFC2410C);

  static const Color background = primary50;

  static LinearGradient get pointGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary400, primary600],
  );
}

class MechanicTypography {
  static TextStyle get headline => GoogleFonts.notoSansKr(
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5, // tight
    fontSize: 24,
    color: Colors.black87,
  );

  static TextStyle get subheader => GoogleFonts.notoSansKr(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: Colors.black87,
  );

  static TextStyle get body =>
      GoogleFonts.notoSansKr(fontSize: 14, color: Colors.black87);
}

class WrenchBackground extends StatelessWidget {
  final Widget child;

  const WrenchBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MechanicColor.background,
      child: Stack(
        children: [
          // Centered Wrench Icon
          Positioned.fill(
            child: Center(
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(
                  LucideIcons.wrench,
                  size: 300,
                  color: MechanicColor.primary500.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                ), // Mobile-First Max Width
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MechanicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const MechanicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // rounded-xl+
        boxShadow: [
          BoxShadow(
            color: MechanicColor.primary600.withValues(
              alpha: 0.08,
            ), // shadow-sm / customized
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: MechanicColor.primary100),
      ),
      child: child,
    );

    // animate-fade-in equivalent
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), // Slide up 20px
            child: child,
          ),
        );
      },
      child: onTap != null ? GestureDetector(onTap: onTap, child: card) : card,
    );
  }
}

class MechanicHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const MechanicHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: MechanicColor.background.withValues(alpha: 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: MechanicColor.pointGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.car,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CarFix Pro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: MechanicColor.primary700,
                        ),
                      ),
                      Text(title, style: MechanicTypography.headline),
                    ],
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: MechanicTypography.body.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
