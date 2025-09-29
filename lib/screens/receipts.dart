import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../helpers/fatoora_db.dart';
import '../screens/edit_receipt_page.dart';
import '../helpers/zatca_api.dart';
import '../models/receipt.dart';
import '../pdf/pdf_receipt_api.dart';
import '../pdf/pdf_screen.dart';

class ReceiptsPg extends StatefulWidget {
  const ReceiptsPg({super.key});

  @override
  State<ReceiptsPg> createState() => _ReceiptsPgState();
}

class _ReceiptsPgState extends State<ReceiptsPg> {
  late Future<List<Receipt>> receiptsFuture;
  List<Receipt> _allReceipts = []; // Store all receipts data
  List<Receipt> _filteredReceipts = []; // Store filtered receipts data
  String _searchQuery = '';
  List<Receipt> globalReceipts = [];
  FatooraDB db = FatooraDB.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      receiptsFuture = fetchReceipts();
      final receipts = await fetchReceipts(); // استنى البيانات

      setState(() {
        _allReceipts = receipts;
        _filteredReceipts = receipts;
        _filterReceipts();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializeReceipts();
  }

  void initializeReceipts() async {
    try {
      globalReceipts = await db.getAllReceipts();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السندات'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 30),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'بحث',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _filterReceipts(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Receipt>>(
              future: receiptsFuture,
              builder: (context, receiptsSnapshot) {
                if (receiptsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (receiptsSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${receiptsSnapshot.error}'));
                } else if (_filteredReceipts.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredReceipts.length,
                          itemBuilder: (context, index) {
                            Receipt receipt = _filteredReceipts[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('سند: '),
                                  Text(receipt.id.toString()),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "تاريخ: ${receipt.date}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "نوع السند: ${receipt.receiptType}",
                                    softWrap: true,
                                  ),
                                  receipt.receiptType == "قبض"
                                      ? Text(
                                          "المستلم: ${receipt.receivedFrom}",
                                          softWrap: true,
                                        )
                                      : Text(
                                          "المصروف له: ${receipt.payTo}",
                                          softWrap: true,
                                        ),
                                  Text(
                                    "قيمة السند: ${NumberFormat("#,##0.00").format(receipt.amount)}",
                                    softWrap: true,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.picture_as_pdf),
                                    onPressed: () async {
                                      _generatePdf(context, index);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () async {
                                      final result =
                                          await Get.to(() => AddEditReceiptPage(
                                                receipt: receipt,
                                              ));
                                      if (result == true) {
                                        _loadData(); // Refresh data if result indicates update
                                      }
                                    },
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('رسالة'),
                                            content: const Text(
                                                "هل تريد حذف السجل الحالي"),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text("نعم"),
                                                onPressed: () async {
                                                  await FatooraDB.instance
                                                      .deleteReceiptById(
                                                          receipt.id!);
                                                  int? receiptsCount =
                                                      await FatooraDB.instance
                                                          .getReceiptsCount();
                                                  if (receiptsCount == 0) {
                                                    await FatooraDB.instance
                                                        .deleteReceiptSequence();
                                                  }
                                                  Get.back();
                                                  ZatcaAPI.successMessage(
                                                      "تمت عملية الحذف بنجاح");
                                                  _loadData();
                                                },
                                              ),
                                              TextButton(
                                                child: const Text("لا"),
                                                onPressed: () {
                                                  Get.back();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.delete),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // height(30),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 25.0, bottom: 25, right: 10),
                        child: Column(
                          children: [
                            Text(
                              'اجمالي سندات القبض: ${NumberFormat("#,##0.00").format(_calculateTotalR())}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'اجمالي سندات الصرف: ${NumberFormat("#,##0.00").format(_calculateTotalP())}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => AddEditReceiptPage());
          if (result == true) {
            _loadData(); // Refresh data if result indicates update
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _generatePdf(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        File? pdf;
        return StatefulBuilder(
          builder: (context, setState) {
            Future.microtask(() async {
              final inv = _filteredReceipts[index];

              try {
                pdf =
                    await PdfReceiptApi.generate(inv, 'سند ${inv.receiptType}');
              } catch (e) {
                ZatcaAPI.errorMessage(e.toString());
              } finally {
                if (context.mounted) {
                  Navigator.pop(context);
                  Get.to(() => ShowPDF(
                        pdf: pdf,
                        title: 'سند ${inv.receiptType}',
                      ));
                }
              }
            });

            return AlertDialog(
              content: Row(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("فضلا انتظر لحظات ..."),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _calculateTotalR() {
    return _filteredReceipts.fold(
        0.0,
        (sum, receipt) =>
            sum + (receipt.receiptType == "قبض" ? receipt.amount : 0));
  }

  double _calculateTotalP() {
    return _filteredReceipts.fold(
        0.0,
        (sum, receipt) =>
            sum + (receipt.receiptType == "صرف" ? receipt.amount : 0));
  }

  void _filterReceipts() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredReceipts = _allReceipts; // No filter, show all receipts
      } else {
        _filteredReceipts = _allReceipts.where((receipt) {
          return receipt.id.toString().contains(_searchQuery) ||
              receipt.date.contains(_searchQuery) ||
              receipt.amount.toString().contains(_searchQuery) ||
              receipt.receivedFrom.contains(_searchQuery) ||
              receipt.payTo.contains(_searchQuery) ||
              receipt.receiptType.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Receipt>> fetchReceipts() async {
    globalReceipts = await db.getAllReceipts();
    if (globalReceipts.isNotEmpty) {
      return globalReceipts;
    } else {
      return [];
    }
  }
}
