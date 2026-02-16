/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zatca/helpers/fatoora_db.dart';
import 'package:zatca/helpers/token.dart';
import 'package:zatca/helpers/utils.dart';
import 'package:zatca/main.dart';

import '../models/invoice.dart';

const String baseUrl = "https://gw-fatoora.zatca.gov.sa/e-invoicing/";
const String alwadehAPI = "https://alwadeh.net/api";
const String reportingEndpoint = "/invoices/reporting/single";
const String clearanceEndpoint = "/invoices/clearance/single";
const String generateInvoiceUrl = "$alwadehAPI/GenerateInvoice1.php";

class ZatcaAPI {
  static final ZatcaAPI instance = ZatcaAPI.init();

  static String e = Utils.environment; // "simulation" OR "core";
  static String authorization = Utils.authorization;
  int zatcaStatusCode = 400;

  ZatcaAPI.init();

  String paymentCode(String method) {
    switch (method) {
      case 'شبكة':
        return '20'; // Payment card
      case 'كاش':
        return '10'; // Cash
      case 'نقدي':
        return '10'; // Cash
      case 'آجل':
        return '97'; // Other (e.g. deferred payment)
      case 'حوالة':
        return '31'; // Credit transfer
      case 'عقد':
        return '97'; // Other (contract-based)
      default:
        return '10'; // Default to "Other"
    }
  }

  Future<bool> generateInvoice(Invoice invoice, {bool isCredit = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final isValid = await Token().isTokenValid();
    if (!isValid) {
      errorMessage("Authentication token expired. Please request new one");
      return false;
    }
    bool result = false;
    FatooraDB db = FatooraDB.instance;
    ZatcaAPI zatca = ZatcaAPI.instance;
    final icv = (await FatooraDB.instance.getLastICV())! + 1;
    final pih = await FatooraDB.instance.getLastInvoiceHash();
    final paymentCode = zatca.paymentCode(invoice.paymentMethod);
    final lines = await db.getInvoiceLinesById(invoice.id!);
    final customer = await db.getCustomerById(invoice.payerId!);
    final invoiceKind = isCredit ? "credit" : invoice.invoiceKind;
    final invoiceType = invoice.invoiceType;
    num totalInvoiceWithTax = 0.0;
    num totalInvoiceTax = 0.0;
    List<Map<String, dynamic>> invoiceLines = [];
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      num lineTotal = (line.price / (1 + 0.15)) * line.qty;
      num taxAmount = lineTotal * 0.15;
      num totalWithTax = lineTotal + taxAmount;
      totalInvoiceTax += taxAmount;
      totalInvoiceWithTax += totalWithTax;
      invoiceLines.add({
        "id": line.id,
        "unitCode": "PCE",
        "quantity": line.qty,
        "lineExtensionAmount": lineTotal,
        "item": {
          "name": line.productName,
          "classifiedTaxCategory": [
            {
              "percent": 15,
              "taxScheme": {"id": "VAT"}
            }
          ]
        },
        "price": {
          "amount": (line.price / (1 + 0.15)),
          "unitCode": "UNIT",
          "allowanceCharges": []
        },
        "taxTotal": {"taxAmount": taxAmount, "roundingAmount": totalWithTax}
      });
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'icv': icv.toString(),
      'pih': pih.toString(),
      'invoice_id': invoice.invoiceNo,
      'invoice_kind': invoiceKind,
      'invoice_type': invoiceType,
      'invoice_date': invoice.date,
      'currency_code': 'SAR',
      'billing_reference_id': isCredit ? invoice.invoiceNo : '', // <28Sep2025>
      'billing_reference_date': isCredit ? invoice.date : '',
      'Authorization': 'Bearer $token'
    };
    var request = http.Request('POST', Uri.parse(generateInvoiceUrl));
    request.body = json.encode({
      "supplier": {
        "registrationName": Utils.companyName,
        "taxId": Utils.vatNumber,
        "identificationId": Utils.crNumber,
        "identificationType": "CRN",
        "address": {
          "street": Utils.street,
          "buildingNumber": Utils.buildingNo,
          "subdivision": Utils.district,
          "city": Utils.city,
          "postalZone": Utils.postalCode,
          "country": "SA"
        }
      },
      "customer": {
        "registrationName": customer.name,
        "taxId": customer.vatNumber.isEmpty || customer.vatNumber == '0'
            ? '399999999900003'
            : customer.vatNumber,
        "address": {
          "street": customer.streetName.isEmpty || customer.streetName == ''
              ? Utils.street
              : customer.streetName,
          "buildingNumber":
              customer.buildingNo.isEmpty || customer.buildingNo == ''
                  ? Utils.buildingNo
                  : customer.buildingNo,
          "subdivision": customer.district.isEmpty || customer.district == ''
              ? Utils.district
              : customer.district,
          "city": customer.city.isEmpty || customer.city == ''
              ? Utils.city
              : customer.city,
          "postalZone": customer.postalCode.isEmpty || customer.postalCode == ''
              ? Utils.postalCode
              : customer.postalCode,
          "country": "SA"
        }
      },
      "paymentMeans": {"code": paymentCode},
      "delivery": {
        "actualDeliveryDate":
            Utils.formatShortDate(DateTime.parse(invoice.supplyDate))
      },
      "invoiceLines": invoiceLines
    });
    request.headers.addAll(headers);
    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final responseString = await response.stream.bytesToString();
        final responseData = json.decode(responseString);
        final String invoiceHash = responseData['invoiceHash'];
        final String uuid = responseData['uuid'];
        final String encodedInvoice = responseData['invoice'];
        final String qrCode = responseData['qrCode'];
        final decodedXml = utf8.decode(base64.decode(encodedInvoice));
        // debugPrint(responseString);
        // Submit invoice to zatca for Reporting/Clearance
        final zatcaResponseData =
            await submitInvoice(invoiceType, invoiceHash, uuid, encodedInvoice);
        final statusCode = invoiceType == "simplified"
            ? zatcaResponseData['reportingStatus']
            : zatcaResponseData['clearanceStatus'];
        final status = zatcaStatusCode;
        final errorMessage =
            zatcaResponseData['validationResults']['errorMessages'];
        final warningMessage =
            zatcaResponseData['validationResults']['warningMessages'];
        int posted = 0;
        if (statusCode == "REPORTED" || statusCode == "CLEARED") {
          result = true; // to return true if all api integration success
          posted = 1;
        }
        if (isCredit) {
          // Update the invoice object
          Invoice newCreditInvoice = Invoice(
            invoiceNo: "${invoice.invoiceNo}-CR",
            date: Utils.formatDate(DateTime.now()),
            supplyDate: Utils.formatDate(DateTime.now()),
            sellerId: Utils.clientId,
            project: "${invoice.invoiceNo}مرتجع فاتورة رقم ",
            total: totalInvoiceWithTax,
            totalVat: totalInvoiceTax,
            posted: posted,
            payerId: invoice.payerId,
            noOfLines: invoiceLines.length,
            paymentMethod: invoice.paymentMethod,
            icv: icv,
            invoiceHash: invoiceHash,
            uuid: uuid,
            xml: decodedXml,
            invoiceKind: invoiceKind,
            invoiceType: invoiceType,
            qrCode: qrCode,
            statusCode: statusCode,
            status: status.toString(),
            errorMessage: errorMessage.toString(),
            warningMessage: warningMessage.toString(),
            isCredit: isCredit ? 1 : 0,
            lastCreditAmount: 0.0,
          );

          // Save to database
          await FatooraDB.instance.createInvoice(newCreditInvoice);

          Invoice updateInvoice = Invoice(
            id: invoice.id,
            invoiceNo: invoice.invoiceNo,
            date: invoice.date,
            supplyDate: invoice.supplyDate,
            sellerId: Utils.clientId,
            project: "فاتورة ملغاة باشعار دائن",
            total: invoice.total,
            totalVat: invoice.totalVat,
            posted: invoice.posted,
            payerId: invoice.payerId,
            noOfLines: invoice.noOfLines,
            paymentMethod: invoice.paymentMethod,
            icv: invoice.icv,
            invoiceHash: invoice.invoiceHash,
            uuid: invoice.uuid,
            xml: invoice.xml,
            invoiceKind: invoice.invoiceKind,
            invoiceType: invoice.invoiceType,
            qrCode: invoice.qrCode,
            statusCode: invoice.statusCode,
            status: invoice.status,
            errorMessage: invoice.errorMessage,
            warningMessage: invoice.warningMessage,
            isCredit: 1,
            lastCreditAmount: 0.0,
          );

          // Save to database
          await FatooraDB.instance.updateInvoice(updateInvoice);
        } else {
          // Update the invoice object
          Invoice updateInvoice = Invoice(
            id: invoice.id,
            invoiceNo: invoice.invoiceNo,
            date: invoice.date,
            supplyDate: invoice.supplyDate,
            sellerId: Utils.clientId,
            project: invoice.project,
            total: totalInvoiceWithTax,
            totalVat: totalInvoiceTax,
            posted: posted,
            payerId: invoice.payerId,
            noOfLines: invoiceLines.length,
            paymentMethod: invoice.paymentMethod,
            icv: icv,
            invoiceHash: invoiceHash,
            uuid: uuid,
            xml: decodedXml,
            invoiceKind: invoiceKind,
            invoiceType: invoiceType,
            qrCode: qrCode,
            statusCode: statusCode,
            status: status.toString(),
            errorMessage: errorMessage.toString(),
            warningMessage: warningMessage.toString(),
            isCredit: isCredit ? 1 : 0,
            lastCreditAmount: 0.0,
          );

          // Save to database
          await FatooraDB.instance.updateInvoice(updateInvoice);
        }
      } else {
        result = false;
        String responseBody = await response.stream.bytesToString();
        debugPrint('Error: ${response.statusCode} - ${response.reasonPhrase}');
        debugPrint('Error: $responseBody');
        errorMessage("Response Error: $responseBody");
      }
    } on Exception catch (e) {
      errorMessage(e.toString());
    }
    return result;
  }

  Future<dynamic> submitInvoice(
    String invoiceType,
    String invoiceHash,
    String uuid,
    String invoice,
  ) async {
    final zatcaUrl = invoiceType == "simplified"
        ? "$baseUrl$e$reportingEndpoint"
        : "$baseUrl$e$clearanceEndpoint";
    final clearanceStatus = invoiceType == "simplified" ? "0" : "1";
    Map<String, String> headers = {
      'accept': 'application/json',
      'accept-language': 'ar',
      'Clearance-Status': clearanceStatus,
      'Accept-Version': 'V2',
      'Content-Type': 'application/json',
      'Authorization': Utils.authorization,
    };
    var request = http.Request('POST', Uri.parse(zatcaUrl));
    request.body = json
        .encode({"invoiceHash": invoiceHash, "uuid": uuid, "invoice": invoice});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      final responseString = await response.stream.bytesToString();
      final responseData = json.decode(responseString);

      if (response.statusCode == 200 || response.statusCode == 202) {
        zatcaStatusCode = response.statusCode;
        successMessage(
            "${invoiceType == "simplified" ? responseData["reportingStatus"] : responseData["clearanceStatus"]}");
      } else {
        // print(
        //     'Reporting Status: ${invoiceKind == "simplified" ? responseData["reportingStatus"] : responseData["clearanceStatus"]}');
        // print(
        //     'Error Messages: ${responseData['validationResults']['errorMessages']}');
        // print(responseData);
        errorMessage("${responseData['validationResults']['errorMessages']}");
      }
      return responseData;
    } on Exception catch (e) {
      errorMessage(e.toString());
    }
  }

  static void errorMessage(String message) {
    final context = navKey.currentContext;
    if (context == null) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl, // لضبط الاتجاه للغة العربية
          child: AlertDialog(
            title: const Text('تنبيه', textAlign: TextAlign.center),
            content: Text(message, textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً'),
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          ),
        );
      },
    );
  }

  static Future<bool> sendCreditNote(String message, Invoice invoice) async {
    final context = navKey.currentContext;
    bool isLoading = false;
    // num lastCreditAmount = 0.0;

    if (context == null) return false;

    final formKey = GlobalKey<FormState>();
    final navigator = Navigator.of(context); // store navigator to avoid lint

    final result = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFCDD2),
              title:
                  const Text('ارسال اشعار دائن', textAlign: TextAlign.center),
              content: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: SizedBox(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(strokeWidth: 3),
                              SizedBox(height: 10),
                              Text("فضلا انتظر ..."),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Text(
                                  'Invoice No. ${invoice.invoiceNo}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(message),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 👇 enable again if you want amount input
                          // TextFormField(...)
                        ],
                      ),
                    ),
              actions: [
                if (!isLoading && invoice.isCredit != 1)
                  TextButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? true) {
                        try {
                          setState(() => isLoading = true);
                          ZatcaAPI zatca = ZatcaAPI.instance;
                          await zatca.generateInvoice(invoice, isCredit: true);

                          setState(() => isLoading = false);

                          navigator.pop(true); // ✅ return true
                        } on Exception catch (e) {
                          setState(() => isLoading = false);
                          ZatcaAPI.errorMessage(e.toString());
                          navigator.pop(false); // ❌ return false
                        }
                      }
                    },
                    child: const Text('تأكيد'),
                  ),
                if (!isLoading)
                  TextButton(
                    onPressed: () => navigator.pop(false), // ❌ return false
                    child: const Text('إلغاء'),
                  ),
              ],
              actionsAlignment: MainAxisAlignment.center,
            );
          },
        );
      },
    );

    return result ?? false;
  }

  static void successMessage(String message) {
    final context = navKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void snackError(String message) {
    final context = navKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zatca/helpers/fatoora_db.dart';
import 'package:zatca/helpers/token.dart';
import 'package:zatca/helpers/utils.dart';

import '../main.dart';
import '../models/invoice.dart';

class ZatcaAPI {
  final http.Client _client;
  final FatooraDB _db;

  /// Use dependency injection for testability.
  ZatcaAPI({
    http.Client? client,
    FatooraDB? db,
  })  : _client = client ?? http.Client(),
        _db = db ?? FatooraDB.instance;

  /// Convert env string to enum safely.
  ZatcaEnvironment get environment => Utils.environment == "core"
      ? ZatcaEnvironment.core
      : ZatcaEnvironment.simulation;

  String get _envSegment =>
      environment == ZatcaEnvironment.core ? "core" : "simulation";

  String paymentCode(String method) {
    switch (method) {
      case 'شبكة':
        return '20';
      case 'كاش':
      case 'نقدي':
        return '10';
      case 'آجل':
      case 'عقد':
        return '97';
      case 'حوالة':
        return '31';
      default:
        return '10';
    }
  }

  static void errorMessage(String message) {
    final context = navKey.currentContext;
    if (context == null) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl, // لضبط الاتجاه للغة العربية
          child: AlertDialog(
            title: const Text('تنبيه', textAlign: TextAlign.center),
            content: Text(message, textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً'),
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          ),
        );
      },
    );
  }

  static void successMessage(String message) {
    final context = navKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void snackError(String message) {
    final context = navKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// PUBLIC: end-to-end flow:
  /// 1) generate invoice via your backend
  /// 2) submit to ZATCA via reporting/clearance (explicit or auto)
  /// 3) persist updates
  Future<ZatcaResult> processInvoice(
    Invoice invoice, {
    bool isCredit = false,
    ZatcaEndpoint? endpoint, // if null => auto by invoiceType
  }) async {
    // 0) Token validation for your backend generate endpoint
    final prefs = await SharedPreferences.getInstance();
    final bearer = prefs.getString('token') ?? '';
    final isValid = await Token().isTokenValid();
    if (!isValid) {
      return ZatcaResult.fail(
          "Authentication token expired. Please request a new one.");
    }

    try {
      final icv = (await _db.getLastICV() ?? 0) + 1;
      final pih = await _db.getLastInvoiceHash() ?? "";

      final lines = await _db.getInvoiceLinesById(invoice.id!);
      final customer = await _db.getCustomerById(invoice.payerId!);

      final invoiceKind = isCredit ? "credit" : invoice.invoiceKind;
      final invoiceType =
          invoice.invoiceType; // "simplified" or "standard" (as you use it)

      // 1) Build lines + totals
      final built = _buildInvoiceLines(lines);
      final totalInvoiceWithTax = built.totalWithTax;
      final totalInvoiceTax = built.totalTax;

      // 2) Generate UBL/XML via your backend
      final gen = await _generate(
        invoice: invoice,
        bearerToken: bearer,
        icv: icv,
        pih: pih,
        invoiceKind: invoiceKind,
        invoiceType: invoiceType,
        isCredit: isCredit,
        customer: customer,
        invoiceLines: built.lines,
      );

      // 3) Decide endpoint (explicit OR auto)
      final chosenEndpoint = endpoint ?? _autoEndpoint(invoiceType);

      // 4) Submit to ZATCA
      final submit = await submitInvoice(
        endpoint: chosenEndpoint,
        invoiceHash: gen.invoiceHash,
        uuid: gen.uuid,
        invoiceBase64: gen.invoiceBase64,
      );

      // 5) Determine posted and persist
      final businessStatus = submit.businessStatus ?? "";
      final posted =
          (businessStatus == "REPORTED" || businessStatus == "CLEARED") ? 1 : 0;

      await _persistInvoice(
        original: invoice,
        isCredit: isCredit,
        icv: icv,
        invoiceKind: invoiceKind,
        invoiceType: invoiceType,
        totalWithTax: totalInvoiceWithTax,
        totalTax: totalInvoiceTax,
        gen: gen,
        submit: submit,
        posted: posted,
      );

      if (!submit.isAccepted) {
        return ZatcaResult.fail(
          "ZATCA rejected the invoice: ${submit.errorMessages}",
          generated: gen,
          submitted: submit,
        );
      }

      return ZatcaResult.success(
        "Success: $businessStatus",
        generated: gen,
        submitted: submit,
      );
    } catch (e) {
      return ZatcaResult.fail("Unexpected error: $e");
    }
  }

  /// Explicit submit function (if you want to call it alone)
  Future<ZatcaSubmitResponse> submitInvoice({
    required ZatcaEndpoint endpoint,
    required String invoiceHash,
    required String uuid,
    required String invoiceBase64,
  }) async {
    final url = Uri.parse("$baseUrl$_envSegment${endpoint.path}");

    final headers = <String, String>{
      'accept': 'application/json',
      'accept-language': 'ar',
      'Clearance-Status': endpoint.clearanceStatusHeaderValue,
      'Accept-Version': 'V2',
      'Content-Type': 'application/json',
      'Authorization': Utils.authorization, // CSID token (Basic ...)
    };

    final body = json.encode({
      "invoiceHash": invoiceHash,
      "uuid": uuid,
      "invoice": invoiceBase64,
    });

    final res = await _client.post(url, headers: headers, body: body);

    final raw = _safeJsonDecode(res.body);
    final validation = (raw['validationResults'] ?? {}) as Map<String, dynamic>;

    return ZatcaSubmitResponse(
      httpStatus: res.statusCode,
      raw: raw,
      reportingStatus: raw["reportingStatus"]?.toString(),
      clearanceStatus: raw["clearanceStatus"]?.toString(),
      errorMessages: (validation['errorMessages'] as List?) ?? const [],
      warningMessages: (validation['warningMessages'] as List?) ?? const [],
    );
  }

  // ----------------------------
  // Private helpers
  // ----------------------------

  ZatcaEndpoint _autoEndpoint(String invoiceType) {
    // Your logic: simplified => reporting, otherwise clearance
    return invoiceType == "simplified"
        ? ZatcaEndpoint.reportingSingle
        : ZatcaEndpoint.clearanceSingle;
  }

  Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"_raw": decoded};
    } catch (_) {
      return {"_rawText": body};
    }
  }

  Future<ZatcaGenerateResponse> _generate({
    required Invoice invoice,
    required String bearerToken,
    required int icv,
    required String pih,
    required String invoiceKind,
    required String invoiceType,
    required bool isCredit,
    required dynamic customer,
    required List<Map<String, dynamic>> invoiceLines,
  }) async {
    final payment = paymentCode(invoice.paymentMethod);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'icv': icv.toString(),
      'pih': pih,
      'invoice_id': invoice.invoiceNo,
      'invoice_kind': invoiceKind,
      'invoice_type': invoiceType,
      'invoice_date': invoice.date,
      'currency_code': 'SAR',
      'billing_reference_id': isCredit ? invoice.invoiceNo : '',
      'billing_reference_date': isCredit ? invoice.date : '',
      'Authorization': 'Bearer $bearerToken',
    };

    final payload = {
      "supplier": {
        "registrationName": Utils.companyName,
        "taxId": Utils.vatNumber,
        "identificationId": Utils.crNumber,
        "identificationType": "CRN",
        "address": {
          "street": Utils.street,
          "buildingNumber": Utils.buildingNo,
          "subdivision": Utils.district,
          "city": Utils.city,
          "postalZone": Utils.postalCode,
          "country": "SA"
        }
      },
      "customer": {
        "registrationName": customer.name,
        "taxId": (customer.vatNumber == null ||
                customer.vatNumber.toString().isEmpty ||
                customer.vatNumber.toString() == '0')
            ? '399999999900003'
            : customer.vatNumber.toString(),
        "address": {
          "street": (customer.streetName ?? "").toString().isEmpty
              ? Utils.street
              : customer.streetName,
          "buildingNumber": (customer.buildingNo ?? "").toString().isEmpty
              ? Utils.buildingNo
              : customer.buildingNo,
          "subdivision": (customer.district ?? "").toString().isEmpty
              ? Utils.district
              : customer.district,
          "city": (customer.city ?? "").toString().isEmpty
              ? Utils.city
              : customer.city,
          "postalZone": (customer.postalCode ?? "").toString().isEmpty
              ? Utils.postalCode
              : customer.postalCode,
          "country": "SA"
        }
      },
      "paymentMeans": {"code": payment},
      "delivery": {
        "actualDeliveryDate":
            Utils.formatShortDate(DateTime.parse(invoice.supplyDate))
      },
      "invoiceLines": invoiceLines,
    };

    final res = await _client.post(
      Uri.parse(generateInvoiceUrl),
      headers: headers,
      body: json.encode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception(
          "GenerateInvoice failed (${res.statusCode}): ${res.body}");
    }

    final data = _safeJsonDecode(res.body);

    final invoiceHash = data['invoiceHash']?.toString() ?? "";
    final uuid = data['uuid']?.toString() ?? "";
    final encodedInvoice = data['invoice']?.toString() ?? "";
    final qrCode = data['qrCode']?.toString() ?? "";

    if (invoiceHash.isEmpty || uuid.isEmpty || encodedInvoice.isEmpty) {
      throw Exception("GenerateInvoice returned missing fields: ${res.body}");
    }

    final decodedXml = utf8.decode(base64.decode(encodedInvoice));

    return ZatcaGenerateResponse(
      invoiceHash: invoiceHash,
      uuid: uuid,
      invoiceBase64: encodedInvoice,
      qrCode: qrCode,
      decodedXml: decodedXml,
    );
  }

  /// Persist logic stays same as you had, but centralized.
  Future<void> _persistInvoice({
    required Invoice original,
    required bool isCredit,
    required int icv,
    required String invoiceKind,
    required String invoiceType,
    required num totalWithTax,
    required num totalTax,
    required ZatcaGenerateResponse gen,
    required ZatcaSubmitResponse submit,
    required int posted,
  }) async {
    final businessStatus = submit.businessStatus ?? "";
    final status = submit.httpStatus.toString();

    final errorMsg = submit.errorMessages.toString();
    final warnMsg = submit.warningMessages.toString();

    if (isCredit) {
      // create credit invoice
      final credit = Invoice(
        invoiceNo: "${original.invoiceNo}-CR",
        date: Utils.formatDate(DateTime.now()),
        supplyDate: Utils.formatDate(DateTime.now()),
        sellerId: Utils.clientId,
        project: "${original.invoiceNo}مرتجع فاتورة رقم ",
        total: totalWithTax,
        totalVat: totalTax,
        posted: posted,
        payerId: original.payerId,
        noOfLines: original.noOfLines,
        paymentMethod: original.paymentMethod,
        icv: icv,
        invoiceHash: gen.invoiceHash,
        uuid: gen.uuid,
        xml: gen.decodedXml,
        invoiceKind: invoiceKind,
        invoiceType: invoiceType,
        qrCode: gen.qrCode,
        statusCode: businessStatus,
        status: status,
        errorMessage: errorMsg,
        warningMessage: warnMsg,
        isCredit: 1,
        lastCreditAmount: 0.0,
      );

      await _db.createInvoice(credit);

      // mark original as credited
      final updated = original.copy(
        project: "فاتورة ملغاة باشعار دائن",
        isCredit: 1,
      );
      await _db.updateInvoice(updated);
      return;
    }

    // normal update
    final updated = original.copy(
      total: totalWithTax,
      totalVat: totalTax,
      posted: posted,
      icv: icv,
      invoiceHash: gen.invoiceHash,
      uuid: gen.uuid,
      xml: gen.decodedXml,
      qrCode: gen.qrCode,
      statusCode: businessStatus,
      status: status,
      errorMessage: errorMsg,
      warningMessage: warnMsg,
      isCredit: 0,
    );

    await _db.updateInvoice(updated);
  }

  _BuiltLines _buildInvoiceLines(List<dynamic> lines) {
    num totalWithTax = 0.0;
    num totalTax = 0.0;

    final List<Map<String, dynamic>> invoiceLines = [];

    for (final line in lines) {
      final num qty = (line.qty ?? 0);
      final num priceWithVat = (line.price ?? 0);

      final num lineTotal = (priceWithVat / 1.15) * qty;
      final num taxAmount = lineTotal * 0.15;
      final num withTax = lineTotal + taxAmount;

      totalTax += taxAmount;
      totalWithTax += withTax;

      invoiceLines.add({
        "id": line.id,
        "unitCode": "PCE",
        "quantity": qty,
        "lineExtensionAmount": lineTotal,
        "item": {
          "name": line.productName,
          "classifiedTaxCategory": [
            {
              "percent": 15,
              "taxScheme": {"id": "VAT"}
            }
          ]
        },
        "price": {
          "amount": (priceWithVat / 1.15),
          "unitCode": "UNIT",
          "allowanceCharges": []
        },
        "taxTotal": {"taxAmount": taxAmount, "roundingAmount": withTax}
      });
    }

    return _BuiltLines(
        lines: invoiceLines, totalWithTax: totalWithTax, totalTax: totalTax);
  }
}

class _BuiltLines {
  final List<Map<String, dynamic>> lines;
  final num totalWithTax;
  final num totalTax;

  _BuiltLines({
    required this.lines,
    required this.totalWithTax,
    required this.totalTax,
  });
}

enum ZatcaEnvironment { simulation, core }

enum ZatcaEndpoint {
  reportingSingle, // simplified
  clearanceSingle, // standard
}

extension ZatcaEndpointPath on ZatcaEndpoint {
  String get path {
    switch (this) {
      case ZatcaEndpoint.reportingSingle:
        return "/invoices/reporting/single";
      case ZatcaEndpoint.clearanceSingle:
        return "/invoices/clearance/single";
    }
  }

  bool get isClearance => this == ZatcaEndpoint.clearanceSingle;

  String get clearanceStatusHeaderValue => isClearance ? "1" : "0";
}

class ZatcaSubmitResponse {
  final int httpStatus;
  final Map<String, dynamic> raw;
  final String? reportingStatus;
  final String? clearanceStatus;
  final List<dynamic> errorMessages;
  final List<dynamic> warningMessages;

  ZatcaSubmitResponse({
    required this.httpStatus,
    required this.raw,
    required this.reportingStatus,
    required this.clearanceStatus,
    required this.errorMessages,
    required this.warningMessages,
  });

  bool get isAccepted => httpStatus == 200 || httpStatus == 202;

  String? get businessStatus => reportingStatus ?? clearanceStatus;
}

class ZatcaGenerateResponse {
  final String invoiceHash;
  final String uuid;
  final String invoiceBase64;
  final String qrCode;
  final String decodedXml;

  ZatcaGenerateResponse({
    required this.invoiceHash,
    required this.uuid,
    required this.invoiceBase64,
    required this.qrCode,
    required this.decodedXml,
  });
}

class ZatcaResult {
  final bool ok;
  final String message;
  final ZatcaGenerateResponse? generated;
  final ZatcaSubmitResponse? submitted;

  const ZatcaResult({
    required this.ok,
    required this.message,
    this.generated,
    this.submitted,
  });

  factory ZatcaResult.success(String msg,
      {ZatcaGenerateResponse? generated, ZatcaSubmitResponse? submitted}) {
    return ZatcaResult(
        ok: true, message: msg, generated: generated, submitted: submitted);
  }

  factory ZatcaResult.fail(String msg,
      {ZatcaGenerateResponse? generated, ZatcaSubmitResponse? submitted}) {
    return ZatcaResult(
        ok: false, message: msg, generated: generated, submitted: submitted);
  }
}
