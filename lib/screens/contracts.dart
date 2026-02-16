import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/zatca_api.dart';
import '../models/contract.dart';
// import '../pdf/pdf_contract_api.dart';
import '../pdf/pdf_contract.dart';
import '../pdf/pdf_screen.dart';
import 'edit_contract_page.dart';
// import '../screens/edit_contract_page.dart';

class ContractsPg extends StatefulWidget {
  const ContractsPg({super.key});

  @override
  State<ContractsPg> createState() => _ContractsPgState();
}

class _ContractsPgState extends State<ContractsPg> {
  late Future<List<Contract>> contractsFuture;
  List<Contract> _allContracts = []; // Store all contracts data
  List<Contract> _filteredContracts = []; // Store filtered contracts data
  String _searchQuery = '';
  List<Contract> globalContracts = [];
  FatooraDB db = FatooraDB.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      contractsFuture = fetchContracts();
      final contracts = await fetchContracts(); // استنى البيانات

      setState(() {
        _allContracts = contracts;
        _filteredContracts = contracts;
        _filterContracts();
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  void didPopNext() {
    // Re-fetch or refresh the list
    initializeContracts();
  }

  void initializeContracts() async {
    try {
      globalContracts = await db.getAllContracts();
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العقود'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 30),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'بحث',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _filterContracts(); // Apply filter whenever the query changes
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Contract>>(
              future: contractsFuture,
              builder: (context, contractsSnapshot) {
                if (contractsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (contractsSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${contractsSnapshot.error}'));
                } else if (_filteredContracts.isEmpty) {
                  return const Center(child: Text(''));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredContracts.length,
                          itemBuilder: (context, index) {
                            Contract contract = _filteredContracts[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  const Text('عقد: '),
                                  Text(contract.title, softWrap: true),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("تاريخ: ${contract.date}",
                                      softWrap: true),
                                  Text("الطرف الأول: ${contract.firstParty}",
                                      softWrap: true),
                                  Text("الطرف الثاني: ${contract.secondParty}",
                                      softWrap: true),
                                  Text(
                                    "قيمة العقد: ${NumberFormat("#,##0.00").format(contract.total)}",
                                    softWrap: true,
                                  ),
                                ],
                              ),

                              /// 👇 three-dot menu
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'pdf':
                                      _generatePdf(context, index);
                                      break;

                                    case 'edit':
                                      final result = await Get.to(
                                        () => AddEditContractPage(
                                            contract: contract),
                                      );
                                      if (result == true) {
                                        _loadData();
                                      }
                                      break;

                                    case 'delete':
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('رسالة'),
                                            content: const Text(
                                                "هل تريد حذف السجل الحالي"),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text("نعم"),
                                                onPressed: () async {
                                                  await FatooraDB.instance
                                                      .deleteContractById(
                                                          contract.id!);

                                                  int? contractsCount =
                                                      await FatooraDB.instance
                                                          .getContractsCount();

                                                  if (contractsCount == 0) {
                                                    await FatooraDB.instance
                                                        .deleteContractSequence();
                                                  }

                                                  Get.back();
                                                  ZatcaAPI.successMessage(
                                                      "تمت عملية الحذف بنجاح");
                                                  _loadData();
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
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(
                                      children: [
                                        Icon(Icons.picture_as_pdf, size: 20),
                                        SizedBox(width: 8),
                                        Text('تصدير PDF'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('تعديل'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('حذف'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 25.0, bottom: 50, right: 10),
                        child: Column(
                          children: [
                            Text(
                              'اجمالي العقود: ${NumberFormat("#,##0.00").format(_calculateTotal())}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => AddEditContractPage());
          if (result == true) {
            _loadData(); // Refresh data if result indicates update
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _generatePdf(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        File? pdf;
        return StatefulBuilder(
          builder: (context, setState) {
            Future.microtask(() async {
              final contract = _filteredContracts[index];
              try {
                // Generate contract pdf
                pdf = await PdfContractApi.generate(contract);
              } catch (e) {
                ZatcaAPI.errorMessage(e.toString());
              } finally {
                if (context.mounted) {
                  Navigator.pop(context);
                  Get.to(() => ShowPDF(
                        pdf: pdf,
                        title: 'عقد ',
                      ));
                }
              }
            });

            return AlertDialog(
              content: Row(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("فضلا انتظر لحظات ..."),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _calculateTotal() {
    return _filteredContracts.fold(
        0.0, (sum, contract) => sum + contract.total);
  }

  void _filterContracts() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredContracts = _allContracts; // No filter, show all contracts
      } else {
        _filteredContracts = _allContracts.where((contract) {
          return contract.id.toString().contains(_searchQuery) ||
              contract.date.contains(_searchQuery) ||
              contract.total.toString().contains(_searchQuery) ||
              contract.firstParty.contains(_searchQuery) ||
              contract.secondParty.contains(_searchQuery) ||
              contract.contractNo.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<List<Contract>> fetchContracts() async {
    globalContracts = await db.getAllContracts();
    if (globalContracts.isNotEmpty) {
      return globalContracts;
    } else {
      return [];
    }
  }
}
