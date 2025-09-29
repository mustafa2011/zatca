import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/zatca_api.dart';
import '../models/purchase.dart';
import '../models/suppliers.dart';
import '../screens/edit_supplier_page.dart';

class SuppliersPg extends StatefulWidget {
  const SuppliersPg({super.key});

  @override
  State<SuppliersPg> createState() => _SuppliersPgState();
}

class _SuppliersPgState extends State<SuppliersPg> {
  late Future<List<Supplier>> suppliersFuture;
  List<Supplier> _allSuppliers = []; // Store all suppliers data
  List<Supplier> _filteredSuppliers = []; // Store filtered suppliers data
  List<Purchase> _filteredPurchases = []; // Store filtered purchases data
  String _searchQuery = '';
  List<Supplier> globalSuppliers = [];
  List<Purchase> globalPurchases = [];
  FatooraDB db = FatooraDB.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      suppliersFuture = fetchSuppliers();
      final suppliers = await fetchSuppliers(); // استنى البيانات
      final purchases = await fetchPurchases();
      setState(() {
        _allSuppliers = suppliers;
        _filteredSuppliers = suppliers;
        _filteredPurchases = purchases;
        _filterSuppliers();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializeSuppliers();
  }

  void initializeSuppliers() async {
    try {
      globalSuppliers = await db.getAllSuppliers();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردين'),
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
                  _filterSuppliers(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Supplier>>(
              future: suppliersFuture,
              builder: (context, suppliersSnapshot) {
                if (suppliersSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (suppliersSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${suppliersSnapshot.error}'));
                } else if (_filteredSuppliers.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredSuppliers.length,
                          itemBuilder: (context, index) {
                            Supplier supplier = _filteredSuppliers[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('رقم المورد: '),
                                  Text(supplier.id.toString()),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "اسم المورد: ${supplier.name}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "مشتريات المورد: ${NumberFormat("#,##0.00").format(_calcTotal(supplier.id!))}",
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
                                          () => AddEditSupplierPage(
                                                supplier: supplier,
                                              ));
                                      if (result == true) {
                                        _loadData(); // Refresh data if result indicates update
                                      }
                                    },
                                  ),
                                  supplier.id == 1
                                      ? Container()
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
                                                        double ttl = _calcTotal(
                                                            supplier.id!);
                                                        if (ttl > 0) {
                                                          ZatcaAPI.snackError(
                                                              "لا يمكن حذف مورد له مشتريات");
                                                          Get.back();
                                                        } else {
                                                          await FatooraDB
                                                              .instance
                                                              .deleteSupplier(
                                                                  supplier);
                                                          int? suppliersCount =
                                                              await FatooraDB
                                                                  .instance
                                                                  .getSupplierCount();
                                                          if (suppliersCount ==
                                                              0) {
                                                            await FatooraDB
                                                                .instance
                                                                .deleteSupplierSequence();
                                                          }
                                                          Get.back();
                                                          ZatcaAPI.successMessage(
                                                              "تمت عملية الحذف بنجاح");
                                                          _loadData();
                                                        }
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
                        child: Text(
                          'اجمالي مشتريات الموردين: ${NumberFormat("#,##0.00").format(_calcTotalPurchases())}',
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
          final result = await Get.to(() => AddEditSupplierPage());
          if (result == true) {
            _loadData(); // Refresh data if result indicates update
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  double _calcTotal(int id) {
    return _filteredPurchases
        .where((purchase) =>
            int.parse(purchase.vendor) == id) // filter by supplierId
        .fold(0.0, (sum, purchase) => sum + purchase.total); // sum the totals
  }

  double _calcTotalPurchases() {
    return _filteredPurchases.fold(
        0.0, (sum, purchase) => sum + purchase.total); // sum the totals
  }

  void _filterSuppliers() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredSuppliers = _allSuppliers;
      } else {
        _filteredSuppliers = _allSuppliers.where((supplier) {
          return supplier.id.toString().contains(_searchQuery) ||
              supplier.name.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Supplier>> fetchSuppliers() async {
    globalSuppliers = await db.getAllSuppliers();
    if (globalSuppliers.isNotEmpty) {
      return globalSuppliers;
    } else {
      return [];
    }
  }

  Future<List<Purchase>> fetchPurchases() async {
    globalPurchases = await db.getAllPurchases();
    if (globalPurchases.isNotEmpty) {
      return globalPurchases;
    } else {
      return [];
    }
  }
}
