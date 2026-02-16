import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/customers.dart';
import '../models/purchase.dart';
import '../models/suppliers.dart';
import '../pdf/pdf_api.dart';

class PdfPurchaseApi {
  static Future<File> generate(Purchase purchase, String title) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load(tahoma)),
      bold: Font.ttf(await rootBundle.load(notoBold)),
    );
    final pdf = Document(theme: myTheme);
    final suppliers = await FatooraDB.instance.getAllSuppliers();

    pdf.addPage(Page(
      margin: const EdgeInsets.all(30),
      // pageFormat: PdfPageFormat.a4,
      build: (context) => Column(children: [
        buildHeader(purchase, title),
        buildPurchase(purchase, suppliers),
        buildLine(),
      ]),
    ));

    return PdfApi.previewPurchase(purchase: purchase, pdf: pdf);
  }

  static Future<String> getCustomerName(int? id) async {
    Customer customer = await FatooraDB.instance.getCustomerById(id!);
    return customer.name;
  }

  static Widget buildHeader(Purchase purchase, String title) => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildLogo(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Utils.companyName,
                    textDirection: TextDirection.rtl,
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Row(children: [
                  Text(Utils.vatNumber,
                      textDirection: TextDirection.rtl,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(width: 2 * PdfPageFormat.mm),
                  Text('رقم ضريبي',
                      textDirection: TextDirection.rtl,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ]),
            ],
          ),
          Text(title,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('${purchase.id!}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: PdfColors.red)),
        ],
      );

  static Widget buildLine() => Container(height: 1, color: PdfColors.grey);

  static Widget buildLogo() => Container(
      width: Utils.logoWidth.toDouble(),
      height: Utils.logoHeight.toDouble(),
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill, image: MemoryImage(base64Decode(Utils.logo)))));

  static Widget buildPurchase(Purchase purchase, List<Supplier> suppliers) {
    String purchaseDate = Utils.formatShortDate(DateTime.parse(purchase.date));
    String vendorName(int vendorId) {
      var supplier =
          suppliers.firstWhere((supplier) => supplier.id == vendorId);
      return supplier.name;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      buildSimpleText(title: 'التاريخ', value: purchaseDate),
      SizedBox(height: 1 * PdfPageFormat.mm),
      buildSimpleText(
          title: 'المورد', value: vendorName(int.parse(purchase.vendor))),
      buildSimpleText(
          title: 'الرقم الضريبي للمورد', value: purchase.vendorVatNumber),
      SizedBox(height: 1 * PdfPageFormat.mm),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        buildSimpleText(
            title: 'الضريبة', value: Utils.format(purchase.totalVat)),
        buildSimpleText(
            title: 'اجمالي الفاتورة', value: Utils.format(purchase.total)),
      ]),
      SizedBox(height: 1 * PdfPageFormat.mm),
      buildSimpleText(title: 'طريقة الدفع', value: purchase.paymentMethod),
      SizedBox(height: 1 * PdfPageFormat.mm),
      buildSimpleText(title: 'تفاصيل المشتريات', value: purchase.details),
      SizedBox(height: 3 * PdfPageFormat.mm),
    ]);
  }

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final styleTitle = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
    const styleValue = TextStyle(fontSize: 14);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, textDirection: TextDirection.rtl, style: styleValue),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(title, textDirection: TextDirection.rtl, style: styleTitle),
      ],
    );
  }
}
