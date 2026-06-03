import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/api_client.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _myCode;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _generateCode();
  }

  Future<void> _generateCode() async {
    try {
      final res = await ApiClient().generateInvite();
      setState(() => _myCode = res['code']);
    } catch (_) {}
  }

  Future<void> _acceptInvite() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().acceptInvite(code);
      setState(() { _success = res['message']; _loading = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/');
    } catch (e) {
      setState(() { _error = 'Invalid or expired code. Try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 20),
              Text('Pair with your\npartner 💕', style: Theme.of(context).textTheme.displaySmall)
                  .animate().fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text('Share your code or enter theirs', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TwineTheme.textSecondary))
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: TwineTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TwineTheme.border),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicatorColor: TwineTheme.rose,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: TwineTheme.textPrimary,
                  unselectedLabelColor: TwineTheme.textSecondary,
                  tabs: const [Tab(text: 'My Code'), Tab(text: 'Enter Code')],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [_buildMyCode(), _buildEnterCode()],
                ),
              ),
              TextButton(
                onPressed: () { context.go('/'); },
                child: Text('Skip for now', style: TextStyle(color: TwineTheme.textHint)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildMyCode() {
    if (_myCode == null) return const Center(child: CircularProgressIndicator(color: TwineTheme.rose));
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: TwineTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TwineTheme.rose.withOpacity(0.3)),
        ),
        child: Column(children: [
          const Text('Your invite code', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Text(_myCode!, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 4))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2000.ms, color: TwineTheme.roseLight.withOpacity(0.3)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _myCode!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'), backgroundColor: TwineTheme.rose));
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Code'),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Code expires in 24 hours', style: TextStyle(color: TwineTheme.textHint, fontSize: 12)),
    ]).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEnterCode() {
    if (_success != null) {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💕', style: TextStyle(fontSize: 64)).animate().scale(curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(_success!, textAlign: TextAlign.center, style: TextStyle(color: TwineTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ]);
    }
    return Column(children: [
      TextField(
        controller: _codeCtrl,
        textCapitalization: TextCapitalization.characters,
        style: TextStyle(color: TwineTheme.textPrimary, fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'LOVE-1234',
          hintStyle: TextStyle(color: TwineTheme.textHint, fontSize: 24, letterSpacing: 4),
        ),
        onChanged: (v) => setState(() => _error = null),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: TwineTheme.error, fontSize: 13)),
      ],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _acceptInvite,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Connect with Partner'),
        ),
      ),
    ]).animate().fadeIn(delay: 200.ms);
  }

  @override
  void dispose() { _tabs.dispose(); _codeCtrl.dispose(); super.dispose(); }
}
