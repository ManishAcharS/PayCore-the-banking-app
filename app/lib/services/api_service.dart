import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService extends ChangeNotifier {
  Future<Map<String, dynamic>> getBalance(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/accounts/balance'),
      headers: {'Authorization': 'Bearer ' + token},
    );
    return json.decode(res.body);
  }

  Future<List<dynamic>> getHistory(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/transfers/history'),
      headers: {'Authorization': 'Bearer ' + token},
    );
    final data = json.decode(res.body);
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> transfer(String token, String toAccount, double amount, String desc) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/transfers/transfer'),
      headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'},
      body: json.encode({'toAccountNumber': toAccount, 'amount': amount, 'description': desc}),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> setPin(String token, String pin) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/pin/set'),
      headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'},
      body: json.encode({'pin': pin}),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> verifyPin(String token, String pin) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/pin/verify'),
      headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'},
      body: json.encode({'pin': pin}),
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> pinStatus(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/pin/status'),
      headers: {'Authorization': 'Bearer ' + token},
    );
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> generateQR(String token, String accountNumber, String name) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/qr/generate'),
      headers: {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'},
      body: json.encode({'accountNumber': accountNumber, 'name': name}),
    );
    return json.decode(res.body);
  }
}
