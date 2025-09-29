import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/customers.dart';
import '../models/receipt.dart';
import '../pdf/pdf_api.dart';

class PdfReceiptApi {
  static Future<File> generate(Receipt receipt, String title) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load(tahoma)),
      bold: Font.ttf(await rootBundle.load(notoBold)),
    );
    final pdf = Document(theme: myTheme);
    pdf.addPage(Page(
      margin: const EdgeInsets.all(30),
      // pageFormat: PdfPageFormat.a4,
      build: (context) => Column(children: [
        buildHeader(receipt, title),
        buildReceipt(receipt),
        buildLine(),
        buildFooter(receipt)
      ]),
    ));

    return PdfApi.previewReceipt(receipt: receipt, pdf: pdf);
  }

  static Future<String> getCustomerName(int? id) async {
    Customer customer = await FatooraDB.instance.getCustomerById(id!);
    return customer.name;
  }

  static Widget buildFooter(Receipt receipt) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      SizedBox(
          width: 150,
          child: Column(children: [
            Text('المستلم',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            receipt.receiptType == "قبض"
                ? Text(Utils.contactName,
                    // textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.normal))
                : Container(),
          ])),
      Text(''),
    ]);
  }

  static Widget buildHeader(Receipt receipt, String title) => Column(
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
          Text('${receipt.id!}',
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

  static Widget buildReceipt(Receipt receipt) {
    String receiptDate = Utils.formatShortDate(DateTime.parse(receipt.date));
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        buildSimpleText(title: 'التاريخ', value: receiptDate),
        buildSimpleText(title: 'المبلغ', value: Utils.format(receipt.amount)),
      ]),
      SizedBox(height: 1 * PdfPageFormat.mm),
      receipt.receiptType == "قبض"
          ? buildSimpleText(title: 'استلمنا من', value: receipt.receivedFrom)
          : buildSimpleText(title: 'صرفنا إلى', value: receipt.payTo),
      SizedBox(height: 1 * PdfPageFormat.mm),
      buildSimpleText(title: 'مبلغاً وقدره', value: receipt.sumOf),
      SizedBox(height: 1 * PdfPageFormat.mm),
      buildSimpleText(title: 'طريقة الدفع', value: receipt.payType),
      SizedBox(height: 1 * PdfPageFormat.mm),
      /*
      receipt.payType == 'شيك'
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              buildSimpleText(title: 'على بنك', value: receipt.bank),
              buildSimpleText(title: 'وتاريخ', value: receipt.chequeDate),
              buildSimpleText(title: 'رقم', value: receipt.chequeNo),
            ])
          : receipt.payType == 'حوالة'
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      buildSimpleText(title: 'على بنك', value: receipt.bank),
                      buildSimpleText(
                          title: 'وتاريخ', value: receipt.transferDate),
                      buildSimpleText(title: 'رقم', value: receipt.transferNo),
                    ])
              : Container(),
      receipt.payType == 'نقدا'
          ? Container()
          : SizedBox(height: 1 * PdfPageFormat.mm),
      */
      buildSimpleText(title: 'وذلك عن', value: receipt.amountFor),
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
