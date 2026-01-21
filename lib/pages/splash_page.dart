import 'package:flutter/material.dart';
import 'main_navigation.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    // Wait for 5 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Navigate to MainNavigation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_logo.jpg',
            fit: BoxFit.cover,
          ),
          // Optional: Add a subtle overlay if needed
          Container(
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
    );
  }
}
