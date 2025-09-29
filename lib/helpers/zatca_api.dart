import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zatca/helpers/fatoora_db.dart';
import 'package:zatca/helpers/token.dart';
import 'package:zatca/helpers/utils.dart';
import 'package:zatca/main.dart';

import '../models/invoice.dart';

const String server = "https://gw-fatoora.zatca.gov.sa/e-invoicing/";
const String reportingEndpoint = "/invoices/reporting/single";
const String clearanceEndpoint = "/invoices/clearance/single";
const String generateInvoiceUrl =
    "https://alwadeh.net/api/GenerateInvoice1.php";

class ZatcaAPI {
  static final ZatcaAPI instance = ZatcaAPI.init();

  static String environment = Utils.environment; // "simulation" OR "core";
  static String certificateToSignXml = "";
  static String cleanPrivateKey = "";
  static String secret = "";
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
        ? "$server$environment$reportingEndpoint"
        : "$server$environment$clearanceEndpoint";
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
