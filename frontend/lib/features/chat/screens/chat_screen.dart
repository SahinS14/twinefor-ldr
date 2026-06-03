import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/api_client.dart';
import '../../../core/providers/socket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _socket = SocketService();
  List<Map> _messages = [];
  bool _loading = true;
  bool _partnerTyping = false;
  bool _partnerOnline = false;
  Map? _me;
  Map? _partner;
  String? _cursor;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
    _setupSocket();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([ApiClient().getMe(), ApiClient().getMyCouple()]);
      final me = results[0];
      final couple = results[1];
      final partner = couple['userA']['id'] == me['id'] ? couple['userB'] : couple['userA'];
      final msgs = await ApiClient().getMessages();
      setState(() {
        _me = me;
        _partner = partner;
        _messages = List<Map>.from(msgs['messages'] ?? []);
        _cursor = msgs['nextCursor'];
        _hasMore = msgs['hasMore'] ?? false;
        _loading = false;
      });
      _scrollToBottom();
      await ApiClient().markRead();
    } catch (e) { setState(() => _loading = false); }
  }

  void _setupSocket() {
    _socket.on('chat:message', (data) {
      if (!mounted) return;
      setState(() => _messages.add(Map<String, dynamic>.from(data['message'])));
      _scrollToBottom();
    });
    _socket.on('chat:typing', (data) {
      if (!mounted) return;
      setState(() => _partnerTyping = data['isTyping'] == true);
    });
    _socket.on('presence:update', (data) {
      if (!mounted) return;
      if (data['userId'] == _partner?['id']) setState(() => _partnerOnline = data['isOnline'] == true);
    });
    _socket.on('chat:reaction', (data) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == data['messageId']);
        if (idx >= 0) _messages[idx] = {..._messages[idx], 'reactedWith': data['emoji']};
      });
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    _socket.sendMessage(text);
    _socket.setTyping(false);
    // Optimistic update
    setState(() => _messages.add({'content': text, 'senderId': _me?['id'], 'type': 'text', 'createdAt': DateTime.now().toIso8601String(), 'isRead': false}));
    _scrollToBottom();
  }

  void _onTypingChanged(String v) {
    _socket.setTyping(v.isNotEmpty);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: 300.ms, curve: Curves.easeOut);
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _cursor == null) return;
    final res = await ApiClient().getMessages(cursor: _cursor);
    setState(() {
      _messages = [...List<Map>.from(res['messages'] ?? []), ..._messages];
      _cursor = res['nextCursor'];
      _hasMore = res['hasMore'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwineTheme.plum,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(gradient: TwineTheme.heroGradient),
        child: _loading ? const Center(child: CircularProgressIndicator(color: TwineTheme.rose)) : Column(children: [
          Expanded(child: _buildMessageList()),
          if (_partnerTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: TwineTheme.surface.withOpacity(0.8),
    title: Row(children: [
      _avatarCircle(_partner?['name'] ?? '?', TwineTheme.plumLight, 36),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_partner?['name'] ?? 'Partner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: _partnerOnline ? TwineTheme.online : TwineTheme.textHint, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(_partnerOnline ? 'Online now' : 'Offline', style: TextStyle(fontSize: 11, color: TwineTheme.textSecondary)),
        ]),
      ]),
    ]),
    actions: [
      IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _socket.joinVoiceRoom('video')),
      IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
    ],
  );

  Widget _buildMessageList() => NotificationListener<ScrollNotification>(
    onNotification: (n) { if (n.metrics.pixels <= 50) _loadMore(); return false; },
    child: ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isMe = msg['senderId'] == _me?['id'];
        final showDate = i == 0 || _isDifferentDay(_messages[i - 1]['createdAt'], msg['createdAt']);
        return Column(children: [
          if (showDate) _buildDateDivider(msg['createdAt']),
          _buildBubble(msg, isMe).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),
        ]);
      },
    ),
  );

  Widget _buildBubble(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showReactionPicker(msg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? TwineTheme.roseGradient : null,
                color: isMe ? null : TwineTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe ? null : Border.all(color: TwineTheme.border),
              ),
              child: Text(msg['content'] ?? '', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.45)),
            ),
            if (msg['reactedWith'] != null) Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(msg['reactedWith'], style: TextStyle(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_formatTime(msg['createdAt']), style: TextStyle(color: TwineTheme.textHint, fontSize: 10)),
                if (isMe) ...[const SizedBox(width: 4), Icon(msg['isRead'] == true ? Icons.done_all : Icons.done, size: 12, color: msg['isRead'] == true ? TwineTheme.roseLight : TwineTheme.textHint)],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.only(left: 20, bottom: 8),
    child: Row(children: [
      _avatarCircle(_partner?['name'] ?? '?', TwineTheme.plumLight, 24),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: TwineTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: TwineTheme.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 5, height: 5,
            decoration: BoxDecoration(color: TwineTheme.textSecondary, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).fadeIn(delay: Duration(milliseconds: i * 150), duration: 300.ms).then().fadeOut(duration: 300.ms),
        )),
      ),
    ]),
  );

  Widget _buildInputBar() => Container(
    padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
    decoration: BoxDecoration(color: TwineTheme.surface.withOpacity(0.9), border: Border(top: BorderSide(color: TwineTheme.border))),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.add_circle_outline, color: TwineTheme.textSecondary), onPressed: () {}),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: TwineTheme.plum.withOpacity(0.6), borderRadius: BorderRadius.circular(24), border: Border.all(color: TwineTheme.border)),
          child: TextField(
            controller: _msgCtrl,
            onChanged: _onTypingChanged,
            onSubmitted: (_) => _sendMessage(),
            style: TextStyle(color: TwineTheme.textPrimary, fontSize: 14),
            maxLines: 4, minLines: 1,
            decoration: const InputDecoration.collapsed(hintText: 'Message...', hintStyle: TextStyle(color: TwineTheme.textHint)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: _sendMessage,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(gradient: TwineTheme.roseGradient, shape: BoxShape.circle),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ),
    ]),
  );

  void _showReactionPicker(Map msg) {
    final emojis = ['❤️', '😂', '😮', '😢', '🔥', '💕'];
    showModalBottomSheet(
      context: context,
      backgroundColor: TwineTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: emojis.map((e) =>
          GestureDetector(
            onTap: () { Navigator.pop(context); _socket.reactToMessage(msg['id'] ?? '', e); },
            child: Text(e, style: TextStyle(fontSize: 32)),
          ),
        ).toList()),
      ),
    );
  }

  Widget _buildDateDivider(String? dateStr) {
    if (dateStr == null) return const SizedBox.shrink();
    final date = DateTime.tryParse(dateStr);
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    String label;
    if (date.day == now.day && date.month == now.month) label = 'Today';
    else if (date.day == now.day - 1 && date.month == now.month) label = 'Yesterday';
    else label = '${date.day}/${date.month}/${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: TwineTheme.border)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(label, style: TextStyle(color: TwineTheme.textHint, fontSize: 11))),
        const Expanded(child: Divider(color: TwineTheme.border)),
      ]),
    );
  }

  Widget _avatarCircle(String name, Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: size * 0.38, fontWeight: FontWeight.w600))),
  );

  bool _isDifferentDay(String? a, String? b) {
    if (a == null || b == null) return false;
    final da = DateTime.tryParse(a); final db = DateTime.tryParse(b);
    if (da == null || db == null) return false;
    return da.day != db.day || da.month != db.month;
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final d = DateTime.tryParse(dateStr)?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); _socket.setTyping(false); super.dispose(); }
}
