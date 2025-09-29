import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/customers.dart';
import '../models/invoice.dart';
import '../models/settings.dart';
import '../pdf/pdf_api.dart';

class PdfReceipt {
  static Future<void> generate(
      Invoice invoice,
      Customer customer,
      List<InvoiceLines> invoiceLines,
      String title,
      String subTitle,
      bool isProVersion,
      bool isPreview) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load(tahoma)),
      bold: Font.ttf(await rootBundle.load(notoBold)),
    );
    final pdf = Document(theme: myTheme);
    String strAddress = Utils.buildingNo;
    strAddress += Utils.buildingNo.isNotEmpty ? ' ' : '';
    strAddress += Utils.street.isNotEmpty ? Utils.street : '';
    strAddress += Utils.district.isNotEmpty ? '-${Utils.district}' : '';
    strAddress += Utils.city.isNotEmpty ? '-${Utils.city}' : '';
    strAddress += 'السعودية'.isNotEmpty ? '-${'السعودية'}' : '';

    String strCustomerAddress = customer.buildingNo;
    strCustomerAddress += customer.buildingNo.isNotEmpty ? ' ' : '';
    strCustomerAddress +=
        customer.streetName.isNotEmpty ? customer.streetName : '';
    strCustomerAddress +=
        customer.district.isNotEmpty ? '-${customer.district}' : '';
    strCustomerAddress += customer.city.isNotEmpty ? '-${customer.city}' : '';
    strCustomerAddress +=
        customer.country.isNotEmpty ? '-${customer.country}' : '';

    pdf.addPage(Page(
      pageFormat: PdfPageFormat.roll80,
      build: (context) => Column(children: [
        buildHeader(invoice, customer, title, subTitle, strAddress,
            strCustomerAddress, isProVersion),
        // SizedBox(height: 10),
        buildInvoice(invoice, invoiceLines),
        Divider(),
        buildTotal(invoice),
        Divider(),
        buildTerms(invoice),
      ]),
      // footer: (context) => buildFooter(invoice),
    ));
    if (isPreview) {
      await PdfApi.previewDocument(invoice: invoice, pdf: pdf);
    }
  }

  static Future<String> getCustomerName(int? id) async {
    Customer customer = await FatooraDB.instance.getCustomerById(id!);
    return customer.name;
  }

  static Widget buildTerms(Invoice invoice) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(
        Utils.terms,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 12),
      ),
      Text('Invoice # ${invoice.invoiceNo}'),
      Text(invoice.date),
      SizedBox(height: 40),
    ]);
  }

  static Widget buildHeader(
          Invoice invoice,
          Customer customer,
          String title,
          String subTitle,
          String strAddress,
          String strCustomerAddress,
          bool isProVersion) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildLogo(),
          Column(
              crossAxisAlignment: isProVersion && customer.id != 1
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.center,
              children: [
                SizedBox(width: 10),
                Text(
                  isProVersion && customer.id != 1
                      ? 'المورد: ${Utils.companyName}'
                      : Utils.companyName,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                isProVersion && customer.id != 1
                    ? Text(strAddress,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 12))
                    : buildCenterText(text: strAddress),
                SizedBox(height: 5),
                buildSimpleText(
                    title: 'الرقم الضريبي:', value: Utils.vatNumber),
                // SizedBox(height: 10),
                isProVersion && customer.id != 1
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                            Divider(),
                            Text(
                              'العميل: ${customer.name}',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(strCustomerAddress,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12)),
                            SizedBox(height: 5),
                            buildSimpleText(
                                title: 'الرقم الضريبي:',
                                value: customer.vatNumber),
                          ])
                    : Container(),
              ]),
          // SizedBox(height: 5 * PdfPageFormat.mm),
          // buildInvoiceInfo(invoice, title, seller),
        ],
      );

  static Widget buildInvoiceInfo(
      Invoice invoice, String title, Setting seller) {
    final titles = <String>[
      'رقم الفاتورة:',
      ' ',
      'التاريخ:',
    ];
    final data = <String>[
      invoice.invoiceNo,
      ' ',
      invoice.date,
    ];

    return Column(
      children: List.generate(titles.length, (index) {
        final value = data[index];
        final title = titles[index];

        return buildText(title: title, value: value);
      }),
    );
  }

  static Widget buildLogo() => Container(
      width: Utils.logoWidth.toDouble(),
      height: Utils.logoHeight.toDouble(),
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill, image: MemoryImage(base64Decode(Utils.logo)))));

  static Widget buildTitle(Invoice invoice, String title, String subTitle) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subTitle,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );

  static Widget buildInvoice(Invoice invoice, List<InvoiceLines> invoiceLines) {
    final data = invoiceLines.map((item) {
      final total = '${Utils.formatPrice(item.qty * item.price)}';
      final line2 = '${Utils.formatPrice(item.price)} × ${item.qty}';
      return [
        total,
        line2,
        item.productName,
      ];
    }).toList();

    return Center(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Divider(),
      buildText(
          title: "البيان", value: "الإجمالي", fontWeight1: FontWeight.bold),
      Divider(),
      ListView.builder(
        itemCount: data.length,
        itemBuilder: (Context context, int index) => Column(children: [
          buildText(
              title: data[index][2], value: "", fontWeight: FontWeight.normal),
          buildText(
              title: data[index][1],
              value: data[index][0],
              fontWeight: FontWeight.normal),
          SizedBox(height: 10),
        ]),
      ),
    ]));
  }

  static Widget buildTotal(Invoice invoice) {
    const vatPercent = 0.15;

    final netTotal = invoice.total / 1.15;
    final vat = invoice.totalVat;
    final total = invoice.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildText(
              title: 'الإجمالي بدون الضريبة',
              value: Utils.formatNoCurrency(netTotal),
              // unite: true,
            ),
            buildText(
              title:
                  'ضريبة القيمة المضافة ${Utils.formatPercent(vatPercent * 100)} ',
              value: Utils.formatNoCurrency(vat),
              // unite: true,
            ),
            // Divider(),
            buildText(
              title: 'المبلغ المستحق',
              value: Utils.formatNoCurrency(total),
              // unite: true,
            ),
            buildText(
              title: 'طريقة الدفع',
              value: invoice.paymentMethod,
              // unite: true,
            ),
            Divider(),
          ],
        ),
      ],
    );
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

  static buildCenterText(
      {required String text, FontWeight fontWeight = FontWeight.normal}) {
    final style = TextStyle(fontWeight: fontWeight, fontSize: 12);

    return Center(
      child: Text(text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: style),
    );
  }

  static buildText(
      {required String title,
      required String value,
      double width = double.infinity,
      TextStyle? titleStyle,
      FontWeight fontWeight = FontWeight.bold,
      FontWeight fontWeight1 = FontWeight.normal,
      bool unite = false}) {
    final style = titleStyle ?? TextStyle(fontWeight: fontWeight, fontSize: 12);
    final style1 =
        titleStyle ?? TextStyle(fontWeight: fontWeight1, fontSize: 12);

    return Container(
      width: width,
      child: Row(
        children: [
          Text(value,
              textDirection: TextDirection.rtl, style: unite ? style : style1),
          Expanded(
              child:
                  Text(title, textDirection: TextDirection.rtl, style: style)),
        ],
      ),
    );
  }
}
