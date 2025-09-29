import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../helpers/zatca_api.dart';
import '../models/product.dart';
import '../widgets/widget.dart';
import '../models/settings.dart';
import '../widgets/buttons.dart';
import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../screens/home.dart';

class VatEndorsementPage extends StatefulWidget {
  const VatEndorsementPage({super.key});

  @override
  State<VatEndorsementPage> createState() => _VatEndorsementPageState();
}

class _VatEndorsementPageState extends State<VatEndorsementPage> {
  FatooraDB db = FatooraDB.instance;
  late int uid;
  bool isLoading = false;
  bool isMonthly = false;
  List<Product> products = [];
  late List<Setting> user;
  int selectedYear = DateTime.now().year;
  final TextEditingController _year = TextEditingController();
  num? totalSales = 0.0;
  num? firstQuarterSales = 0.0;
  num? secondQuarterSales = 0.0;
  num? thirdQuarterSales = 0.0;
  num? forthQuarterSales = 0.0;
  num? janSales = 0.0;
  num? febSales = 0.0;
  num? marSales = 0.0;
  num? aprSales = 0.0;
  num? maySales = 0.0;
  num? junSales = 0.0;
  num? julSales = 0.0;
  num? augSales = 0.0;
  num? sepSales = 0.0;
  num? octSales = 0.0;
  num? novSales = 0.0;
  num? decSales = 0.0;

  num? totalExpenses = 0.0;
  num? totalPurchases = 0.0;
  num? firstQuarterPurchases = 0.0;
  num? secondQuarterPurchases = 0.0;
  num? thirdQuarterPurchases = 0.0;
  num? forthQuarterPurchases = 0.0;
  num? janPurchases = 0.0;
  num? febPurchases = 0.0;
  num? marPurchases = 0.0;
  num? aprPurchases = 0.0;
  num? mayPurchases = 0.0;
  num? junPurchases = 0.0;
  num? julPurchases = 0.0;
  num? augPurchases = 0.0;
  num? sepPurchases = 0.0;
  num? octPurchases = 0.0;
  num? novPurchases = 0.0;
  num? decPurchases = 0.0;

  @override
  void initState() {
    _year.text = selectedYear.toString();
    super.initState();
    getVatEndorsementCalculation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future getVatEndorsementCalculation() async {
    try {
      setState(() => isLoading = true);
      totalSales = await FatooraDB.instance.getTotalSales(selectedYear) ?? 0;
      janSales = await FatooraDB.instance.getJanTotalSales(selectedYear) ?? 0;
      febSales = await FatooraDB.instance.getFebTotalSales(selectedYear) ?? 0;
      marSales = await FatooraDB.instance.getMarTotalSales(selectedYear) ?? 0;
      aprSales = await FatooraDB.instance.getAprTotalSales(selectedYear) ?? 0;
      maySales = await FatooraDB.instance.getMayTotalSales(selectedYear) ?? 0;
      junSales = await FatooraDB.instance.getJunTotalSales(selectedYear) ?? 0;
      julSales = await FatooraDB.instance.getJulTotalSales(selectedYear) ?? 0;
      augSales = await FatooraDB.instance.getAugTotalSales(selectedYear) ?? 0;
      sepSales = await FatooraDB.instance.getSepTotalSales(selectedYear) ?? 0;
      octSales = await FatooraDB.instance.getOctTotalSales(selectedYear) ?? 0;
      novSales = await FatooraDB.instance.getNovTotalSales(selectedYear) ?? 0;
      decSales = await FatooraDB.instance.getDecTotalSales(selectedYear) ?? 0;

      firstQuarterSales = janSales! + febSales! + marSales!;
      secondQuarterSales = aprSales! + maySales! + junSales!;
      thirdQuarterSales = julSales! + augSales! + sepSales!;
      forthQuarterSales = octSales! + novSales! + decSales!;

      totalExpenses =
          await FatooraDB.instance.getTotalExpenses(selectedYear) ?? 0;
      totalPurchases =
          await FatooraDB.instance.getTotalPurchases(selectedYear) ?? 0;
      janPurchases =
          await FatooraDB.instance.getJanTotalPurchases(selectedYear) ?? 0;
      febPurchases =
          await FatooraDB.instance.getFebTotalPurchases(selectedYear) ?? 0;
      marPurchases =
          await FatooraDB.instance.getMarTotalPurchases(selectedYear) ?? 0;
      aprPurchases =
          await FatooraDB.instance.getAprTotalPurchases(selectedYear) ?? 0;
      mayPurchases =
          await FatooraDB.instance.getMayTotalPurchases(selectedYear) ?? 0;
      junPurchases =
          await FatooraDB.instance.getJunTotalPurchases(selectedYear) ?? 0;
      julPurchases =
          await FatooraDB.instance.getJulTotalPurchases(selectedYear) ?? 0;
      augPurchases =
          await FatooraDB.instance.getAugTotalPurchases(selectedYear) ?? 0;
      sepPurchases =
          await FatooraDB.instance.getSepTotalPurchases(selectedYear) ?? 0;
      octPurchases =
          await FatooraDB.instance.getOctTotalPurchases(selectedYear) ?? 0;
      novPurchases =
          await FatooraDB.instance.getNovTotalPurchases(selectedYear) ?? 0;
      decPurchases =
          await FatooraDB.instance.getDecTotalPurchases(selectedYear) ?? 0;

      firstQuarterPurchases = janPurchases! + febPurchases! + marPurchases!;
      secondQuarterPurchases = aprPurchases! + mayPurchases! + junPurchases!;
      thirdQuarterPurchases = julPurchases! + augPurchases! + sepPurchases!;
      forthQuarterPurchases = octPurchases! + novPurchases! + decPurchases!;

      setState(() => isLoading = false);
    } on Exception catch (e) {
      setState(() => isLoading = false);
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Utils.primary,
        foregroundColor: Colors.white,
        title: const Text("الإقرارات الضريبية"),
        leading: Container(),
        leadingWidth: 0.0,
        actions: [
          TextButton(
              onPressed: () => setState(() => isMonthly = !isMonthly),
              child: Text(
                isMonthly ? 'شهري' : 'ربع سنوي',
                style: const TextStyle(color: Colors.white),
              )),
          backHome,
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() => Container(
        color: Utils.background,
        padding: const EdgeInsets.all(10),
        height: MediaQuery.of(context).size.height * 0.76,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(children: [
            DropdownButtonFormField2<String>(
              isExpanded: true,
              iconStyleData: const IconStyleData(
                  iconSize: 30,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Utils.primary,
                  )),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 10, right: 10),
                constraints: BoxConstraints(maxHeight: 40, maxWidth: 125),
                labelText: 'السنة',
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Utils.primary,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
              ),
              items: [for (int i = 2022; i < 2124; i++) '$i']
                  .map((String item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Utils.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              value: selectedYear.toString(),
              onChanged: (String? value) async {
                setState(() => selectedYear = int.parse(value!));
                getVatEndorsementCalculation();
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
            Utils.space(1, 0),
            isMonthly ? buildSalesMonthly() : buildSalesQuarterly(),
            Utils.space(4, 0),
            isMonthly ? buildPurchasesMonthly() : buildPurchasesQuarterly(),
            Utils.space(4, 0),
            buildAmount('الصافي:', (totalSales! - totalPurchases!)),
            Utils.space(2, 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اجمالي المصروفات: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  color: Colors.orange,
                  width: 100,
                  child: Text(
                    '${Utils.formatNoCurrency(totalExpenses!)}',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            Utils.space(2, 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'صافي الربح: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  color: Colors.green,
                  width: 100,
                  child: Text(
                    '${Utils.formatNoCurrency(totalSales! - totalPurchases! - totalExpenses!)}',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ]),
        ),
      );

  Widget buildSalesQuarterly() => Column(
        children: [
          buildHeaderAndFooter(true, true),
          buildAmount('- اقرار الربع الأول', firstQuarterSales!),
          buildAmount('- اقرار الربع الثاني', secondQuarterSales!),
          buildAmount('- اقرار الربع الثالث', thirdQuarterSales!),
          buildAmount('- اقرار الربع الرابع', forthQuarterSales!),
          buildHeaderAndFooter(false, true),
        ],
      );

  Widget buildSalesMonthly() => Column(
        children: [
          buildHeaderAndFooter(true, true),
          buildAmount('- اقرار شهر يناير', janSales!),
          buildAmount('- اقرار شهر فبراير', febSales!),
          buildAmount('- اقرار شهر مارس', marSales!),
          buildAmount('- اقرار شهر ابريل', aprSales!),
          buildAmount('- اقرار شهر مايو', maySales!),
          buildAmount('- اقرار شهر يونيو', junSales!),
          buildAmount('- اقرار شهر يوليو', julSales!),
          buildAmount('- اقرار شهر أغسطس', augSales!),
          buildAmount('- اقرار شهر سبتمبر', sepSales!),
          buildAmount('- اقرار شهر أكتوبر', octSales!),
          buildAmount('- اقرار شهر نوفمبر', novSales!),
          buildAmount('- اقرار شهر ديسمبر', decSales!),
          buildHeaderAndFooter(false, true),
        ],
      );

  Widget buildPurchasesQuarterly() => Column(children: [
        Column(
          children: [
            buildHeaderAndFooter(true, false),
            buildAmount('- اقرار الربع الأول', firstQuarterPurchases!),
            buildAmount('- اقرار الربع الثاني', secondQuarterPurchases!),
            buildAmount('- اقرار الربع الثالث', thirdQuarterPurchases!),
            buildAmount('- اقرار الربع الرابع', forthQuarterPurchases!),
            buildHeaderAndFooter(false, false),
          ],
        ),
      ]);

  Widget buildPurchasesMonthly() => Column(
        children: [
          buildHeaderAndFooter(true, false),
          buildAmount('- اقرار شهر يناير', janPurchases!),
          buildAmount('- اقرار شهر فبراير', febPurchases!),
          buildAmount('- اقرار شهر مارس', marPurchases!),
          buildAmount('- اقرار شهر ابريل', aprPurchases!),
          buildAmount('- اقرار شهر مايو', mayPurchases!),
          buildAmount('- اقرار شهر يونيو', junPurchases!),
          buildAmount('- اقرار شهر يوليو', julPurchases!),
          buildAmount('- اقرار شهر أغسطس', augPurchases!),
          buildAmount('- اقرار شهر سبتمبر', sepPurchases!),
          buildAmount('- اقرار شهر أكتوبر', octPurchases!),
          buildAmount('- اقرار شهر نوفمبر', novPurchases!),
          buildAmount('- اقرار شهر ديسمبر', decPurchases!),
          buildHeaderAndFooter(false, false),
        ],
      );

  Widget buildHeaderAndFooter(bool isHeader, bool isSales) => Column(
        children: [
          const Divider(height: 2, color: Utils.primary),
          isHeader
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSales ? 'ضريبة المبيعات' : 'ضريبة المشتريات',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            'المبلغ',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'الضريبة',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : isSales
                  ? buildAmount('الإجمالي:', totalSales!)
                  : buildAmount('الإجمالي:', totalPurchases!),
          const Divider(height: 2, color: Utils.primary),
        ],
      );

  Widget buildAmount(String caption, num total) => Column(
        children: [
          caption == 'الإجمالي:' ||
                  caption == '- اقرار الربع الأول' ||
                  caption == '- اقرار شهر يناير'
              ? Container()
              : const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ' $caption',
                style: TextStyle(
                    fontWeight: caption == 'الإجمالي:' || caption == 'الصافي:'
                        ? FontWeight.bold
                        : FontWeight.normal),
              ),
              Row(
                children: [
                  Container(
                    color: caption == 'الإجمالي:'
                        ? null
                        : caption == 'الصافي:'
                            ? total >= 0
                                ? Colors.green[200]
                                : Colors.red[200]
                            : Colors.white,
                    width: 100,
                    child: Text(
                      Utils.formatNoCurrency(total / 1.15),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight:
                              caption == 'الإجمالي:' || caption == 'الصافي:'
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    color: caption == 'الإجمالي:'
                        ? null
                        : caption == 'الصافي:'
                            ? (total - total / 1.15) >= 0
                                ? Colors.green[200]
                                : Colors.red[200]
                            : Utils.secondary,
                    width: 100,
                    child: Text(
                      Utils.formatNoCurrency(total - total / 1.15),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight:
                            caption == 'الإجمالي:' || caption == 'الصافي:'
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color: caption == 'الإجمالي:'
                            ? null
                            : caption == 'الصافي:'
                                ? Colors.black
                                : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  Widget buildButtonsActions() => Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
        color: Utils.background,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: isMonthly,
                      onChanged: (bool value) {
                        setState(() {
                          isMonthly = !isMonthly;
                        });
                      },
                    ),
                    isMonthly
                        ? const Text(
                            'اقرار شهري',
                            style: TextStyle(
                                color: Utils.primary,
                                fontWeight: FontWeight.bold),
                          )
                        : const Text(
                            'اقرار ربع سنوي',
                            style: TextStyle(
                                color: Utils.primary,
                                fontWeight: FontWeight.bold),
                          ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButtons(
                      icon: Icons.home,
                      iconSize: 24,
                      radius: 24,
                      onTap: () => Get.to(() => const HomePage()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}
