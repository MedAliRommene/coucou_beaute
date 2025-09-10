import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/api_base.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _me;

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get me => _me;
  String? get role => _me?['role'] as String?;
  bool get hasProExtras =>
      (_me?['professional_profile'] as Map<String, dynamic>?)
          ?.containsKey('extra') ==
      true;

  Future<void> loadFromStorage() async {
    final sp = await SharedPreferences.getInstance();
    _accessToken = sp.getString('access');
    _refreshToken = sp.getString('refresh');
    if (_accessToken != null) {
      await fetchMe();
    }
  }

  Future<bool> login(
      {required String email,
      required String password,
      String? expectedRole}) async {
    final uri = Uri.parse('${apiBase()}/api/auth/login/');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'expected_role': expectedRole
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken = data['access'] as String?;
      _refreshToken = data['refresh'] as String?;
      final sp = await SharedPreferences.getInstance();
      if (_accessToken != null) sp.setString('access', _accessToken!);
      if (_refreshToken != null) sp.setString('refresh', _refreshToken!);
      await fetchMe();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> fetchMe() async {
    if (_accessToken == null) return;
    final uri = Uri.parse('${apiBase()}/api/auth/me/');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $_accessToken',
      'Accept': 'application/json',
    });
    if (res.statusCode == 200) {
      _me = jsonDecode(res.body) as Map<String, dynamic>;
      notifyListeners();
    }
  }

  Future<bool> saveProfessionalExtras(Map<String, dynamic> extras) async {
    if (_accessToken == null) return false;
    final uri = Uri.parse('${apiBase()}/api/professionals/extras/save/');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(extras),
    );
    if (res.statusCode == 200) {
      await fetchMe();
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> registerClient(
      Map<String, dynamic> payload) async {
    final uri = Uri.parse('${apiBase()}/api/auth/register/client/');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 201 || res.statusCode == 200) {
      _accessToken = data['access'] as String?;
      _refreshToken = data['refresh'] as String?;
      final sp = await SharedPreferences.getInstance();
      if (_accessToken != null) sp.setString('access', _accessToken!);
      if (_refreshToken != null) sp.setString('refresh', _refreshToken!);
      await fetchMe();
      notifyListeners();
    }
    return {'ok': res.statusCode == 201 || res.statusCode == 200, 'data': data};
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('access');
    await sp.remove('refresh');
    _accessToken = null;
    _refreshToken = null;
    _me = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> bookAppointment({
    required int proId,
    required String serviceName,
    required num price,
    required DateTime start,
    required DateTime end,
  }) async {
    if (_accessToken == null) {
      return {'ok': false, 'error': 'not_authenticated'};
    }
    final uri = Uri.parse('${apiBase()}/api/appointments/client/book/');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'pro_id': proId,
        'service_name': serviceName,
        'price': price,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return {'ok': true, 'data': jsonDecode(res.body)};
    }
    return {
      'ok': false,
      'status': res.statusCode,
      'error': res.body,
    };
  }
}
