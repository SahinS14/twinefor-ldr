import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://twine-api.onrender.com/api/v1';
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _addInterceptors();
  }

  void _addInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh == null) return false;
      final res = await Dio().post('$baseUrl/auth/refresh', data: {'refreshToken': refresh});
      await _storage.write(key: 'access_token', value: res.data['accessToken']);
      await _storage.write(key: 'refresh_token', value: res.data['refreshToken']);
      return true;
    } catch (_) { return false; }
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────
  Future<Map> register(String email, String password, String name, String username) async {
  final res = await dio.post(
    '/auth/register',
    data: {
      'email': email,
      'password': password,
      'name': name,
      'username': username,
    },
  );

  await _saveTokens(res.data);
  return res.data;
}

  Future<Map> login(String email, String password) async {
  final res = await dio.post(
    '/auth/login',
    data: {
      'email': email,
      'password': password,
    },
  );

  await _saveTokens(res.data);
  return res.data;
}

  Future<void> logout() async {
    try { await dio.post('/auth/logout'); } catch (_) {}
    await _storage.deleteAll();
  }

  Future<Map> getMe() async {
    final res = await dio.get('/users/me');
    return res.data;
  }

  Future<Map> updateProfile(Map<String, dynamic> data) async {
    final res = await dio.patch('/users/me', data: data);
    return res.data;
  }

  // ─── COUPLES ───────────────────────────────────────────────────────────────
  Future<Map> generateInvite() async { final r = await dio.post('/couples/invite'); return r.data; }
  Future<Map> acceptInvite(String code) async { final r = await dio.post('/couples/accept', data: {'code': code}); return r.data; }
  Future<Map> getMyCouple() async { final r = await dio.get('/couples/me'); return r.data; }
  Future<Map> getCoupleStats() async { final r = await dio.get('/couples/me/stats'); return r.data; }

  // ─── CHAT ──────────────────────────────────────────────────────────────────
  Future<Map> getMessages({String? cursor, int limit = 30}) async {
    final r = await dio.get('/chat/messages', queryParameters: {'cursor': cursor, 'limit': limit});
    return r.data;
  }
  Future<Map> sendMessage(String content, {String? type, String? replyToId}) async {
    final r = await dio.post('/chat/send', data: {'content': content, 'type': type ?? 'text', 'replyToId': replyToId});
    return r.data;
  }
  Future<void> markRead() async { await dio.post('/chat/read'); }
  Future<List> getPinnedMessages() async { final r = await dio.get('/chat/pinned'); return r.data; }

  // ─── GAMES ─────────────────────────────────────────────────────────────────
  Future<Map> createGame(String gameType) async {
    final r = await dio.post('/games/session', data: {'gameType': gameType});
    return r.data;
  }
  Future<Map> getGameSession(String id) async { final r = await dio.get('/games/session/$id'); return r.data; }
  Future<List> getGameHistory() async { final r = await dio.get('/games/history'); return r.data; }
  Future<Map> getLeaderboard() async { final r = await dio.get('/games/leaderboard'); return r.data; }

  // ─── AI ────────────────────────────────────────────────────────────────────
  Future<Map> getDailyQuestion() async { final r = await dio.get('/ai/question/daily'); return r.data; }
  Future<Map> submitAnswer(String questionId, String answer) async {
    final r = await dio.post('/ai/question/answer', data: {'questionId': questionId, 'answer': answer});
    return r.data;
  }
  Future<Map> getInsights() async { final r = await dio.get('/ai/insights'); return r.data; }
  Future<Map> getWeeklySummary() async { final r = await dio.get('/ai/summary/weekly'); return r.data; }

  // ─── GAMIFICATION ──────────────────────────────────────────────────────────
  Future<Map> getGamificationProfile() async { final r = await dio.get('/gamification/profile'); return r.data; }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────
  Future<List> getNotifications() async { final r = await dio.get('/notifications'); return r.data; }
  Future<void> markNotificationRead(String id) async { await dio.post('/notifications/$id/read'); }
  Future<void> markAllRead() async { await dio.post('/notifications/read-all'); }

  // ─── SUBSCRIPTIONS ─────────────────────────────────────────────────────────
  Future<Map> getSubscriptionStatus() async { final r = await dio.get('/subscriptions/status'); return r.data; }
  Future<Map> startTrial() async { final r = await dio.post('/subscriptions/trial'); return r.data; }
  Future<Map> getCheckoutUrl() async { final r = await dio.post('/subscriptions/checkout'); return r.data; }

  Future<void> _saveTokens(Map data) async {
    if (data['accessToken'] != null) await _storage.write(key: 'access_token', value: data['accessToken']);
    if (data['refreshToken'] != null) await _storage.write(key: 'refresh_token', value: data['refreshToken']);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
