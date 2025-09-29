import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/core/styles/sunmi_qrcode_style.dart';
import 'package:sunmi_printer_plus/core/styles/sunmi_text_style.dart';
import 'package:sunmi_printer_plus/core/sunmi/sunmi_printer.dart';
import 'package:sunmi_printer_plus/core/types/sunmi_column.dart';
import 'package:zatca/helpers/fatoora_db.dart';
import 'package:zatca/models/customers.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/product.dart';
import 'package:zatca/models/purchase.dart';
import 'package:zatca/models/settings.dart';
import 'package:zatca/screens/qr_scanner.dart';

import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/suppliers.dart';
import '../pdf/pdf_invoice_api.dart';
import '../pdf/pdf_receipt.dart';
import '../widgets/widget.dart';

const fontStyle =
    TextStyle(color: Utils.primary, fontWeight: FontWeight.bold, fontSize: 12);

class AddEditInvoiceAndroidPage extends StatefulWidget {
  final bool? isCreditNote;
  final bool? isPurchases;
  final dynamic product;
  final Invoice? invoice;
  final Purchase? purchase;
  final String? invoiceType;

  const AddEditInvoiceAndroidPage({
    super.key,
    this.isCreditNote = false,
    this.isPurchases = false,
    this.product,
    this.invoice,
    this.purchase,
    this.invoiceType = "simplified",
  });

  @override
  State<AddEditInvoiceAndroidPage> createState() =>
      _AddEditInvoiceAndroidPageState();
}

class _AddEditInvoiceAndroidPageState extends State<AddEditInvoiceAndroidPage> {
  List<String> payMethod = ['شبكة', 'كاش', 'آجل', 'حوالة', 'عقد'];
  String paymentMeans = '10';
  String selectedPayMethod = 'شبكة';

  String getPaymentMeansCode(String method) {
    switch (method) {
      case 'شبكة':
        return '20'; // Payment card
      case 'كاش':
        return '10'; // Cash
      case 'نقدي':
        return '10'; // Cash
      case 'آجل':
        return '97'; // Other (e.g. deferred payment)
      case 'حوالة':
        return '31'; // Credit transfer
      case 'عقد':
        return '97'; // Other (contract-based)
      default:
        return '10'; // Default to "Other"
    }
  }

  String? selectedProduct;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool scanned = false;
  TextEditingController textQRCode = TextEditingController();
  final TextEditingController qrController = TextEditingController();
  final _key1 = GlobalKey<FormState>();
  final _key2 = GlobalKey<FormState>();
  late int recId;
  late int newId; // This id for new invoice id in cloud database
  late int id; // this is existing invoice id will be retrieved from widget
  late final Customer payer;

  // late final Setting seller;
  // late final Setting vendor;
  late final Supplier supplier;
  late final Setting vendorVatNumber;
  late final String project;
  late final String date;
  late final String supplyDate;
  late List<InvoiceLines> items = [];
  late List<InvoiceLines> lines = [];
  late List<Invoice> dailyInvoices = [];
  late List<String> customers = [];
  late List<String> vendors = [];
  String invoiceNo = '';
  int counter = 50;
  Image? imgText;
  bool isPreview = false;
  bool isEstimate = false;
  int smsCredits = 0;

  final TextEditingController _productName = TextEditingController();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _invoiceNo = TextEditingController();
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
  bool isManualProduct = true;
  bool isLoading = false;
  List<Product> products = [];
  List<String> productsList = [];
  int curPayerId = 1;
  int curSupplierId = 1;
  String curProject = '';
  String curDate = Utils.formatDate(DateTime.now());
  String curSupplyDate = Utils.formatDate(DateTime.now());
  bool printerConnected = false;
  String sellerAddress = '';
  String payerAddress = '';
  String newPayerAddress = '';
  String language = 'Arabic';
  String? activity;
  String? device = "Mobile";
  bool showCamera = false;
  bool isModified = false;
  String pdfPath = "";
  String qrText = 'Scan a QR code';
  String invoiceType = "";
  bool isApprovedByZatca = false;

  @override
  void initState() {
    super.initState();
    invoiceType = widget.invoiceType!;
    getInvoice();
    focusNode.requestFocus();
  }

  Future getInvoice() async {
    FatooraDB db = FatooraDB.instance;
    language = "Arabic";
    final pdfDir = await getApplicationDocumentsDirectory();
    pdfPath = "${pdfDir.path}/INVOICE.pdf";
    activity = "Commercial";
    try {
      setState(() => isLoading = true);
      _customerCellphone.text = "";

      int? purchasesCount = await FatooraDB.instance.getPurchasesCount();
      int? invoicesCount = await FatooraDB.instance.getInvoicesCount();

      if (widget.invoice != null) {
        curPayerId = widget.invoice!.payerId!;
        curProject = widget.invoice!.project;
        curDate = widget.invoice!.date;
        curSupplyDate = widget.invoice!.supplyDate;
        selectedPayMethod = widget.invoice!.paymentMethod;
        paymentMeans = getPaymentMeansCode(selectedPayMethod);
        invoiceNo = widget.invoice!.invoiceNo;
        if (widget.invoice!.posted == 1) {
          setState(() => isApprovedByZatca = true);
        }
      } else if (widget.purchase != null) {
        curSupplierId = int.parse(widget.purchase!.vendor);
      }

      id = widget.isPurchases == true
          ? widget.purchase == null
              ? purchasesCount == 0
                  ? 1
                  : (await db.getNewPurchaseId())! + 1
              : widget.purchase!.id!
          : widget.invoice != null
              ? widget.invoice!.id!
              : invoicesCount == 0
                  ? 1
                  : (await db.getNewInvoiceId())! + 1;
      payer = await FatooraDB.instance.getCustomerById(curPayerId);
      supplier = await FatooraDB.instance.getSupplierById(curSupplierId);

      if (widget.isPurchases == false) {
        _payer.text = payer.name;
        _payerVatNumber.text = payer.vatNumber;
        _project.text = curProject;
        _date.text = curDate;
        _supplyDate.text = curSupplyDate;
        _invoiceNo.text = invoiceNo;
        _totalDiscount.text = Utils.formatPrice(totalDiscount);
        _payMethod.text = selectedPayMethod;
      } else {
        if (widget.purchase == null) {
          _vendor.text = '';
          _vendorVatNumber.text = '';
          _date.text = Utils.formatDate(DateTime.now());
          _totalPurchases.text = '';
          _vatPurchases.text = '';
          _details.text = '';
        } else {
          Purchase purchase = await FatooraDB.instance.getPurchaseById(id);
          _vendor.text = supplier.name; // purchase.vendor;
          _vendorVatNumber.text =
              supplier.vatNumber; // purchase.vendorVatNumber;
          _date.text = purchase.date;
          _totalPurchases.text = Utils.formatNoCurrency(purchase.total);
          _vatPurchases.text = Utils.formatNoCurrency(purchase.totalVat);
          _details.text = purchase.details;
        }
      }

      List<Customer> list = await FatooraDB.instance.getAllCustomers();
      customers.clear();
      for (int i = 0; i < list.length; i++) {
        customers.add("${list[i].id}-${list[i].name}");
      }

      List<Supplier> list1 = await FatooraDB.instance.getAllSuppliers();
      vendors.clear();
      for (int i = 0; i < list1.length; i++) {
        vendors.add("${list1[i].id}-${list1[i].name}");
      }

      recId = id;

      /// to generate a unique invoice no declare the user who create this invoice
      invoiceNo = widget.isCreditNote!
          ? '${Utils.clientId}-$recId-CR'
          : invoiceNo.isNotEmpty
              ? invoiceNo
              : '${Utils.clientId}-$recId'; // default value if invoiceNo is empty

      ///  Initialize Invoice lines
      if (widget.invoice != null) {
        items = await db.getInvoiceLinesById(recId);
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

      /// Initialize invoice form controller header
      _totalDiscount.text = '$totalDiscount';
      _price.text = '0.00';
      _priceWithoutVat.text = '0.00';
      _qty.text = activity == "محروقات" ? '0.00' : '1';
      _invoiceNo.text = invoiceNo;

      sellerAddress +=
          Utils.buildingNo.isNotEmpty ? "${Utils.buildingNo} " : "";
      sellerAddress += Utils.street.isNotEmpty ? "${Utils.street} " : "";
      sellerAddress += Utils.district.isNotEmpty ? "${Utils.district}\n" : "";
      sellerAddress += Utils.city.isNotEmpty ? "${Utils.city}\n" : "";
      sellerAddress += "السعودية";

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
        // resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Utils.primary,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              const Text('فاتورة'),
              const SizedBox(width: 10), // Small spacing
              if (widget.isPurchases != true)
                Expanded(
                  // <-- constrain the dropdown to remaining space
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InvoiceKind(
                      initialValue:
                          invoiceType == "simplified" ? 'مبسطة' : 'ضريبية',
                      onChanged: (value) {
                        setState(() {
                          invoiceType = value;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            widget.isPurchases != true
                ? Container()
                : IconButton(
                    onPressed: savePurchases,
                    icon: const Icon(Icons.save, size: 35)),
            widget.isPurchases == true
                ? Container()
                : isApprovedByZatca
                    ? Utils.device == "Sunmi"
                        ? IconButton(
                            onPressed: () async {
                              printReceipt();
                            },
                            icon: const Icon(Icons.print, size: 35),
                          )
                        : Container() // for other devices give blank
                    : Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              // handel sending to zatca api
                              FatooraDB db = FatooraDB.instance;
                              ZatcaAPI zatca = ZatcaAPI.instance;
                              final invoice = await db.getInvoiceById(recId);
                              setState(() => isLoading = true);
                              final result =
                                  await zatca.generateInvoice(invoice);
                              setState(() => isLoading = false);
                              if (result) {
                                setState(() => isApprovedByZatca = true);
                              }
                            },
                            tooltip: 'ارسال الى هيئة الزكاة',
                            icon: const Icon(Icons.cloud_upload, size: 35),
                          ),
                          IconButton(
                            onPressed: () {
                              addOrUpdateInvoice();
                            },
                            tooltip: 'حفظ الفاتورة',
                            icon: const Icon(Icons.save, size: 35),
                          ),
                        ],
                      )
          ],
          leading: IconButton(
              onPressed: () => Get.back(result: true),
              icon: Icon(Icons.arrow_back)),
        ),
        body: widget.isPurchases! ? buildPurchaseInvoiceBody() : buildBody(),
      );

  void printReceipt() async {
    final db = FatooraDB.instance;
    final inv = widget.invoice;
    final seller = (await db.getAllSettings())[0];
    final customer = await db.getCustomerById(inv!.payerId!);
    final items = await db.getInvoiceLinesById(inv.id!);
    String? sellerAddress, payerAddress;

    try {
      sellerAddress = Utils.buildingNo;
      sellerAddress += Utils.buildingNo.isNotEmpty ? ' ' : '';
      sellerAddress += Utils.street.isNotEmpty ? Utils.street : '';
      sellerAddress += Utils.district.isNotEmpty ? '-${Utils.district}' : '';
      sellerAddress += Utils.city.isNotEmpty ? '-${Utils.city}' : '';
      sellerAddress += '-السعودية';

      payerAddress = customer.buildingNo;
      payerAddress += customer.buildingNo.isNotEmpty ? ' ' : '';
      payerAddress += customer.streetName.isNotEmpty ? customer.streetName : '';
      payerAddress +=
          customer.district.isNotEmpty ? '-${customer.district}' : '';
      payerAddress += customer.city.isNotEmpty ? '-${customer.city}' : '';
      payerAddress += '-السعودية';
      await SunmiPrinter.printImage(base64Decode(seller.logo),
          align: SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText(
          invoiceType == "simplified"
              ? 'فاتورة ضريبية مبسطة'
              : 'فاتورة مبيعات ضريبية',
          style: SunmiTextStyle(bold: true, align: SunmiPrintAlign.CENTER));
      await SunmiPrinter.lineWrap(50);
      await SunmiPrinter.printText(Utils.companyName,
          style: SunmiTextStyle(bold: true, align: SunmiPrintAlign.CENTER));
      await SunmiPrinter.printText(sellerAddress,
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER));
      await SunmiPrinter.printText('الرقم الضريبي  ${Utils.vatNumber}',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER));
      if (invoiceType == "standard") {
        await SunmiPrinter.lineWrap(50);
        await SunmiPrinter.printText('العميل: ${customer.name}',
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT));
        await SunmiPrinter.printText(payerAddress,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT));
        await SunmiPrinter.printText('الرقم الضريبي  ${customer.vatNumber}',
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT));
      }

      await SunmiPrinter.lineWrap(50);
      await SunmiPrinter.printText('==== تفاصيل الفاتورة ===',
          style: SunmiTextStyle(bold: true, align: SunmiPrintAlign.CENTER));
      for (int i = 0; i <= items.length - 1; i++) {
        await SunmiPrinter.printText(items[i].productName,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT));

        await SunmiPrinter.printRow(cols: [
          SunmiColumn(
            text: '${Utils.formatPrice(items[i].qty * items[i].price)}',
            width: 15,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: '${Utils.formatPrice(items[i].price)}x${items[i].qty}',
            width: 15,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
        ]);

        await SunmiPrinter.lineWrap(25);
      }
      await SunmiPrinter.lineWrap(25);
      double netTotal = inv.total / 1.15;
      double vat = inv.total - netTotal;
      await SunmiPrinter.printText(
          'الإجمالي الصافي   ${Utils.formatPrice(netTotal)}',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT));
      await SunmiPrinter.printText('الضريبة 15%   ${Utils.formatPrice(vat)}',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT));

      await SunmiPrinter.printText(
          'الإجمالي المستحق   ${Utils.formatPrice(inv.total)}',
          style: SunmiTextStyle(bold: true, align: SunmiPrintAlign.LEFT));
      await SunmiPrinter.printText('الدفع ${inv.paymentMethod}',
          style: SunmiTextStyle(align: SunmiPrintAlign.LEFT));
      await SunmiPrinter.lineWrap(50);
      final qrString = inv.qrCode;
      await SunmiPrinter.printQRCode(qrString!,
          style: SunmiQrcodeStyle(
            qrcodeSize: 3,
            errorLevel: SunmiQrcodeLevel.LEVEL_H,
          ));
      await SunmiPrinter.lineWrap(50);
      await SunmiPrinter.printText(seller.terms,
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER));
      await SunmiPrinter.printText('Invoice # ${inv.invoiceNo}',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER));
      await SunmiPrinter.printText(inv.date,
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER));

      await SunmiPrinter.lineWrap(150);
    } catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

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
                              Expanded(child: buildInvoiceDate()),
                              Utils.space(0, 1),
                              SizedBox(width: 130, child: buildInvoiceNo()),
                            ],
                          ),
                          Utils.space(0.25, 0),
                          Row(
                            children: [
                              Expanded(child: buildPayer()),
                              Utils.space(0, 1),
                              buildPayMethod(),
                            ],
                          ),
                          buildProject(),
                        ],
                      ),
                    ),
                  ),
                  Utils.space(0.25, 0),
                  NewFrame(
                    title: 'بيانات سطور الفاتورة',
                    child: Column(
                      children: [
                        buildProductName(),
                        Row(
                          children: [
                            SizedBox(width: 70, child: buildQty()),
                            Utils.space(0, 0.1),
                            activity == "محروقات"
                                ? Container()
                                : Expanded(child: buildPriceWithoutVat()),
                            activity == "محروقات"
                                ? Container()
                                : Expanded(child: buildPrice()),
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
                          "اجمالي الفاتورة",
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
                      if (widget.invoice != null) {
                        Invoice invoice = Invoice(
                          id: id,
                          invoiceNo: invoiceNo,
                          date: Utils.formatDate(DateTime.now()),
                          sellerId: Utils.clientId,
                          total: total,
                          totalVat: total - (total / 1.15),
                          posted: 1,
                          payerId: payer.id,
                          noOfLines: items.length,
                          invoiceType: invoiceType,
                        );
                        await FatooraDB.instance.updateInvoice(invoice);
                        await FatooraDB.instance.deleteInvoiceLines(id);
                        for (int i = 0; i < items.length; i++) {
                          await FatooraDB.instance
                              .createInvoiceLines(items[i], items[i].recId);
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
            isModified = true;
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

  Widget buildProductName() => MyTextFormField(
        controller: _productName,
        labelText: 'المنتج',
      );

  Widget buildInvoiceNo() => MyTextFormField(
        controller: _invoiceNo,
        labelText: 'رقم الفاتورة',
        isMandatory: true,
        onTap: () {
          var textValue = _invoiceNo.text;
          _invoiceNo.selection = TextSelection(
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
      onChanged: (value) {
        setState(() {
          _totalPrice.text =
              "${Utils.formatNoCurrency(num.parse(value) * num.parse(_price.text))}";
          isModified = true;
        });
      });

  Widget buildPrice() => MyTextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: _price,
      labelText: language == 'Arabic' ? 'السعر + ض' : 'Price VAT Included',
      onTap: () {
        var textValue = _price.text;
        _price.selection = TextSelection(
          baseOffset: 0,
          extentOffset: textValue.length,
        );
      },
      isMandatory: true,
      onChanged: (value) {
        setState(() {
          value.isNotEmpty
              ? _priceWithoutVat.text =
                  "${Utils.formatNoCurrency(num.parse(value) / 1.15)}"
              : null;
          isModified = true;
        });
      });

  Widget buildTotalDiscount() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            language == 'Arabic' ? 'مبلغ الخصم على الفاتورة' : 'Disc. Amount',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          // Utils.space(0, 1),
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
                  isModified = true;
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
      onChanged: (value) {
        setState(() {
          _qty.text =
              "${Utils.formatNoCurrency(num.parse(value) / num.parse(_price.text))}";
          isModified = true;
        });
      });

  Widget buildPriceWithoutVat() => MyTextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: _priceWithoutVat,
      labelText: language == 'Arabic' ? 'السعر - ض' : 'Price VAT Excluded',
      onTap: () {
        var textValue = _priceWithoutVat.text;
        _priceWithoutVat.selection = TextSelection(
          baseOffset: 0,
          extentOffset: textValue.length,
        );
      },
      isMandatory: true,
      onChanged: (value) {
        setState(() {
          _price.text = "${Utils.formatNoCurrency(num.parse(value) * 1.15)}";
          isModified = true;
        });
      });

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
              items.add(InvoiceLines(
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

  Widget buildPurchaseInvoiceBody() => Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.90,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(10),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _key2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildVendor(),
                              Row(
                                children: [
                                  Expanded(child: buildVendorVatNumber()),
                                  Utils.space(0, 1),
                                  Expanded(child: buildDate()),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: buildTotalPurchases()),
                                  Utils.space(0, 1),
                                  Expanded(child: buildVatPurchases()),
                                ],
                              ),
                              buildDetails(),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _scanQRCode,
                                child: const Text('مسح رمز الجودة'),
                              ),
                              Utils.space(10, 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
          hint: Text(_vendor.text, style: dataStyle),
          items: vendors
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
            String vendorName = value!.split('-')[1];
            setState(() {
              curSupplierId = int.parse(value.split('-')[0]);
              _vendor.text = vendorName;
              isModified = true;
            });
            final sup = await FatooraDB.instance.getSupplierById(curSupplierId);
            _vendorVatNumber.text = sup.vatNumber;
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
            searchController: _payer,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding:
                  const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: _payer,
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
                    onPressed: () => addNewSupplier(_vendor.text),
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
      labelText: language == 'Arabic' ? 'إجمالي الفاتورة' : 'Total Invoice',
      isMandatory: true,
      onChanged: (value) {
        setState(() {
          _vatPurchases.text =
              "${Utils.formatNoCurrency(num.parse(_totalPurchases.text) - (num.parse(_totalPurchases.text) / 1.15))}";
          isModified = true;
        });
      });

  Widget buildVatPurchases() => MyTextFormField(
        controller: _vatPurchases,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        labelText: 'ضريبة القيمة المضافة',
        readOnly: true,
      );

  Widget buildPayer() => Container(
        margin: const EdgeInsets.only(left: 5, right: 5),
        child: DropdownButtonFormField2<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'العميل',
            labelStyle: TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
          ),
          hint: Text(_payer.text, style: dataStyle),
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
              curPayerId = int.parse(value.split('-')[0]);
              _payer.text = customerName;
              isModified = true;
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
            searchController: _payer,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding:
                  const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: _payer,
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
                    onPressed: () => addNewCustomer(_payer.text),
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

  Widget buildPayMethod() => Container(
      margin: const EdgeInsets.only(left: 5, right: 5),
      child: DropdownButtonFormField2<String>(
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'الدفع',
          labelStyle: TextStyle(fontSize: 12),
          constraints: BoxConstraints(maxWidth: 120),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
        ),
        items: payMethod
            .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: dataStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        value: selectedPayMethod,
        onChanged: (String? value) async {
          setState(() {
            _payMethod.text = value!;
            paymentMeans = getPaymentMeansCode(selectedPayMethod);
            isModified = true;
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
      ));

  Widget buildPayMethod1() => MyTextFormField(
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
        labelText: 'ملاحظات',
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

  Widget buildInvoiceDate() => MyTextFormField(
        controller: _date,
        labelText: 'التاريخ',
        onTap: _selectDate,
        isMandatory: true,
      );

  Widget buildDate() => MyTextFormField(
        controller: _date,
        labelText: language == 'Arabic' ? 'تاريخ الفاتورة' : 'Invoice Date',
        onTap: _selectDate,
      );

  Widget buildSupplyDate() => MyTextFormField(
        controller: _supplyDate,
        labelText: language == 'Arabic' ? 'تاريخ التوريد' : 'Supply Date',
        onTap: _selectSupplyDate,
      );

  void savePurchases() {
    setState(() {
      isPreview = false;
    });
    addOrUpdateInvoice();
    // Get.to(() => const InvoicesPage(tabVal: 1));
  }

  void printPreview() {
    setState(() {
      isPreview = true;
      isEstimate = false;
    });
    addOrUpdateInvoice();
  }

  void printEstimate() {
    setState(() {
      isEstimate = true;
      isPreview = false;
    });
    addOrUpdateInvoice();
  }

  /// To add/update invoice to database
  void addOrUpdateInvoice() async {
    if (widget.isPurchases == false) {
      final isValid =
          Platform.isAndroid ? true : _key1.currentState!.validate();
      final hasLines = items.isNotEmpty ? true : false;
      if (!hasLines) {
        messageBox('يجب إدخال سطور للفاتورة');
      }
      if (isValid && hasLines) {
        final isUpdating = widget.invoice != null;
        setState(() {
          isLoading = true;
        });
        isUpdating ? await updateInvoice() : await addInvoice();

        setState(() {
          isLoading = false;
        });
        ZatcaAPI.successMessage("تم حفظ الفاتورة");
      }
    } else {
      final isValid = _key2.currentState!.validate();
      if (isValid) {
        final isUpdating = widget.purchase != null;

        setState(() {
          isLoading = true;
        });
        if (isUpdating) {
          await updateInvoice();
        } else {
          await addInvoice();
        }
        setState(() {
          isLoading = false;
        });
        ZatcaAPI.successMessage("تم حفظ الفاتورة");
      }
    }
    //Get.to(() => const InvoicesPage(tabVal: 0));
  }

  Future updateInvoice() async {
    if (widget.isPurchases == false) {
      Invoice invoice = Invoice(
        id: id,
        invoiceNo: _invoiceNo.text,
        date: _date.text,
        supplyDate: _supplyDate.text,
        sellerId: Utils.clientId,
        project: _project.text,
        total: total - totalDiscount,
        totalVat: (total - totalDiscount) - ((total - totalDiscount) / 1.15),
        posted: 0,
        payerId: curPayerId,
        noOfLines: items.length,
        paymentMethod: _payMethod.text,
        invoiceType: invoiceType,
      );

      await FatooraDB.instance.updateInvoice(invoice);
      await FatooraDB.instance.deleteInvoiceLines(id);

      for (int i = 0; i < items.length; i++) {
        await FatooraDB.instance.createInvoiceLines(items[i], items[i].recId);
      }
    } else {
      final vendorId =
          await FatooraDB.instance.getSupplierIdByName(_vendor.text);
      Purchase purchase = Purchase(
        id: id,
        date: _date.text,
        vendor: vendorId.toString(),
        vendorVatNumber: _vendorVatNumber.text,
        total: (num.parse(_totalPurchases.text)),
        totalVat: (num.parse(_totalPurchases.text)) -
            ((num.parse(_totalPurchases.text)) / 1.15),
        details: _details.text,
      );
      await FatooraDB.instance.updatePurchase(purchase);
    }
  }

  Future addInvoice() async {
    if (widget.isPurchases == false) {
      Customer currentPayer =
          await FatooraDB.instance.getCustomerById(curPayerId);
      Invoice invoice = Invoice(
        invoiceNo: _invoiceNo.text,
        date: _date.text,
        supplyDate: _supplyDate.text,
        sellerId: Utils.clientId,
        project: _project.text,
        total: total,
        totalVat: total - (total / 1.15),
        posted: 0,
        payerId: curPayerId,
        noOfLines: items.length,
        paymentMethod: _payMethod.text,
        invoiceType: invoiceType,
      );
      await FatooraDB.instance.createInvoice(invoice);

      for (int i = 0; i < items.length; i++) {
        await FatooraDB.instance.createInvoiceLines(items[i], items[i].recId);
      }
      Utils.isA4Invoice && isPreview
          ? await PdfInvoiceApi.generate(
              invoice,
              currentPayer,
              items,
              invoice.posted == 1
                  ? 'فاتورة مبيعات ضريبية مرحلة'
                  : 'فاتورة مبيعات ضريبية',
              invoice.project,
              isPreview)
          : await PdfReceipt.generate(
              invoice,
              currentPayer,
              items,
              invoice.posted == 1
                  ? 'فاتورة مبيعات ضريبية مرحلة'
                  : 'فاتورة مبيعات ضريبية',
              invoice.project,
              Utils.isProVersion,
              isPreview);
      // }
    } else {
      final vendorId =
          await FatooraDB.instance.getSupplierIdByName(_vendor.text);
      Purchase purchase = Purchase(
        date: _date.text,
        vendor: vendorId.toString(),
        vendorVatNumber: _vendorVatNumber.text,
        total: num.parse(_totalPurchases.text),
        totalVat: (num.parse(_totalPurchases.text)) -
            ((num.parse(_totalPurchases.text)) / 1.15),
        details: _details.text,
      );
      await FatooraDB.instance.createPurchase(purchase);
    }
  }

  Future<void> addNewCustomer(String value) async {
    if (value.isNotEmpty) {
      Customer newCustomer;
      final isCustomer = await FatooraDB.instance.customerExist(value);
      if (isCustomer) {
        messageBox("العميل $value موجود بالفعل");
      } else {
        newCustomer =
            await FatooraDB.instance.createCustomer(Customer(name: value));
        setState(() {
          curPayerId = newCustomer.id!;
          customers.add("$curPayerId-$value");
          _payer.text = value;
        });
        messageBox("تم إضافة العميل $value");
      }
    } else {
      messageBox("لم يتم ادخل بيانات");
    }
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
          vendors.add("$curSupplierId-$value");
          _vendor.text = value;
        });
        messageBox("تم إضافة المورد $value");
      }
    } else {
      messageBox("لم يتم ادخل بيانات");
    }
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
      messageBox("لم يتم ادخل بيانات");
    }
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerPage("مسح رمز الجودة"),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        qrController.text = result;
        final parsed = jsonDecode(qrController.text);
        _vendor.text = parsed['seller'];
        _vendorVatNumber.text = parsed['vatNumber'];
        _date.text = parsed['invoiceDate'];
        _totalPurchases.text = parsed['totalAmount'];
        _vatPurchases.text = parsed['vatAmount'];
      });
    }
  }
}
