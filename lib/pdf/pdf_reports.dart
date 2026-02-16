import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../helpers/utils.dart';
import '../models/invoice.dart';
import '../models/purchase.dart';
import '../pdf/pdf_api.dart';

class PdfReport {
  static Future<File> generateDailyReport(
      {required List<Invoice> invoices,
      required String reportTitle,
      required String dateFrom,
      required String dateTo,
      required List<Purchase> purchases,
      required bool isDemo}) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load(tahoma)),
      bold: Font.ttf(await rootBundle.load(notoBold)),
    );
    final pdf = Document(theme: myTheme);
    pdf.addPage(MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
              buildTitle(reportTitle, dateFrom, dateTo),
              Divider(),
              buildBody(invoices, dateFrom, dateTo, purchases, reportTitle),
              Divider(),
              buildTotal(invoices, purchases, reportTitle),
            ],
        footer: (context) {
          return isDemo
              ? Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    UrlLink(
                        destination:
                            'https://wa.me/${Utils.defFullSupportNumber}',
                        child: Row(children: [
                          Text("ارسل رسالة واتساب للدعم الفني",
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PdfColors.blue))
                        ])),
                    SizedBox(width: 5),
                    Text("نسخة تجريبية",
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: PdfColors.red)),
                  ]),
                  UrlLink(
                      destination:
                          'https://wa.me/${Utils.defFullSupportNumber}',
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(Utils.defSupportNumber,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: PdfColors.blue)),
                            SizedBox(width: 5),
                            Text("رقم الدعم الفني",
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: PdfColors.blue))
                          ])),
                ])
              : Container(
                  alignment: Alignment.center,
                  child: Text(
                      "صفحة ${context.pagesCount}/${context.pageNumber}",
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: PdfColors.black)));
        }));
    final reportPrefix = reportTitle == 'تقرير مبيعات اليوم'
        ? 'R1'
        : reportTitle == 'تقرير مبيعات فترة'
            ? 'R2'
            : 'R3';
    return PdfApi.savePreviewDailyReport(
        name: Utils.formatShortDate(DateTime.now()) + '[$reportPrefix].pdf',
        pdf: pdf);
  }

  static Future<File> generateCustomerStatementReport(
      {required List<Map<String, dynamic>> data,
      required String reportTitle,
      required String dateFrom,
      required String dateTo,
      required bool isDemo}) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load(tahoma)),
      bold: Font.ttf(await rootBundle.load(notoBold)),
    );
    final pdf = Document(theme: myTheme);
    pdf.addPage(MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        // buildTitle(reportTitle, dateFrom, dateTo),

        buildBody1(data, dateFrom, dateTo, reportTitle),
        Divider(),
        buildTotal1(data),
      ],
      header: (context) => Column(children: [
        buildTitle(reportTitle, dateFrom, dateTo),
        Divider(),
      ]),
      footer: (context) {
        return isDemo
            ? Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  UrlLink(
                      destination:
                          'https://wa.me/${Utils.defFullSupportNumber}',
                      child: Row(children: [
                        Text("ارسل رسالة واتساب للدعم الفني",
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: PdfColors.blue))
                      ])),
                  SizedBox(width: 5),
                  Text("نسخة تجريبية",
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PdfColors.red)),
                ]),
                UrlLink(
                    destination: 'https://wa.me/${Utils.defFullSupportNumber}',
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(Utils.defSupportNumber,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PdfColors.blue)),
                          SizedBox(width: 5),
                          Text("رقم الدعم الفني",
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PdfColors.blue))
                        ])),
              ])
            : Container(
                alignment: Alignment.center,
                child: Text("صفحة ${context.pagesCount}/${context.pageNumber}",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PdfColors.black)));
      },
    ));

    return await PdfApi.savePreviewDailyReport(
        name: '$reportTitle[${Utils.formatShortDate(DateTime.now())}].pdf',
        pdf: pdf);
  }

  static Widget buildBody1(List<Map<String, dynamic>> data, String dateFrom,
      String dateTo, String reportTitle) {
    int length = data.length;
    return Container(
      child: Column(children: [
        Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Container(
                  width: 75,
                  child: buildNormalText(
                      text: 'عليه', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 75,
                  child:
                      buildNormalText(text: 'له', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 235,
                  child: buildNormalText(
                      text: 'الشرح', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
              ]),
              Container(
                width: 70,
                child: buildNormalText(
                    text: 'التاريخ', fontWeight: FontWeight.bold),
              ),
            ])),
        Divider(),
        for (int index = 0; index < length; index++)
          Container(
              height: 30,
              color: index % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Container(
                        width: 75,
                        child: buildNormalText(
                            text: Utils.formatNoCurrency(data[index]['debit'])),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 75,
                        child: buildNormalText(
                            text:
                                Utils.formatNoCurrency(data[index]['credit'])),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 235,
                        child:
                            buildNormalText(text: data[index]['description']),
                      ),
                    ]),
                    Container(
                      width: 70,
                      child: buildNormalText(
                          text: data[index]['date'].substring(0, 10)),
                    ),
                  ])),
      ]),
    );
  }

  static Widget buildTotal1(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return buildNormalText(
        text: '0',
        fontWeight: FontWeight.bold,
      );
    }

    final double finalBalance = (data.last['balance'] as num).toDouble();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 75,
              child: buildNormalText(
                text: Utils.formatNoCurrency(
                    finalBalance < 0 ? -finalBalance : finalBalance),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 2),
            SizedBox(
              width: 75,
              child: buildNormalText(
                text: finalBalance > 0
                    ? 'الرصيد عليه'
                    : finalBalance < 0
                        ? 'الرصيد له'
                        : 'الرصيد',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildTitle(
          String reportTitle, String dateFrom, String dateTo) =>
      Center(
        child: Column(children: [
          Text(reportTitle,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          dateFrom == dateTo
              ? Text(dateFrom)
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(dateTo),
                  Text(" : "),
                  Text(dateFrom),
                ]),
        ]),
      );

  static Widget buildHeader(
          String reportTitle, String dateFrom, String dateTo) =>
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          width: 45,
          child: buildNormalText(text: 'الاجمالي', fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 1),
        Container(
          width: 45,
          child: buildNormalText(text: 'الضريبة', fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 1),
        dateFrom == dateTo
            ? Container()
            : Container(
                width: 66,
                child: buildNormalText(
                    text: 'التاريخ', fontWeight: FontWeight.bold),
              ),
        dateFrom == dateTo ? Container() : SizedBox(width: 2),
        Container(
          width: dateFrom == dateTo ? 100 : 40,
          child: buildNormalText(text: 'الفاتورة', fontWeight: FontWeight.bold),
        ),
      ]);

  static Widget buildBody(List<Invoice> invoices, String dateFrom,
      String dateTo, List<Purchase> purchases, String reportTitle) {
    int length = reportTitle == 'تقرير مشتريات فترة'
        ? purchases.length
        : invoices.length;
    return Container(
      child: Column(children: [
        Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Container(
                  width: 75,
                  child: buildNormalText(
                      text: 'الاجمالي', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 75,
                  child: buildNormalText(
                      text: 'الضريبة', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 75,
                  child: buildNormalText(
                      text: 'المبلغ', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 0,
                  child: buildNormalText(text: '', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 0,
                  child: buildNormalText(text: '', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 45,
                  child: buildNormalText(text: '', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
                Container(
                  width: 45,
                  child: buildNormalText(text: '', fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1),
              ]),
              Container(
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                dateFrom == dateTo
                    ? Container()
                    : Container(
                        width: 66,
                        child: buildNormalText(
                            text: 'التاريخ', fontWeight: FontWeight.bold),
                      ),
                dateFrom == dateTo ? Container() : SizedBox(width: 2),
                Container(
                  width: 70,
                  child: buildNormalText(
                      text: 'الفاتورة', fontWeight: FontWeight.bold),
                ),
              ])),
            ])),
        Divider(),
        for (int index = 0; index < length; index++)
          Container(
              color: index % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Container(
                        width: 75,
                        child: buildNormalText(
                            text: Utils.formatNoCurrency(
                                reportTitle == 'تقرير مشتريات فترة'
                                    ? purchases[index].total
                                    : invoices[index].total)),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 75,
                        child: buildNormalText(
                            text: Utils.formatNoCurrency(
                                reportTitle == 'تقرير مشتريات فترة'
                                    ? purchases[index].totalVat
                                    : invoices[index].totalVat)),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 75,
                        child: buildNormalText(
                            text: Utils.formatNoCurrency(
                                reportTitle == 'تقرير مشتريات فترة'
                                    ? purchases[index].total -
                                        purchases[index].totalVat
                                    : invoices[index].total -
                                        invoices[index].totalVat)),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 0,
                        child: buildNormalText(text: ''),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 0,
                        child: buildNormalText(text: ''),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 45,
                        child: buildNormalText(text: ''),
                      ),
                      SizedBox(width: 1),
                      Container(
                        width: 45,
                        child: buildNormalText(text: ''),
                      ),
                      SizedBox(width: 1),
                    ]),
                    Container(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                          dateFrom == dateTo
                              ? Container()
                              : Container(
                                  width: 66,
                                  child: buildNormalText(
                                      text: reportTitle == 'تقرير مشتريات فترة'
                                          ? purchases[index]
                                              .date
                                              .substring(0, 10)
                                          : invoices[index]
                                              .date
                                              .substring(0, 10)),
                                ),
                          dateFrom == dateTo ? Container() : SizedBox(width: 2),
                          Container(
                            width: 70,
                            child: buildNormalText(
                                text: reportTitle == 'تقرير مشتريات فترة'
                                    ? purchases[index].id.toString()
                                    : "${invoices[index].invoiceNo} ${invoices[index].paymentMethod}"),
                          ),
                        ])),
                  ])),
      ]),
    );
  }

  static Widget buildTotal(
      List<Invoice> invoices, List<Purchase> purchases, String reportTitle) {
    double total = 0;
    double totalCash = 0;
    double totalNetwork = 0;
    double totalTransfer = 0;
    double totalCredit = 0;
    double vat = 0;
    double vatCash = 0;
    double vatNetwork = 0;
    double vatTransfer = 0;
    double vatCredit = 0;
    int length = reportTitle == 'تقرير مشتريات فترة'
        ? purchases.length
        : invoices.length;
    for (int i = 0; i < length; i++) {
      total = total +
          (reportTitle == 'تقرير مشتريات فترة'
              ? purchases[i].total
              : invoices[i].total);
      vat = vat +
          (reportTitle == 'تقرير مشتريات فترة'
              ? purchases[i].totalVat
              : invoices[i].totalVat);
      if (reportTitle != 'تقرير مشتريات فترة') {
        totalCash = totalCash +
            (invoices[i].paymentMethod == 'كاش' ? invoices[i].total : 0);
        totalNetwork = totalNetwork +
            (invoices[i].paymentMethod == 'شبكة' ? invoices[i].total : 0);
        totalTransfer = totalTransfer +
            (invoices[i].paymentMethod == 'حوالة' ? invoices[i].total : 0);
        totalCredit = totalCredit +
            (invoices[i].paymentMethod == 'آجل' ? invoices[i].total : 0);
        vatCash = vatCash +
            (invoices[i].paymentMethod == 'كاش' ? invoices[i].totalVat : 0);
        vatNetwork = vatNetwork +
            (invoices[i].paymentMethod == 'شبكة' ? invoices[i].totalVat : 0);
        vatTransfer = vatTransfer +
            (invoices[i].paymentMethod == 'حوالة' ? invoices[i].totalVat : 0);
        vatCredit = vatCredit +
            (invoices[i].paymentMethod == 'آجل' ? invoices[i].totalVat : 0);
      }
    }
    return reportTitle == 'تقرير مشتريات فترة'
        ? Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(total),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(vat),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: 'الإجمالي', fontWeight: FontWeight.bold),
              ),
            ]),
          ])
        : Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(total),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(vat),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: 'الإجمالي', fontWeight: FontWeight.bold),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(totalCash),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(vatCash),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child:
                    buildNormalText(text: 'كاش', fontWeight: FontWeight.normal),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(totalNetwork),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(vatNetwork),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: 'شبكة', fontWeight: FontWeight.normal),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(totalTransfer),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(vatTransfer),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: 'حوالة', fontWeight: FontWeight.normal),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(totalCredit),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child: buildNormalText(
                    text: Utils.formatNoCurrency(vatCredit),
                    fontWeight: FontWeight.normal),
              ),
              SizedBox(width: 2),
              Container(
                width: 75,
                child:
                    buildNormalText(text: 'آجل', fontWeight: FontWeight.normal),
              ),
            ]),
          ]);
  }

  static buildSimpleText({required String title, required String value}) {
    final styleTitle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    const styleValue = TextStyle(fontSize: 12);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            textDirection: TextDirection.rtl, style: styleValue, maxLines: 2),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(title, textDirection: TextDirection.rtl, style: styleTitle),
      ],
    );
  }

  static buildNormalText(
      {required String text,
      TextAlign align = TextAlign.right,
      FontWeight fontWeight = FontWeight.normal}) {
    final style = TextStyle(fontWeight: fontWeight, fontSize: 10);
    return Container(
        child: Text(text,
            textDirection: TextDirection.rtl, style: style, textAlign: align));
  }
}
