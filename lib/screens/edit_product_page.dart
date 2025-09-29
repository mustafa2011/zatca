import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../helpers/fatoora_db.dart';
import '../models/product.dart';
import '../widgets/product_form_widget.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';

class AddEditProductPage extends StatefulWidget {
  final dynamic product;

  const AddEditProductPage({
    super.key,
    this.product,
  });

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String productName;
  late num price;
  late String imgUrl;

  @override
  void initState() {
    super.initState();
    productName = widget.product?.productName ?? '';
    price = widget.product?.price ?? 0;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("صفحة المنتج"),
          backgroundColor: Utils.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
              onPressed: () => Get.back(result: true),
              icon: const Icon(Icons.arrow_back)),
          actions: [
            IconButton(
              onPressed: addOrUpdateProduct,
              icon: Icon(
                Icons.save,
                size: 35,
              ),
            )
          ],
        ),
        body: Form(
          key: _formKey,
          child: ProductFormWidget(
            price: price,
            productName: productName,
            onChangedPrice: (price) => setState(() => this.price = price),
            onChangedProductName: (productName) =>
                setState(() => this.productName = productName),
          ),
        ),
      );

  void addOrUpdateProduct() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      final isUpdating = widget.product != null;

      if (isUpdating) {
        await updateProduct();
      } else {
        await addProduct();
      }

      ZatcaAPI.successMessage("تمت عملية الحفظ بنجاح");
    }
  }

  Future updateProduct() async {
    final product = widget.product!.copy(
      price: price,
      productName: productName,
    );
    await FatooraDB.instance.updateProduct(product);
  }

  Future addProduct() async {
    final product = Product(
      price: price,
      productName: productName,
    );
    await FatooraDB.instance.createProduct(product);
  }
}
