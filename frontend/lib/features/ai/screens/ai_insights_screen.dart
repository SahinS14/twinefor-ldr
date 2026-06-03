import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/api_client.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  Map? _insights;
  Map? _question;

  bool _loading = true;
  bool _answered = false;

  final _answerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient().getInsights(),
        ApiClient().getDailyQuestion(),
      ]);

      setState(() {
        _insights = results[0];
        _question = results[1];
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerCtrl.text.trim().isEmpty || _question == null) return;

    try {
      await ApiClient().submitAnswer(
        _question!['id'] ?? '',
        _answerCtrl.text.trim(),
      );

      setState(() {
        _answered = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Answer submitted! ✨'),
          backgroundColor: TwineTheme.rose,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwineTheme.plum,
      appBar: AppBar(
        title: const Text('AI Insights'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: TwineTheme.heroGradient,
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: TwineTheme.rose,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildCompatRing(),
                    const SizedBox(height: 24),
                    _buildInsightCards(),
                    const SizedBox(height: 24),
                    _buildDailyQuestion(),
                    const SizedBox(height: 24),
                    _buildSuggestions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCompatRing() {
    final score = _insights?['compatScore'] ?? 75;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: TwineTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: TwineTheme.rose.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Compatibility Score',
            style: TextStyle(
              color: TwineTheme.textSecondary,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 100.0,
                    strokeWidth: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                      TwineTheme.rose,
                    ),
                    strokeCap: StrokeCap.round,
                  ).animate().rotate(begin: -0.25),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: TwineTheme.textPrimary,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 1000.ms),

                    Text(
                      '%',
                      style: TextStyle(
                        color: TwineTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _insights?['weekHighlight'] ?? 'Keep connecting!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TwineTheme.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: TwineTheme.plumLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: TwineTheme.plumLight.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Love Language: ${_insights?['loveLanguage'] ?? 'Quality Time'}',
              style: TextStyle(
                color: TwineTheme.roseLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInsightCards() {
    return Column(
      children: [
        _insightCard(
          'Communication',
          _insights?['communicationScore'] ?? 78,
          TwineTheme.rose,
          '💬',
        ),

        const SizedBox(height: 10),

        _insightCard(
          'Emotional Bond',
          _insights?['emotionalScore'] ?? 80,
          TwineTheme.plumLight,
          '💜',
        ),
      ],
    );
  }

  Widget _insightCard(
    String label,
    int score,
    Color color,
    String emoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TwineTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TwineTheme.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: TwineTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '$score%',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: score / 100.0,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ).animate().fadeIn(duration: 800.ms),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDailyQuestion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: TwineTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TwineTheme.plumLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '✨',
                style: TextStyle(fontSize: 18),
              ),

              const SizedBox(width: 8),

              Text(
                "Today's Question",
                style: TextStyle(
                  color: TwineTheme.roseLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _question?['question'] ?? 'Loading...',
            style: TextStyle(
              color: TwineTheme.textPrimary,
              fontSize: 16,
              height: 1.55,
            ),
          ),

          if (!_answered) ...[
            const SizedBox(height: 16),

            TextField(
              controller: _answerCtrl,
              style: TextStyle(
                color: TwineTheme.textPrimary,
                fontSize: 14,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Your answer...',
                hintStyle: TextStyle(
                  color: TwineTheme.textHint,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAnswer,
                child: const Text('Submit Answer'),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: TwineTheme.online,
                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'Answered! Waiting for partner...',
                    style: TextStyle(
                      color: TwineTheme.online,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSuggestions() {
    final suggestions = List<String>.from(
      _insights?['suggestions'] ?? [
        'Try a new game together today',
        'Share a memory this evening',
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Suggestions for You',
          style: TextStyle(
            color: TwineTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        ...suggestions.asMap().entries.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TwineTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TwineTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: TwineTheme.rose,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: TwineTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
                delay: Duration(
                  milliseconds: 350 + e.key * 60,
                ),
              ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }
}