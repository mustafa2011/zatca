import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart';
import '../models/estimate.dart';
import '../models/invoice.dart';
import '../models/po.dart';
import '../models/receipt.dart';

class PdfApi {
  static Future<File> saveDocument(
      {required String name,
      required Document pdf,
      required bool isPreview}) async {
    File file;
    Directory docDir = await getApplicationSupportDirectory();
    try {
      file = File('${docDir.path}/$name');
    } on Exception catch (e) {
      throw Exception(e);
    }
    return file;
  }

  static Future<File> previewEstimate(
      {required Estimate estimate, required Document pdf}) async {
    final bytes = await pdf.save();
    String name = 'ESTIMATE.pdf';
    File file;
    Directory? docDir = await getApplicationDocumentsDirectory();
    try {
      file = File('${docDir.path}/$name');
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw Exception(e);
    }
    return file;
  }

  static Future<File> previewPo({required Po po, required Document pdf}) async {
    final bytes = await pdf.save();
    String name = 'PO.pdf'; // 'PO-${po.poNo}.pdf';
    File file;
    Directory? docDir = await getApplicationDocumentsDirectory();
    try {
      file = File('${docDir.path}/$name');
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw Exception(e);
    }
    return file;
  }

  static Future<File> previewReceipt(
      {required Receipt receipt, required Document pdf}) async {
    final bytes = await pdf.save();
    String name = 'RECEIPT.pdf'; // 'RST-${receipt.id}.pdf';
    File file;
    Directory? docDir = await getApplicationDocumentsDirectory();
    try {
      file = File('${docDir.path}/$name');
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw Exception(e);
    }
    return file;
  }

  static Future<File> previewDocument(
      {required Invoice invoice,
      required Document pdf,
      bool isEstimate = false,
      String title = 'تقرير'}) async {
    final bytes = await pdf.save();
    String name = isEstimate
        ? 'ESTIMATE.pdf' // 'EST-${invoice.invoiceNo}.pdf'
        : 'INVOICE.pdf'; // 'INV-${invoice.invoiceNo}.pdf';
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

  static Future<File> savePreviewDailyReport(
      {required String name,
      required Document pdf,
      String title = 'تقرير'}) async {
    final bytes = await pdf.save();
    File file;
    final docDir = await getApplicationDocumentsDirectory();

    try {
      file = File('${docDir.path}/REPORT.pdf');
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw Exception(e);
    }

    return file;
  }

  static Future<File> savePreviewMonthlyReport(
      {required String name, required Document pdf}) async {
    final bytes = await pdf.save();
    File file;
    final docDir = await getApplicationDocumentsDirectory();
    try {
      file = File('${docDir.path}/MONTH_REPORT.pdf');
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw Exception(e);
    }

    return file;
  }
}
