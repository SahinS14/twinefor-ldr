import '../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/api_client.dart';
import '../../../core/providers/socket_service.dart';

class GameScreen extends StatefulWidget {
  final String sessionId;
  const GameScreen({super.key, required this.sessionId});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _socket = SocketService();
  Map? _state;
  Map? _me;
  bool _loading = true;
  bool _gameOver = false;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _load();
    _setupSocket();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([ApiClient().getMe(), ApiClient().getGameSession(widget.sessionId)]);
      setState(() { _me = results[0]; _state = results[1]; _loading = false; });
      _socket.joinGame(widget.sessionId);
    } catch (e) { setState(() => _loading = false); }
  }

  void _setupSocket() {
    _socket.on('game:state', (data) { if (mounted) setState(() => _state = Map<String, dynamic>.from(data)); });
    _socket.on('game:end', (data) {
      if (!mounted) return;
      setState(() { _gameOver = true; _winner = data['winnerId']; });
      _showEndDialog(data);
    });
    _socket.on('game:player_joined', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${data['name']} joined!'), backgroundColor: TwineTheme.rose, duration: const Duration(seconds: 2)));
    });
  }

  void _makeMove(Map move) {
    _socket.makeMove(widget.sessionId, move);
  }

  void _showEndDialog(Map data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: TwineTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(data['isDraw'] == true ? '🤝' : (data['winnerId'] == _me?['id'] ? '🎉' : '😔'), style: TextStyle(fontSize: 56)).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(data['isDraw'] == true ? "It's a Draw!" : (data['winnerId'] == _me?['id'] ? 'You Won!' : 'You Lost'), style: TextStyle(color: TwineTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(data['resignedBy'] != null ? 'Opponent resigned' : 'Game over', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Lobby'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); _rematch(); }, child: const Text('Rematch'))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _rematch() async {
    final type = _state?['gameType'] ?? 'tic_tac_toe';
    try {
      final session = await ApiClient().createGame(type);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameScreen(sessionId: session['session']['id'])));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: TwineTheme.plum, body: Container(decoration: BoxDecoration(gradient: TwineTheme.heroGradient), child: const Center(child: CircularProgressIndicator(color: TwineTheme.rose))));
    final gameType = _state?['gameType'] ?? 'tic_tac_toe';
    return Scaffold(
      backgroundColor: TwineTheme.plum,
      appBar: AppBar(
        title: Text(_gameTitle(gameType)),
        actions: [
          TextButton(onPressed: () => _socket.resignGame(widget.sessionId), child: const Text('Resign', style: TextStyle(color: TwineTheme.error))),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
        child: Column(children: [
          _buildTurnIndicator(),
          Expanded(child: Center(child: _buildGameUI(gameType))),
        ]),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    final myTurn = _state?['currentTurn'] == _me?['id'];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: myTurn ? TwineTheme.rose.withOpacity(0.15) : TwineTheme.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: myTurn ? TwineTheme.rose.withOpacity(0.4) : TwineTheme.border),
      ),
      child: Text(myTurn ? "Your turn ⚡" : "Partner's turn...", style: TextStyle(color: myTurn ? TwineTheme.rose : TwineTheme.textSecondary, fontWeight: FontWeight.w600)),
    ).animate(target: myTurn ? 1 : 0).shimmer(duration: 1500.ms, color: TwineTheme.rose.withOpacity(0.2));
  }

  Widget _buildGameUI(String type) {
    switch (type) {
      case 'tic_tac_toe': return _buildTicTacToe();
      case 'truth_or_dare': return _buildTruthOrDare();
      case 'quiz': return _buildQuiz();
      default: return _buildGenericGame(type);
    }
  }

  Widget _buildTicTacToe() {
    final board = List.from(_state?['board'] ?? List.filled(9, null));
    final mySymbol = _state?['hostId'] == _me?['id'] ? 'X' : 'O';
    final myTurn = _state?['currentTurn'] == _me?['id'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _symbolChip('X', mySymbol == 'X'),
          const SizedBox(width: 20),
          _symbolChip('O', mySymbol == 'O'),
        ]),
        const SizedBox(height: 32),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: 9,
            itemBuilder: (_, i) {
              final cell = board[i];
              return GestureDetector(
                onTap: (cell == null && myTurn && !_gameOver) ? () => _makeMove({'index': i}) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: cell == null ? TwineTheme.surface : (cell == 'X' ? TwineTheme.rose.withOpacity(0.15) : TwineTheme.plumAccent.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cell == null ? TwineTheme.border : (cell == 'X' ? TwineTheme.rose : TwineTheme.plumLight), width: cell == null ? 1 : 1.5),
                  ),
                  child: Center(child: Text(cell ?? '', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: cell == 'X' ? TwineTheme.rose : TwineTheme.plumLight)))
                      .animate(target: cell != null ? 1 : 0).scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _symbolChip(String symbol, bool isMe) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: isMe ? TwineTheme.rose.withOpacity(0.15) : TwineTheme.surface,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: isMe ? TwineTheme.rose : TwineTheme.border),
    ),
    child: Text('$symbol ${isMe ? "(You)" : "(Partner)"}', style: TextStyle(color: isMe ? TwineTheme.rose : TwineTheme.textSecondary, fontWeight: FontWeight.w600)),
  );

  Widget _buildTruthOrDare() {
    final round = _state?['round'] ?? 1;
    final myTurn = _state?['currentTurn'] == _me?['id'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Round $round', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        if (myTurn) ...[
          const Text('Your turn! Choose:', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: () => _makeMove({'choice': 'truth', 'prompt': 'What is your biggest fear?'}),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              child: const Column(children: [Text('🙏', style: TextStyle(fontSize: 28)), SizedBox(height: 6), Text('Truth')]),
            )),
            const SizedBox(width: 16),
            Expanded(child: OutlinedButton(
              onPressed: () => _makeMove({'choice': 'dare', 'prompt': 'Send a voice note saying I love you!'}),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(20)),
              child: const Column(children: [Text('🎯', style: TextStyle(fontSize: 28)), SizedBox(height: 6), Text('Dare')]),
            )),
          ]),
        ] else
          const Column(children: [
            Text('⏳', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text("Partner's turn...", style: TextStyle(color: TwineTheme.textSecondary, fontSize: 16)),
          ]),
        const SizedBox(height: 24),
        if ((_state?['log'] as List? ?? []).isNotEmpty) ...[
          Divider(color: TwineTheme.border),
          ...((_state?['log'] as List?) ?? []).reversed.take(3).map((l) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TwineTheme.border)),
              child: Text('${l['choice'] == 'truth' ? '🙏' : '🎯'} ${l['prompt']}', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 13)),
            ),
          )),
        ],
      ]),
    );
  }

  Widget _buildQuiz() {
    final scores = Map<String, dynamic>.from(_state?['scores'] ?? {});
    final myScore = scores[_me?['id']] ?? 0;
    final qIdx = _state?['currentQuestion'] ?? 0;
    final questions = ['What year did the Eiffel Tower open?', 'How many planets are in our solar system?', 'What is the capital of Japan?'];
    final options = [['1887', '1889', '1891', '1893'], ['7', '8', '9', '10'], ['Beijing', 'Seoul', 'Tokyo', 'Osaka']];
    final q = qIdx < questions.length ? questions[qIdx] : null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _scoreChip('You', myScore, TwineTheme.rose),
          const SizedBox(width: 20),
          Text('Q ${qIdx + 1}/10', style: TextStyle(color: TwineTheme.textSecondary)),
          const SizedBox(width: 20),
          _scoreChip('Partner', scores.values.where((v) => v != myScore).firstOrNull ?? 0, TwineTheme.plumLight),
        ]),
        const SizedBox(height: 28),
        if (q != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: TwineTheme.cardGradient, borderRadius: BorderRadius.circular(16), border: Border.all(color: TwineTheme.plumLight.withOpacity(0.3))),
            child: Text(q, textAlign: TextAlign.center, style: TextStyle(color: TwineTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5)),
          ),
          const SizedBox(height: 20),
          ...((qIdx < options.length ? options[qIdx] : []) as List<String>).asMap().entries.map((e) =>
            GestureDetector(
              onTap: () => _makeMove({'answer': e.value, 'questionIndex': qIdx, 'isCorrect': e.key == 1, 'bothAnswered': true}),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TwineTheme.border)),
                child: Row(children: [
                  Container(width: 26, height: 26, decoration: BoxDecoration(color: TwineTheme.plumAccent, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(String.fromCharCode(65 + e.key), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 12),
                  Text(e.value, style: TextStyle(color: TwineTheme.textPrimary, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ] else
          const Text('Game complete! 🎉', style: TextStyle(color: TwineTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _scoreChip(String label, dynamic score, Color color) => Column(children: [
    Text(label, style: TextStyle(color: TwineTheme.textSecondary, fontSize: 11)),
    Text('$score', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
  ]);

  Widget _buildGenericGame(String type) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(_gameTitle(type), style: TextStyle(color: TwineTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
    const SizedBox(height: 16),
    const Text('Game in progress...', style: TextStyle(color: TwineTheme.textSecondary, fontSize: 16)),
    const SizedBox(height: 8),
    Text('Moves: ${_state?['moveCount'] ?? 0}', style: TextStyle(color: TwineTheme.textHint, fontSize: 13)),
  ]);

  String _gameTitle(String type) {
    const titles = {'chess': 'Chess', 'ludo': 'Ludo', 'tic_tac_toe': 'Tic Tac Toe', 'quiz': 'Quiz Battle', 'truth_or_dare': 'Truth or Dare'};
    return titles[type] ?? type;
  }
}
