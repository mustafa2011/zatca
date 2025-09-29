import 'package:flutter/material.dart';
import '../helpers/utils.dart';

class InvoicePayerWidget extends StatelessWidget {
  final String? payer;
  final String? payerTaxNumber;
  final ValueChanged<String> onChangedPayer;
  final ValueChanged<String> onChangedPayerTaxNumber;

  const InvoicePayerWidget({
    super.key,
    this.payer = 'عميل نقدي',
    this.payerTaxNumber = '',
    required this.onChangedPayer,
    required this.onChangedPayerTaxNumber,
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
                  Expanded(child: buildPayerTaxNumber()),
                ],
              ),
            ],
          ),
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

  Widget buildPayerTaxNumber() => TextFormField(
        initialValue: payerTaxNumber,
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
        onChanged: onChangedPayerTaxNumber,
      );
}
