import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  final RandomGeneratorMessage generator = RandomGeneratorMessage();
  late String randomMessage;

  @override
  void initState() {
    randomMessage = generator.getMessage();

    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.forward();

    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1a1625),
              const Color(0xFF2d1b3d),
              const Color(0xFF1a1625),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative orbs background
            Positioned(
              top: 50,
              right: 30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.shade600.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.indigo.shade600.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with scale animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade900.withOpacity(0.3),
                              Colors.amber.shade700.withOpacity(0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade600.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'lib/assets/images/logo.png',
                          width: 160,
                          height: 160,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title with RPG styling
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'HeroForge',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade200,
                        letterSpacing: 2.5,
                        shadows: [
                          Shadow(
                            color: Colors.amber.shade900.withOpacity(0.8),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                          ),
                          Shadow(
                            color: Colors.purple.shade600.withOpacity(0.5),
                            offset: const Offset(2, 2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle line
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 100,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.amber.shade400,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // RPG-styled loading spinner
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber.shade300,
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Preparing your adventure...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber.shade200.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quote at bottom
            Align(
              alignment: Alignment(0, 0.85),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.purple.shade700.withOpacity(0.5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade900.withOpacity(0.2),
                            Colors.indigo.shade900.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Text(
                        randomMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.amber.shade300,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RandomGeneratorMessage {
  var random = Random();

  List<String> messages = [
    "Try your best to become a HERO!",
    "Every step counts—level up yourself today!",
    "Conquer your fears, claim your power!",
    "Unleash the hero within you!",
    "Adventure awaits—embrace your destiny!",
    "Forge your path to greatness!",
    "Rise above challenges, be the hero!",
    "Courage is your greatest weapon!",
    "Believe in yourself, become unstoppable!",
    "Heroes are made, not born—start your journey!",
    "Dream big, act bigger!",
    "Rise, grind, and conquer!",
    "Turn your goals into achievements!",
    "Be bold, be brave, be unstoppable!",
    "Push limits, break barriers, grow!",
    "Master yourself, master your world!",
    "Your future self will thank you!",
    "Success is a journey, not a destination!",
  ];

  String getMessage() {
    return messages[random.nextInt(messages.length)];
  }
}