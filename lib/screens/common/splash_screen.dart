// lib/screens/common/splash_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:medcluster/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mController;
  late Animation<double> _mScale;
  late Animation<Offset> _mSlide;

  late AnimationController _restController;
  late Animation<double> _restFade;

  late AnimationController _dotsController;

  late AnimationController _exitController;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // "M" animation controller
    _mController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _mScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mController, curve: Curves.easeOutBack));

    _mSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.06, 0), // slide left (do not change)
    ).animate(CurvedAnimation(parent: _mController, curve: Curves.easeInOut));

    // "edCluster" fade-in controller
    _restController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _restFade = CurvedAnimation(parent: _restController, curve: Curves.easeIn);

    // Dots animation controller
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Exit fade controller
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitFade = CurvedAnimation(parent: _exitController, curve: Curves.easeOut);

    // Sequence: Play M -> then rest -> then dots
    _mController.forward().whenComplete(() {
      _restController.forward().whenComplete(() {
        _dotsController.repeat();
      });
    });

    // After 4 seconds, fade out then navigate
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _exitController.forward().whenComplete(() {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionDuration: const Duration(milliseconds: 600),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(opacity: anim, child: child);
              },
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _mController.dispose();
    _restController.dispose();
    _dotsController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edStyle = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1.0,
      shadows: [
        Shadow(
          offset: const Offset(2, 2),
          blurRadius: 4,
          color: Colors.black.withValues(alpha: 0.4),
        ),
      ],
    );

    final mStyle = edStyle.copyWith(
      fontSize: 39, // M slightly larger
    );

    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_exitFade),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title animation row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _mScale,
                    child: SlideTransition(
                      position: _mSlide,
                      child: Text("M", style: mStyle),
                    ),
                  ),
                  FadeTransition(
                    opacity: _restFade,
                    child: Text("edCluster", style: edStyle),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Waving 6-dot animation
              FadeTransition(
                opacity: _restFade,
                child: SizedBox(
                  height: 24,
                  child: AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final double phase =
                              (_dotsController.value * 2 * math.pi) +
                              (index * 0.4);
                          final double dy = math.sin(phase);
                          const double amplitude = 6.0;
                          final double translateY = -dy * amplitude;
                          return Transform.translate(
                            offset: Offset(0, translateY),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
