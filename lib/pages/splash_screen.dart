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

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.forward();



    // to optimize - when application is ready, navigate imediatelly
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
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    randomMessage,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.amber,
                      fontStyle: FontStyle.italic,
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
