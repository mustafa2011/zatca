import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:zatca/screens/sales.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/customers.dart';
import '../models/estimate.dart';
import '../models/invoice.dart';
import '../pdf/pdf_estimate_api.dart';
import '../pdf/pdf_screen.dart';
import '../screens/edit_estimate_page.dart';

class EstimatesPg extends StatefulWidget {
  const EstimatesPg({super.key});

  @override
  State<EstimatesPg> createState() => _EstimatesPgState();
}

class _EstimatesPgState extends State<EstimatesPg> {
  late Future<List<Estimate>> estimatesFuture;
  List<Estimate> _allEstimates = []; // Store all estimates data
  List<Estimate> _filteredEstimates = []; // Store filtered estimates data
  String _searchQuery = '';
  List<Estimate> globalEstimates = [];
  List<Customer> globalCustomers = [];
  FatooraDB db = FatooraDB.instance;

  String getCustomerNameById(int customerId) {
    var customer =
        globalCustomers.firstWhere((customer) => customer.id == customerId);
    return customer.name;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      estimatesFuture = fetchEstimates();
      final estimates = await fetchEstimates(); // استنى البيانات

      setState(() {
        _allEstimates = estimates;
        _filteredEstimates = estimates;
        _filterEstimates();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializeEstimates();
  }

  void initializeEstimates() async {
    try {
      globalEstimates = await db.getAllEstimates();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عروض أسعار'),
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
                  _filterEstimates(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Estimate>>(
              future: estimatesFuture,
              builder: (context, estimatesSnapshot) {
                if (estimatesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (estimatesSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${estimatesSnapshot.error}'));
                } else if (_filteredEstimates.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredEstimates.length,
                          itemBuilder: (context, index) {
                            Estimate estimate = _filteredEstimates[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('عرض: '),
                                  Text(estimate.estimateNo),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "تاريخ: ${estimate.date}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "المشروع: ${estimate.project}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "اجمالي العرض: ${NumberFormat("#,##0.00").format(estimate.total)}",
                                    softWrap: true,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.add_box),
                                    onPressed: () async {
                                      _generateInvoice(context, index);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.picture_as_pdf),
                                    onPressed: () async {
                                      _generatePdf(context, index);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Get.to(
                                          () => AddEditEstimatePage(
                                                estimate: estimate,
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
                                                      .deleteEstimateById(
                                                          estimate.id!);
                                                  int? estimatesCount =
                                                      await FatooraDB.instance
                                                          .getEstimatesCount();
                                                  if (estimatesCount == 0) {
                                                    await FatooraDB.instance
                                                        .deleteEstimateSequence();
                                                    await FatooraDB.instance
                                                        .deleteEstimateLinesSequence();
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
                            top: 25.0, bottom: 50, right: 10),
                        child: Text(
                          'اجمالي العروض: ${NumberFormat("#,##0.00").format(_calculateTotalNetWithVat())}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
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
          final result = await Get.to(() => AddEditEstimatePage());
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
              final inv = _filteredEstimates[index];
              final customer =
                  await FatooraDB.instance.getCustomerById(inv.payerId!);
              final items =
                  await FatooraDB.instance.getEstimateLinesById(inv.id!);

              try {
                pdf = await PdfEstimateApi.generate(
                  inv,
                  customer,
                  items,
                  'عرض سعر',
                  inv.project,
                  true,
                );
              } catch (e) {
                ZatcaAPI.errorMessage(e.toString());
              } finally {
                if (context.mounted) {
                  Navigator.pop(context);
                  Get.to(() => ShowPDF(
                        pdf: pdf,
                        title: 'عرض سعر',
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

  void _generateInvoice(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future.microtask(() async {
              try {
                final inv = _filteredEstimates[index];
                final items =
                    await FatooraDB.instance.getEstimateLinesById(inv.id!);
                final newInvId =
                    (await FatooraDB.instance.getNewInvoiceId())! + 1;

                Invoice invoice = Invoice(
                  id: newInvId,
                  invoiceNo: '${Utils.clientId}-$newInvId',
                  date: inv.date,
                  supplyDate: inv.date,
                  sellerId: Utils.clientId,
                  project: inv.project,
                  total: inv.total,
                  totalVat: inv.totalVat,
                  posted: 0,
                  payerId: inv.payerId,
                  noOfLines: items.length,
                  paymentMethod: inv.paymentMethod,
                );
                await FatooraDB.instance.createInvoice(invoice);
                List<InvoiceLines> invoiceLines = [];
                InvoiceLines invoiceLine;

                for (int i = 0; i < items.length; i++) {
                  invoiceLines.add(InvoiceLines(
                      recId: newInvId,
                      productName: items[i].productName,
                      price: items[i].price,
                      qty: items[i].qty));

                  invoiceLine = invoiceLines[i];

                  await FatooraDB.instance
                      .createInvoiceLines(invoiceLine, newInvId);
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                ZatcaAPI.errorMessage(e.toString());
              } finally {
                if (context.mounted) {
                  Navigator.pop(context);
                  Get.to(() => InvoicesPg());
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

  double _calculateTotalNetWithVat() {
    return _filteredEstimates.fold(
        0.0, (sum, estimate) => sum + estimate.total);
  }

  void _filterEstimates() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredEstimates = _allEstimates; // No filter, show all estimates
      } else {
        _filteredEstimates = _allEstimates.where((estimate) {
          return estimate.estimateNo.contains(_searchQuery) ||
              estimate.date.contains(_searchQuery) ||
              estimate.total.toString().contains(_searchQuery) ||
              estimate.project.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Estimate>> fetchEstimates() async {
    globalCustomers = await db.getAllCustomers();
    globalEstimates = await db.getAllEstimates();
    if (globalEstimates.isNotEmpty) {
      return globalEstimates;
    } else {
      return [];
    }
  }
}
