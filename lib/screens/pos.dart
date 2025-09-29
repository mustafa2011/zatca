import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/zatca_api.dart';
import '../models/po.dart';
import '../models/suppliers.dart';
import '../pdf/pdf_po_api.dart';
import '../pdf/pdf_screen.dart';
import '../screens/edit_po_page.dart';

class PosPg extends StatefulWidget {
  const PosPg({super.key});

  @override
  State<PosPg> createState() => _PosPgState();
}

class _PosPgState extends State<PosPg> {
  late Future<List<Po>> posFuture;
  List<Po> _allPos = []; // Store all pos data
  List<Po> _filteredPos = []; // Store filtered pos data
  String _searchQuery = '';
  List<Po> globalPos = [];
  List<Supplier> globalSuppliers = [];
  FatooraDB db = FatooraDB.instance;

  String getSupplierNameById(int supplierId) {
    var supplier =
        globalSuppliers.firstWhere((supplier) => supplier.id == supplierId);
    return supplier.name;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      posFuture = fetchPos();
      final pos = await fetchPos(); // استنى البيانات

      setState(() {
        _allPos = pos;
        _filteredPos = pos;
        _filterPos();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializePos();
  }

  void initializePos() async {
    try {
      globalPos = await db.getAllPo();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات شراء'),
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
                  _filterPos(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Po>>(
              future: posFuture,
              builder: (context, posSnapshot) {
                if (posSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (posSnapshot.hasError) {
                  return Center(child: Text('Error: ${posSnapshot.error}'));
                } else if (_filteredPos.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredPos.length,
                          itemBuilder: (context, index) {
                            Po po = _filteredPos[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('طلب: '),
                                  Text(po.poNo),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "تاريخ: ${po.date}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "المورد: ${getSupplierNameById(po.payerId!)}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "اجمالي الطلب: ${NumberFormat("#,##0.00").format(po.total)}",
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
                                          await Get.to(() => AddEditPoPage(
                                                po: po,
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
                                                      .deletePoById(po.id!);
                                                  int? posCount =
                                                      await FatooraDB.instance
                                                          .getPoCount();
                                                  if (posCount == 0) {
                                                    await FatooraDB.instance
                                                        .deletePoSequence();
                                                    await FatooraDB.instance
                                                        .deletePoLinesSequence();
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
                          'اجمالي الطلبات: ${NumberFormat("#,##0.00").format(_calculateTotalNetWithVat())}',
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
          final result = await Get.to(() => AddEditPoPage());
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
              final inv = _filteredPos[index];
              final supplier =
                  await FatooraDB.instance.getSupplierById(inv.payerId!);
              final items = await FatooraDB.instance.getPoLinesById(inv.id!);

              try {
                pdf = await PdfPoApi.generate(
                  inv,
                  supplier,
                  items,
                  'طلب شراء',
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
                        title: 'طلب شراء',
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
    return _filteredPos.fold(0.0, (sum, po) => sum + po.total);
  }

  void _filterPos() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredPos = _allPos; // No filter, show all pos
      } else {
        _filteredPos = _allPos.where((po) {
          String supplierName = getSupplierNameById(po.payerId!);
          return po.poNo.contains(_searchQuery) ||
              po.date.contains(_searchQuery) ||
              po.total.toString().contains(_searchQuery) ||
              supplierName.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Po>> fetchPos() async {
    globalSuppliers = await db.getAllSuppliers();
    globalPos = await db.getAllPo();
    if (globalPos.isNotEmpty) {
      return globalPos;
    } else {
      return [];
    }
  }
}
