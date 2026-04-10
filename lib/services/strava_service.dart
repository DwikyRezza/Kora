import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class StravaService {
  // ── Strava API Credentials ────────────────────────────────────────────
  static const String _clientId = '222125';
  static const String _clientSecret = 'bc0d2e3a0bbdf08ed0c6efd9e0ff00bfb0c11973';
  static const String _redirectScheme = 'athletesync';
  static const String _redirectUrl = 'athletesync://callback';

  // ── SharedPreferences Keys ─────────────────────────────────────────────
  static const String _keyAccessToken = 'strava_access_token';
  static const String _keyRefreshToken = 'strava_refresh_token';
  static const String _keyExpiresAt = 'strava_expires_at';
  static const String _keyAthleteId = 'strava_athlete_id';

  // ── Base URLs ──────────────────────────────────────────────────────────
  static const String _authUrl = 'https://www.strava.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';
  static const String _apiBase = 'https://www.strava.com/api/v3';

  // ── Check apakah sudah terhubung ke Strava ─────────────────────────────
  static Future<bool> get isConnected async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  // ── Mulai proses OAuth2 — membuka browser Strava ──────────────────────
  static Future<bool> connectStrava() async {
    try {
      final url = Uri.parse(_authUrl).replace(queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUrl,
        'response_type': 'code',
        'approval_prompt': 'auto',
        'scope': 'activity:read_all',
      });

      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: _redirectScheme,
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return false;

      return await _exchangeCodeForToken(code);
    } catch (e) {
      debugPrint('❌ Strava OAuth error: $e');
      return false;
    }
  }

  // ── Tukar authorization code dengan access token ───────────────────────
  static Future<bool> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data);
        return true;
      } else {
        debugPrint('❌ Token exchange gagal: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exchange token error: $e');
      return false;
    }
  }

  // ── Simpan token ke SharedPreferences ────────────────────────────────
  static Future<void> _saveTokens(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, data['access_token'] ?? '');
    await prefs.setString(_keyRefreshToken, data['refresh_token'] ?? '');
    await prefs.setInt(_keyExpiresAt, data['expires_at'] ?? 0);
    final athlete = data['athlete'];
    if (athlete != null) {
      await prefs.setInt(_keyAthleteId, athlete['id'] ?? 0);
    }
    debugPrint('✅ Strava token disimpan. Expires at: ${data['expires_at']}');
  }

  // ── Refresh token jika sudah expired ─────────────────────────────────
  static Future<String?> _getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);
    final refreshToken = prefs.getString(_keyRefreshToken);
    final expiresAt = prefs.getInt(_keyExpiresAt) ?? 0;

    if (accessToken == null || refreshToken == null) return null;

    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Refresh jika token expire dalam 5 menit ke depan
    if (nowEpoch < expiresAt - 300) {
      return accessToken;
    }

    // Token perlu di-refresh
    debugPrint('🔄 Refreshing Strava token...');
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data);
        return data['access_token'];
      } else {
        debugPrint('❌ Refresh token gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
      return null;
    }
  }

  // ── Ambil daftar aktivitas lari terbaru (max 30) ─────────────────────
  static Future<List<Map<String, dynamic>>> getRecentRunActivities({
    int perPage = 30,
    int page = 1,
  }) async {
    final token = await _getValidAccessToken();
    if (token == null) return [];

    try {
      // Ambil aktivitas 90 hari terakhir
      final after = DateTime.now()
          .subtract(const Duration(days: 90))
          .millisecondsSinceEpoch ~/
          1000;

      final uri = Uri.parse('$_apiBase/athlete/activities').replace(
        queryParameters: {
          'after': after.toString(),
          'per_page': perPage.toString(),
          'page': page.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> all = jsonDecode(response.body);
        // Filter hanya aktivitas lari
        return all
            .where((a) => a['type'] == 'Run' || a['sport_type'] == 'Run')
            .map((a) => Map<String, dynamic>.from(a))
            .toList();
      } else {
        debugPrint('❌ Get activities error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Fetch activities error: $e');
      return [];
    }
  }

  // ── Ambil detail satu aktivitas (polyline, splits) ────────────────────
  static Future<Map<String, dynamic>?> getActivityDetail(int activityId) async {
    final token = await _getValidAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_apiBase/activities/$activityId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        debugPrint('❌ Get activity detail error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Fetch detail error: $e');
      return null;
    }
  }

  // ── Disconnect / Hapus token ──────────────────────────────────────────
  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyExpiresAt);
    await prefs.remove(_keyAthleteId);
    debugPrint('✅ Strava disconnected');
  }

  // ── Format helper: pace (detik/km → "M:SS /km") ──────────────────────
  static String formatPace(double distanceM, int movingTimeSec) {
    if (distanceM <= 0 || movingTimeSec <= 0) return '--:--';
    final paceSecPerKm = movingTimeSec / (distanceM / 1000);
    if (paceSecPerKm > 99 * 60) return '--:--';
    final m = (paceSecPerKm ~/ 60);
    final s = (paceSecPerKm % 60).round().toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Format helper: durasi (detik → "Xj Ym" atau "Ym Zd") ─────────────
  static String formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}j ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}d';
    return '${s}d';
  }

  // ── Format helper: jarak (meter → "X.XX km") ─────────────────────────
  static String formatDistance(double distanceM) {
    return '${(distanceM / 1000).toStringAsFixed(2)} km';
  }
}
