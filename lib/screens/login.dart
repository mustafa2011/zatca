import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/token.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/settings.dart';
import '../screens/home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _pwd = TextEditingController(text: "admin");
  bool _rememberMe = true;
  bool _loading = false;

  // bool _obscureText = true;
  Setting? setting;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSetting() async {
    final settings = await FatooraDB.instance.getAllSettings();
    int id = Utils.clientId;
    if (settings.isEmpty) {
      setting = await FatooraDB.instance.createSetting(Setting(id: id));
    } else {
      setting = settings[0];
    }
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Get and store global static class from prefs
    Utils.clientId = prefs.getInt('clientId') ?? 0;
    Utils.companyName = prefs.getString('companyName') ?? '';
    Utils.vatNumber = prefs.getString('vatNumber') ?? '';
    Utils.contactNumber = prefs.getString('contactNumber') ?? '';
    Utils.contactName = prefs.getString('contactName') ?? '';
    Utils.password = prefs.getString('password') ?? '';
    Utils.subscriptionExpiry = prefs.getString('subscriptionExpiry') ?? '';
    Utils.crNumber = prefs.getString('crNumber') ?? '';
    Utils.buildingNo = prefs.getString('buildingNo') ?? '';
    Utils.street = prefs.getString('street') ?? '';
    Utils.secondaryNo = prefs.getString('secondaryNo') ?? '';
    Utils.district = prefs.getString('district') ?? '';
    Utils.postalCode = prefs.getString('postalCode') ?? '';
    Utils.city = prefs.getString('city') ?? '';
    Utils.environment = prefs.getString('environment') ?? '';
    Utils.authorization = prefs.getString('authorization') ?? '';
    Utils.device = prefs.getString('device') ?? '';
    Utils.logo = prefs.getString('logo') ?? '';
    Utils.logoWidth = prefs.getInt('logoWidth') ?? 75;
    Utils.logoHeight = prefs.getInt('logoHeight') ?? 75;
    Utils.terms = prefs.getString('terms') ?? '';
    Utils.showAllData = prefs.getInt('showAllData') ?? 1;

    if (Utils.clientId != 0) {
      Get.to(() => const HomePage());
      return;
    }
    String? savedContact = prefs.getString('contactNumber');
    String? savedPassword = prefs.getString('password');
    if (savedContact != null && savedPassword != null) {
      setState(() {
        _contact.text = savedContact;
        _pwd.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    final contact = _contact.text.trim();
    final password = _pwd.text.trim();

    if (contact.isEmpty || password.isEmpty) {
      _showMessage('الرجاء إدخال رقم الاتصال وكلمة المرور');
      return;
    }

    setState(() => _loading = true);

    try {
      final url = Uri.parse('$alwadehApiUrl/settings.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_number': contact,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Save to shared preferences
          if (_rememberMe) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('contactNumber', contact);
            await prefs.setString('password', password);
            await prefs.setInt('clientId', data['client_id'] ?? 0);
            await prefs.setString('companyName', data['company_name'] ?? '');
            await prefs.setString('contactName', data['contact_name'] ?? '');
            await prefs.setString('vatNumber', data['vat_number'] ?? '');
            await prefs.setString('crNumber', data['cr_number'] ?? '');
            await prefs.setString('terms', data['terms'] ?? '');
            await prefs.setString('buildingNo', data['building_no'] ?? '');
            await prefs.setString('street', data['street'] ?? '');
            await prefs.setString('secondaryNo', data['secondary_no'] ?? '');
            await prefs.setString('district', data['district'] ?? '');
            await prefs.setString('postalCode', data['postal_code'] ?? '');
            await prefs.setString('city', data['city'] ?? '');
            await prefs.setString('environment', data['environment'] ?? '');
            await prefs.setString('authorization', data['authorization'] ?? '');
            await prefs.setString('device', data['device'] ?? '');
            await prefs.setString('logo', data['logo'] ?? '');
            await prefs.setString('terms', data['terms'] ?? '');
            // await prefs.setInt('showAllData', data['showAllData'] ?? 0);
            await prefs.setInt('logoWidth', data['logoWidth'] ?? 75);
            await prefs.setInt('logoHeight', data['logoHeight'] ?? 75);
            await prefs.setString(
                'subscriptionExpiry', data['subscription_expiry'] ?? '');
          }

          // Save to global static class
          Utils.contactNumber = contact;
          Utils.password = password;
          Utils.clientId = data['client_id'] ?? 0;
          Utils.companyName = data['company_name'] ?? '';
          Utils.contactName = data['contact_name'] ?? '';
          Utils.vatNumber = data['vat_number'] ?? '';
          Utils.crNumber = data['cr_number'] ?? '';
          Utils.buildingNo = data['building_no'] ?? '';
          Utils.street = data['street'] ?? '';
          Utils.secondaryNo = data['secondary_no'] ?? '';
          Utils.district = data['district'] ?? '';
          Utils.postalCode = data['postal_code'] ?? '';
          Utils.city = data['city'] ?? '';
          Utils.environment = data['environment'] ?? '';
          Utils.authorization = data['authorization'] ?? '';
          Utils.device = data['device'] ?? '';
          Utils.logo = data['logo'] ?? '';
          Utils.terms = data['terms'] ?? '';
          Utils.logoWidth = data['logoWidth'] ?? 75;
          Utils.logoHeight = data['logoHeight'] ?? 75;
          Utils.device = data['device'] ?? '';
          Utils.subscriptionExpiry =
              Utils.formatDateAM(data['subscription_expiry']);
          _loadSetting();
          await Token().initToken();
          Get.to(() => const HomePage());
        } else {
          _showMessage(data['message'] ?? 'فشل تسجيل الدخول');
        }
      } else {
        _showMessage('حدث خطأ في الاتصال بالخادم');
      }
    } catch (e) {
      _showMessage('خطأ: ${e.toString()}');
    }

    setState(() => _loading = false);
  }

  void _showMessage(String message) {
    ZatcaAPI.errorMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.only(top: 100.0, left: 50, right: 50),
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 80, color: Colors.purple),
                  const SizedBox(height: 16),
                  Text("شاشة الدخول",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _contact,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'رقم الاتصال 05XXXXXXXX',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.isEmpty
                        ? 'أدخل رقم الاتصال بالصيغة 05XXXXXXXX'
                        : null,
                  ),
                  /*
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pwd,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'أدخل كلمة المرور'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (val) {
                          setState(() => _rememberMe = val ?? false);
                        },
                      ),
                      const Text("تذكرني"),
                    ],
                  ),
                  */
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("تسجيل الدخول",
                            style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
