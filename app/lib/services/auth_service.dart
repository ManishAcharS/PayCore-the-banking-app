import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      _user = json.decode(userStr);
    }
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
    } else {
      await prefs.remove('token');
    }
    if (_user != null) {
      await prefs.setString('user', json.encode(_user));
    } else {
      await prefs.remove('user');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = json.decode(res.body);
    if (res.statusCode == 200) {
      _token = data['token'];
      _user = data['user'];
      await _savePrefs();
      notifyListeners();
    }
    return data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );
    final data = json.decode(res.body);
    if (res.statusCode == 201) {
      _token = data['token'];
      _user = data['user'];
      await _savePrefs();
      notifyListeners();
    }
    return data;
  }

  Future<Map<String, dynamic>> googleSignIn(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    final data = json.decode(res.body);
    if (res.statusCode == 200) {
      _token = data['token'];
      _user = data['user'];
      await _savePrefs();
      notifyListeners();
    }
    return data;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _savePrefs();
    notifyListeners();
  }
}
