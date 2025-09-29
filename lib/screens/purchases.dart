import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/zatca_api.dart';
import '../models/purchase.dart';
import '../models/suppliers.dart';
import '../screens/edit_invoice_android_page.dart';

class PurchasesPg extends StatefulWidget {
  const PurchasesPg({super.key});

  @override
  State<PurchasesPg> createState() => _PurchasesPgState();
}

class _PurchasesPgState extends State<PurchasesPg> {
  late Future<List<Purchase>> purchasesFuture;
  List<Purchase> _allPurchases = []; // Store all purchases data
  List<Purchase> _filteredPurchases = []; // Store filtered purchases data
  String _searchQuery = '';
  List<Purchase> globalPurchases = [];
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
      purchasesFuture = fetchPurchases();
      final purchases = await fetchPurchases(); // استنى البيانات

      setState(() {
        _allPurchases = purchases;
        _filteredPurchases = purchases;
        _filterPurchases();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializePurchases();
  }

  void initializePurchases() async {
    try {
      globalPurchases = await db.getAllPurchases();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المشتريات'),
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
                  _filterPurchases(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Purchase>>(
              future: purchasesFuture,
              builder: (context, purchasesSnapshot) {
                if (purchasesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (purchasesSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${purchasesSnapshot.error}'));
                } else if (_filteredPurchases.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredPurchases.length,
                          itemBuilder: (context, index) {
                            Purchase purchase = _filteredPurchases[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('فاتورة: '),
                                  Text(purchase.id.toString()),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "تاريخ: ${purchase.date}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "المورد: ${getSupplierNameById(int.parse(purchase.vendor))}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "اجمالي الفاتورة: ${NumberFormat("#,##0.00").format(purchase.total)}",
                                    softWrap: true,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Get.to(
                                          () => AddEditInvoiceAndroidPage(
                                                purchase: purchase,
                                                isPurchases: true,
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
                                                      .deletePurchaseById(
                                                          purchase.id!);
                                                  int? purchasesCount =
                                                      await FatooraDB.instance
                                                          .getPurchasesCount();
                                                  if (purchasesCount == 0) {
                                                    await FatooraDB.instance
                                                        .deletePurchaseSequence();
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
                          'اجمالي الفواتير: ${NumberFormat("#,##0.00").format(_calculateTotalNetWithVat())}',
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
          final result = await Get.to(() => AddEditInvoiceAndroidPage(
                isPurchases: true,
              ));
          if (result == true) {
            _loadData(); // Refresh data if result indicates update
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  double _calculateTotalNetWithVat() {
    return _filteredPurchases.fold(
        0.0, (sum, purchase) => sum + purchase.total);
  }

  void _filterPurchases() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredPurchases = _allPurchases; // No filter, show all purchases
      } else {
        _filteredPurchases = _allPurchases.where((purchase) {
          String supplierName = getSupplierNameById(int.parse(purchase.vendor));

          return purchase.id.toString().contains(_searchQuery) ||
              purchase.date.contains(_searchQuery) ||
              purchase.total.toString().contains(_searchQuery) ||
              supplierName.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Purchase>> fetchPurchases() async {
    globalSuppliers = await db.getAllSuppliers();
    globalPurchases = await db.getAllPurchases();
    if (globalPurchases.isNotEmpty) {
      return globalPurchases;
    } else {
      return [];
    }
  }
}
