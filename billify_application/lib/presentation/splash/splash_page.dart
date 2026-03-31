import 'dart:math';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  // --- Main logo animation ---
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // --- Glow pulse ---
  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  // --- Tagline reveal ---
  late AnimationController _taglineController;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  // --- Shimmer sweep across logo ---
  late AnimationController _shimmerController;
  late Animation<double> _shimmerPosition;

  // --- Background ring expand ---
  late AnimationController _ringController;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  // --- Particles ---
  late AnimationController _particleController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _generateParticles();

    // Logo: scale + fade in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Glow pulse loop
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 30.0, end: 70.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Expanding ring
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ringScale = Tween<double>(
      begin: 0.6,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));

    // Tagline
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _taglineController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Shimmer sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Particles loop
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Sequence: ring → logo → shimmer → tagline
    _startSequence();
    _navigateToNext();
  }

  void _generateParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(random: _random));
    }
  }

  Future<void> _startSequence() async {
    // Ring burst
    _ringController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Logo in
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));

    // Shimmer sweep
    _shimmerController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Tagline
    _taglineController.forward();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 5000));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    final businessState = ref.read(businessProvider);

    if (authState.isLoggedIn) {
      if (businessState.currentBusiness == null) {
        Navigator.pushReplacementNamed(context, '/business-setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _ringController.dispose();
    _taglineController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF0D2B27),
                  Color(0xFF00473E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Subtle mesh overlay ──
          Positioned.fill(child: CustomPaint(painter: _MeshPainter())),

          // ── Floating particles ──
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),

          // ── Center content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expanding ring
                AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _ringScale.value,
                      child: Opacity(
                        opacity: _ringOpacity.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryTeal,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Logo + glow + shimmer — overlaid using Stack
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoController,
                    _glowController,
                    _shimmerController,
                  ]),
                  builder: (context, _) {
                    return Transform.translate(
                      // pull logo up to overlap with ring visually
                      offset: Offset(0, -_ringScale.value * 60),
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryTeal.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: _glowRadius.value * 2,
                                      spreadRadius: _glowRadius.value * 0.4,
                                    ),
                                  ],
                                ),
                              ),

                              // Logo container with glass effect
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Image.asset(
                                          'assets/billify.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // Shimmer sweep
                                      if (_shimmerController.isAnimating ||
                                          _shimmerController.isCompleted)
                                        Positioned.fill(
                                          child: Transform.translate(
                                            offset: Offset(
                                              _shimmerPosition.value * 160,
                                              0,
                                            ),
                                            child: Container(
                                              width: 60,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(
                                                      0.0,
                                                    ),
                                                    Colors.white.withOpacity(
                                                      0.25,
                                                    ),
                                                    Colors.white.withOpacity(
                                                      0.0,
                                                    ),
                                                  ],
                                                ),
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
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // App name
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Text(
                        'Billify',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Tagline
                AnimatedBuilder(
                  animation: _taglineController,
                  builder: (context, _) {
                    return SlideTransition(
                      position: _taglineSlide,
                      child: Opacity(
                        opacity: _taglineOpacity.value,
                        child: Text(
                          'Simplify your business management',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                            color: AppTheme.primaryTeal.withOpacity(0.9),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Bottom brand strip ──
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _taglineController,
              builder: (context, _) {
                return Opacity(
                  opacity: _taglineOpacity.value,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Particle model ──
class _Particle {
  late double x, y, radius, speed, opacity, angle;

  _Particle({required Random random}) {
    reset(random);
    // randomize initial y so they don't all start at bottom
    y = random.nextDouble();
  }

  void reset(Random random) {
    x = random.nextDouble();
    y = 1.0;
    radius = random.nextDouble() * 2.5 + 0.5;
    speed = random.nextDouble() * 0.12 + 0.04;
    opacity = random.nextDouble() * 0.5 + 0.1;
    angle = (random.nextDouble() - 0.5) * 0.3;
  }
}

// ── Particle painter ──
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yPos = (p.y - p.speed * progress * 6) % 1.2;
      final xPos = p.x + sin(progress * 2 * pi + p.angle) * 0.02;

      final paint = Paint()
        ..color = AppTheme.primaryTeal.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(xPos * size.width, yPos * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── Background mesh painter ──
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => false;
}
