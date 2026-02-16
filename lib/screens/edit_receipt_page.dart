import 'dart:async';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zatca/screens/receipts.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/customers.dart';
import '../models/receipt.dart';
import '../models/settings.dart';
import '../pdf/pdf_receipt_api.dart';
import '../widgets/widget.dart';

class AddEditReceiptPage extends StatefulWidget {
  final Receipt? receipt;

  const AddEditReceiptPage({
    super.key,
    this.receipt,
  });

  @override
  State<AddEditReceiptPage> createState() => _AddEditReceiptPageState();
}

class _AddEditReceiptPageState extends State<AddEditReceiptPage> {
  List<String> payTypeList = ['نقدا', 'شيك', 'حوالة'];

  final _key1 = GlobalKey<FormState>();
  late int newId; // This id for new receipt id in cloud database
  late int id = 1; // this is existing receipt id will be retrieved from widget
  late final String date;
  String payType = "نقدا";
  late final String receivedFrom;
  late final String sumOf;
  late final num amount;
  late final String amountFor;
  late final String chequeNo;
  late final String chequeDate;
  late final String transferNo;
  late final String transferDate;
  late final String bank;
  late final String payTo;
  String receiptType = "قبض";
  late final Setting seller;
  late String receiptNo;
  int counter = 0;
  final TextEditingController _date = TextEditingController();
  final TextEditingController _receivedFrom = TextEditingController();
  final TextEditingController _sumOf = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _amountFor = TextEditingController();
  final TextEditingController _chequeNo = TextEditingController();
  final TextEditingController _chequeDate = TextEditingController();
  final TextEditingController _transferNo = TextEditingController();
  final TextEditingController _transferDate = TextEditingController();
  final TextEditingController _bank = TextEditingController();
  final TextEditingController _payTo = TextEditingController();

  final FocusNode focusNode = FocusNode();

  bool isLoading = false;
  String language = 'Arabic';
  String pdfPath = "";
  late List<String> customers = [];
  int payerId = 0;

  @override
  void initState() {
    super.initState();
    getReceipt();
    focusNode.requestFocus();
  }

  Future getReceipt() async {
    FatooraDB db = FatooraDB.instance;
    language = "Arabic";
    final pdfDir = await getApplicationDocumentsDirectory();
    pdfPath = "${pdfDir.path}/RECEIPT.pdf";
    List<Customer> list = await db.getAllCustomers();
    if (list.isEmpty) {
      await db.createCustomer(
          const Customer(name: 'عميل نقدي', vatNumber: '000000000000000'));
    }
    customers.clear();
    for (int i = 0; i < list.length; i++) {
      customers.add("${list[i].id}-${list[i].name}");
    }
    try {
      setState(() => isLoading = true);
      var user = await db.getAllSettings();
      seller = user[0];

      int? receiptsCount = await FatooraDB.instance.getReceiptsCount();

      if (widget.receipt != null) {
        date = widget.receipt!.date;
        sumOf = widget.receipt!.sumOf;
        payType = widget.receipt!.payType;
        receivedFrom = widget.receipt!.receivedFrom;
        amount = widget.receipt!.amount;
        amountFor = widget.receipt!.amountFor;
        chequeNo = widget.receipt!.chequeNo;
        chequeDate = widget.receipt!.chequeDate;
        transferNo = widget.receipt!.transferNo;
        transferDate = widget.receipt!.transferDate;
        bank = widget.receipt!.bank;
        payTo = widget.receipt!.payTo;
        receiptType = widget.receipt!.receiptType;
      } else {
        date = Utils.formatShortDate(DateTime.now());
        sumOf = '';
        payType = "نقدا";
        receivedFrom = '';
        amount = 0;
        amountFor = '';
        chequeNo = '';
        chequeDate = '';
        transferNo = '';
        transferDate = '';
        bank = '';
        payTo = '';
        receiptType = "قبض";
      }
      id = widget.receipt != null
          ? widget.receipt!.id!
          : receiptsCount == 0
              ? 1
              : (await db.getNewReceiptId())! + 1;
      _date.text = date;
      _sumOf.text = sumOf;
      _receivedFrom.text = receivedFrom;
      _amount.text = amount.toString();
      _amountFor.text = amountFor;
      _chequeNo.text = chequeNo;
      _chequeDate.text = chequeDate;
      _transferNo.text = transferNo;
      _transferDate.text = transferDate;
      _bank.text = bank;
      _payTo.text = payTo;

      receiptNo = id.toString(); // like '0000321'

      setState(() {
        isLoading = false;
      });
    } on Exception catch (e) {
      messageBox(e.toString());
    }
  }

  void messageBox(String? message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('رسالة'),
          content: Text(message!),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: const Text("موافق"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Utils.primary,
          title: Text('سند $receiptType'),
          leading: IconButton(
              onPressed: () => Get.back(result: true),
              icon: const Icon(Icons.arrow_back)),
          actions: [
            buildButtonSave(),
          ],
        ),
        body: buildBody(),
      );

  Widget buildBody() => Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _key1,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                          onTap: () => _selectDate(),
                          child: Text('التاريخ: ${_date.text}')),
                      Container(
                        margin: const EdgeInsets.only(left: 5, right: 5),
                        width: 160,
                        child: buildReceiptType(),
                      ),
                    ],
                  ),
                  receiptType == "صرف" ? buildPayTo() : buildPayer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 160,
                        child: buildAmount(),
                      ),
                      SizedBox(
                        width: 160,
                        child: buildPayType(),
                      ),
                    ],
                  ),
                  buildSumOf(),
                  buildAmountFor(),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      );

  Widget buildButtonSave() {
    return IconButton(
      onPressed: saveAndPreview,
      icon: Icon(
        Icons.save,
        color: Colors.white,
        size: 35,
      ),
    );
  }

  Widget buildChequeNo() => TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _chequeNo,
        onTap: () {
          var textValue = _chequeNo.text;
          _chequeNo.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          labelText: language == 'Arabic' ? 'رقم الشيك' : 'Cheque No',
        ),
      );

  Widget buildReceiptType() => DropdownButtonFormField2<String>(
        isExpanded: true,
        hint: Text(receiptType),
        decoration: const InputDecoration(
          labelText: 'نوع السند',
          labelStyle: TextStyle(fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
        ),
        items: ["قبض", "صرف"]
            .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: dataStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        value: receiptType,
        onChanged: (String? value) async {
          setState(() {
            receiptType = value!;
          });
          if (receiptType == "قبض") {
            _payTo.text = "*";
          } else {
            _receivedFrom.text = "*";
          }
        },
        dropdownStyleData: DropdownStyleData(
          maxHeight: 250,
          offset: const Offset(0, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all<double>(6),
            thumbVisibility: WidgetStateProperty.all<bool>(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
      );

  Widget buildAmount() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _amount,
        onTap: () {
          var textValue = _amount.text;
          _amount.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        labelText: 'المبلغ',
        isMandatory: true,
        onChanged: (value) => value.isNotEmpty
            ? _sumOf.text = Utils.numToWord(_amount.text)
            : _sumOf.text = "",
      );

  Widget buildSumOf() => MyTextFormField(
        readOnly: true,
        controller: _sumOf,
        labelText: language == 'Arabic' ? 'فقط' : 'Sum Of',
      );

  Widget buildChequeDate() => TextFormField(
        controller: _chequeDate,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          labelText: language == 'Arabic' ? 'تاريخ الشيك' : 'Cheque Date',
        ),
      );

  Widget buildAmountFor() => MyTextFormField(
        controller: _amountFor,
        isMandatory: true,
        labelText: 'وذلك عن',
        onChanged: (value) => _amountFor.text = value,
      );

  Widget buildTransferDate() => TextFormField(
        controller: _transferDate,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          labelText: language == 'Arabic' ? 'تاريخ الحوالة' : 'Transfer Date',
        ),
      );

  Widget buildBank() => TextFormField(
        controller: _bank,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          labelText: language == 'Arabic' ? 'على بنك' : 'Bank',
        ),
      );

  Widget buildReceivedFrom() => MyTextFormField(
        controller: _receivedFrom,
        isMandatory: true,
        labelText: 'استلمنا من',
        onChanged: (value) => _receivedFrom.text = value,
      );

  Widget buildPayTo() => MyTextFormField(
        controller: _payTo,
        isMandatory: true,
        labelText: 'صرفنا إلى',
        onChanged: (value) => _payTo.text = value,
      );

  Widget buildTransferNo() => TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _transferNo,
        onTap: () {
          var textValue = _transferNo.text;
          _transferNo.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          labelText: language == 'Arabic' ? 'رقم الحوالة' : 'Transfer No',
        ),
      );

  Widget buildPayType() => Container(
        margin: const EdgeInsets.only(left: 5, right: 5),
        child: DropdownButtonFormField2<String>(
          isExpanded: true,
          hint: Text(payType),
          decoration: const InputDecoration(
            labelText: 'الدفع',
            labelStyle: TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
          ),
          items: payTypeList
              .map((String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: dataStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          value: payType,
          onChanged: (String? value) async {
            setState(() {
              payType = value!;
            });
          },
          dropdownStyleData: DropdownStyleData(
            maxHeight: 250,
            offset: const Offset(0, 0),
            scrollbarTheme: ScrollbarThemeData(
              radius: const Radius.circular(40),
              thickness: WidgetStateProperty.all<double>(6),
              thumbVisibility: WidgetStateProperty.all<bool>(true),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.only(left: 14, right: 14),
          ),
        ),
      );

  Widget buildPayer() => Container(
        padding: const EdgeInsets.only(top: 5, bottom: 5),
        margin: const EdgeInsets.only(left: 5, right: 5),
        child: DropdownButtonFormField2<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'استلمنا من',
            labelStyle: TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
          ),
          hint: Text(_receivedFrom.text, style: dataStyle),
          items: customers
              .map((String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item.split('-')[1],
                      style: dataStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (String? value) {
            String customerName = value!.split('-')[1];
            setState(() {
              payerId = int.parse(value.split('-')[0]);
              _receivedFrom.text = customerName;
            });
          },
          dropdownStyleData: const DropdownStyleData(
            maxHeight: 250,
            offset: Offset(0, 0),
            scrollbarTheme: ScrollbarThemeData(radius: Radius.circular(40)),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 50,
            padding: EdgeInsets.only(left: 14, right: 14),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _receivedFrom,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding:
                  const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: _receivedFrom,
                style: dataStyle,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value.toString().contains(searchValue);
            },
          ),
        ),
      );

  Widget buildPayerVatNumber() => Text(
        _transferDate.text,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );

  Widget buildProject() => TextFormField(
        controller: _receivedFrom,
        keyboardType: TextInputType.name,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          labelText: language == 'Arabic' ? 'اسم المشروع' : 'Project Name',
        ),
        // onChanged: onChangedPayer,
      );

  _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _date.text = Utils.formatShortDate(picked!).toString());
  }

  void saveAndPreview() {
    addOrUpdateReceipt();
  }

  /// To add/update receipt to database
  void addOrUpdateReceipt() async {
    final isValid = Platform.isAndroid ? true : _key1.currentState!.validate();

    if (isValid) {
      final isUpdating = widget.receipt != null;
      setState(() {
        isLoading = true;
      });

      if (isUpdating) {
        await updateReceipt();
      } else {
        await addReceipt();
      }
      setState(() {
        isLoading = false;
      });
      ZatcaAPI.successMessage("تمت عملية الحفظ بنجاح");
      Get.to(() => const ReceiptsPg());
    }
  }

  Future updateReceipt() async {
    Receipt receipt = Receipt(
      id: id,
      date: _date.text,
      sumOf: _sumOf.text,
      payType: payType,
      receivedFrom: receiptType == "قبض" ? _receivedFrom.text : "*",
      amount: num.parse(_amount.text),
      amountFor: _amountFor.text,
      chequeNo: _chequeNo.text,
      chequeDate: _chequeDate.text,
      transferNo: _transferNo.text,
      transferDate: _transferDate.text,
      bank: _bank.text,
      payTo: receiptType == "قبض" ? "*" : _payTo.text,
      receiptType: receiptType,
      payerId: payerId,
    );

    await FatooraDB.instance.updateReceipt(receipt);

    await PdfReceiptApi.generate(receipt, 'سند $receiptType');
  }

  Future addReceipt() async {
    Receipt receipt = Receipt(
      id: id,
      date: _date.text,
      sumOf: _sumOf.text,
      payType: payType,
      receivedFrom: receiptType == "قبض" ? _receivedFrom.text : "*",
      amount: num.parse(_amount.text),
      amountFor: _amountFor.text,
      chequeNo: _chequeNo.text,
      chequeDate: _chequeDate.text,
      transferNo: _transferNo.text,
      transferDate: _transferDate.text,
      bank: _bank.text,
      payTo: receiptType == "قبض" ? "*" : _payTo.text,
      receiptType: receiptType,
      payerId: payerId,
    );
    await FatooraDB.instance.createReceipt(receipt);

    await PdfReceiptApi.generate(receipt, 'سند $receiptType');
  }

  @override
  void dispose() {
    super.dispose();
  }
}
