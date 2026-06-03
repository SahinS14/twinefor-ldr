import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/api_client.dart';

class GamesLobbyScreen extends StatefulWidget {
  const GamesLobbyScreen({super.key});
  @override
  State<GamesLobbyScreen> createState() => _GamesLobbyScreenState();
}

class _GamesLobbyScreenState extends State<GamesLobbyScreen> {
  List _history = [];
  Map _leaderboard = {};
  bool _starting = false;

  final _games = [
    {'icon': '♟', 'name': 'Chess', 'type': 'chess', 'desc': 'Classic strategy', 'color': Color(0xFF7B5EA7), 'xp': '50 XP'},
    {'icon': '🎲', 'name': 'Ludo', 'type': 'ludo', 'desc': 'Race to home', 'color': Color(0xFFFF4B6E), 'xp': '30 XP'},
    {'icon': '⭕', 'name': 'Tic Tac Toe', 'type': 'tic_tac_toe', 'desc': 'Quick & fun', 'color': Color(0xFFFF8FA3), 'xp': '20 XP'},
    {'icon': '❓', 'name': 'Quiz Battle', 'type': 'quiz', 'desc': 'Test each other', 'color': Color(0xFFF5C842), 'xp': '40 XP'},
    {'icon': '🎯', 'name': 'Truth or Dare', 'type': 'truth_or_dare', 'desc': 'Get to know each other', 'color': Color(0xFF4A2D7A), 'xp': '25 XP'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final results = await Future.wait([ApiClient().getGameHistory(), ApiClient().getLeaderboard()]);
      setState(() { _history = results[0] as List; _leaderboard = results[1] as Map; });
    } catch (_) {}
  }

  Future<void> _startGame(String type) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final session = await ApiClient().createGame(type);
      if (mounted) context.push('/games/${session['session']['id']}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: TwineTheme.error));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwineTheme.plum,
      appBar: AppBar(title: const Text('Games')),
      body: Container(
        decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_leaderboard.isNotEmpty) _buildLeaderboard(),
            if (_leaderboard.isNotEmpty) const SizedBox(height: 24),
            const Text('Choose a Game', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            ..._games.asMap().entries.map((e) => _buildGameCard(e.value, e.key)),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text('Recent Games', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ..._history.take(5).map((g) => _buildHistoryTile(g)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: TwineTheme.cardGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TwineTheme.gold.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🏆 Win Leaderboard', style: TextStyle(color: TwineTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      ..._leaderboard.entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text('Player ${e.key.substring(0, 6)}', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 13)),
          const Spacer(),
          Text('${e.value} wins', style: TextStyle(color: TwineTheme.gold, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      )),
    ]),
  ).animate().fadeIn();

  Widget _buildGameCard(Map g, int idx) => GestureDetector(
    onTap: () => _startGame(g['type'] as String),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TwineTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TwineTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: (g['color'] as Color).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(g['icon'] as String, style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g['name'] as String, style: TextStyle(color: TwineTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(g['desc'] as String, style: TextStyle(color: TwineTheme.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: TwineTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(99), border: Border.all(color: TwineTheme.gold.withOpacity(0.3))),
            child: Text(g['xp'] as String, style: TextStyle(color: TwineTheme.gold, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          _starting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TwineTheme.rose))
              : const Icon(Icons.play_circle_outline, color: TwineTheme.rose, size: 26),
        ]),
      ]),
    ),
  ).animate().fadeIn(delay: Duration(milliseconds: 80 * idx)).slideX(begin: 0.05);

  Widget _buildHistoryTile(Map g) {
    final typeIcons = {'chess': '♟', 'ludo': '🎲', 'tic_tac_toe': '⭕', 'quiz': '❓', 'truth_or_dare': '🎯'};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TwineTheme.border)),
      child: Row(children: [
        Text(typeIcons[g['gameType']] ?? '🎮', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(g['gameType']?.toString().replaceAll('_', ' ').toUpperCase() ?? '', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
        if (g['winnerId'] != null) const Icon(Icons.emoji_events, color: TwineTheme.gold, size: 16),
        Text(' +${g['xpAwarded'] ?? 0} XP', style: TextStyle(color: TwineTheme.gold, fontSize: 11)),
      ]),
    );
  }
}
