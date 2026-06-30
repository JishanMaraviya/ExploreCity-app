import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'main.dart';
import 'theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _loadingController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _skylineAnimation;

  @override
  void initState() {
    super.initState();

    // Main content animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _skylineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Loading bar animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _mainController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _loadingController.forward();
    });

    Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF0F8FF),
                  Color(0xFFE1F2FF),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Soft abstract circle glow (top-right) ───────────────────────
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Soft abstract circle glow (bottom-left) ─────────────────────
          Positioned(
            bottom: size.height * 0.22,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom skyline + wave ────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _skylineAnimation,
              builder: (_, __) => Opacity(
                opacity: _skylineAnimation.value,
                child: SizedBox(
                  height: size.height * 0.28,
                  child: CustomPaint(
                    painter: _SkylinePainter(),
                    size: Size(size.width, size.height * 0.28),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content — truly centered on full screen ─────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Logo with glow shadow ────────────────────────────────
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (_, child) => ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: child,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withOpacity(0.18),
                            blurRadius: 36,
                            spreadRadius: 4,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.9),
                            blurRadius: 16,
                            spreadRadius: -4,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── App name + subtitle ──────────────────────────────────
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // "Explore city" — split color text, centered
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Explore ',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'city',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0EA5E9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle — centered
                          Text(
                            'Discover your next adventure',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Thin elegant loading bar — fixed 200px, centered ─────
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _loadingAnimation,
                      builder: (_, __) => SizedBox(
                        width: 200,
                        height: 3,
                        child: Stack(
                          children: [
                            // Track
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            // Animated fill
                            FractionallySizedBox(
                              widthFactor: _loadingAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0EA5E9),
                                      Color(0xFF38BDF8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

/// CustomPainter that draws:
/// 1. A soft two-layer wave at the bottom
/// 2. A faint silhouette of Indian landmarks (India Gate, Taj Mahal, Qutub Minar, etc.)
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Wave layer 1 (back, lighter) ──────────────────────────────────────
    final wavePaint1 = Paint()
      ..color = const Color(0xFFBAE6FD).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final wavePath1 = Path();
    wavePath1.moveTo(0, h * 0.38);
    wavePath1.cubicTo(w * 0.22, h * 0.18, w * 0.45, h * 0.52, w * 0.65, h * 0.30);
    wavePath1.cubicTo(w * 0.80, h * 0.14, w * 0.92, h * 0.42, w, h * 0.28);
    wavePath1.lineTo(w, h);
    wavePath1.lineTo(0, h);
    wavePath1.close();
    canvas.drawPath(wavePath1, wavePaint1);

    // ── Wave layer 2 (front, slightly more opaque) ───────────────────────
    final wavePaint2 = Paint()
      ..color = const Color(0xFF7DD3FC).withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final wavePath2 = Path();
    wavePath2.moveTo(0, h * 0.55);
    wavePath2.cubicTo(w * 0.18, h * 0.38, w * 0.40, h * 0.68, w * 0.60, h * 0.48);
    wavePath2.cubicTo(w * 0.78, h * 0.32, w * 0.90, h * 0.58, w, h * 0.46);
    wavePath2.lineTo(w, h);
    wavePath2.lineTo(0, h);
    wavePath2.close();
    canvas.drawPath(wavePath2, wavePaint2);

    // ── Silhouette paint ─────────────────────────────────────────────────
    final paint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.28)
      ..style = PaintingStyle.fill;

    final skyline = Path();
    final baseY = h * 0.95; // ground line

    // Helper: draw a rectangle block
    void rect(double x, double w2, double topY) {
      skyline.moveTo(x, baseY);
      skyline.lineTo(x, topY);
      skyline.lineTo(x + w2, topY);
      skyline.lineTo(x + w2, baseY);
    }

    // Helper: draw a triangle/pointed top
    void pointedTop(double x, double w2, double topY, double baseTopY) {
      skyline.moveTo(x, baseY);
      skyline.lineTo(x, baseTopY);
      skyline.lineTo(x + w2 / 2, topY);
      skyline.lineTo(x + w2, baseTopY);
      skyline.lineTo(x + w2, baseY);
    }

    // ── India Gate (left side) ───────────────────────────────────────────
    // Main arch pillars
    double igX = w * 0.03;
    // Left pillar
    rect(igX, w * 0.014, baseY - h * 0.32);
    // Right pillar
    rect(igX + w * 0.072, w * 0.014, baseY - h * 0.32);
    // Top beam across the arch
    rect(igX, w * 0.086, baseY - h * 0.34);
    // Small top tower
    rect(igX + w * 0.028, w * 0.030, baseY - h * 0.40);
    // Tiny pinnacle
    pointedTop(igX + w * 0.031, w * 0.024, baseY - h * 0.46, baseY - h * 0.40);

    // ── Small trees near India Gate ──────────────────────────────────────
    // Tree 1
    pointedTop(igX + w * 0.095, w * 0.024, baseY - h * 0.18, baseY - h * 0.10);
    rect(igX + w * 0.103, w * 0.008, baseY - h * 0.10);
    // Tree 2
    pointedTop(igX + w * 0.122, w * 0.020, baseY - h * 0.16, baseY - h * 0.09);

    // ── Taj Mahal (center) ───────────────────────────────────────────────
    double tmX = w * 0.34;
    // Main platform
    rect(tmX - w * 0.02, w * 0.20, baseY - h * 0.07);
    // Left minaret
    rect(tmX, w * 0.016, baseY - h * 0.42);
    pointedTop(tmX, w * 0.016, baseY - h * 0.47, baseY - h * 0.42);
    // Right minaret
    rect(tmX + w * 0.155, w * 0.016, baseY - h * 0.42);
    pointedTop(tmX + w * 0.155, w * 0.016, baseY - h * 0.47, baseY - h * 0.42);
    // Main base
    rect(tmX + w * 0.022, w * 0.127, baseY - h * 0.27);
    // Side wings
    rect(tmX + w * 0.014, w * 0.020, baseY - h * 0.20);
    rect(tmX + w * 0.137, w * 0.020, baseY - h * 0.20);
    // Central dome base
    rect(tmX + w * 0.060, w * 0.055, baseY - h * 0.35);
    // Dome (circle approximation with arc)
    final domeCenter = Offset(tmX + w * 0.0875, baseY - h * 0.52);
    final domePath = Path()
      ..addOval(Rect.fromCenter(
          center: domeCenter, width: w * 0.07, height: h * 0.17));
    skyline.addPath(domePath, Offset.zero);
    // Finial on dome
    rect(tmX + w * 0.0845, w * 0.006, baseY - h * 0.61);
    pointedTop(tmX + w * 0.0823, w * 0.010, baseY - h * 0.64, baseY - h * 0.61);

    // Small inner domes
    final leftDomeCenter = Offset(tmX + w * 0.047, baseY - h * 0.36);
    final leftDomePath = Path()
      ..addOval(Rect.fromCenter(
          center: leftDomeCenter, width: w * 0.032, height: h * 0.07));
    skyline.addPath(leftDomePath, Offset.zero);

    final rightDomeCenter = Offset(tmX + w * 0.127, baseY - h * 0.36);
    final rightDomePath = Path()
      ..addOval(Rect.fromCenter(
          center: rightDomeCenter, width: w * 0.032, height: h * 0.07));
    skyline.addPath(rightDomePath, Offset.zero);

    // ── Hawa Mahal style (right-center) ──────────────────────────────────
    double hmX = w * 0.58;
    // Multiple stepped arched tiers
    rect(hmX, w * 0.075, baseY - h * 0.12);
    // Tier 2
    rect(hmX + w * 0.006, w * 0.063, baseY - h * 0.22);
    // Tier 3
    rect(hmX + w * 0.012, w * 0.051, baseY - h * 0.30);
    // Tier 4
    rect(hmX + w * 0.018, w * 0.039, baseY - h * 0.37);
    // Tier 5 with pointed crown
    rect(hmX + w * 0.024, w * 0.027, baseY - h * 0.43);
    pointedTop(hmX + w * 0.022, w * 0.031, baseY - h * 0.49, baseY - h * 0.43);
    // Small turrets on each tier
    for (int i = 0; i < 5; i++) {
      pointedTop(
        hmX + w * (0.002 + i * 0.013),
        w * 0.010,
        baseY - h * (0.14 + i * 0.085),
        baseY - h * (0.12 + i * 0.085),
      );
    }

    // ── Qutub Minar (right side) ─────────────────────────────────────────
    double qmX = w * 0.73;
    // Base (widest)
    rect(qmX, w * 0.044, baseY - h * 0.10);
    // Section 2
    rect(qmX + w * 0.006, w * 0.032, baseY - h * 0.25);
    // Section 3
    rect(qmX + w * 0.010, w * 0.024, baseY - h * 0.38);
    // Section 4
    rect(qmX + w * 0.013, w * 0.018, baseY - h * 0.49);
    // Section 5
    rect(qmX + w * 0.016, w * 0.012, baseY - h * 0.58);
    // Pointed top
    pointedTop(qmX + w * 0.014, w * 0.016, baseY - h * 0.65, baseY - h * 0.58);

    // ── Small dome structure (far right) ─────────────────────────────────
    double sdX = w * 0.83;
    rect(sdX, w * 0.065, baseY - h * 0.09);
    rect(sdX + w * 0.010, w * 0.045, baseY - h * 0.18);
    final sdDomeCenter = Offset(sdX + w * 0.0325, baseY - h * 0.28);
    final sdDomePath = Path()
      ..addOval(Rect.fromCenter(
          center: sdDomeCenter, width: w * 0.042, height: h * 0.095));
    skyline.addPath(sdDomePath, Offset.zero);
    pointedTop(sdX + w * 0.026, w * 0.013, baseY - h * 0.34, baseY - h * 0.30);

    // ── Palm trees (scattered) ───────────────────────────────────────────
    void palmTree(double x, double height) {
      // Trunk
      rect(x, w * 0.006, baseY - height);
      // Fronds (simple triangles fanning out)
      skyline.moveTo(x + w * 0.003, baseY - height);
      skyline.lineTo(x - w * 0.022, baseY - height - h * 0.06);
      skyline.lineTo(x - w * 0.010, baseY - height - h * 0.02);
      skyline.moveTo(x + w * 0.003, baseY - height);
      skyline.lineTo(x + w * 0.028, baseY - height - h * 0.06);
      skyline.lineTo(x + w * 0.016, baseY - height - h * 0.02);
      skyline.moveTo(x + w * 0.003, baseY - height);
      skyline.lineTo(x + w * 0.003, baseY - height - h * 0.08);
    }

    palmTree(w * 0.20, h * 0.18);
    palmTree(w * 0.79, h * 0.15);

    canvas.drawPath(skyline, paint);

    // ── Flying birds (tiny V shapes) ─────────────────────────────────────
    final birdPaint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    void bird(double x, double y, double sz) {
      final p = Path();
      p.moveTo(x - sz, y);
      p.quadraticBezierTo(x - sz * 0.5, y - sz * 0.6, x, y);
      p.quadraticBezierTo(x + sz * 0.5, y - sz * 0.6, x + sz, y);
      canvas.drawPath(p, birdPaint);
    }

    bird(w * 0.22, h * 0.08, w * 0.012);
    bird(w * 0.26, h * 0.05, w * 0.009);
    bird(w * 0.70, h * 0.06, w * 0.011);
    bird(w * 0.74, h * 0.04, w * 0.008);
    bird(w * 0.50, h * 0.03, w * 0.010);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
