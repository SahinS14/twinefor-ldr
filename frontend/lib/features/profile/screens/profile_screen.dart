import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/api_client.dart';

// ─── PROFILE SCREEN ───────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map? _user;
  Map? _gamification;
  Map? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Future.wait([ApiClient().getMe(), ApiClient().getGamificationProfile().catchError((_) => <String,dynamic>{}), ApiClient().getCoupleStats().catchError((_) => <String,dynamic>{})]);
      setState(() { _user = r[0]; _gamification = r[1]; _stats = r[2]; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: TwineTheme.plum,
    appBar: AppBar(title: const Text('Profile'), actions: [
      IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
    ]),
    body: Container(
      decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
      child: _loading ? const Center(child: CircularProgressIndicator(color: TwineTheme.rose)) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _buildAvatar(),
          const SizedBox(height: 20),
          _buildLevelCard(),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 20),
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildActions(),
        ]),
      ),
    ),
  );

  Widget _buildAvatar() => Column(children: [
    Container(
      width: 90, height: 90,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: TwineTheme.roseGradient, border: Border.all(color: TwineTheme.rose.withOpacity(0.4), width: 3)),
      child: Center(child: Text((_user?['name'] ?? 'U')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
    ).animate().scale(curve: Curves.elasticOut),
    const SizedBox(height: 12),
    Text(_user?['name'] ?? '', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    Text('@${_user?['username'] ?? ''}', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 14)),
    if (_user?['bio'] != null) ...[
      const SizedBox(height: 8),
      Text(_user!['bio'], textAlign: TextAlign.center, style: TextStyle(color: TwineTheme.textSecondary, fontSize: 13, height: 1.5)),
    ],
  ]);

  Widget _buildLevelCard() {
    final level = _gamification?['level'] ?? 1;
    final xp = _gamification?['xp'] ?? 0;
    final nextXp = _gamification?['nextLevelXp'] ?? 100;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: TwineTheme.cardGradient, borderRadius: BorderRadius.circular(18), border: Border.all(color: TwineTheme.plumLight.withOpacity(0.3))),
      child: Column(children: [
        Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(gradient: TwineTheme.roseGradient, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('$level', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Level $level', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            Text('$xp XP total', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 12)),
          ])),
          Text('🔥 ${_stats?['streakDays'] ?? 0} day streak', style: TextStyle(color: TwineTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: (xp / nextXp).clamp(0.0, 1.0), backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(TwineTheme.rose), minHeight: 6),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$xp XP', style: TextStyle(color: TwineTheme.textHint, fontSize: 11)),
          Text('$nextXp XP to next level', style: TextStyle(color: TwineTheme.textHint, fontSize: 11)),
        ]),
      ]),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildStatsRow() => Row(children: [
    _statTile('Days Together', '${_stats?['daysTogether'] ?? 0}', '📅'),
    const SizedBox(width: 10),
    _statTile('Bond Score', '${_stats?['bondScore'] ?? 0}%', '💕'),
    const SizedBox(width: 10),
    _statTile('Total XP', '${_stats?['totalXp'] ?? 0}', '⚡'),
  ]);

  Widget _statTile(String label, String value, String icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: TwineTheme.border)),
      child: Column(children: [
        Text(icon, style: TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: TwineTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: TwineTheme.textHint, fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _buildInfoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: TwineTheme.border)),
    child: Column(children: [
      _infoRow('Email', _user?['email'] ?? '', Icons.email_outlined),
      Divider(color: TwineTheme.border, height: 20),
      _infoRow('Love Language', _user?['loveLanguage'] ?? 'Not set', Icons.favorite_border),
      Divider(color: TwineTheme.border, height: 20),
      _infoRow('Mood', _user?['moodStatus'] ?? 'Happy', Icons.mood),
    ]),
  );

  Widget _infoRow(String label, String value, IconData icon) => Row(children: [
    Icon(icon, size: 18, color: TwineTheme.textSecondary),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(color: TwineTheme.textSecondary, fontSize: 13)),
    const Spacer(),
    Text(value, style: TextStyle(color: TwineTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
  ]);

  Widget _buildActions() => Column(children: [
    _actionBtn('✏️ Edit Profile', () => context.push('/settings')),
    const SizedBox(height: 10),
    _actionBtn('👑 Upgrade to Premium', () => context.push('/subscribe'), color: TwineTheme.gold),
  ]);

  Widget _actionBtn(String label, VoidCallback onTap, {Color? color}) => SizedBox(
    width: double.infinity,
    child: color != null
        ? ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.15), side: BorderSide(color: color.withValues(alpha: 0.5))), child: Text(label, style: TextStyle(color: color)))
        : OutlinedButton(onPressed: onTap, child: Text(label)),
  );
}

// ─── SETTINGS SCREEN ─────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: TwineTheme.plum,
    appBar: AppBar(title: const Text('Settings')),
    body: Container(
      decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _section('Account', [
          _tile(Icons.person_outline, 'Edit Profile', () {}),
          _tile(Icons.lock_outline, 'Change Password', () {}),
          _tile(Icons.notifications_outlined, 'Notification Settings', () {}),
        ]),
        const SizedBox(height: 20),
        _section('Couple', [
          _tile(Icons.people_outline, 'Couple Settings', () {}),
          _tile(Icons.calendar_today_outlined, 'Anniversary Date', () {}),
          _tile(Icons.link_off, 'Unpair', () {}, color: TwineTheme.error),
        ]),
        const SizedBox(height: 20),
        _section('Privacy & Data', [
          _tile(Icons.privacy_tip_outlined, 'Privacy Settings', () {}),
          _tile(Icons.download_outlined, 'Export My Data', () {}),
          _tile(Icons.delete_outline, 'Delete Account', () {}, color: TwineTheme.error),
        ]),
        const SizedBox(height: 20),
        _section('Support', [
          _tile(Icons.help_outline, 'Help Center', () {}),
          _tile(Icons.star_border, 'Rate the App', () {}),
          _tile(Icons.info_outline, 'About Twine', () {}),
        ]),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async { await ApiClient().logout(); if (c.mounted) c.go('/login'); },
          icon: const Icon(Icons.logout, color: TwineTheme.error),
          label: const Text('Sign Out', style: TextStyle(color: TwineTheme.error)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: TwineTheme.error)),
        ),
      ]),
    ),
  );

  Widget _section(String title, List<Widget> tiles) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title.toUpperCase(), style: TextStyle(color: TwineTheme.textHint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
    const SizedBox(height: 8),
    Container(decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: TwineTheme.border)), child: Column(children: tiles)),
  ]);

  Widget _tile(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
    leading: Icon(icon, color: color ?? TwineTheme.textSecondary, size: 20),
    title: Text(label, style: TextStyle(color: color ?? TwineTheme.textPrimary, fontSize: 14)),
    trailing: const Icon(Icons.arrow_forward_ios, color: TwineTheme.textHint, size: 13),
    onTap: onTap,
    dense: true,
  );
}

// ─── SUBSCRIPTION SCREEN ─────────────────────────────────────────────────
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map? _status;
  bool _loading = true;
  bool _upgrading = false;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final r = await ApiClient().getSubscriptionStatus(); setState(() { _status = r; _loading = false; }); } catch (_) { setState(() => _loading = false); } }

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: TwineTheme.plum,
    appBar: AppBar(title: const Text('Premium')),
    body: Container(
      decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
      child: _loading ? const Center(child: CircularProgressIndicator(color: TwineTheme.rose)) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text('✨', style: TextStyle(fontSize: 52)).animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 12),
          const Text('Twine Together', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_status?['plan'] == 'together' ? '✅ You\'re on Premium!' : 'Unlock everything for your relationship', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          _buildPlanCard(),
          const SizedBox(height: 16),
          _buildFeatures(),
          const SizedBox(height: 24),
          if (_status?['plan'] != 'together') ...[
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _upgrading ? null : _startTrial,
              style: ElevatedButton.styleFrom(backgroundColor: TwineTheme.gold, foregroundColor: TwineTheme.plum, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _upgrading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Start 7-Day Free Trial', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            )),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _upgrading ? null : _subscribe, child: const Text('Subscribe ₹299/month'))),
            const SizedBox(height: 12),
            const Text('Cancel anytime. No questions asked.', style: TextStyle(color: TwineTheme.textHint, fontSize: 12), textAlign: TextAlign.center),
          ],
        ]),
      ),
    ),
  );

  Widget _buildPlanCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: TwineTheme.cardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: TwineTheme.gold.withOpacity(0.4))),
    child: Column(children: [
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.workspace_premium, color: TwineTheme.gold, size: 20),
        SizedBox(width: 6),
        Text('TOGETHER PLAN', style: TextStyle(color: TwineTheme.gold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ]),
      const SizedBox(height: 12),
      const Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('₹', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        Text('299', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 42, fontWeight: FontWeight.w800, height: 1)),
        Text('/mo', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 14)),
      ]),
      const SizedBox(height: 4),
      const Text('Annual plan saves 40%', style: TextStyle(color: TwineTheme.gold, fontSize: 11)),
    ]),
  );

  Widget _buildFeatures() => Column(children: [
    _feat('All 5 games including Chess & Ludo'),
    _feat('Advanced AI weekly relationship insights'),
    _feat('Unlimited memories & shared journal'),
    _feat('Voice rooms & ambient together mode'),
    _feat('Custom themes & couple widgets'),
    _feat('Priority support'),
  ]);

  Widget _feat(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(color: TwineTheme.rose.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.check, color: TwineTheme.rose, size: 13)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(color: TwineTheme.textSecondary, fontSize: 13))),
    ]),
  );

  Future<void> _startTrial() async {
    setState(() => _upgrading = true);
    try { final r = await ApiClient().startTrial(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? 'Trial started!'), backgroundColor: TwineTheme.rose)); await _load(); } catch (_) {}
    setState(() => _upgrading = false);
  }

  Future<void> _subscribe() async {
    setState(() => _upgrading = true);
    try { final r = await ApiClient().getCheckoutUrl(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? 'Opening checkout...'), backgroundColor: TwineTheme.rose)); } catch (_) {}
    setState(() => _upgrading = false);
  }
}
