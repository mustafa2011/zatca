import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:zatca/helpers/fatoora_db.dart';

import '../helpers/zatca_api.dart';
import '../models/customers.dart';
import '../models/invoice.dart';
import '../pdf/pdf_invoice_api.dart';
import '../pdf/pdf_screen.dart';
import 'edit_invoice_android_page.dart';

class InvoicesPg extends StatefulWidget {
  const InvoicesPg({super.key});

  @override
  State<InvoicesPg> createState() => _InvoicesPgState();
}

class _InvoicesPgState extends State<InvoicesPg> {
  late Future<List<Invoice>> salesFuture;
  List<Invoice> _allInvoices = []; // Store all sales data
  List<Invoice> _filteredInvoices = []; // Store filtered sales data
  String _searchQuery = '';
  List<Invoice> globalInvoices = [];
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
      salesFuture = fetchInvoices();
      final invoices = await fetchInvoices(); // استنى البيانات

      setState(() {
        _allInvoices = invoices;
        _filteredInvoices = invoices;
        _filterInvoices();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializeInvoices();
  }

  void initializeInvoices() async {
    try {
      globalInvoices = await db.getAllInvoices();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات'),
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
                  _filterInvoices(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Invoice>>(
              future: salesFuture,
              builder: (context, salesSnapshot) {
                if (salesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (salesSnapshot.hasError) {
                  return Center(child: Text('Error: ${salesSnapshot.error}'));
                } else if (_filteredInvoices.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            Invoice sale = _filteredInvoices[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('فاتورة: '),
                                  Text(
                                      "${sale.invoiceNo} ${sale.invoiceType == "simplified" ? "مبسطة" : "ضريبية"}"),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "تاريخ: ${sale.date}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "العميل: ${getCustomerNameById(sale.payerId!)}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "اجمالي الفاتورة: ${NumberFormat("#,##0.00").format(sale.total)}",
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
                                      final inv = _filteredInvoices[index];
                                      inv.invoiceKind == "credit"
                                          ? _generateCreditPdf(context, index)
                                          : _generatePdf(context, index);
                                    },
                                  ),
                                  sale.posted == 1
                                      ? IconButton(
                                          icon: Icon(
                                              sale.isCredit == 1
                                                  ? Icons.check
                                                  : Icons.cancel,
                                              color: Colors.red),
                                          onPressed: () async {
                                            try {
                                              final result = await ZatcaAPI.sendCreditNote(
                                                  sale.isCredit == 1
                                                      ? "هذه الفاتورة ملغاة وتم ارتجاعها بالكامل"
                                                      : "مبلغ الفاتورة ${sale.total}\n"
                                                          "هل تريد عمل اشعار دائن والغاء الفاتورة",
                                                  sale);
                                              if (result) _loadData();
                                            } on Exception catch (e) {
                                              ZatcaAPI.errorMessage(
                                                  e.toString());
                                            }

                                            // final result = await Get.to(() =>
                                            //     AddEditInvoiceAndroidPage(
                                            //       invoice: sale,
                                            //       invoiceKind: sale.invoiceKind,
                                            //     ));
                                            // if (result == true) {
                                            //   _loadData(); // Refresh data if result indicates update
                                            // }
                                          },
                                        )
                                      : IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () async {
                                            final result = await Get.to(() =>
                                                AddEditInvoiceAndroidPage(
                                                  invoice: sale,
                                                  invoiceType: sale.invoiceType,
                                                ));
                                            if (result == true) {
                                              _loadData(); // Refresh data if result indicates update
                                            }
                                          },
                                        ),
                                  sale.posted == 1
                                      ? IconButton(
                                          onPressed: () {
                                            ZatcaAPI.successMessage(
                                                "هذه الفاتورة تم ارسالها واعتمادها من هيئة الزكاة");
                                          },
                                          icon: const Icon(Icons.check),
                                          color: Colors.green,
                                        )
                                      : IconButton(
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
                                                            .deleteInvoice(
                                                                sale);
                                                        int? invoicesCount =
                                                            await FatooraDB
                                                                .instance
                                                                .getInvoicesCount();
                                                        if (invoicesCount ==
                                                            0) {
                                                          await FatooraDB
                                                              .instance
                                                              .deleteInvoiceSequence();
                                                          await FatooraDB
                                                              .instance
                                                              .deleteInvoiceLinesSequence();
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
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'اجمالي الفواتير: ${NumberFormat("#,##0.00").format(_calculateTotalNetWithVat())}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'اجمالي اشعارات الدائن: ${NumberFormat("#,##0.00").format(_calculateTotalCreditNote())}',
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
          final result = await Get.to(() => AddEditInvoiceAndroidPage());
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
              final inv = _filteredInvoices[index];
              final customer =
                  await FatooraDB.instance.getCustomerById(inv.payerId!);
              final items =
                  await FatooraDB.instance.getInvoiceLinesById(inv.id!);
              String invKind = inv.invoiceKind;
              int posted = inv.posted;

              try {
                pdf = await PdfInvoiceApi.generate(
                  inv,
                  customer,
                  items,
                  posted == 1
                      ? invKind == "simplified"
                          ? 'فاتورة ضريبية مبسطة'
                          : 'فاتورة مبيعات ضريبية'
                      : 'فاتورة مبيعات مبدئية',
                  inv.project,
                  true,
                );
              } catch (e) {
                // Handle error
                ZatcaAPI.errorMessage(e.toString());
              } finally {
                if (context.mounted) {
                  Navigator.pop(context);
                  Get.to(() => ShowPDF(
                        pdf: pdf,
                        title:
                            inv.posted == 1 ? 'فاتورة ضريبية' : 'فاتورة مبدئية',
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

  void _generateCreditPdf(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        File? pdf;
        return StatefulBuilder(
          builder: (context, setState) {
            Future.microtask(() async {
              final inv = _filteredInvoices[index];
              final customer =
                  await FatooraDB.instance.getCustomerById(inv.payerId!);

              try {
                pdf = await PdfInvoiceApi.generateCreditNote(
                  inv,
                  customer,
                  'اشعار دائن',
                  inv.project,
                  true,
                );
              } catch (e) {
                // Handle error
                ZatcaAPI.errorMessage(e.toString());
              } finally {
                if (context.mounted) {
                  Navigator.pop(context);
                  Get.to(() => ShowPDF(
                        pdf: pdf,
                        title:
                            inv.posted == 1 ? 'فاتورة ضريبية' : 'فاتورة مبدئية',
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

  double _calculateTotalNetWithVat() {
    return _filteredInvoices.fold(0.0, (sum, sale) {
      if (sale.invoiceKind == "invoice") {
        return sum + sale.total;
      }
      return sum;
    });
  }

  double _calculateTotalCreditNote() {
    return _filteredInvoices.fold(0.0, (sum, sale) {
      if (sale.invoiceKind == "credit") {
        return sum + sale.total;
      }
      return sum;
    });
  }

  void _filterInvoices() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredInvoices = _allInvoices; // No filter, show all sales
      } else {
        _filteredInvoices = _allInvoices.where((sale) {
          String customerName = getCustomerNameById(sale.payerId!);

          return sale.invoiceNo.contains(_searchQuery) ||
              sale.date.contains(_searchQuery) ||
              sale.total.toString().contains(_searchQuery) ||
              customerName.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Invoice>> fetchInvoices() async {
    globalCustomers = await db.getAllCustomers();
    globalInvoices = await db.getAllInvoices();
    if (globalInvoices.isNotEmpty) {
      return globalInvoices;
    } else {
      return [];
    }
  }
}
