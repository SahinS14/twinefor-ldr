import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwineTheme.plum,
      body: Container(
        decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
        child: Stack(
          children: [
            Positioned(
              top: -100, right: -80,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TwineTheme.rose.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: 100, left: -80,
              child: Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TwineTheme.plumAccent.withOpacity(0.15),
                ),
              ),
            ),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, TwineTheme.roseLight],
                  ).createShader(bounds),
                  child: const Text(
                    'Twine',
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 52,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  'your private world, built for two',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TwineTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                const SizedBox(height: 48),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) =>
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: TwineTheme.roseLight,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                      .fadeIn(
                        delay: Duration(milliseconds: i * 200),
                        duration: const Duration(milliseconds: 400),
                      )
                      .then()
                      .fadeOut(duration: const Duration(milliseconds: 400)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
