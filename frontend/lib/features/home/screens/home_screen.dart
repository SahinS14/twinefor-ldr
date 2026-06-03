import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/api_client.dart';
import '../../../core/providers/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  Map? _user;
  Map? _couple;
  Map? _stats;
  Map? _gamification;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService().connect();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient().getMe(),
        ApiClient().getCoupleStats().catchError((_) => <String, dynamic>{}),
        ApiClient().getGamificationProfile().catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0];
        _stats = results[1];
        _gamification = results[2];
        _loading = false;
      });
      // Load couple separately
      try {
        final c = await ApiClient().getMyCouple();
        setState(() => _couple = c);
      } catch (_) {}
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwineTheme.plum,
      body: _loading ? _buildLoading() : _buildBody(),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildLoading() => Container(
    decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
    child: const Center(child: CircularProgressIndicator(color: TwineTheme.rose)),
  );

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: TwineTheme.rose,
          backgroundColor: TwineTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBondCard(),
              const SizedBox(height: 16),
              _buildStreakCard(),
              const SizedBox(height: 24),
              _buildSectionLabel('Play Together'),
              const SizedBox(height: 12),
              _buildGamesGrid(),
              const SizedBox(height: 24),
              _buildSectionLabel("Today's Question"),
              const SizedBox(height: 12),
              _buildDailyQuestion(),
              const SizedBox(height: 24),
              _buildSectionLabel('Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final partnerA = _couple?['userA'];
    final partnerB = _couple?['userB'];
    final myId = _user?['id'];
    final partner = partnerA?['id'] == myId ? partnerB : partnerA;
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Good ${_greeting()},', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 13)),
        Text(_user?['name']?.split(' ')[0] ?? 'You', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
      ])),
      if (partner != null) _buildAvatarPair(_user, partner),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () => context.push('/profile'),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TwineTheme.border)),
          child: const Icon(Icons.person_outline, color: TwineTheme.textSecondary, size: 20),
        ),
      ),
    ]).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildAvatarPair(Map? me, Map? partner) {
    return SizedBox(width: 56, height: 36, child: Stack(children: [
      _avatar(partner?['name'] ?? '?', TwineTheme.plumLight, left: 20),
      _avatar(me?['name'] ?? '?', TwineTheme.rose, left: 0),
    ]));
  }

  Widget _avatar(String name, Color color, {double left = 0}) => Positioned(
    left: left,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: TwineTheme.plum, width: 2)),
      child: Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
    ),
  );

  Widget _buildBondCard() {
    final score = _stats?['bondScore'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: TwineTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TwineTheme.rose.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Bond Meter', style: TextStyle(color: TwineTheme.roseLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const Spacer(),
          Text('$score / 100', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(TwineTheme.rose),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Keep connecting daily to grow your bond', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 12)),
          const Spacer(),
          Text('+${_stats?['daysTogether'] ?? 0}d together', style: TextStyle(color: TwineTheme.roseLight, fontSize: 11)),
        ]),
      ]),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildStreakCard() {
    final streak = _stats?['streakDays'] ?? 0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: TwineTheme.gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TwineTheme.gold.withOpacity(0.2)),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🔥 ', style: TextStyle(fontSize: 18)),
            Text('$streak day streak', style: TextStyle(color: TwineTheme.gold, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 2),
          Text('${_gamification?['xp'] ?? 0} XP • Level ${_gamification?['level'] ?? 1}',
              style: TextStyle(color: TwineTheme.textSecondary, fontSize: 12)),
        ]),
        const Spacer(),
        Row(children: List.generate(7, (i) => Container(
          margin: const EdgeInsets.only(left: 4),
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: i <= today ? TwineTheme.gold : TwineTheme.gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(child: Text(days[i], style: TextStyle(
            color: i <= today ? TwineTheme.plum : TwineTheme.gold.withOpacity(0.4),
            fontSize: 9, fontWeight: FontWeight.w700,
          ))),
        ))),
      ]),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildSectionLabel(String label) => Text(label,
      style: TextStyle(color: TwineTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600));

  Widget _buildGamesGrid() {
    final games = [
      {'icon': '♟', 'name': 'Chess', 'type': 'chess', 'color': TwineTheme.plumLight},
      {'icon': '🎲', 'name': 'Ludo', 'type': 'ludo', 'color': TwineTheme.rose},
      {'icon': '⭕', 'name': 'Tic Tac Toe', 'type': 'tic_tac_toe', 'color': TwineTheme.roseLight},
      {'icon': '❓', 'name': 'Quiz', 'type': 'quiz', 'color': TwineTheme.gold},
      {'icon': '🎯', 'name': 'Truth/Dare', 'type': 'truth_or_dare', 'color': TwineTheme.plumAccent},
      {'icon': '🎮', 'name': 'More Soon', 'type': null, 'color': TwineTheme.textHint},
    ];
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1),
      itemCount: games.length,
      itemBuilder: (_, i) {
        final g = games[i];
        return GestureDetector(
          onTap: g['type'] == null ? null : () => _startGame(g['type'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: TwineTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TwineTheme.border),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(g['icon'] as String, style: TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(g['name'] as String, style: TextStyle(color: TwineTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 200 + i * 40));
      },
    );
  }

  Future<void> _startGame(String type) async {
    try {
      final session = await ApiClient().createGame(type);
      if (mounted) context.push('/games/${session['session']['id']}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start game: $e'), backgroundColor: TwineTheme.error));
    }
  }

  Widget _buildDailyQuestion() {
    return FutureBuilder(
      future: ApiClient().getDailyQuestion(),
      builder: (ctx, snap) {
        if (!snap.hasData) return Container(height: 80, decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(16)));
        final q = snap.data as Map;
        return GestureDetector(
          onTap: () => context.push('/ai'),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: TwineTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TwineTheme.plumLight.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Text(q['question'] ?? 'Loading...', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 14, height: 1.5))),
              const Icon(Icons.arrow_forward_ios, color: TwineTheme.textHint, size: 14),
            ]),
          ),
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.chat_bubble_outline, 'label': 'Chat', 'route': '/chat', 'color': TwineTheme.rose},
      {'icon': Icons.favorite_border, 'label': 'AI Insights', 'route': '/ai', 'color': TwineTheme.plumLight},
      {'icon': Icons.location_on_outlined, 'label': 'Location', 'route': '/', 'color': TwineTheme.gold},
      {'icon': Icons.workspace_premium_outlined, 'label': 'Premium', 'route': '/subscribe', 'color': TwineTheme.goldSoft},
    ];
    return Row(children: actions.asMap().entries.map((e) {
      final a = e.value;
      return Expanded(
        child: GestureDetector(
          onTap: () => context.push(a['route'] as String),
          child: Container(
            margin: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: TwineTheme.border)),
            child: Column(children: [
              Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
              const SizedBox(height: 6),
              Text(a['label'] as String, style: TextStyle(color: TwineTheme.textSecondary, fontSize: 11)),
            ]),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 350 + e.key * 50)),
      );
    }).toList());
  }

  Widget _buildNavBar() => NavigationBar(
    selectedIndex: _navIndex,
    onDestinationSelected: (i) {
      setState(() => _navIndex = i);
      final routes = ['/', '/chat', '/games', '/ai', '/profile'];
      context.go(routes[i]);
    },
    backgroundColor: TwineTheme.surface,
    indicatorColor: TwineTheme.rose.withOpacity(0.15),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: TwineTheme.rose), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: TwineTheme.rose), label: 'Chat'),
      NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports, color: TwineTheme.rose), label: 'Games'),
      NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: TwineTheme.rose), label: 'AI'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: TwineTheme.rose), label: 'Profile'),
    ],
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}
