import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:zatca/helpers/fatoora_db.dart';
import 'package:zatca/models/customers.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/settings.dart';

import '../helpers/utils.dart';

class PdfInvoiceApi {
  static Future<File> generate(
      Invoice invoice,
      Customer customer,
      List<InvoiceLines> invoiceLines,
      String title,
      String subTitle,
      bool isPreview,
      {bool isEstimate = false}) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load("assets/fonts/Tahoma.ttf")),
      bold: Font.ttf(await rootBundle.load("assets/fonts/Cairo-Bold.ttf")),
    );
    final pdf = Document(theme: myTheme);
    pdf.addPage(MultiPage(
        margin: const EdgeInsets.all(30),
        build: (context) => [
              buildHeader(
                  invoice, customer, title, subTitle, isPreview, isEstimate),
              SizedBox(height: 0.75 * PdfPageFormat.cm),
              buildInvoice(invoice, invoiceLines),
              // Divider(),
              buildTotal(invoice),
              buildTerms(),
            ],
        footer: (context) {
          return Container(
              alignment: Alignment.center,
              child: Text("صفحة${context.pagesCount}/${context.pageNumber}",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black)));
        }));
    final bytes = await pdf.save();
    String name = isEstimate ? 'ESTIMATE.pdf' : 'INVOICE.pdf';
    File file;
    final docDir = await getApplicationDocumentsDirectory();
    try {
      file = File('${docDir.path}/$name');
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw Exception(e);
    }
    return file;
  }

  static Future<File> generateCreditNote(Invoice invoice, Customer customer,
      String title, String subTitle, bool isPreview,
      {bool isEstimate = false}) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load("assets/fonts/Tahoma.ttf")),
      bold: Font.ttf(await rootBundle.load("assets/fonts/Cairo-Bold.ttf")),
    );
    final pdf = Document(theme: myTheme);
    pdf.addPage(MultiPage(
        margin: const EdgeInsets.all(30),
        build: (context) => [
              buildHeader(
                  invoice, customer, title, subTitle, isPreview, isEstimate),
              SizedBox(height: 0.75 * PdfPageFormat.cm),
              // Divider(),
              buildTotal(invoice),
              // buildTerms(),
            ],
        footer: (context) {
          return Container(
              alignment: Alignment.center,
              child: Text("صفحة${context.pagesCount}/${context.pageNumber}",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black)));
        }));
    final bytes = await pdf.save();
    String name = isEstimate ? 'ESTIMATE.pdf' : 'CREDIT_NOTE.pdf';
    File file;
    final docDir = await getApplicationDocumentsDirectory();
    try {
      file = File('${docDir.path}/$name');
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw Exception(e);
    }
    return file;
  }

  static Future<String> getCustomerName(int? id) async {
    Customer customer = await FatooraDB.instance.getCustomerById(id!);
    return customer.name;
  }

  static Widget buildHeader(Invoice invoice, Customer customer, String title,
          String subTitle, bool isPreview, bool isEstimate) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            buildLogo(),
            buildTitle(invoice, title, subTitle, isEstimate),
          ]),
          Divider(),
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.end,
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     buildInvoiceInfo(invoice, title, isEstimate),
          //     Container(),
          //     // buildCustomerAddress(invoice.customer),
          //   ],
          // ),
          SizedBox(height: 0.75 * PdfPageFormat.cm),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: PdfColors.grey600,
                    width: 1,
                  ),
                ),
              ),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  width: 260,
                  color: PdfColors.grey300,
                  child: Text('بيانات المورد',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                buildSimpleText(title: 'اسم المورد:', value: Utils.companyName),
                buildSimpleText(
                    title: 'الرقم الضريبي:', value: Utils.vatNumber),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 110,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildSimpleText(
                                  title: 'رقم المبنى:',
                                  value: Utils.buildingNo),
                              buildSimpleText(
                                  title: 'الحي:', value: Utils.district),
                              buildSimpleText(
                                  title: 'البلد:', value: 'السعودية'),
                              buildSimpleText(
                                  title: 'الرقم الإضافي:',
                                  value: Utils.secondaryNo),
                            ]),
                      ),
                      Container(
                        width: 150,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              buildSimpleText(
                                  title: 'رقم الاتصال:',
                                  value: Utils.contactNumber),
                              buildSimpleText(
                                  title: 'الشارع:', value: Utils.street),
                              buildSimpleText(
                                  title: 'المدينة:', value: Utils.city),
                              buildSimpleText(
                                  title: 'رمز البريد:',
                                  value: Utils.postalCode),
                            ]),
                      ),
                    ]),
              ]),
            ),
            SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: PdfColors.grey600,
                    width: 1,
                  ),
                ),
              ),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  width: 260,
                  color: PdfColors.grey300,
                  child: Text('بيانات العميل',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                buildSimpleText(title: 'اسم العميل:', value: customer.name),
                buildSimpleText(
                    title: 'الرقم الضريبي:', value: customer.vatNumber),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 110,
                        child: Column(children: [
                          buildSimpleText(
                              title: 'رقم المبنى:', value: customer.buildingNo),
                          buildSimpleText(
                              title: 'الحي:', value: customer.district),
                          buildSimpleText(
                              title: 'البلد:', value: customer.country),
                          buildSimpleText(
                              title: 'الرقم الإضافي:',
                              value: customer.additionalNo),
                        ]),
                      ),
                      Container(
                        width: 150,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              buildSimpleText(
                                  title: 'رقم الاتصال:',
                                  value: customer.contactNumber),
                              buildSimpleText(
                                  title: 'الشارع:', value: customer.streetName),
                              buildSimpleText(
                                  title: 'المدينة:', value: customer.city),
                              buildSimpleText(
                                  title: 'رمز البريد:',
                                  value: customer.postalCode),
                            ]),
                      ),
                      // SizedBox(width: 10),
                    ]),
              ]),
            ),
          ]),
        ],
      );

  static Widget buildCustomerAddress(Invoice invoice, Customer customer) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            customer.buildingNo,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // Text('customer.address', textDirection: TextDirection.rtl),
        ],
      );

  static Widget buildInvoiceInfo(
      Invoice invoice, String title, bool isEstimate) {
    final titles = <String>[
      title == 'إشعار دائن'
          ? 'رقم الإشعار'
          : isEstimate
              ? 'رقم عرض السعر'
              : invoice.invoiceKind == "credit"
                  ? "رقم الاشعار"
                  : 'رقم الفاتورة',
      'التاريخ:',
      invoice.project.isNotEmpty ? 'ملاحظات:' : '',
    ];
    final data = <String>[
      invoice.invoiceNo,
      invoice.date,
      invoice.project,
    ];

    return Column(
      children: List.generate(titles.length, (index) {
        final value = data[index];
        final title = titles[index];

        return buildText(title: title, value: value, width: 170);
      }),
    );
  }

  static Widget buildLogo() => Container(
      width: Utils.logoWidth.toDouble(),
      height: Utils.logoHeight.toDouble(),
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill, image: MemoryImage(base64Decode(Utils.logo)))));

  static Widget buildSupplierAddress(Setting seller) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Utils.companyName,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 1 * PdfPageFormat.mm),
          buildSimpleText(title: "الرقم الضريبي", value: Utils.vatNumber),
        ],
      );

  static Widget buildTitle(
          Invoice invoice, String title, String subTitle, bool isEstimate) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          buildInvoiceInfo(invoice, title, isEstimate)
          // // Project name
          // Text(
          //   subTitle,
          //   textDirection: TextDirection.rtl,
          //   style: TextStyle(fontWeight: FontWeight.bold),
          // ),
        ],
      );

  static Widget buildInvoice(Invoice invoice, List<InvoiceLines> invoiceLines) {
    final data = invoiceLines.map((item) {
      final total = item.qty * item.price;
      return [
        '${Utils.format(total)}',
        '${Utils.formatPercent(0.15 * 100)}',
        '${Utils.format(item.price / 1.15)}',
        '${item.qty}',
        item.productName,
      ];
    }).toList();

    return Container(
        child: Column(children: [
      Container(
        padding: const EdgeInsets.all(2),
        color: PdfColors.grey300,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 2.5 * PdfPageFormat.cm,
              margin: const EdgeInsets.only(right: 2.25, left: 0),
              child: Column(children: [
                Text(
                  "الإجمالي",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
                Text(
                  "Total",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
              ]),
            ),
            Container(
              width: 2 * PdfPageFormat.cm,
              margin: const EdgeInsets.only(right: 2.25, left: 2.25),
              child: Column(children: [
                Text(
                  "الضريبة",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
                Text(
                  "VAT",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
              ]),
            ),
            Container(
              width: 2 * PdfPageFormat.cm,
              margin: const EdgeInsets.only(right: 2.25, left: 2.25),
              child: Column(children: [
                Text(
                  "السعر",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
                Text(
                  "Price",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
              ]),
            ),
            Container(
                width: 2 * PdfPageFormat.cm,
                margin: const EdgeInsets.only(right: 2.25, left: 2.25),
                child: Column(children: [
                  Text(
                    "الكمية",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: PdfColors.black),
                  ),
                  Text(
                    "Qty",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: PdfColors.black),
                  ),
                ])),
            Container(
                width: 9.5 * PdfPageFormat.cm,
                margin: const EdgeInsets.only(right: 0, left: 2.25),
                child: Column(children: [
                  Text(
                    "البيان",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: PdfColors.black),
                  ),
                  Text(
                    "Description",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: PdfColors.black),
                  ),
                ])),
          ],
        ),
      ),
      ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              color: index % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 2.5 * PdfPageFormat.cm,
                    margin: const EdgeInsets.only(right: 2.25, left: 2.25),
                    child: buildPriceText(currency: '', value: data[index][0]),
                  ),
                  Container(
                    width: 1.5 * PdfPageFormat.cm,
                    margin: const EdgeInsets.only(right: 2.25, left: 2.25),
                    child: Text(
                      data[index][1],
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Container(
                    width: 2.5 * PdfPageFormat.cm,
                    margin: const EdgeInsets.only(right: 2.25, left: 2.25),
                    child: buildPriceText(currency: '', value: data[index][2]),
                  ),
                  Container(
                    width: 2 * PdfPageFormat.cm,
                    margin: const EdgeInsets.only(right: 2.25, left: 2.25),
                    child: Text(
                      data[index][3],
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Container(
                    width: 9.5 * PdfPageFormat.cm,
                    margin: const EdgeInsets.only(right: 0, left: 2.25),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        data[index][4],
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      Container(height: 1.5, color: PdfColors.black),
      Container(height: 5, color: PdfColors.white),
    ]));
  }

  static Widget buildTotal(Invoice invoice) {
    const vatPercent = 0.15;

    final netTotal = invoice.total / 1.15;
    final vat = invoice.totalVat;
    final total = invoice.total;
    final qrString = invoice.qrCode;

    return invoice.invoiceKind == "credit"
        ? Container(
            // alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Divider(),
                      buildText(
                        title: 'مبلغ الاشعار الدائن',
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        value: Utils.format(total),
                        unite: true,
                      ),
                    ],
                  ),
                ),
                Spacer(flex: 3),
                Container(
                  height: 100,
                  width: 100,
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: qrString!,
                  ),
                ),
              ],
            ),
          )
        : Container(
            // alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      buildText(
                        title: 'الإجمالي الصافي بدون الضريبة',
                        value: Utils.format(netTotal),
                        unite: true,
                      ),
                      buildText(
                        title:
                            'ضريبة القيمة المضافة ${Utils.formatPercent(vatPercent * 100)} ',
                        value: Utils.format(vat),
                        unite: true,
                      ),
                      Divider(),
                      buildText(
                        title: 'المبلغ المستحق',
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        value: Utils.format(total),
                        unite: true,
                      ),
                      buildText(
                        title: 'طريقة الدفع',
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        value: invoice.paymentMethod,
                        unite: true,
                      ),
                    ],
                  ),
                ),
                Spacer(flex: 3),
                Container(
                  height: 100,
                  width: 100,
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: qrString!,
                  ),
                ),
              ],
            ),
          );
  }

  static Widget buildTerms() {
    final noTerms = Utils.terms.isEmpty ? true : false;
    String terms = Utils.terms.replaceAll("\r\n", "\n").trim();
    return noTerms
        ? Container()
        : Column(
            children: [
              SizedBox(height: 0.75 * PdfPageFormat.cm),
              buildText(title: 'الشروط والأحكام', value: '\n$terms'),
            ],
          );
  }

  static Widget buildFooter(Invoice invoice) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          buildSimpleText(
              title: 'جميع الأسعار تشمل ضريبة القيمة المضافة',
              value: Utils.formatPercent(0.15 * 100)),
          // SizedBox(height: 1 * PdfPageFormat.mm),
          // buildSimpleText(title: 'حسب العقد', value: invoice.supplier.paymentInfo),
        ],
      );

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final styleTitle = TextStyle(fontWeight: FontWeight.bold, fontSize: 10);
    const styleValue = TextStyle(fontSize: 10);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      // mainAxisSize: MainAxisSize.min,
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, textDirection: TextDirection.rtl, style: styleValue),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(title, textDirection: TextDirection.rtl, style: styleTitle),
      ],
    );
  }

  static buildText({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style =
        titleStyle ?? TextStyle(fontWeight: FontWeight.bold, fontSize: 10);

    return Container(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, textDirection: TextDirection.rtl),
          Expanded(
              child:
                  Text(title, textDirection: TextDirection.rtl, style: style)),
        ],
      ),
    );
  }

  static buildConditionText({
    required String text,
    double width = double.infinity,
    TextStyle? titleStyle,
  }) {
    final style = titleStyle ?? const TextStyle(fontSize: 10);

    return Text(text, textDirection: TextDirection.rtl, style: style);
  }

  static buildPriceText({
    required String value,
    required String currency,
    double width = double.infinity,
    TextStyle? titleStyle,
  }) {
    final style = titleStyle ?? const TextStyle(fontSize: 10);

    return Container(
      width: width,
      child: Row(
        children: [
          Text(currency, textDirection: TextDirection.rtl, style: style),
          Expanded(
              child:
                  Text(value, textDirection: TextDirection.rtl, style: style)),
        ],
      ),
    );
  }
}
