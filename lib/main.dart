import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/token.dart';
import '../helpers/utils.dart';
import '../screens/login.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Token().initToken();
  final tokenInfo = await Token().getTokenInfo();
  await prefs.setString('expiry', tokenInfo);
  final docDir = await getApplicationDocumentsDirectory();
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await Utils.createNewDirectory("${docDir.path}${slash}Database");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      // supportedLocales: const [Locale('en'), Locale('ar')],
      title: 'FATOORA',
      theme: ThemeData(
        // fontFamily: 'Cairo',
        primarySwatch: Colors.orange,
        primaryColor: Utils.primary,
        primaryColorLight: Utils.secondary,
        scaffoldBackgroundColor: Utils.background,
        appBarTheme: AppBarTheme(
          backgroundColor: Utils.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'NotoKufi',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const LoginPage(),
    );
  }
}
