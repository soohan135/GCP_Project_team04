import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ConsumerColor {
  static const Color brand50 = Color(0xFFF0F9FF);
  static const Color brand100 = Color(0xFFE0F2FE);
  static const Color brand200 = Color(0xFFBAE6FD);
  static const Color brand300 = Color(0xFF7DD3FC);
  static const Color brand400 = Color(0xFF38BDF8);
  static const Color brand500 = Color(0xFF0EA5E9);
  static const Color brand600 = Color(0xFF0284C7);
  static const Color brand700 = Color(0xFF0369A1);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color background = brand50;
  static const Color cardBackground = Colors.white;
}

class ConsumerTypography {
  static TextStyle get h1 => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: ConsumerColor.slate800,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: ConsumerColor.slate800,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ConsumerColor.slate600,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ConsumerColor.slate500,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ConsumerColor.slate400,
  );

  static TextStyle get tag => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: ConsumerColor.brand500,
  );

  static TextStyle get navLabel => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
}

class PixieMascot extends StatelessWidget {
  final String status; // 'idle', 'thinking', 'success', 'error'
  final double size;

  const PixieMascot({super.key, required this.status, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: PixiePainter(status: status)),
    );
  }
}

class PixiePainter extends CustomPainter {
  final String status;
  PixiePainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final unit = size.width / 100;

    // Antenna
    final antennaPaint = Paint()
      ..color = ConsumerColor.brand400
      ..strokeWidth = 4 * unit
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(50 * unit, 30 * unit),
      Offset(50 * unit, 15 * unit),
      antennaPaint,
    );

    paint.color = const Color(0xFFFB923C); // Amber/Orange
    canvas.drawCircle(Offset(50 * unit, 15 * unit), 5 * unit, paint);

    // Body/Head
    paint.color = ConsumerColor.brand400;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20 * unit, 30 * unit, 60 * unit, 50 * unit),
      Radius.circular(16 * unit),
    );
    canvas.drawRRect(bodyRect, paint);

    // Face Screen
    paint.color = const Color(0xFFF0F9FF);
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(30 * unit, 42 * unit, 40 * unit, 26 * unit),
      Radius.circular(8 * unit),
    );
    canvas.drawRRect(faceRect, paint);

    // Eyes & Mouth (Idle expression by default)
    final eyePaint = Paint()..color = const Color(0xFF0284C7);

    if (status == 'idle' || status == 'thinking') {
      canvas.drawCircle(
        Offset(42 * unit, 53 * unit),
        3.5 * unit,
        eyePaint,
      ); // Left eye
      canvas.drawCircle(
        Offset(58 * unit, 53 * unit),
        3.5 * unit,
        eyePaint,
      ); // Right eye

      final mouthPath = Path()
        ..moveTo(46 * unit, 60 * unit)
        ..quadraticBezierTo(50 * unit, 63 * unit, 54 * unit, 60 * unit);
      canvas.drawPath(
        mouthPath,
        Paint()
          ..color = const Color(0xFF0284C7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * unit
          ..strokeCap = StrokeCap.round,
      );

      if (status == 'idle') {
        final blushPaint = Paint()
          ..color = const Color(0xFFF472B6).withOpacity(0.6);
        canvas.drawCircle(Offset(36 * unit, 58 * unit), 2 * unit, blushPaint);
        canvas.drawCircle(Offset(64 * unit, 58 * unit), 2 * unit, blushPaint);
      }
    } else if (status == 'success') {
      // Happy eyes ^ ^
      final eyeStroke = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * unit
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(39 * unit, 53 * unit)
          ..lineTo(42 * unit, 50 * unit)
          ..lineTo(45 * unit, 53 * unit),
        eyeStroke,
      );
      canvas.drawPath(
        Path()
          ..moveTo(55 * unit, 53 * unit)
          ..lineTo(58 * unit, 50 * unit)
          ..lineTo(61 * unit, 53 * unit),
        eyeStroke,
      );
      canvas.drawPath(
        Path()
          ..moveTo(45 * unit, 60 * unit)
          ..quadraticBezierTo(50 * unit, 65 * unit, 55 * unit, 60 * unit),
        eyeStroke,
      );
    } else if (status == 'error') {
      // X eyes
      final xPaint = Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * unit
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(39 * unit, 50 * unit),
        Offset(45 * unit, 56 * unit),
        xPaint,
      );
      canvas.drawLine(
        Offset(45 * unit, 50 * unit),
        Offset(39 * unit, 56 * unit),
        xPaint,
      );
      canvas.drawLine(
        Offset(55 * unit, 50 * unit),
        Offset(61 * unit, 56 * unit),
        xPaint,
      );
      canvas.drawLine(
        Offset(61 * unit, 50 * unit),
        Offset(55 * unit, 56 * unit),
        xPaint,
      );

      final sadMouth = Path()
        ..moveTo(46 * unit, 62 * unit)
        ..quadraticBezierTo(50 * unit, 58 * unit, 54 * unit, 62 * unit);
      canvas.drawPath(sadMouth, xPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConsumerHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsTap;
  const ConsumerHeader({super.key, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ConsumerColor.brand50,
      padding: const EdgeInsets.only(left: 24, right: 20, top: 36, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
                        'assets/images/app_logo_blue_void.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                Flexible(
                  child: Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    child: OverflowBox(
                      maxHeight: 100,
                      maxWidth: 300,
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/logo_blue.png',
                        height: 66,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(
                LucideIcons.settings,
                size: 22,
                color: ConsumerColor.slate400,
              ),
              onPressed: onSettingsTap,
              hoverColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(84);
}

class WaveGraphic extends StatelessWidget {
  const WaveGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: CustomPaint(painter: WavePainter()),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ConsumerColor.brand500
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.525)
      ..lineTo(4, size.height * 0.525)
      ..lineTo(9, size.height * 0.15)
      ..lineTo(15, size.height * 0.85)
      ..lineTo(21, size.height * 0.15)
      ..lineTo(26, size.height * 0.525)
      ..lineTo(40, size.height * 0.525);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(Offset(9, size.height * 0.15), 1.5, dotPaint);
    canvas.drawCircle(Offset(15, size.height * 0.85), 1.5, dotPaint);
    canvas.drawCircle(Offset(21, size.height * 0.15), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConsumerBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ConsumerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'icon': LucideIcons.home, 'label': '홈'},
      {'icon': LucideIcons.fileText, 'label': '견적 미리보기'},
      {'icon': LucideIcons.store, 'label': '정비소 응답'},
      {'icon': LucideIcons.messageCircle, 'label': '채팅'},
      {'icon': LucideIcons.mapPin, 'label': '근처 정비소'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? ConsumerColor.brand50
                          : ConsumerColor.brand50.withValues(alpha: 0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      items[index]['icon'],
                      size: 24,
                      color: isActive
                          ? ConsumerColor.brand600
                          : ConsumerColor.slate400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: ConsumerTypography.navLabel.copyWith(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? ConsumerColor.brand600
                          : ConsumerColor.slate400,
                    ),
                    child: Text(items[index]['label']),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SearchBackground extends StatelessWidget {
  final Widget child;
  final Offset offset;

  const SearchBackground({
    super.key,
    required this.child,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ConsumerColor.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: 0.5236, // 30 degrees in radians
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: MagnifierPainter(
                      color: ConsumerColor.brand500.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class MagnifierPainter extends CustomPainter {
  final Color color;

  MagnifierPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth =
          32 // Increase stroke width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final unit = size.width / 100;

    final path = Path();

    // Use a single path to avoid darkening at intersections
    path.addOval(
      Rect.fromCircle(center: Offset(40 * unit, 40 * unit), radius: 30 * unit),
    );

    final start = Offset(
      40 * unit + (30 * unit * 0.707),
      40 * unit + (30 * unit * 0.707),
    );
    final end = Offset(95 * unit, 95 * unit);

    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
