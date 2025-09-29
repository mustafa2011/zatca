import 'package:flutter/material.dart';
import '../widgets/widget.dart';

class ProductFormWidget extends StatelessWidget {
  final num price;
  final String? productName;
  final ValueChanged<num> onChangedPrice;
  final ValueChanged<String> onChangedProductName;

  const ProductFormWidget({
    super.key,
    this.price = 0.0,
    this.productName = '',
    required this.onChangedPrice,
    required this.onChangedProductName,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildProductName(),
              const SizedBox(height: 4),
              buildPrice(),
            ],
          ),
        ),
      );

  Widget buildProductName() => MyTextFormField(
        initialValue: productName,
        keyboardType: TextInputType.name,
        textAlign: TextAlign.center,
        labelText: 'اسم المنتج',
        isMandatory: true,
        onChanged: onChangedProductName,
      );

  Widget buildPrice() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        initialValue: price.toString(),
        textAlign: TextAlign.center,
        labelText: 'سعر المنتج',
        isMandatory: true,
        onChanged: (price) =>
            price.isNotEmpty ? onChangedPrice(num.parse(price)) : null,
      );
}
