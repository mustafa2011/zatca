import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zatca/helpers/zatca_api.dart';

import '/models/settings.dart';
import '/widgets/loading.dart';
import '/widgets/setting_form_widget.dart';
import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../widgets/widget.dart';
import 'home.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Setting? setting;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String logo = Utils.logo;
  String terms = Utils.terms;
  int logoWidth = Utils.logoWidth;
  int logoHeight = Utils.logoHeight;
  int _showAllData = Utils.showAllData; // local copy for UI
  @override
  void initState() {
    super.initState();
    _loadCurrentSetting();
  }

  Future<void> _loadCurrentSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAllData = prefs.getInt('showAllData') ?? 1;
    });
  }

  Future<void> _updateShowAllData(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('showAllData', value);

    setState(() {
      _showAllData = value;
      Utils.showAllData = value; // update global static
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return Scaffold(
        // resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('شاشة الإعدادات'),
          leading: Container(),
          leadingWidth: 0,
          backgroundColor: Utils.primary,
          foregroundColor: Colors.white,
          actions: [
            backHome,
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: selectAndReplaceDb,
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Utils.primary),
                  foregroundColor: WidgetStateProperty.all(Colors.white)),
              child: Text("استيراد ملف بيانات"),
            ),
            TextButton(
              onPressed: () {
                setState(() => isLoading = true);
                String dt = DateFormat('yyyyMMdd').format(DateTime.now());
                backupDatabase('fatoora_${Utils.clientId}_$dt.db');
                setState(() => isLoading = false);
              },
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Utils.primary),
                  foregroundColor: WidgetStateProperty.all(Colors.white)),
              child: Text("تصدير ملف بيانات"),
            ),
          ],
        ),
        body: Container(
          width: w,
          color: Utils.background,
          child: Column(
            children: [
              RadioGroup<int>(
                groupValue: _showAllData,
                onChanged: (value) {
                  setState(() => _showAllData = value!);
                  if (value != null) _updateShowAllData(value);
                },
                child: const RadioListTile<int>(
                  dense: true,
                  title: Text(
                    'اظهار بيانات السنة الحالية',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: 0,
                ),
              ),
              RadioGroup<int>(
                groupValue: _showAllData,
                onChanged: (value) {
                  setState(() => _showAllData = value!);
                  if (value != null) _updateShowAllData(value);
                },
                child: const RadioListTile<int>(
                  dense: true,
                  title: Text(
                    'اظهار جميع البيانات',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: 1,
                ),
              ),
              Expanded(
                  child: Container(
                padding: const EdgeInsets.all(10),
                width: w,
                child: isLoading
                    ? const Loading()
                    : Form(
                        key: _formKey,
                        child: SettingFormWidget(
                          logo: Utils.logo,
                          terms: Utils.terms,
                          logoWidth: Utils.logoWidth,
                          logoHeight: Utils.logoHeight,
                          onChangedLogo: (logo) =>
                              setState(() => this.logo = logo),
                          onChangedTerms: (terms) =>
                              setState(() => this.terms = terms),
                          onChangedLogoWidth: (logoWidth) => setState(
                              () => this.logoWidth = int.parse(logoWidth)),
                          onChangedLogoHeight: (logoHeight) => setState(
                              () => this.logoHeight = int.parse(logoHeight)),
                        ),
                      ),
              )),
            ],
          ),
        ));
  }

  Future<File> getLogoFile(ByteData byteData) async {
    final byteData = await rootBundle.load('assets/images/logo.png');

    final file = File('${(await getTemporaryDirectory()).path}/logo.png');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  Future updateSetting() async {
    try {
      if (logo == "") {
        setState(() {
          logo = Utils.logo;
        });
      }
      var user = Setting(
        id: Utils.clientId,
        logo: logo,
        terms: terms,
        logoWidth: logoWidth,
        logoHeight: logoHeight,
      );
      await FatooraDB.instance.updateSetting(user);
      Get.to(() => const HomePage());
    } on Exception catch (e) {
      ZatcaAPI.errorMessage("تأكد من وجود اتصال بالانترنت\n$e");
    }
  }

  Future<void> backupDatabase(String filename) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    // Sanitize filename for Windows
    String safeFilename = filename.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');

    String source = "${appDirectory.path}${slash}Database${slash}fatoora.db";
    String backup = "${appDirectory.path}${slash}Database$slash$safeFilename";

    await File(source).copy(backup);

    if (Platform.isAndroid) {
      SharePlus.instance.share(
        ShareParams(
          text: "مشاركة",
          files: [XFile(backup)],
        ),
      );
    } else if (Platform.isWindows) {
      ZatcaAPI.errorMessage("تم نسخ الملف بالمسار\n$backup");
    }
  }

  Future<void> selectAndReplaceDb() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await FatooraDB.instance.replaceDatabaseSafely(file);
    } else {
      ZatcaAPI.errorMessage('❌ لم يتم اختيار أي ملف');
    }
  }
}
