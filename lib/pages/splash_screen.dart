import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animație fade-in
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    // Trecerea la HomeScreen după 4 secunde
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
            colors: [Color.fromARGB(255, 20, 93, 154), Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Logo + titlu
            Align(
              alignment: Alignment(0, -0.2), 
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/logo.png',
                      width: 200,
                      height: 200,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'HeroForge',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(
                      color: Colors.amber,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment(0, 0.7),
              child: Text(
                'Try your best to become a HERO!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.amber,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
