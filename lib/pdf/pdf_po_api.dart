import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/po.dart';
import '../models/settings.dart';
import '../models/suppliers.dart';
import '../pdf/pdf_api.dart';

class PdfPoApi {
  static Future<File> generate(Po po, Supplier supplier, List<PoLines> poLines,
      String title, String subTitle, bool isPreview,
      {bool isPo = false}) async {
    var myTheme = ThemeData.withFont(
      base: Font.ttf(await rootBundle.load(tahoma)),
      bold: Font.ttf(await rootBundle.load(notoBold)),
    );
    final pdf = Document(theme: myTheme);
    pdf.addPage(MultiPage(
        margin: const EdgeInsets.all(30),
        build: (context) => [
              buildHeader(po, supplier, title, subTitle, isPreview, isPo),
              SizedBox(height: 0.2 * PdfPageFormat.cm),
              buildPo(po, poLines),
              buildTotal(po),
              buildNotes(po),
              // buildTerms(seller, dbVersion!),
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

    return PdfApi.previewPo(po: po, pdf: pdf);
  }

  static Future<String> getSupplierName(int? id) async {
    Supplier supplier = await FatooraDB.instance.getSupplierById(id!);
    return supplier.name;
  }

  static Widget buildHeader(Po po, Supplier supplier, String title,
          String subTitle, bool isPreview, bool isPo) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            buildLogo(),
            buildCompanyName(),
          ]),
          Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildPoInfo(po, title, isPreview, isPo),
              buildTitle(po, title, supplier),
            ],
          ),
          SizedBox(height: 0.5 * PdfPageFormat.cm),
        ],
      );

  static Widget buildSupplierAddress(Po po, Supplier supplier) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            supplier.buildingNo,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // Text('supplier.address', textDirection: TextDirection.rtl),
        ],
      );

  static Widget buildPoInfo(Po po, String title, bool isPreview, bool isPo) {
    final titles = <String>[
      title == 'إشعار دائن'
          ? 'رقم الإشعار'
          : isPo
              ? 'رقم طلب الشراء'
              : 'رقم الفاتورة',
      'التاريخ:',
      // 'تاريخ التوريد:',
    ];
    final data = <String>[
      po.poNo,
      po.date,
      // po.supplyDate,
    ];

    return Column(
      children: List.generate(titles.length, (index) {
        final value = data[index];
        final title = titles[index];

        return buildText(title: title, value: value, width: 200);
      }),
    );
  }

  static Widget buildLogo() => Container(
      width: Utils.logoWidth.toDouble(),
      height: Utils.logoHeight.toDouble(),
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill, image: MemoryImage(base64Decode(Utils.logo)))));

  static Widget buildTitle(Po po, String title, Supplier supplier) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(children: [
            Text(
              supplier.name,
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
          /*Row(children: [
            Text(
              'متخصصون في التكييف المركزي والاسبليت وأعمال الدكت ',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ]),*/
          Row(children: [
            Text(
              Utils.vatNumber,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            SizedBox(width: 5),
            Text(
              'رقم ضريبي',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            SizedBox(width: 10),
            Text(
              Utils.city,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            SizedBox(width: 5),
            Text(
              Utils.district,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ]),
          // SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );

  static Widget buildPo(Po po, List<PoLines> poLines) {
    final data = poLines.map((item) {
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

  static Widget buildTotal(Po po) {
    const vatPercent = 0.15;

    final netTotal = po.total / 1.15;
    final vat = po.totalVat;
    final total = po.total;

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
                  value: po.paymentMethod,
                  unite: true,
                )
              ],
            ),
          ),
          Spacer(flex: 3),
        ],
      ),
    );
  }

  static Widget buildNotes(Po po) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Divider(),
      buildSimpleText(title: 'ملاحظات', value: po.notes),
    ]);
  }

  static Widget buildTerms(Setting setting, int version) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Divider(),
        buildText(title: 'الشروط والأحكام', value: ''),
        buildConditionText(text: setting.terms),
      ],
    );
  }

  static Widget buildFooter(Po po) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          buildSimpleText(
              title: 'جميع الأسعار تشمل ضريبة القيمة المضافة',
              value: Utils.formatPercent(0.15 * 100)),
          // SizedBox(height: 1 * PdfPageFormat.mm),
          // buildSimpleText(title: 'حسب العقد', value: po.supplier.paymentInfo),
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
