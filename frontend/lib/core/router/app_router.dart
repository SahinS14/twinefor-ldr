import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/couple/screens/pairing_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/games/screens/games_lobby_screen.dart';
import '../../features/games/screens/game_screen.dart';
import '../../features/ai/screens/ai_insights_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/subscription_screen.dart';

final _storage = const FlutterSecureStorage();

Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  final loggedIn = (await _storage.read(key: 'access_token')) != null;
  final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register' || state.matchedLocation == '/onboarding';
  if (!loggedIn && !loggingIn) return '/onboarding';
  if (loggedIn && loggingIn) return '/';
  return null;
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: _authRedirect,
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/pair', builder: (_, __) => const PairingScreen()),
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(path: 'chat', builder: (_, __) => const ChatScreen()),
        GoRoute(path: 'games', builder: (_, __) => const GamesLobbyScreen(), routes: [
          GoRoute(path: ':sessionId', builder: (c, s) => GameScreen(sessionId: s.pathParameters['sessionId']!)),
        ]),
        GoRoute(path: 'ai', builder: (_, __) => const AiInsightsScreen()),
        GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: 'subscribe', builder: (_, __) => const SubscriptionScreen()),
      ],
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('404: ${state.error}')),
  ),
);
