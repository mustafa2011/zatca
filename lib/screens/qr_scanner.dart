import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final String jsonString;

  const QRScannerPage(this.jsonString, {super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح رمز الجودة')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: MobileScannerController(),
              onDetect: (capture) {
                if (!isScanning) return;
                isScanning = false; // Prevent multiple pops
                final List<Barcode> barcodes = capture.barcodes;
                final String? code = barcodes.first.rawValue;
                if (code != null && context.mounted) {
                  final jsonString = parseZatcaQrCodeToJson(code);
                  Navigator.pop(context, jsonString); // Return scanned value
                }
              },
            ),
          ),
          // Expanded(
          //   child: Center(
          //     child: Text(
          //       widget.jsonString,
          //       style: const TextStyle(fontSize: 18),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  String parseZatcaQrCodeToJson(String base64Str) {
    final decodedBytes = base64.decode(base64Str);
    final data = Uint8List.fromList(decodedBytes);

    final result = <String, String>{};
    int index = 0;

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    final numberFormatter = NumberFormat('#0.00');

    for (int i = 1; i <= 5 && index < data.length; i++) {
      final tag = data[index];
      final length = data[index + 1];
      final valueBytes = data.sublist(index + 2, index + 2 + length);
      final value = utf8.decode(valueBytes);

      switch (tag) {
        case 1:
          result['seller'] = value;
          break;
        case 2:
          result['vatNumber'] = value;
          break;
        case 3:
          try {
            final dateTime = DateTime.parse(value);
            result['invoiceDate'] = dateFormatter.format(dateTime);
          } catch (_) {
            result['invoiceDate'] = value;
          }
          break;
        case 4:
          try {
            final amount = double.parse(value);
            result['totalAmount'] = numberFormatter.format(amount);
          } catch (_) {
            result['totalAmount'] = value;
          }
          break;
        case 5:
          try {
            final vat = double.parse(value);
            result['vatAmount'] = numberFormatter.format(vat);
          } catch (_) {
            result['vatAmount'] = value;
          }
          break;
      }

      index += 2 + length;
    }

    return jsonEncode(result);
  }
}
