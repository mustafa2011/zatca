import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/customers.dart';
import '../models/estimate.dart';
import '../models/settings.dart';
import '../pdf/pdf_api.dart';

class PdfEstimateApi {
  static Future<File> generate(
      Estimate estimate,
      Customer customer,
      List<EstimateLines> estimateLines,
      String title,
      String subTitle,
      bool isPreview,
      {bool isEstimate = false}) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load(tahoma)),
      bold: Font.ttf(await rootBundle.load(notoBold)),
    );
    final pdf = Document(theme: myTheme);
    final settings = await FatooraDB.instance.getAllSettings();
    final seller = settings[0];

    pdf.addPage(MultiPage(
        margin: const EdgeInsets.all(30),
        build: (context) => [
              buildHeader(estimate, customer, seller, title, subTitle,
                  isPreview, isEstimate),
              SizedBox(height: 0.2 * PdfPageFormat.cm),
              buildEstimate(estimate, estimateLines),
              buildTotal(estimate),
              buildTerms(seller),
            ],
        footer: (context) {
          return Container(
              alignment: Alignment.center,
              child: Text("صفحة ${context.pagesCount}/${context.pageNumber}",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black)));
        }));

    return PdfApi.previewEstimate(estimate: estimate, pdf: pdf);
  }

  static Future<String> getCustomerName(int? id) async {
    Customer customer = await FatooraDB.instance.getCustomerById(id!);
    return customer.name;
  }

  static Widget buildHeader(
          Estimate estimate,
          Customer customer,
          Setting seller,
          String title,
          String subTitle,
          bool isPreview,
          bool isEstimate) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            buildLogo(seller),
            buildCompanyName(),
          ]),
          Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildEstimateInfo(estimate, title, isPreview, isEstimate),
              buildTitle(estimate, title, subTitle),
            ],
          ),
          SizedBox(height: 0.5 * PdfPageFormat.cm),
          Text(
            'تتشرف ${Utils.companyName} بأن تتقدم بعرض سعر على النحو التالي '
            'آملين أن ينال عرضنا القبول والاسستحسان',
            maxLines: 2,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      );

  static Widget buildCustomerAddress(Estimate estimate, Customer customer) =>
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

  static Widget buildEstimateInfo(
      Estimate estimate, String title, bool isPreview, bool isEstimate) {
    final titles = <String>[
      'رقم العرض',
      'التاريخ:',
      // 'تاريخ التوريد:',
    ];
    final data = <String>[
      estimate.estimateNo,
      estimate.date,
      // estimate.supplyDate,
    ];

    return Column(
      children: List.generate(titles.length, (index) {
        final value = data[index];
        final title = titles[index];

        return buildText(title: title, value: value, width: 200);
      }),
    );
  }

  static Widget buildLogo(Setting seller) {
    return Container(
        width: Utils.logoWidth.toDouble(),
        height: Utils.logoHeight.toDouble(),
        decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.fill,
                image: MemoryImage(base64Decode(Utils.logo)))));
  }

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

  static Widget buildTitle(Estimate estimate, String title, String subTitle) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(children: [
            Text(
              subTitle,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            SizedBox(width: 5),
            Text(
              'السادة',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ])
        ],
      );

  static Widget buildCompanyName() => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Utils.companyName,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Row(children: [
            Text(
              Utils.city,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5),
            Text(
              Utils.district,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ]),
          Row(children: [
            Text(
              Utils.vatNumber,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5),
            Text(
              'رقم ضريبي',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ]),
          // SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );

  static Widget buildEstimate(
      Estimate estimate, List<EstimateLines> estimateLines) {
    final data = estimateLines.map((item) {
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
                Text(
                  "Total",
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PdfColors.black),
                ),
                Text(
                  "Price",
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: PdfColors.black),
                  ),
                  Text(
                    "Description",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
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
              // padding: const EdgeInsets.all(4),
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

  static Widget buildTotal(Estimate estimate) {
    const vatPercent = 0.15;

    final netTotal = estimate.total / 1.15;
    final vat = estimate.totalVat;
    final total = estimate.total;

    return Container(
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
                  value: estimate.paymentMethod,
                  unite: true,
                ),
              ],
            ),
          ),
          Spacer(flex: 3),
        ],
      ),
    );
  }

  static Widget buildTerms(Setting seller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Divider(),
        buildText(title: 'الشروط والأحكام', value: ''),
        buildConditionText(text: seller.terms),
      ],
    );
  }

  static Widget buildFooter(Estimate estimate) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          buildSimpleText(
              title: 'جميع الأسعار تشمل ضريبة القيمة المضافة',
              value: Utils.formatPercent(0.15 * 100)),
          // SizedBox(height: 1 * PdfPageFormat.mm),
          // buildSimpleText(title: 'حسب العقد', value: estimate.supplier.paymentInfo),
        ],
      );

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final styleTitle = TextStyle(fontWeight: FontWeight.bold, fontSize: 10);
    const styleValue = TextStyle(fontSize: 10);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
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
        children: [
          Text(value,
              textDirection: TextDirection.rtl, style: unite ? style : null),
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

    return Container(
      width: width,
      child: Text(text, textDirection: TextDirection.rtl, style: style),
    );
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
