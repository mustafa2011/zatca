import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/product.dart';
import '../widgets/loading.dart';
import '../widgets/setting_form_widget.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String name = ''; // Utils.defUserName;
  String email = 'adm@company.com'; // Utils.defEmail;
  String password = ''; // Utils.defUserPassword;
  String cellphone = ''; // Utils.defCellphone;
  String seller = ''; // Utils.defSellerName;
  String buildingNo = ''; // Utils.defBuildingNo;
  String streetName = ''; // Utils.defStreetName;
  String district = ''; // Utils.defDistrict;
  String city = ''; // Utils.defCity;
  String country = ''; // Utils.defCountry;
  String postalCode = ''; // Utils.defPostcode;
  String additionalNo = ''; // Utils.defAdditionalNo;
  String vatNumber = ''; // Utils.defVatNumber;
  String logo = '';
  String terms = ''; // Utils.defTerms;
  String terms1 = '';
  String terms2 = '';
  String terms3 = '';
  String terms4 = '';
  String terms5 = '';
  String terms6 = '';
  String terms7 = '';
  String terms8 = '';
  String terms9 = '';
  int logoWidth = 75;
  int logoHeight = 75;
  String sheetId = Utils.defSheetId;
  int showVat = 1;
  String paperSize = Utils.defPaperSize;
  String optionsCode = '';
  String defaultPayment = Utils.defPayMethod;
  String language = Utils.defLanguage;
  String freeText2 = Utils.defWhatsApp;
  String freeText3 = Utils.defShowPayMethod;
  String freeText4 = Utils.defDevice;
  String printerName = Utils.defPrinterName;
  String freeText5 = Utils.defActivity;
  String freeText6 = Utils.defSupportNumber;
  String freeText7 = 'يدوي';
  String freeText8 = '';
  String freeText9 = '';
  String freeText10 = '';
  String activationCode = '';
  String startDateTime = DateTime.now().toString();
  String? appVersion = '';
  bool isRegister = true;
  final TextEditingController _supportNumber = TextEditingController();

  @override
  void initState() {
    super.initState();
    _supportNumber.text = Utils.defSupportNumber;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void messageBox(String? message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('رسالة'),
          content: Text(message!),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
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

  Widget buildSupportNumber() => SizedBox(
        width: 200,
        child: TextFormField(
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(),
          controller: _supportNumber,
          autofocus: true,
          textDirection: TextDirection.ltr,
          onTap: () {
            var textValue = _supportNumber.text;
            _supportNumber.selection = TextSelection(
              baseOffset: 0,
              extentOffset: textValue.length,
            );
          },
          style: const TextStyle(
            color: Utils.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          decoration: const InputDecoration(
            labelText: 'رقم الدعم الفني الحالي لصاحب البرنامج',
          ),
        ),
      );

  void updateSupportNumber() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          alignment: Alignment.topCenter,
          actionsAlignment: MainAxisAlignment.center,
          title: const Text('تغيير رقم الدعم الفني',
              style: TextStyle(
                  color: Utils.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            height: 100,
            child: Column(
              children: [
                buildSupportNumber(),
                const Text('للتواصل ارسل واتساب',
                    style: TextStyle(
                        color: Utils.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold))
              ],
            ),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: const Text("موافق"),
              onPressed: () {
                setState(() {
                  freeText6 = _supportNumber.text;
                });
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('تسجيل مستخدم جديد'),
        // leadingWidth: 0,
        backgroundColor: Utils.primary,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: IconButton(
              onPressed: () async {
                setState(() => isLoading = true);
                setState(() => isLoading = false);
              },
              padding: const EdgeInsets.only(left: 15, right: 15),
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Utils.secondary)),
              icon: const Text("تسجيل",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: Container(
            padding: const EdgeInsets.all(10),
            width: w,
            child: isLoading
                ? const Loading()
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: SettingFormWidget(
                            logo: logo,
                            terms: terms,
                            logoWidth: logoWidth,
                            logoHeight: logoHeight,
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
                      ],
                    ),
                  ),
          )),
        ],
      ),
    );
  }

  Future<File> getLogoFile() async {
    final byteData = await rootBundle.load('assets/images/logo.png');

    final file = File('${(await getTemporaryDirectory()).path}/logo.png');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  void downloadProductsFromServer(String activity) async {
    try {
      setState(() => isLoading = true);
      // Make HTTP request to fetch products from server
      var response = await http.post(
        Uri.parse('https://alwadeh.net/fatoora/downloadProductsToLocal.php'),
        body: {'activity': activity}, // Pass activity in the request body
      );

      // Check if request was successful (status code 200)
      if (response.statusCode == 200) {
        // Parse the JSON response body
        dynamic data = json.decode(response.body);

        // Check if data is a list and not empty
        if (data is List && data.isNotEmpty) {
          // Map JSON data to Product objects
          List<Product> downloadedProducts = [];
          // = data.map((json) => Product.fromJson(json)).toList();
          for (int i = 0; i < data.length; i++) {
            downloadedProducts.add(Product(
              productName: data[i]["productName"],
              price: num.parse(data[i]["price"]),
              // unit: data[i]["unit"],
              // barcode: data[i]["barcode"],
            ));
          }
          // Insert downloaded products into SQLite database
          for (var product in downloadedProducts) {
            await FatooraDB.instance.createProduct(product);
          }
        }
      } else {
        // Display an error message if the request was not successful
        messageBox("فشل في تحميل المنتجات ${response.statusCode}");
      }
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      // Handle errors
      messageBox("حدث خطأ أثناء تنزيل المنتجات:\n $e");
    }
  }
}
