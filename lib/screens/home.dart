import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../models/customers.dart';
import '../models/suppliers.dart';
import '../screens/customers.dart';
import '../screens/estimates.dart';
import '../screens/login.dart';
import '../screens/pos.dart';
import '../screens/products.dart';
import '../screens/purchases.dart';
import '../screens/receipts.dart';
import '../screens/reports_page.dart';
import '../screens/sales.dart';
import '../screens/settings_page.dart';
import '../screens/suppliers.dart';
import '../screens/vat_endorsement.dart';
import '../widgets/widget.dart';
import 'contracts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    initSetup();
  }

  Future<void> initSetup() async {
    final checkFirstCustomer = await FatooraDB.instance.isFirstCustomerExist();
    final checkFirstSupplier = await FatooraDB.instance.isFirstSupplierExist();
    Customer newCustomer = Customer(
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
    Supplier newSupplier = Supplier(
      id: 1,
      name: 'مورد نقدي',
      vatNumber: '399999999900003',
      streetName: Utils.street,
      city: Utils.city,
      country: "السعودية",
      buildingNo: Utils.buildingNo,
      additionalNo: Utils.secondaryNo,
      postalCode: Utils.postalCode,
      district: Utils.district,
    );
    if (!checkFirstCustomer!) {
      await FatooraDB.instance.createCustomer(newCustomer);
    }
    if (!checkFirstSupplier!) {
      await FatooraDB.instance.createSupplier(newSupplier);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildHeader(),
        titleSpacing: 0.0,
        toolbarHeight: 180.0,
        leadingWidth: 0.0,
        leading: Container(),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 10.0, right: 20, left: 20),
        color: Utils.background,
        child: buildBody(),
      ),
    );
  }

  Widget buildHeader() => Container(
        height: MediaQuery.of(context).size.height * 0.30,
        color: Utils.secondary,
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width * 0.45,
              color: Utils.primary,
            ),
            buildHeaderBackground(),
            buildTextHeader(),
          ],
        ),
      );

  Widget buildHeaderBackground() => Positioned(
      top: 0,
      right: 0,
      left: 70,
      bottom: 0,
      child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fitHeight,
              image: AssetImage("assets/images/header_page.png"),
            ),
          )));

  Widget buildTextHeader() => Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(right: 10, left: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الواضح فاتورة',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Utils.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Utils.space(2, 0),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: Text(
                    Utils.companyName,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Get.to(() => const LoginPage());
                      },
                      icon: Icon(Icons.logout, color: Colors.white, size: 30),
                    ),
                    IconButton(
                      onPressed: () async {
                        Get.to(() => SettingsPage());
                      },
                      icon: Icon(Icons.settings, color: Colors.white, size: 35),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  TextStyle bodyStyle() => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        fontFamily: "Cairo",
      );

  TextStyle headerStyle() => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Utils.primary,
        fontFamily: "Cairo",
      );

  Widget buildBody() => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Utils.device == "Mobile"
                  ? Image.memory(
                      base64Decode(Utils.logo),
                      height: Utils.logoHeight.toDouble(),
                      width: Utils.logoWidth.toDouble(),
                      fit: BoxFit.fill,
                    )
                  : Container(),
              Utils.device == "Mobile" ? Utils.space(2, 0) : Container(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MyTextButton(
                    onPressed: () => Get.to(() => const VatEndorsementPage()),
                    line1: "الإقرار الضريبي",
                  ),
                  Utils.space(0, 3),
                  MyTextButton(
                    onPressed: () => Get.to(() => const ReportsPage()),
                    line1: "التقارير",
                  ),
                ],
              ),
              Utils.space(2, 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MyTextButton(
                    onPressed: () => Get.to(() => const CustomersPg()),
                    line1: "العملاء",
                  ),
                  Utils.space(0, 3),
                  MyTextButton(
                    onPressed: () => Get.to(() => const SuppliersPg()),
                    line1: "الموردين",
                  ),
                ],
              ),
              Utils.space(2, 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MyTextButton(
                    onPressed: () => Get.to(() => const ProductsPg()),
                    line1: "المنتجات",
                  ),
                  Utils.space(0, 3),
                  // المبيعات
                  MyTextButton(
                    onPressed: () => Get.to(() => const InvoicesPg()),
                    line1: "المبيعات",
                  ),
                ],
              ),
              Utils.space(2, 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // المشتريات
                  MyTextButton(
                    onPressed: () => Get.to(() => const PurchasesPg()),
                    line1: "المشتريات",
                  ),
                  Utils.space(0, 3),
                  // عروض الأسعار
                  MyTextButton(
                    onPressed: () => Get.to(() => const EstimatesPg()),
                    line1: "عروض الأسعار",
                  ),
                ],
              ),
              Utils.space(2, 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // السندات
                  MyTextButton(
                    onPressed: () => Get.to(() => const ReceiptsPg()),
                    line1: "السندات",
                  ),
                  Utils.space(0, 3),
                  MyTextButton(
                    onPressed: () => Get.to(() => const PosPg()),
                    line1: "طلبات الشراء",
                  ),
                ],
              ),
              Utils.space(2, 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // العقود
                  MyTextButton(
                    onPressed: () => Get.to(() => const ContractsPg()),
                    line1: "العقود",
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget buildRotateText(String text) => Wrap(
        direction: Axis.vertical,
        children: verticalText(text),
      );

  List<Widget> verticalText(String text) {
    List<Widget> res = [];
    var words = text.split(" ");
    for (var word in words) {
      var parts = word.split(" ");
      int i = 0;
      res.add(RotatedBox(
          quarterTurns: 3, child: Text('${parts[i]} ', style: headerStyle())));
    }
    return res;
  }
}
