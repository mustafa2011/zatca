import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../pdf/pdf_reports.dart';
import '../pdf/pdf_screen.dart';
import '../screens/home.dart';
import '../widgets/buttons.dart';
import '../widgets/widget.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  FatooraDB db = FatooraDB.instance;
  bool isDemo = false;
  String language = 'Arabic';
  final TextEditingController _dateFrom = TextEditingController();
  final TextEditingController _dateTo = TextEditingController();
  final TextEditingController _dateFrom1 = TextEditingController();
  final TextEditingController _dateTo1 = TextEditingController();
  String reportName = "تقرير مبيعات اليوم";
  int yy = DateTime.now().year;
  int mm = DateTime.now().month;
  int dd = DateTime.now().day;
  DateTime now = DateTime.now();
  String pdfPath = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getStart();
  }

  getStart() async {
    final pdfDir = await getApplicationDocumentsDirectory();
    pdfPath = "${pdfDir.path}/REPORT.pdf";
    language = "Arabic";
    setState(() {
      _dateFrom.text = Utils.formatShortDate(DateTime(yy, mm, dd - 1));
      _dateTo.text = Utils.formatShortDate(DateTime(yy, mm, dd - 1));
      _dateTo1.text = Utils.formatShortDate(now);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("التقارير"),
          actions: [
            backHome,
          ],
        ),
        body: buildBody());
  }

  Widget buildBody() => Column(
        children: [
          Container(
            color: Utils.background,
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                DropdownButtonFormField2<String>(
                  isExpanded: true,
                  iconStyleData: const IconStyleData(
                      iconSize: 30,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                      )),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(left: 10, right: 10),
                    labelText: 'حدد التقرير',
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                  ),
                  items: [
                    'تقرير مبيعات اليوم',
                    'تقرير مبيعات فترة',
                    'تقرير مشتريات فترة',
                  ]
                      .map((String item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ))
                      .toList(),
                  value: reportName,
                  onChanged: (String? value) async {
                    setState(() => reportName = value!);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _selectDateFrom,
                      child: Text("من: ${_dateFrom.text}"),
                    ),
                    reportName == 'تقرير مبيعات اليوم'
                        ? Container()
                        : TextButton(
                            onPressed: _selectDateTo,
                            child: Text("إلى: ${_dateTo.text}"),
                          ),
                  ],
                ),
                Utils.space(1, 0),
                IconButton(
                  onPressed: () async {
                    String d1 = _dateFrom.text;
                    String d2 = _dateTo.text;
                    setState(() => isLoading = true);
                    final pdf = await PdfReport.generateDailyReport(
                        reportTitle: reportName,
                        dateFrom: d1,
                        dateTo: reportName == 'تقرير مبيعات اليوم' ? d1 : d2,
                        invoices: reportName == 'تقرير مبيعات اليوم'
                            ? await FatooraDB.instance
                                .getAllInvoicesBetweenTwoDates(d1, d1)
                            : await FatooraDB.instance
                                .getAllInvoicesBetweenTwoDates(d1, d2),
                        purchases: await FatooraDB.instance
                            .getAllPurchasesBetweenTwoDates(d1, d2),
                        isDemo: isDemo);
                    Get.to(() => ShowPDF(pdf: pdf, title: 'تقرير'));
                    setState(() => isLoading = false);
                  },
                  icon: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 45,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading) Center(child: CircularProgressIndicator()),
        ],
      );

  Widget buildButtonsActions() => Positioned(
        left: 0,
        bottom: 0,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.10,
          width: MediaQuery.of(context).size.width,
          child: Container(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
            color: Utils.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
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
          ),
        ),
      );

  Widget buildCard(String reportTitle, String dateFrom, String dateTo) => Card(
        color: Colors.grey.shade400,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  reportTitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Utils.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                reportTitle == 'تقرير مبيعات اليوم'
                    ? Text(dateFrom)
                    : reportTitle == 'تقرير مبيعات فترة'
                        ? Row(
                            children: [
                              InkWell(
                                onTap: _selectDateFrom,
                                child: Text(dateFrom),
                              ),
                              const Text("  :  "),
                              InkWell(
                                onTap: _selectDateTo,
                                child: Text(dateTo),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              InkWell(
                                onTap: _selectDateFrom1,
                                child: Text(dateFrom),
                              ),
                              const Text("  :  "),
                              InkWell(
                                onTap: _selectDateTo1,
                                child: Text(dateTo),
                              ),
                            ],
                          )
              ]),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Utils.primary,
                  backgroundColor: Utils.background,
                ),
                onPressed: () async => {
                  await PdfReport.generateDailyReport(
                      reportTitle: reportTitle,
                      dateFrom: dateFrom,
                      dateTo: dateTo,
                      invoices: reportTitle == 'تقرير مبيعات اليوم'
                          ? await FatooraDB.instance
                              .getAllInvoicesBetweenTwoDates(dateFrom, dateTo)
                          : await FatooraDB.instance
                              .getAllInvoicesBetweenTwoDates(
                                  _dateFrom.text, _dateTo.text),
                      purchases: await FatooraDB.instance
                          .getAllPurchasesBetweenTwoDates(
                              _dateFrom1.text, _dateTo1.text),
                      isDemo: isDemo),
                },
                child: const Text('عرض'),
              ),
            ],
          ),
        ),
      );

  _selectDateFrom() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day - 1),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _dateFrom.text = Utils.formatShortDate(picked!).toString());
  }

  _selectDateTo() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _dateTo.text = Utils.formatShortDate(picked!).toString());
  }

  _selectDateFrom1() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day - 1),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _dateFrom1.text = Utils.formatShortDate(picked!).toString());
  }

  _selectDateTo1() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _dateTo1.text = Utils.formatShortDate(picked!).toString());
  }
}
