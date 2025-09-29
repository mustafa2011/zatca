import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../helpers/fatoora_db.dart';
import '../screens/edit_product_page.dart';
import '../helpers/zatca_api.dart';
import '../models/product.dart';

class ProductsPg extends StatefulWidget {
  const ProductsPg({super.key});

  @override
  State<ProductsPg> createState() => _ProductsPgState();
}

class _ProductsPgState extends State<ProductsPg> {
  late Future<List<Product>> productsFuture;
  List<Product> _allProducts = []; // Store all products data
  List<Product> _filteredProducts = []; // Store filtered products data
  String _searchQuery = '';
  List<Product> globalProducts = [];
  FatooraDB db = FatooraDB.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      productsFuture = fetchProducts();
      final products = await fetchProducts(); // استنى البيانات
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _filterProducts();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializeProducts();
  }

  void initializeProducts() async {
    try {
      globalProducts = await db.getAllProducts();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
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
                  _filterProducts(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: productsFuture,
              builder: (context, productsSnapshot) {
                if (productsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (productsSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${productsSnapshot.error}'));
                } else if (_filteredProducts.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            Product product = _filteredProducts[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('رقم المنتج: '),
                                  Text(product.id.toString()),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "اسم المنتج: ${product.productName}",
                                    softWrap: true,
                                  ),
                                  Text(
                                    "سعر المنتج: ${NumberFormat("#,##0.00").format(product.price)}",
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
                                      final result =
                                          await Get.to(() => AddEditProductPage(
                                                product: product,
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
                                                      .deleteProduct(product);
                                                  int? productsCount =
                                                      await FatooraDB.instance
                                                          .getProductsCount();
                                                  if (productsCount == 0) {
                                                    await FatooraDB.instance
                                                        .deleteProductSequence();
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
          final result = await Get.to(() => AddEditProductPage());
          if (result == true) {
            _loadData(); // Refresh data if result indicates update
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _filterProducts() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          return product.id.toString().contains(_searchQuery) ||
              product.price.toString().contains(_searchQuery) ||
              product.productName!.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Product>> fetchProducts() async {
    globalProducts = await db.getAllProducts();
    if (globalProducts.isNotEmpty) {
      return globalProducts;
    } else {
      return [];
    }
  }
}
