import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/zatca_api.dart';
import '../models/customers.dart';
import '../models/invoice.dart';
import '../screens/edit_customer_page.dart';

class CustomersPg extends StatefulWidget {
  const CustomersPg({super.key});

  @override
  State<CustomersPg> createState() => _CustomersPgState();
}

class _CustomersPgState extends State<CustomersPg> {
  late Future<List<Customer>> customersFuture;
  List<Customer> _allCustomers = []; // Store all customers data
  List<Customer> _filteredCustomers = []; // Store filtered customers data
  List<Invoice> _filteredSales = []; // Store filtered sales data
  String _searchQuery = '';
  List<Customer> globalCustomers = [];
  List<Invoice> globalInvoices = [];
  FatooraDB db = FatooraDB.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      customersFuture = fetchCustomers();
      final customers = await fetchCustomers(); // استنى البيانات
      final sales = await fetchInvoices();
      setState(() {
        _allCustomers = customers;
        _filteredCustomers = customers;
        _filteredSales = sales;
        _filterCustomers();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializeCustomers();
  }

  void initializeCustomers() async {
    try {
      globalCustomers = await db.getAllCustomers();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
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
                  _filterCustomers(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: customersFuture,
              builder: (context, customersSnapshot) {
                if (customersSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (customersSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${customersSnapshot.error}'));
                } else if (_filteredCustomers.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            Customer customer = _filteredCustomers[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('رقم العميل: '),
                                  Text(customer.id.toString()),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "اسم العميل: ${customer.name}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "مبيعات العميل: ${NumberFormat("#,##0.00").format(calcCustomerTotalSales(customer.id!))}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "مرتجعات العميل: ${NumberFormat("#,##0.00").format(calcCustomerTotalCredits(customer.id!))}",
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
                                          () => AddEditCustomerPage(
                                                customer: customer,
                                              ));
                                      if (result == true) {
                                        _loadData(); // Refresh data if result indicates update
                                      }
                                    },
                                  ),
                                  customer.id == 1
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
                                                        double ttl =
                                                            calcCustomerTotalSales(
                                                                customer.id!);
                                                        if (ttl > 0) {
                                                          ZatcaAPI.snackError(
                                                              "لا يمكن حذف عميل له مبيعات");
                                                          Get.back();
                                                        } else {
                                                          await FatooraDB
                                                              .instance
                                                              .deleteCustomer(
                                                                  customer);
                                                          int? customersCount =
                                                              await FatooraDB
                                                                  .instance
                                                                  .getCustomerCount();
                                                          if (customersCount ==
                                                              0) {
                                                            await FatooraDB
                                                                .instance
                                                                .deleteCustomerSequence();
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
                            top: 25.0, bottom: 50, right: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'اجمالي مبيعات العملاء: ${NumberFormat("#,##0.00").format(calcTotalSales())}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'اجمالي مرتجعات العملاء: ${NumberFormat("#,##0.00").format(calcTotalCredits())}',
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
          final result = await Get.to(() => AddEditCustomerPage());
          if (result == true) {
            _loadData(); // Refresh data if result indicates update
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  double calcCustomerTotalSales(int id) {
    return _filteredSales
        .where((sale) => sale.payerId == id) // filter by customerId
        .fold(0.0, (sum, sale) {
      if (sale.invoiceKind == "invoice") {
        return sum + sale.total;
      }
      return sum;
    }); // sum the totals
  }

  double calcCustomerTotalCredits(int id) {
    return _filteredSales
        .where((sale) => sale.payerId == id) // filter by customerId
        .fold(0.0, (sum, sale) {
      if (sale.invoiceKind == "credit") {
        return sum + sale.total;
      }
      return sum;
    }); // sum the totals
  }

  double calcTotalSales() {
    return _filteredSales.fold(0.0, (sum, sale) {
      if (sale.invoiceKind == "invoice") {
        return sum + sale.total;
      }
      return sum;
    });
  }

  double calcTotalCredits() {
    return _filteredSales.fold(0.0, (sum, sale) {
      if (sale.invoiceKind == "credit") {
        return sum + sale.total;
      }
      return sum;
    });
  }

  void _filterCustomers() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers.where((customer) {
          return customer.id.toString().contains(_searchQuery) ||
              customer.name.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Customer>> fetchCustomers() async {
    globalCustomers = await db.getAllCustomers();
    if (globalCustomers.isNotEmpty) {
      return globalCustomers;
    } else {
      return [];
    }
  }

  Future<List<Invoice>> fetchInvoices() async {
    globalInvoices = await db.getAllInvoices();
    if (globalInvoices.isNotEmpty) {
      return globalInvoices;
    } else {
      return [];
    }
  }
}
