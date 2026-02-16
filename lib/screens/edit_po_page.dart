import 'dart:async';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zatca/screens/pos.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/po.dart';
import '../models/product.dart';
import '../models/settings.dart';
import '../models/suppliers.dart';
import '../pdf/pdf_po_api.dart';
import '../widgets/widget.dart';

class AddEditPoPage extends StatefulWidget {
  final dynamic product;
  final Po? po;

  const AddEditPoPage({
    super.key,
    this.product,
    this.po,
  });

  @override
  State<AddEditPoPage> createState() => _AddEditPoPageState();
}

class _AddEditPoPageState extends State<AddEditPoPage> {
  List<String> payMethod = ['شبكة', 'كاش', 'آجل', 'حوالة'];
  String? selectedPayMethod = Utils.defPayMethod;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool scanned = false;

  TextEditingController textQRCode = TextEditingController();

  final _key1 = GlobalKey<FormState>();
  late int recId;
  late int newId; // This id for new po id in cloud database
  late int id; // this is existing po id will be retrieved from widget
  late final Supplier supplier;
  late final Setting seller;
  late final Setting vendor;
  late final Setting vendorVatNumber;
  late final String project;
  late final String date;
  late final String supplyDate;
  late List<PoLines> items = [];
  late List<Po> dailyPos = [];
  late List<String> suppliers = [];
  late String poNo;
  int counter = 0;
  bool isPreview = false;
  bool isPo = true;

  final TextEditingController _productName = TextEditingController();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _totalPrice = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _priceWithoutVat = TextEditingController();
  final TextEditingController _supplier = TextEditingController();
  final TextEditingController _project = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _date = TextEditingController();
  final TextEditingController _supplyDate = TextEditingController();
  final FocusNode focusNode = FocusNode();

  num total = 0.0;
  int cardQty = 1;

  bool noProductFount = true;
  bool isLoading = false;
  List<Product> products = [];
  List<String> productsList = [];
  int curSupplierId = 1;
  String curProject = '';
  String curNotes = '';
  String curDate = Utils.formatDate(DateTime.now());
  String curSupplyDate = Utils.formatDate(DateTime.now());
  bool printerBinded = false;
  String sellerAddress = '';
  String newPayerAddress = '';
  String language = 'Arabic';
  String pdfPath = "";

  @override
  void initState() {
    super.initState();
    getPo();
    focusNode.requestFocus();
  }

  Future getPo() async {
    FatooraDB db = FatooraDB.instance;
    language = "Arabic";
    final pdfDir = await getApplicationDocumentsDirectory();
    pdfPath = "${pdfDir.path}/PO.pdf";
    try {
      setState(() => isLoading = true);
      var user = await db.getAllSettings();
      seller = user[0];

      int? posCount = await FatooraDB.instance.getPoCount();
      int? countCustomers = await FatooraDB.instance.getCustomerCount();
      bool? checkFirstPayer = await FatooraDB.instance.isFirstCustomerExist();

      Supplier newSupplier = const Supplier(
          id: 1, name: 'مورد نقدي', vatNumber: '399999999900003');

      if (!checkFirstPayer!) {
        await FatooraDB.instance.createSupplier(newSupplier);
      }
      if (widget.po != null) {
        curSupplierId = widget.po!.payerId!;
        curProject = widget.po!.project;
        curDate = widget.po!.date;
        curSupplyDate = widget.po!.supplyDate;
        selectedPayMethod = widget.po!.paymentMethod;
        curNotes = widget.po!.notes;
      }

      id = widget.po != null
          ? widget.po!.id!
          : posCount == 0
              ? 1
              : (await db.getNewPoId())! + 1;
      supplier = countCustomers == 0
          ? newSupplier
          : await FatooraDB.instance.getSupplierById(curSupplierId);
      _supplier.text = supplier.name;
      _project.text = curProject;
      _date.text = curDate;
      _supplyDate.text = curSupplyDate;
      _notes.text = curNotes;
      List<Supplier> list = await FatooraDB.instance.getAllSuppliers();
      suppliers.clear();
      for (int i = 0; i < list.length; i++) {
        suppliers.add("${list[i].id}-${list[i].name}");
      }

      recId = id;

      poNo = recId.toString(); // like '0000321'

      ///  Initialize Po lines
      if (widget.po != null) {
        items = await db.getPoLinesById(recId);
        for (int i = 0; i < items.length; i++) {
          total = total + (items[i].qty * items[i].price);
        }
      }

      /// Initialize products list offLine/onLine
      await db.getAllProducts().then((list) {
        products = list;
        for (int i = 0; i < products.length; i++) {
          productsList.add('${products[i].id!}-${products[i].productName!}');
        }
      });
      if (products.isEmpty) {
        noProductFount = true;
      } else {
        noProductFount = false;
      }

      /// Initialize po form controller header
      _totalPrice.text = '0.00';
      _price.text = '0.00';
      _priceWithoutVat.text = '0.00';
      _qty.text = '1';

      sellerAddress += Utils.buildingNo;
      sellerAddress += Utils.buildingNo.isNotEmpty ? ' ' : '';
      sellerAddress += Utils.street.isNotEmpty ? Utils.street : '';
      sellerAddress += Utils.district.isNotEmpty ? '-${Utils.district}' : '';
      sellerAddress += Utils.city.isNotEmpty ? '-${Utils.city}' : '';
      sellerAddress += 'السعودية'.isNotEmpty ? '-${'السعودية'}' : '';

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
          title: const Text('طلب شراء'),
          leading: IconButton(
              onPressed: () => Get.back(result: true),
              icon: Icon(Icons.arrow_back)),
          actions: [
            buildButtonSave(),
          ],
        ),
        body: buildBody(),
      );

  Widget buildBody() => Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
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
                            ]),
                        Utils.space(2, 0),
                        buildVendor(),
                        buildProject(),
                        buildNotes(),
                      ],
                    ),
                  ),
                ),
                NewFrame(
                  title: 'بيانات سطور طلب الشراء',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: buildProductName()),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(width: 100, child: buildQty()),
                          Expanded(child: buildPrice()),
                          buildInsertButton(),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  color: Colors.grey,
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  padding: const EdgeInsets.only(right: 5, left: 5),
                  child: Row(
                    children: [
                      Utils.space(0, 1),
                      const Expanded(
                          child: Text(
                        "اجمالي طلب الشراء",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      )),
                      SizedBox(
                          width: 80,
                          child: Text(
                            Utils.formatNoCurrency(total),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                            textAlign: TextAlign.right,
                          )),
                      const Icon(
                        Icons.clear,
                        size: 35,
                        color: Colors.transparent,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  padding: const EdgeInsets.only(right: 0, left: 0),
                  child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              Utils.space(0, 1),
                              Row(
                                children: [
                                  Utils.space(0, 1),
                                  Expanded(
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'عدد ${items[index].qty} ${items[index].productName}',
                                          textDirection: TextDirection.rtl,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black),
                                        )),
                                  ),
                                  Utils.space(0, 1),
                                  SizedBox(
                                      width: 80,
                                      child: Text(
                                        Utils.formatNoCurrency(
                                            items[index].qty *
                                                (items[index].price)),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black),
                                        textAlign: TextAlign.right,
                                      )),
                                  IconButton(
                                    onPressed: () async {
                                      setState(() {
                                        num lineTotal = items[index].qty *
                                            items[index].price;
                                        total = total - lineTotal;
                                        items.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 25,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              Utils.space(0, 1),
                              const Divider(thickness: 1, height: 0),
                            ],
                          ),
                        );
                      }),
                ),
              ],
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

  Widget buildQty() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _qty,
        onTap: () {
          var textValue = _qty.text;
          _qty.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        labelText: language == 'Arabic' ? 'الكمية' : 'Qty',
        isMandatory: true,
        onChanged: (value) => _totalPrice.text =
            "${Utils.formatNoCurrency(num.parse(value) * num.parse(_price.text))}",
      );

  Widget buildPrice() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _price,
        onTap: () {
          var textValue = _price.text;
          _price.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        labelText: 'السعر مع الضريبة',
        isMandatory: true,
        onChanged: (value) => value.isNotEmpty
            ? _priceWithoutVat.text =
                "${Utils.formatNoCurrency(num.parse(value) / 1.15)}"
            : null,
      );

  Widget buildTotalPrice() => TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _totalPrice,
        onTap: () {
          var textValue = _totalPrice.text;
          _totalPrice.selection = TextSelection(
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
          labelText: language == 'Arabic' ? 'المبلغ' : 'Paid Amount',
        ),
        validator: (price) =>
            price == null || price == '' ? 'يجب ادخال المبلغ' : null,
        onChanged: (value) => _qty.text =
            "${Utils.formatNoCurrency(num.parse(value) / num.parse(_price.text))}",
      );

  Widget buildPriceWithoutVat() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _priceWithoutVat,
        onTap: () {
          var textValue = _priceWithoutVat.text;
          _priceWithoutVat.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        labelText:
            language == 'Arabic' ? 'السعر بدون ضريبة' : 'Price VAT Excluded',
        isMandatory: true,
        onChanged: (value) =>
            _price.text = "${Utils.formatNoCurrency(num.parse(value) * 1.15)}",
      );

  Widget buildInsertButton() => IconButton(
        onPressed: () {
          if (_price.text.isEmpty) {
            _price.text = "0.00";
          }
          String price = _price.text.replaceAll(',', '');
          if (_productName.text != '' &&
              num.parse(_qty.text) > 0 &&
              num.parse(price) >= 0) {
            setState(() {
              items.add(PoLines(
                productName: _productName.text,
                qty: num.parse(_qty.text.toString()),
                price: num.parse(price),
                recId: recId,
              ));
              num lineTotal = num.parse(_qty.text) * num.parse(price);
              total = total + lineTotal;
              _productName.clear();
              _qty.text = '1';
              _price.text = '0.00';
              _totalPrice.text = '0.00';
              _priceWithoutVat.text = '0.00';
              focusNode.requestFocus();
            });
          }
        },
        icon: const Icon(
          Icons.add_shopping_cart_sharp,
          size: 40,
          color: Utils.primary,
        ),
      );

  Widget buildVendor() => Container(
        margin: const EdgeInsets.only(left: 5, right: 5),
        child: DropdownButtonFormField2<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'المورد',
            labelStyle: TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
          ),
          hint: Text(_supplier.text, style: dataStyle),
          items: suppliers
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
            String vendorName = value!.split('-')[1];
            setState(() {
              curSupplierId = int.parse(value.split('-')[0]);
              _supplier.text = vendorName;
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
            height: 50,
            padding: EdgeInsets.only(left: 14, right: 14),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _supplier,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding:
                  const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: _supplier,
                style: dataStyle,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    onPressed: () => addNewSupplier(_supplier.text),
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value.toString().contains(searchValue);
            },
          ),
        ),
      );

  Widget buildProject() => MyTextFormField(
        controller: _project,
        autofocus: true,
        keyboardType: TextInputType.name,
        labelText: 'اسم المشروع',
        // onChanged: onChangedPayer,
      );

  Widget buildProductName() => MyTextFormField(
        controller: _productName,
        autofocus: true,
        keyboardType: TextInputType.name,
        labelText: language == 'Arabic' ? 'البيان' : 'Description',
      );

  Widget buildNotes() => MyTextFormField(
        controller: _notes,
        autofocus: true,
        keyboardType: TextInputType.name,
        labelText: language == 'Arabic' ? 'ملاحظات' : 'Notes',
      );

  _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _date.text = Utils.formatDate(picked!).toString());
  }

  _selectSupplyDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _supplyDate.text = Utils.formatDate(picked!));
  }

  Widget buildDate() => InkWell(
        onTap: () => _selectDate(),
        child: IgnorePointer(
          child: TextFormField(
            controller: _date,
            keyboardType: TextInputType.text,
            style: const TextStyle(
              color: Utils.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              labelText: language == 'Arabic' ? 'تاريخ العرض' : 'Po Date',
            ),
            // onChanged: onChangedPayer,
          ),
        ),
      );

  Widget buildSupplyDate() => InkWell(
        onTap: () => _selectSupplyDate(),
        child: IgnorePointer(
          child: TextFormField(
            controller: _supplyDate,
            keyboardType: TextInputType.text,
            style: const TextStyle(
              color: Utils.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              labelText: language == 'Arabic' ? 'تاريخ التوريد' : 'Supply Date',
            ),
            // onChanged: onChangedPayer,
          ),
        ),
      );

  void saveAndPreview() {
    addOrUpdatePo();
  }

  /// To add/update po to database
  void addOrUpdatePo() async {
    final isValid = Platform.isAndroid ? true : _key1.currentState!.validate();
    final hasLines = items.isNotEmpty ? true : false;

    if (!hasLines) {
      ZatcaAPI.errorMessage('يجب إدخال سطور للعرض');
    }

    if (isValid && hasLines) {
      final isUpdating = widget.po != null;
      setState(() {
        isLoading = true;
      });

      if (isUpdating) {
        await updatePo();
      } else {
        await addPo();
      }
      setState(() {
        isLoading = false;
      });
      ZatcaAPI.successMessage("تمت عملية الحفظ بنجاح");
      Get.to(() => const PosPg());
    }
  }

  Future updatePo() async {
    Supplier supp = await FatooraDB.instance.getSupplierById(curSupplierId);
    Po po = Po(
      id: id,
      poNo: poNo,
      date: _date.text,
      supplyDate: _supplyDate.text,
      sellerId: Utils.clientId,
      project: _project.text,
      total: total,
      totalVat: total - (total / 1.15),
      posted: 0,
      payerId: curSupplierId,
      noOfLines: items.length,
      paymentMethod: selectedPayMethod!,
      notes: _notes.text,
    );

    await FatooraDB.instance.updatePo(po);
    await FatooraDB.instance.deletePoLines(id);

    for (int i = 0; i < items.length; i++) {
      await FatooraDB.instance.createPoLines(items[i], items[i].recId);
    }
    await PdfPoApi.generate(po, supp, items, 'طلب شراء', po.project, isPreview,
        isPo: isPo);
  }

  Future addPo() async {
    Supplier supp = await FatooraDB.instance.getSupplierById(curSupplierId);
    Po po = Po(
      poNo: poNo,
      date: _date.text,
      supplyDate: _supplyDate.text,
      sellerId: Utils.clientId,
      project: _project.text,
      total: total,
      totalVat: total - (total / 1.15),
      posted: 0,
      payerId: curSupplierId,
      noOfLines: items.length,
      paymentMethod: selectedPayMethod!,
      notes: _notes.text,
    );
    await FatooraDB.instance.createPo(po);

    for (int i = 0; i < items.length; i++) {
      await FatooraDB.instance.createPoLines(items[i], items[i].recId);
    }
    await PdfPoApi.generate(po, supp, items, 'طلب شراء', po.project, isPreview,
        isPo: isPo);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> addNewSupplier(String value) async {
    if (value.isNotEmpty) {
      Supplier newSupplier;
      final isSupplier = await FatooraDB.instance.supplierExist(value);
      if (isSupplier) {
        messageBox("المورد $value موجود بالفعل");
      } else {
        newSupplier =
            await FatooraDB.instance.createSupplier(Supplier(name: value));
        setState(() {
          curSupplierId = newSupplier.id!;
          suppliers.add("$curSupplierId-$value");
          _supplier.text = value;
        });
        messageBox("تم إضافة المورد $value");
      }
    } else {
      messageBox("لم يتم ادخال بيانات");
    }
  }

  /// End of QR code scanner
}
