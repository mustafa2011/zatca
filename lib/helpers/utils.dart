import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:number_to_word_arabic/number_to_word_arabic.dart';

String slash = Platform.isWindows ? "\\" : "/";
const notoBold = "assets/fonts/NotoKufiArabic-Bold.ttf";
const tahoma = "assets/fonts/Tahoma.ttf";

class Utils {
  static int clientId = 0;
  static String companyName = '';
  static String vatNumber = '';
  static String crNumber = '';
  static String buildingNo = '';
  static String street = '';
  static String secondaryNo = '';
  static String district = '';
  static String postalCode = '';
  static String city = '';
  static String contactNumber = '';
  static String contactName = '';
  static String password = '';
  static String subscriptionExpiry = '';
  static String environment = '';
  static String authorization = '';
  static String device = '';
  static String logo = '';
  static int logoWidth = 75;
  static int logoHeight = 75;
  static String terms = '';

  static const Color primary = Color(0xFF57007F);
  static const Color secondary = Color(0xFFFF9800);
  static const Color background = Color(0xFFE5E5E5);
  static const Color button = Color(0xFF6F746F);

  static Future<Directory> createNewDirectory(String strPath) async {
    final newDirectory = Directory(strPath);
    if (!(await newDirectory.exists())) {
      await newDirectory.create();
    }
    return newDirectory;
  }

  static formatPrice(num price) => price.toStringAsFixed(2);

  static formatPercent(double percent) => '%${percent.toStringAsFixed(0)}';

  static formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd HH:mm').format(date);

  static formatDateAM(String date) =>
      DateFormat('dd-MM-yyyy').format(DateTime.parse(date));

  static formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  static formatShortDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static format(num price) => NumberFormat("#,##0.00 SR").format(price);

  static format00(int intNumber) => NumberFormat("00").format(intNumber);

  static formatCellphone(String cellphone) {
    if (cellphone.length == 10 && cellphone.substring(0, 1) == "0") {
      cellphone = "966${cellphone.substring(1, 10)}";
    }
    return cellphone;
  }

  static formatNoCurrency(num price) => NumberFormat("#0.00").format(price);

  static formatNoCurrencyNoComma(num price) =>
      NumberFormat("#0.00").format(price);

  static Image imageFromBase64String(String base64String) =>
      Image.memory(base64Decode(base64String), fit: BoxFit.fill);

  static bool isProVersion = true;
  static bool isA4Invoice = true;
  static bool isOilServices = true;
  static bool isLaundry = false;

  ///Default settings
  static String defUserName = 'مستخدم عام';
  static String defUserPassword = '123';
  static String defSellerName = 'الواضح تقنية معلومات';
  static String defEmail = 'adm@gmail.com';
  static String defCellphone = '0502300618';
  static String defBuildingNo = '46';
  static String defStreetName = 'طريق الملك فهد';
  static String defDistrict = 'حي عتيقة';
  static String defCity = 'الرياض';
  static String defCountry = 'السعودية';
  static String defPostcode = '1111';
  static String defAdditionalNo = '1234';
  static String defVatNumber = '300005555500003';
  static String defTerms = 'الأسعار بالريال وتشمل الضريبة';
  static String defSheetId = '1uA1Yib05DypFgGnv6r77KoqRwgbP3r9Oz1uXy_NpQG4';
  static String defSupportNumber = '966502300618'; // owner
  static String defPayMethod = 'شبكة';
  static String defShowPayMethod = 'اظهار';
  static String defDevice = 'Mobile';
  static String defActivity = 'أخرى';
  static String defPaperSize = 'a4';
  static String defPrinterName = 'IposPrinter';
  static String defLanguage = 'Arabic';
  static String defWhatsApp = 'واتساب';
  static String defFullSupportNumber = '966502300618'; // Reseller #1
  /// End of default settings

  static Widget space(double height, double width) =>
      SizedBox(height: height * 5, width: width * 5);

  static String numToWord(String number) {
    String newNumber = number;
    String numInWord = '';
    num numberBeforeDot =
        num.parse(newNumber.split('.')[0].replaceAll(",", ""));
    num numberAfterDot = newNumber.contains('.')
        ? num.parse(newNumber.split('.')[1].replaceAll(",", ""))
        : 00;
    numInWord = Tafqeet.convert(numberBeforeDot.toString());
    numInWord += ' ريال';
    numInWord += numberAfterDot > 0 ? ' و' : '';
    numInWord +=
        numberAfterDot > 0 ? Tafqeet.convert(numberAfterDot.toString()) : '';
    numInWord += numberAfterDot > 0 ? ' هللة' : '';

    return numInWord;
  }
}
