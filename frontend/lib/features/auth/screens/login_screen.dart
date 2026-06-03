import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/api_client.dart';

// ─── SHARED INPUT WIDGET ──────────────────────────────────────────────────
class _TwineField extends StatelessWidget {
  final String label; final String? hint; final bool obscure; final TextEditingController ctrl; final TextInputType? keyboard; final String? Function(String?)? validator;
  const _TwineField({required this.label, required this.ctrl, this.hint, this.obscure = false, this.keyboard, this.validator});
  @override
  Widget build(BuildContext c) => TextFormField(
    controller: ctrl, obscureText: obscure, keyboardType: keyboard, validator: validator,
    style: TextStyle(color: TwineTheme.textPrimary),
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient().login(_email.text.trim(), _pass.text);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() { _error = 'Invalid email or password'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: Container(
      decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            Text('Welcome\nback', style: Theme.of(c).textTheme.displayMedium)
              .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text('Sign in to your world', style: Theme.of(c).textTheme.bodyLarge?.copyWith(color: TwineTheme.textSecondary))
              .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 48),
            _TwineField(label: 'Email', ctrl: _email, keyboard: TextInputType.emailAddress,
              validator: (v) => v!.contains('@') ? null : 'Enter a valid email')
              .animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
            const SizedBox(height: 16),
            _TwineField(label: 'Password', ctrl: _pass, obscure: true,
              validator: (v) => v!.length >= 8 ? null : 'Min 8 characters')
              .animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight,
              child: TextButton(onPressed: () {}, child: Text('Forgot password?', style: TextStyle(color: TwineTheme.roseLight)))),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: TwineTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: TwineTheme.error.withOpacity(0.3))),
                child: Text(_error!, style: TextStyle(color: TwineTheme.error, fontSize: 13))),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In'),
            )).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Don't have an account? ", style: TextStyle(color: TwineTheme.textSecondary)),
              GestureDetector(onTap: () => context.go('/register'), child: Text('Sign up', style: TextStyle(color: TwineTheme.rose, fontWeight: FontWeight.w600))),
            ]),
          ])),
        ),
      ),
    ),
  );

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }
}

// ─── REGISTER SCREEN ──────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient().register(_email.text.trim(), _pass.text, _name.text.trim(), _username.text.trim().toLowerCase());
      if (mounted) context.go('/pair');
    } catch (e) {
      setState(() { _error = e.toString().contains('409') ? 'Email or username already taken' : 'Registration failed. Try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: Container(
      decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(onTap: () => context.go('/login'), child: const Icon(Icons.arrow_back, color: TwineTheme.textSecondary)),
            const SizedBox(height: 32),
            Text('Create your\naccount', style: Theme.of(c).textTheme.displayMedium).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text('Your private world awaits', style: Theme.of(c).textTheme.bodyLarge?.copyWith(color: TwineTheme.textSecondary)).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 48),
            _TwineField(label: 'Full name', ctrl: _name, validator: (v) => v!.length >= 2 ? null : 'Enter your name').animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            _TwineField(label: 'Username', hint: 'e.g. arjun_k', ctrl: _username, validator: (v) => RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(v!) ? null : 'Lowercase letters, numbers, underscores').animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 16),
            _TwineField(label: 'Email', ctrl: _email, keyboard: TextInputType.emailAddress, validator: (v) => v!.contains('@') ? null : 'Enter valid email').animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            _TwineField(label: 'Password', ctrl: _pass, obscure: true, validator: (v) => v!.length >= 8 ? null : 'Min 8 characters').animate().fadeIn(delay: 350.ms),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: TwineTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: TwineTheme.error.withOpacity(0.3))),
                child: Text(_error!, style: TextStyle(color: TwineTheme.error, fontSize: 13))),
            ],
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Account'),
            )).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Already have an account? ", style: TextStyle(color: TwineTheme.textSecondary)),
              GestureDetector(onTap: () => context.go('/login'), child: Text('Sign in', style: TextStyle(color: TwineTheme.rose, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 24),
          ])),
        ),
      ),
    ),
  );

  @override
  void dispose() { _name.dispose(); _username.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }
}
