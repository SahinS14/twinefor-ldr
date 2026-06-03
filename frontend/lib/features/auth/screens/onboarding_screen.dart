import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  final _pages = [
    _OnboardPage('💬', 'Chat Privately', 'End-to-end encrypted messages, voice notes, and GIFs — just between you two.'),
    _OnboardPage('🎮', 'Play Together', 'Chess, Ludo, Truth or Dare and more — realtime multiplayer, anywhere.'),
    _OnboardPage('✨', 'Grow Together', 'AI-powered compatibility insights, daily questions, and your bond meter — always growing.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
        child: SafeArea(
          child: Column(children: [
            Align(alignment: Alignment.topRight,
              child: TextButton(onPressed: () => context.go('/login'),
                child: Text('Skip', style: TextStyle(color: TwineTheme.textSecondary)))),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            _buildDots(),
            _buildBottomSection(),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardPage p) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(p.emoji, style: TextStyle(fontSize: 72))
        .animate().scale(begin: const Offset(0.7, 0.7), duration: 400.ms, curve: Curves.elasticOut),
      const SizedBox(height: 32),
      Text(p.title, style: Theme.of(context).textTheme.displaySmall)
        .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
      const SizedBox(height: 16),
      Text(p.subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TwineTheme.textSecondary, height: 1.6))
        .animate().fadeIn(delay: 200.ms),
    ]),
  );

  Widget _buildDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(_pages.length, (i) => AnimatedContainer(
      duration: 300.ms,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _current == i ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: _current == i ? TwineTheme.rose : TwineTheme.textHint,
        borderRadius: BorderRadius.circular(99),
      ),
    )),
  );

  Widget _buildBottomSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    child: Column(children: [
      if (_current < _pages.length - 1)
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _controller.nextPage(duration: 350.ms, curve: Curves.easeInOut),
            child: const Text('Next'),
          ))
      else ...[
        SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: () => context.go('/register'), child: const Text('Create Account'))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: OutlinedButton(onPressed: () => context.go('/login'), child: const Text('Sign In'))),
      ]
    ]),
  );
}

class _OnboardPage { final String emoji, title, subtitle;
  _OnboardPage(this.emoji, this.title, this.subtitle);
}
