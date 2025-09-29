import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void messageBox(String title, String? message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message!),
          actions: <Widget>[
            TextButton(
              child: const Text("موافق"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
            /*
            IconButton(
                onPressed: selectAndReplaceDb,
                tooltip: "استيراد ملف بيانات",
                icon: Icon(
                  Icons.file_download_outlined,
                  color: Colors.white,
                  size: 35,
                )),
            IconButton(
                onPressed: () {
                  setState(() => isLoading = true);
                  String dt = DateFormat('yyyyMMdd').format(DateTime.now());
                  backupDatabase('fatoora_${Utils.clientId}_$dt.db');
                  setState(() => isLoading = false);
                },
                tooltip: "تصدير ملف بيانات",
                icon: Icon(
                  Icons.file_upload_outlined,
                  color: Colors.white,
                  size: 35,
                )),
            */
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

            /*
            NewButton(
              text: 'حفظ الاعدادات',
              onTap: () async {
                setState(() => isLoading = true);
                await updateSetting();
                setState(() => isLoading = false);
                ZatcaAPI.successMessage("تم حفظ الاعدادات");
              },
            ),
            NewButton(
              text: 'تغيير الشعار',
              onTap: () async {
                File? customImageFile;
                if (Platform.isWindows) {
                  var image = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'png', 'jpeg'],
                  );
                  customImageFile = image != null
                      ? File(image.files.first.path.toString())
                      : File(
                          '${(await getTemporaryDirectory()).path}/logo.png');
                } else {
                  var img = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  customImageFile = File(img!.path);
                }
                String imgString =
                    base64Encode(customImageFile.readAsBytesSync());
                setState(() {
                  logo = imgString;
                });
              },
            ),
            NewButton(
              text: 'الرئيسية',
              onTap: () async {
                setState(() => isLoading = true);
                Get.to(() => const HomePage());
                setState(() => isLoading = false);
              },
            ),
            */
          ],
        ),
        body: Container(
          width: w,
          color: Utils.background,
          child: Column(
            children: [
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
      messageBox('تنبيه', "تأكد من وجود اتصال بالانترنت\n$e");
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
