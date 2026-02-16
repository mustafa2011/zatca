import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/contract.dart';

class PdfContractApi {
  static Future<File> generate(Contract contract) async {
    final pdf = pw.Document();

    // Load Arabic font (VERY IMPORTANT)
    final font = pw.Font.ttf(await rootBundle.load(tahoma));
    final fontBold = pw.Font.ttf(await rootBundle.load(notoBold));

    // Fetch clauses
    final clauses =
        await FatooraDB.instance.getClausesByContractId(contract.id!);

    // Fetch lines per clause
    final Map<int, List<ClausesLines>> clauseLinesMap = {};

    for (final clause in clauses) {
      clauseLinesMap[clause.id!] =
          await FatooraDB.instance.getLinesByClauseId(clause.id!);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(contract, context),
        // footer: (context) => _footer(context),
        build: (context) => [
          _contractInfo(contract),
          pw.SizedBox(height: 20),
          ..._buildClauses(clauses, clauseLinesMap),
          pw.SizedBox(height: 40),
          _signatures(contract),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/contract_${contract.id}.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget buildLogo() => pw.Container(
      width: Utils.logoWidth.toDouble(),
      height: Utils.logoHeight.toDouble(),
      decoration: pw.BoxDecoration(
          image: pw.DecorationImage(
              fit: pw.BoxFit.fill,
              image: pw.MemoryImage(base64Decode(Utils.logo)))));

  static pw.Widget _header(Contract contract, pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(Utils.companyName,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Row(children: [
                    pw.Text(Utils.vatNumber,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 2 * PdfPageFormat.mm),
                    pw.Text('رقم ضريبي',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  )
                ]),
            buildLogo(),
          ],
        ),
        pw.Divider(),
        pw.Text(
          contract.title,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _contractInfo(Contract c) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _infoRow('تاريخ العقد', c.date),
        _infoRow('عنوان العقد', c.title),
        _infoRow('الطرف الأول', c.firstParty),
        _infoRow('الطرف الثاني', c.secondParty),
        _infoRow('قيمة العقد', c.total.toString()),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text('$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildClauses(
    List<Clauses> clauses,
    Map<int, List<ClausesLines>> linesMap,
  ) {
    final widgets = <pw.Widget>[];

    for (int i = 0; i < clauses.length; i++) {
      final clause = clauses[i];
      final lines = linesMap[clause.id] ?? [];

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'البند ${i + 1}: ${clause.clauseName}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            ...List.generate(lines.length, (index) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(right: 12, bottom: 4),
                child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${index + 1}.${i + 1}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(width: 2 * PdfPageFormat.mm),
                      pw.Expanded(
                        child: pw.Text(
                          textAlign: pw.TextAlign.justify,
                          lines[index].description,
                          softWrap: true,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ]),
              );
            }),
            pw.SizedBox(height: 12),
          ],
        ),
      );
    }

    return widgets;
  }

  static pw.Widget _signatures(Contract c) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              pw.Text('الطرف الأول',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 40),
              pw.Text(c.firstParty, textAlign: pw.TextAlign.center),
            ],
          ),
        ),
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              pw.Text('الطرف الثاني',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 40),
              pw.Text(c.secondParty, textAlign: pw.TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }

/*
  static pw.Widget _footer(pw.Context context) {
    return pw.Text(
      'صفحة ${context.pageNumber} من ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 10),
      textAlign: pw.TextAlign.center,
    );
  }
*/
}
