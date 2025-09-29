import 'dart:async';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/customers.dart';
import '../models/estimate.dart';
import '../models/product.dart';
import '../models/settings.dart';
import '../pdf/pdf_estimate_api.dart';
import '../widgets/widget.dart';

const fontStyle =
    TextStyle(color: Utils.primary, fontWeight: FontWeight.bold, fontSize: 12);

class AddEditEstimatePage extends StatefulWidget {
  final dynamic product;
  final Estimate? estimate;

  const AddEditEstimatePage({
    super.key,
    this.product,
    this.estimate,
  });

  @override
  State<AddEditEstimatePage> createState() => _AddEditEstimatePageState();
}

class _AddEditEstimatePageState extends State<AddEditEstimatePage> {
  List<String> payMethod = ['شبكة', 'كاش', 'آجل', 'حوالة', 'عقد'];
  String selectedPayMethod = 'شبكة';

  final _key1 = GlobalKey<FormState>();
  late int recId;
  late int newId; // This id for new estimate id in cloud database
  late int id; // this is existing estimate id will be retrieved from widget
  late final Customer payer;
  late final Setting vendor;
  late final Setting vendorVatNumber;
  late final String project;
  late final String date;
  late final String supplyDate;
  late List<EstimateLines> items = [];
  late List<EstimateLines> lines = [];
  late List<Estimate> dailyEstimates = [];
  late List<String> customers = [];
  String estimateNo = '';
  int counter = 50;
  Image? imgText;

  // bool isSimplifiedTaxEstimate = false;
  bool isPreview = true;
  bool isEstimate = true;
  int smsCredits = 0;

  final TextEditingController _productName = TextEditingController();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _estimateNo = TextEditingController();
  final TextEditingController _totalPrice = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _priceWithoutVat = TextEditingController();
  final TextEditingController _payer = TextEditingController();
  final TextEditingController _payerVatNumber = TextEditingController();
  final TextEditingController _vendor = TextEditingController();
  final TextEditingController _details = TextEditingController();
  final TextEditingController _vendorVatNumber = TextEditingController();
  final TextEditingController _totalPurchases = TextEditingController();
  final TextEditingController _vatPurchases = TextEditingController();
  final TextEditingController _project = TextEditingController();
  final TextEditingController _date = TextEditingController();
  final TextEditingController _supplyDate = TextEditingController();
  final TextEditingController _totalDiscount = TextEditingController();
  final TextEditingController _customerCellphone = TextEditingController();
  final TextEditingController _payMethod = TextEditingController();
  final FocusNode focusNode = FocusNode();

  num total = 0.0;
  num totalDiscount = 0.0;
  int cardQty = 1;

  bool noProductFound = true;
  bool isManualProduct = true;
  bool isLoading = false;
  List<Product> products = [];
  List<String> productsList = [];
  int curPayerId = 1;
  String curProject = '';
  String curDate = Utils.formatDate(DateTime.now());
  String curSupplyDate = Utils.formatDate(DateTime.now());
  bool printerConnected = false;
  String sellerAddress = '';
  String payerAddress = '';
  String newPayerAddress = '';
  String language = 'Arabic';
  String? activity;
  bool showPdf = false;
  String pdfPath = "";
  File? pdf;

  @override
  void initState() {
    super.initState();
    getEstimate();
    focusNode.requestFocus();
  }

  Future getEstimate() async {
    FatooraDB db = FatooraDB.instance;
    final pdfDir = await getApplicationDocumentsDirectory();
    pdfPath = "${pdfDir.path}/ESTIMATE.pdf";
    language = "Arabic";
    activity = "Commercial";
    try {
      setState(() => isLoading = true);
      _customerCellphone.text = "";
      int? estimatesCount = await FatooraDB.instance.getEstimatesCount();
      int? countCustomers = await FatooraDB.instance.getCustomerCount();
      bool? checkFirstPayer = await FatooraDB.instance.isFirstCustomerExist();

      Customer newPayer = Customer(
        id: 1,
        name: 'عميل نقدي',
        vatNumber: '399999999900003',
        streetName: Utils.street,
        city: Utils.city,
        country: "السعودية",
        buildingNo: Utils.buildingNo,
        additionalNo: Utils.secondaryNo,
        postalCode: Utils.postalCode,
        district: Utils.district,
      );

      if (!checkFirstPayer!) {
        await FatooraDB.instance.createCustomer(newPayer);
      }
      if (widget.estimate != null) {
        curPayerId = widget.estimate!.payerId!;
        curProject = widget.estimate!.project;
        curDate = widget.estimate!.date;
        curSupplyDate = widget.estimate!.supplyDate;
        selectedPayMethod = widget.estimate!.paymentMethod;
        // totalDiscount = widget.estimate!.totalDiscount;
        estimateNo = widget.estimate!.estimateNo;
      }

      id = widget.estimate != null
          ? widget.estimate!.id!
          : estimatesCount == 0
              ? 1
              : (await db.getNewEstimateId())! + 1;
      payer = countCustomers == 0
          ? newPayer
          : await FatooraDB.instance.getCustomerById(curPayerId);

      List<Customer> list = await FatooraDB.instance.getAllCustomers();
      customers.clear();
      for (int i = 0; i < list.length; i++) {
        customers.add("${list[i].id}-${list[i].name}");
      }

      recId = id;
      estimateNo = '$id';

      _payer.text = payer.name;
      _payerVatNumber.text = payer.vatNumber;
      _project.text = curProject;
      _date.text = curDate;
      _supplyDate.text = curSupplyDate;
      _estimateNo.text = estimateNo;
      _totalDiscount.text = Utils.formatPrice(totalDiscount);
      _payMethod.text = selectedPayMethod;

      ///  Initialize Estimate lines
      if (widget.estimate != null) {
        items = await db.getEstimateLinesById(recId);
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
        noProductFound = true;
      } else {
        noProductFound = false;
      }

      /// Initialize estimate form controller header
      _totalDiscount.text = '$totalDiscount';
      _price.text = '0.00';
      _priceWithoutVat.text = '0.00';
      _qty.text = activity == "محروقات" ? '0.00' : '1';
      _estimateNo.text = estimateNo;

      sellerAddress +=
          Utils.buildingNo.isNotEmpty ? "${Utils.buildingNo} " : "";
      sellerAddress += Utils.street.isNotEmpty ? "${Utils.street} " : "";
      sellerAddress += Utils.district.isNotEmpty ? "${Utils.district}\n" : "";
      sellerAddress += Utils.city.isNotEmpty ? "${Utils.city}\n" : "";
      sellerAddress += 'السعودية'.isNotEmpty ? "${'السعودية'} " : "";

      payerAddress += payer.buildingNo;
      payerAddress += payer.buildingNo.isNotEmpty ? ' ' : '';
      payerAddress += payer.streetName.isNotEmpty ? payer.streetName : '';
      payerAddress += payer.district.isNotEmpty ? '-${payer.district}' : '';
      payerAddress += payer.city.isNotEmpty ? '-${payer.city}' : '';
      payerAddress += payer.country.isNotEmpty ? '-${payer.country}' : '';

      setState(() {
        isLoading = false;
      });
    } on Exception catch (e) {
      messageBox(e.toString());
    }
  }

  Future<File> txtFile(String text) async {
    final tempDir = await getTemporaryDirectory();
    List<int> bytes = text.codeUnits;
    File file = await File('${tempDir.path}/text.png').create();
    file.writeAsBytes(bytes);
    return file;
  }

  void messageBox(String? message) {
    showDialog(
      context: context,
      barrierDismissible: false,
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

  void getCustomerCellphone() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إدخال رقم العميل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _customerCellphone,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.phone,
                autofocus: true,
                onTap: () {
                  var textValue = _customerCellphone.text;
                  _customerCellphone.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: textValue.length,
                  );
                },
              ),
              const Text("أدخل رقم جوال العميل"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("موافق"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("إلغاء"),
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
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Utils.primary,
          title: const Text('عرض سعر'),
          actions: [
            showPdf
                ? IconButton(
                    icon: Platform.isAndroid
                        ? const Icon(Icons.share)
                        : const Icon(Icons.folder),
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: "مشاركة",
                          files: [XFile(pdfPath)],
                        ),
                      );
                    },
                  )
                : IconButton(
                    onPressed: printPreview,
                    icon: Icon(Icons.save, color: Colors.white, size: 35),
                  ),
          ],
          leading: IconButton(
              onPressed: () => Get.back(result: true),
              icon: Icon(Icons.arrow_back)),
        ),
        body: buildBody(),
      );

  Widget buildBody() => Stack(
        children: [
          SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Form(
                      key: _key1,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: buildEstimateDate()),
                              Utils.space(0, 2),
                              SizedBox(width: 120, child: buildEstimateNo()),
                              // Utils.space(0, 3),
                              // SizedBox(
                              //     width: 90, child: buildPayMethod()),
                            ],
                          ),
                          Utils.space(0.25, 0),
                          Row(
                            children: [
                              Expanded(child: buildProject()),
                              Utils.space(0, 2),
                              SizedBox(width: 120, child: buildPayMethod()),
                              // Expanded(child: buildProject()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Utils.space(0.25, 0),
                  NewFrame(
                    title: 'بيانات سطور العرض',
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
                            Utils.space(0, 1),
                            activity == "محروقات"
                                ? Container()
                                : Utils.space(0, 1),
                            activity == "محروقات"
                                ? Container()
                                : Expanded(child: buildPrice()),
                            activity == "محروقات"
                                ? Container()
                                : Utils.space(0, 1),
                            activity == "محروقات"
                                ? Expanded(child: buildTotalPrice())
                                : Container(),
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
                          "اجمالي العرض",
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
                                              fontSize: 12,
                                              color: Colors.black),
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
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      );

  Widget buildButtonEstimate() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Utils.primary,
          backgroundColor: Utils.background,
        ),
        onPressed: printEstimate,
        child: Text(language == 'Arabic' ? 'عرض سعر' : 'Estimate'),
      ),
    );
  }

  Widget buildButtonPost() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Utils.primary,
          backgroundColor: Utils.background,
        ),
        onPressed: () async {
          String message =
              'لن يمكنك تعديل/حذف هذه الفاتورة بعد عملية الترحيل\nهل أنت متأكد من هذا الإجراء';
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('رسالة'),
                content: Text(message),
                actions: <Widget>[
                  // usually buttons at the bottom of the dialog
                  TextButton(
                    child: const Text("نعم"),
                    onPressed: () async {
                      if (widget.estimate != null) {
                        Estimate estimate = Estimate(
                          id: id,
                          estimateNo: estimateNo,
                          date: Utils.formatDate(DateTime.now()),
                          sellerId: Utils.clientId,
                          total: total,
                          // totalDiscount: totalDiscount,
                          totalVat: total - (total / 1.15),
                          posted: 1,
                          payerId: payer.id,
                          noOfLines: items.length,
                        );
                        await FatooraDB.instance.updateEstimate(estimate);
                        await FatooraDB.instance.deleteEstimateLines(id);
                        for (int i = 0; i < items.length; i++) {
                          await FatooraDB.instance
                              .createEstimateLines(items[i], items[i].recId);
                        }
                      } else {
                        messageBox('يجب حفظ الفاتورة قبل الترحيل');
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
        child: const Text('ترحيل'),
      ),
    );
  }

  Widget buildPayer() => MyTextFormField(
        labelText: "العميل",
        controller: _payer,
        suffixIcon: PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          icon: const Icon(Icons.arrow_drop_down, size: 35),
          itemBuilder: (BuildContext context) {
            return customers.map((String item) {
              return PopupMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList();
          },
          onSelected: (String selectedItem) async {
            String customerName = selectedItem.split('-')[1];
            setState(() {
              curPayerId = int.parse(selectedItem.split('-')[0]);
              _payer.text = customerName;
            });
          },
        ),
      );

  Widget buildProductName() => MyTextFormField(
        controller: _productName,
        labelText: 'المنتج',
      );

  Widget buildProductNameCombo() => Container(
      margin: const EdgeInsets.only(left: 5, right: 5),
      child: DropdownButtonFormField2<String>(
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'المنتج',
          labelStyle: TextStyle(fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
        ),
        items: productsList
            .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item.split('-')[1],
                    style: dataStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (String? value) async {
          String productName = value!.split('-')[1];
          int productId = int.parse(value.split('-')[0]);
          Product prod = await FatooraDB.instance.getProductById(productId);
          num? productPrice = prod.price;
          setState(() {
            _productName.text = productName;
            _price.text = Utils.formatNoCurrency(productPrice!);
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
        dropdownSearchData: DropdownSearchData(
          searchController: _productName,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding:
                const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: _productName,
              style: dataStyle,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  onPressed: () => addNewProduct(_productName.text),
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().contains(searchValue);
          },
        ),
      ));

  Widget buildEstimateNo() => MyTextFormField(
        controller: _estimateNo,
        labelText: 'رقم العرض',
        isMandatory: true,
        onTap: () {
          var textValue = _estimateNo.text;
          _estimateNo.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
      );

  Widget buildQty() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _qty,
        isMandatory: true,
        labelText: activity == "محروقات"
            ? language == 'Arabic'
                ? 'الكمية/اللترات'
                : 'Qty/Litre'
            : language == 'Arabic'
                ? 'الكمية'
                : 'Qty',
        onTap: () {
          var textValue = _qty.text;
          _qty.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        onChanged: (value) => _totalPrice.text =
            "${Utils.formatNoCurrency(num.parse(value) * num.parse(_price.text))}",
      );

  Widget buildPrice() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _price,
        labelText:
            language == 'Arabic' ? 'السعر مع الضريبة' : 'Price VAT Included',
        onTap: () {
          var textValue = _price.text;
          _price.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        isMandatory: true,
        onChanged: (value) => value.isNotEmpty
            ? _priceWithoutVat.text =
                "${Utils.formatNoCurrency(num.parse(value) / 1.15)}"
            : null,
      );

  Widget buildTotalDiscount() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            language == 'Arabic' ? 'مبلغ الخصم على العرض' : 'Disc. Amount',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          // Utils.space(0, 2),
          SizedBox(
            width: 90,
            child: TextField(
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              controller: _totalDiscount,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(border: InputBorder.none),
              onTap: () {
                var textValue = _totalDiscount.text;
                _totalDiscount.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: textValue.length,
                );
              },
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
              onChanged: (value) {
                setState(() {
                  totalDiscount = num.parse(_totalDiscount.text);
                });
              },
            ),
          ),
        ],
      );

  Widget buildTotalPrice() => TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _totalPrice,
        autofocus: true,
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
        labelText:
            language == 'Arabic' ? 'السعر بدون ضريبة' : 'Price VAT Excluded',
        onTap: () {
          var textValue = _priceWithoutVat.text;
          _priceWithoutVat.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
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
          String desc = isManualProduct
              ? _productName.text
              : _productName.text.split('-')[1];
          if (_productName.text != '' && num.parse(_qty.text) > 0) {
            setState(() {
              items.add(EstimateLines(
                productName: num.parse(price) == 0 ? '$desc- مجاناً' : desc,
                qty: num.parse(_qty.text.toString()),
                price: num.parse(price),
                recId: recId,
              ));
              num lineTotal = num.parse(_qty.text) * num.parse(price);
              total = total + lineTotal;
              _productName.clear();
              _qty.text = activity == "محروقات" ? '0.00' : '1';
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

  Widget buildVendor() => MyTextFormField(
        controller: _vendor,
        labelText: language == 'Arabic' ? 'اسم المورد' : 'Vendor Name',
        isMandatory: true,
      );

  Widget buildDetails() => MyTextFormField(
        controller: _details,
        labelText: language == 'Arabic' ? 'التفاصيل' : 'Details',
      );

  Widget buildVendorVatNumber() => MyTextFormField(
        controller: _vendorVatNumber,
        keyboardType: TextInputType.number,
        isMandatory: true,
        pattern: RegExp(r'^(3)([0-9]{10})(0003)$'),
        errorMessage: 'الصيغة الصحيحة 3XXXXXXXXXX0003',
        labelText: 'الرقم الضريبي للمورد',
      );

  Widget buildTotalPurchases() => MyTextFormField(
        controller: _totalPurchases,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        labelText: language == 'Arabic' ? 'إجمالي العرض' : 'Total Estimate',
        isMandatory: true,
        onChanged: (value) => _vatPurchases.text =
            "${Utils.formatNoCurrency(num.parse(_totalPurchases.text) - (num.parse(_totalPurchases.text) / 1.15))}",
      );

  Widget buildVatPurchases() => MyTextFormField(
        controller: _vatPurchases,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        labelText: 'ضريبة القيمة المضافة',
        readOnly: true,
      );

  Widget buildPayMethod() => MyTextFormField(
        labelText: "الدفع",
        controller: _payMethod,
        readOnly: true,
        suffixIcon: PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          icon: const Icon(Icons.arrow_drop_down, size: 35),
          itemBuilder: (BuildContext context) {
            return payMethod.map((String item) {
              return PopupMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList();
          },
          onSelected: (String selectedItem) {
            _payMethod.text = selectedItem;
          },
        ),
      );

  Widget buildPayerVatNumber() => Text(
        _payerVatNumber.text,
        style: const TextStyle(
          color: Utils.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );

  Widget buildProject() => MyTextFormField(
        controller: _project,
        labelText: 'اسم المشروع',
      );

  _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        // locale: const Locale('ar'),
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    if (picked != null) {
      setState(() => _date.text = Utils.formatDate(picked).toString());
    }
  }

  _selectSupplyDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        // locale: const Locale('ar'),
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    if (picked != null) {
      setState(() => _supplyDate.text = Utils.formatDate(picked));
    }
  }

  Widget buildEstimateDate() => MyTextFormField(
        controller: _date,
        labelText: 'التاريخ',
        onTap: _selectDate,
        isMandatory: true,
      );

  Widget buildDate() => MyTextFormField(
        controller: _date,
        labelText: language == 'Arabic' ? 'تاريخ العرض' : 'Estimate Date',
        onTap: _selectDate,
      );

  Widget buildSupplyDate() => MyTextFormField(
        controller: _supplyDate,
        labelText: language == 'Arabic' ? 'تاريخ التوريد' : 'Supply Date',
        onTap: _selectSupplyDate,
      );

  void saveAndPrint() {
    setState(() {
      isPreview = false;
    });
    addOrUpdateEstimate();
  }

  void printPreview() {
    setState(() {
      isPreview = true;
      isEstimate = false;
    });
    addOrUpdateEstimate();
  }

  void printEstimate() {
    setState(() {
      isEstimate = true;
      isPreview = false;
    });
    addOrUpdateEstimate();
  }

  /// To add/update estimate to database
  void addOrUpdateEstimate() async {
    final isValid = _key1.currentState!.validate();
    final hasLines = items.isNotEmpty ? true : false;
    if (!hasLines) {
      ZatcaAPI.errorMessage('يجب إدخال سطور عرض السعر');
    }
    if (isValid && hasLines) {
      final isUpdating = widget.estimate != null;
      setState(() {
        isLoading = true;
      });

      if (isUpdating) {
        await updateEstimate();
      } else {
        await addEstimate();
      }
      setState(() {
        isLoading = false;
      });
      ZatcaAPI.successMessage("تمت عملية الحفظ بنجاح");
    }
  }

  Future updateEstimate() async {
    Customer currentPayer =
        await FatooraDB.instance.getCustomerById(curPayerId);
    Estimate estimate = Estimate(
      id: id,
      estimateNo: _estimateNo.text,
      date: _date.text,
      supplyDate: _supplyDate.text,
      sellerId: Utils.clientId,
      project: _project.text,
      total: total - totalDiscount,
      totalVat: (total - totalDiscount) - ((total - totalDiscount) / 1.15),
      // totalDiscount: totalDiscount,
      posted: 0,
      payerId: curPayerId,
      noOfLines: items.length,
      paymentMethod: _payMethod.text,
    );

    await FatooraDB.instance.updateEstimate(estimate);
    await FatooraDB.instance.deleteEstimateLines(id);

    for (int i = 0; i < items.length; i++) {
      await FatooraDB.instance.createEstimateLines(items[i], items[i].recId);
    }
    final file = await PdfEstimateApi.generate(
        estimate, currentPayer, items, 'عرض سعر', estimate.project, isPreview,
        isEstimate: isEstimate);
    setState(() => pdf = file);
  }

  Future addEstimate() async {
    Customer currentPayer =
        await FatooraDB.instance.getCustomerById(curPayerId);
    Estimate estimate = Estimate(
      id: id,
      estimateNo: _estimateNo.text,
      date: _date.text,
      supplyDate: _supplyDate.text,
      sellerId: Utils.clientId,
      project: _project.text,
      total: total - totalDiscount,
      totalVat: (total - totalDiscount) - ((total - totalDiscount) / 1.15),
      // totalDiscount: totalDiscount,
      posted: 0,
      payerId: curPayerId,
      noOfLines: items.length,
      paymentMethod: _payMethod.text,
    );

    await FatooraDB.instance.createEstimate(estimate);
    await FatooraDB.instance.deleteEstimateLines(id);

    for (int i = 0; i < items.length; i++) {
      await FatooraDB.instance.createEstimateLines(items[i], items[i].recId);
    }

    final file = await PdfEstimateApi.generate(
        estimate, currentPayer, items, 'عرض سعر', estimate.project, isPreview,
        isEstimate: isEstimate);
    setState(() => pdf = file);
  }

  Future<void> addNewProduct(String value) async {
    if (value.isNotEmpty) {
      Product newProduct;
      final isProduct = await FatooraDB.instance.productExist(value);
      if (isProduct) {
        messageBox("المنتج $value موجود بالفعل");
      } else {
        newProduct = await FatooraDB.instance.createProduct(Product(
          productName: value,
          price: 0.0,
        ));
        setState(() {
          productsList.add("${newProduct.id!}-$value");
          _productName.text = value; // newProduct.productName!;
        });
        messageBox("تم إضافة المنتج $value");
      }
    } else {
      messageBox("لم يتم ادخال بيانات");
    }
  }
}
