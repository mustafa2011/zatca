import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../screens/login.dart';

class Token {
  /// Get token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  /// Save token to SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  /// Validate token via API
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse(validateTokenUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['valid'] == true;
    }

    return false;
  }

  /// Request and store a new token
  Future<String?> issueNewToken() async {
    try {
      String contact = Utils.contactNumber;
      final response = await http.post(
        Uri.parse(issueTokenUrl),
        body: {
          'contact_number': contact,
          'password': 'admin',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        await saveToken(token);
        return token;
      }
    } on Exception catch (e) {
      throw Exception(e);
    }

    return null;
  }

  /// Initialize at app startup
  Future<void> initToken() async {
    final token = await getToken();
    if (token == null || !(await isTokenValid())) {
      await issueNewToken();
    }
  }

  /// 🔒 Logout: clear token and restart app
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.remove(tokenKey);
    await prefs.clear();

    Get.to(() => const LoginPage());
  }

  Future<String> getTokenInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);

    if (token == null || token.isEmpty) {
      return "No token found.";
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException("Invalid token format");
      }

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = json.decode(payload);

      final issuedAt = DateTime.fromMillisecondsSinceEpoch(data['iat'] * 1000);
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
      final formatter = DateFormat('yyyy-MM-dd hh:mm a');

      return 'Certificate License\n🕓 Issued: ${formatter.format(issuedAt)}\n⏳ Expires: ${formatter.format(expiresAt)}';
    } catch (e) {
      return "⚠️ Error parsing token: $e";
    }
  }

  Future<bool> loginAndGetToken(
      String username, String password, String clientId) async {
    final response = await http.post(
      Uri.parse('$alwadehApiUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'client_id': clientId,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      // Store token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      ZatcaAPI.errorMessage(
          "النسخة الحالية صالحة حتى تاريخ\n${data['expires_at']}");
      return true; // successful login
    } else {
      ZatcaAPI.errorMessage("Error ${response.statusCode}\n${data['error']}");
      return false; // failed login
    }
  }
}
