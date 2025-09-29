import 'package:flutter/material.dart';
import '../helpers/utils.dart';

class InvoiceFormWidget extends StatelessWidget {
  final dynamic qty;
  final dynamic price;
  final String? productName;
  final ValueChanged<dynamic> onChangedQty;
  final ValueChanged<dynamic> onChangedPrice;
  final ValueChanged<String> onChangedProductName;
  final Function()? onPressed;
  final String? payer;
  final String? payerVatNumber;
  final String? date;
  final String? project;
  final ValueChanged<String> onChangedPayer;
  final ValueChanged<String> onChangedPayerVatNumber;
  final ValueChanged<String> onChangedProject;
  final ValueChanged<String> onChangedDate;

  const InvoiceFormWidget({
    super.key,
    this.qty = 1,
    this.price = 0.0,
    this.productName = '',
    required this.onChangedQty,
    required this.onChangedPrice,
    required this.onChangedProductName,
    this.payer = '',
    this.payerVatNumber = '',
    this.date = '',
    this.project = '',
    required this.onChangedPayer,
    required this.onChangedPayerVatNumber,
    required this.onChangedDate,
    required this.onChangedProject,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: buildPayer()),
                  const SizedBox(width: 20),
                  Expanded(child: buildPayerVatNumber()),
                ],
              ),
              Row(
                children: [
                  Expanded(child: buildProject()),
                  const SizedBox(width: 20),
                  Expanded(child: buildDate()),
                ],
              ),
            ],
          ),
        ),
      );

  Widget buildProductName() => TextFormField(
        minLines: 1,
        maxLines: 3,
        initialValue: productName,
        keyboardType: TextInputType.name,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          labelText: 'اسم المنتج/الخدمة',
        ),
        validator: (invoiceName) => invoiceName != null && invoiceName.isEmpty
            ? 'يجب إدخال اسم المنتج'
            : null,
        onChanged: onChangedProductName,
      );

  Widget buildQty() => TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        initialValue: qty.toString(),
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          labelText: 'الكمية',
        ),
        validator: (qty) =>
            qty == null || qty == '' ? 'يجب إدخال الكمية' : null,
        onChanged: (qty) => onChangedQty(qty),
      );

  Widget buildPrice() => TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        initialValue: price.toString(),
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          labelText: 'سعر المنتج',
        ),
        validator: (price) =>
            price == null || price == '' ? 'يجب إدخال سعر المنتج' : null,
        onChanged: (price) => onChangedPrice(price),
      );

  Widget buildInsertButton() => IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.add_shopping_cart_sharp,
          size: 50,
          color: Utils.primary,
        ),
      );

  Widget buildPayer() => TextFormField(
        initialValue: payer,
        keyboardType: TextInputType.name,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          labelText: 'اسم العميل',
        ),
        validator: (value) =>
            value != null && value.isEmpty ? 'يجب إدخال اسم العميل' : null,
        onChanged: onChangedPayer,
      );

  Widget buildPayerVatNumber() => TextFormField(
        initialValue: payerVatNumber,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          labelText: 'الرقم الضريبي للعميل',
        ),
        validator: (value) =>
            value!.length != 15 ? 'الرقم الضريبي 15 رقم' : null,
        onChanged: onChangedPayerVatNumber,
      );

  Widget buildProject() => TextFormField(
        initialValue: project,
        keyboardType: TextInputType.name,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          labelText: 'اسم المشروع',
        ),
        onChanged: onChangedProject,
      );

  Widget buildDate() => TextFormField(
        initialValue: date,
        keyboardType: TextInputType.name,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          labelText: 'التاريخ',
        ),
        onChanged: onChangedDate,
      );
}
