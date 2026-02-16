import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zatca/screens/contracts.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/contract.dart';
import '../widgets/widget.dart';

class AddEditContractPage extends StatefulWidget {
  final Contract? contract;

  const AddEditContractPage({
    super.key,
    this.contract,
  });

  @override
  State<AddEditContractPage> createState() => _AddEditContractPageState();
}

class _AddEditContractPageState extends State<AddEditContractPage> {
  List<String> payTypeList = ['نقدا', 'شيك', 'حوالة'];

  final _key1 = GlobalKey<FormState>();
  late int id = 1;
  String date = Utils.formatShortDate(DateTime.now());
  num total = 0;
  String title = '';
  String firstParty = '';
  String secondParty = Utils.companyName;

  final TextEditingController _date = TextEditingController();
  final TextEditingController _total = TextEditingController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _firstParty = TextEditingController();
  final TextEditingController _secondParty = TextEditingController();

  final FocusNode focusNode = FocusNode();

  bool isLoading = false;
  String pdfPath = "";
  List<Clauses> _filteredClauses = [];
  List<ClausesLines> clausesLines = [];
  late Future<List<Clauses>> clausesFuture;
  late Future<List<ClausesLines>> clausesLinesFuture;
  List<Clauses> globalClauses = [];

  @override
  void initState() {
    super.initState();
    getContract();
    _loadData();
    focusNode.requestFocus();
  }

  Future<void> _loadData() async {
    try {
      clausesFuture = fetchClauses();
      final clauses = await fetchClauses();

      setState(() {
        _filteredClauses = clauses;
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  Future<List<Clauses>> fetchClauses() async {
    try {
      if (widget.contract != null) {
        globalClauses = await FatooraDB.instance
            .getClausesByContractId(widget.contract!.id!);
        if (globalClauses.isNotEmpty) {
          return globalClauses;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
      return [];
    }
  }

  Future getContract() async {
    FatooraDB db = FatooraDB.instance;
    final pdfDir = await getApplicationDocumentsDirectory();
    pdfPath = "${pdfDir.path}/CONTRACT.pdf";

    // clausesLinesFuture = fetchClausesLines();
    try {
      setState(() => isLoading = true);

      int? contractsCount = await FatooraDB.instance.getContractsCount();

      if (widget.contract != null) {
        date = widget.contract!.date;
        total = widget.contract!.total;
        title = widget.contract!.title;
        firstParty = widget.contract!.firstParty;
        secondParty = widget.contract!.secondParty;
      }
      id = widget.contract != null
          ? widget.contract!.id!
          : contractsCount == 0
              ? 1
              : (await db.getNewContractId())! + 1;
      _date.text = date;
      _total.text = total.toString();
      _title.text = title;
      _firstParty.text = firstParty;
      _secondParty.text = secondParty;

      setState(() {
        isLoading = false;
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Utils.primary,
          title: Text('عقد '),
          leading: IconButton(
              onPressed: () => Get.back(result: true),
              icon: const Icon(Icons.arrow_back)),
          actions: [
            buildButtonSave(),
          ],
        ),
        body: buildBody(),
      );

  void _addClause() {
    final TextEditingController clauseController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('إضافة بند رئيسي'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: clauseController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اسم البند',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم البند مطلوب';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await _saveClause(clauseController.text.trim());

              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClause(String clauseName) async {
    try {
      setState(() => isLoading = true);

      await createClause(
        Clauses(
          contractId: widget.contract!.id!,
          clauseName: clauseName,
        ),
      );

      await _loadData(); // refresh clauses
    } catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<int> createClause(Clauses clause) async {
    final db = await FatooraDB.instance.database;

    return await db.insert('clauses', {
      'contractId': clause.contractId,
      'clauseName': clause.clauseName,
    });
  }

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
                          child: Text('تاريخ العقد: ${_date.text}')),
                    ],
                  ),
                  Utils.space(1, 0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: buildTitle()),
                      SizedBox(
                        width: 120,
                        child: buildTotal(),
                      ),
                    ],
                  ),
                  buildFirstParty(),
                  buildSecondParty(),
                  Utils.space(1, 0),
                  if (widget.contract != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة بند رئيسي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Utils.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _addClause,
                        ),
                      ),
                    ),
                  widget.contract != null
                      ? buildClauses(widget.contract!.id!)
                      : Container(),
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

  Widget buildTotal() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: _total,
        textDirection: TextDirection.ltr,
        onTap: () {
          var textValue = _total.text;
          _total.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textValue.length,
          );
        },
        labelText: 'قيمة العقد',
        isMandatory: true,
        onChanged: (value) {},
      );

  Widget buildContractNo() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        labelText: 'رقم العقد',
        isMandatory: true,
        onChanged: (value) {},
      );

  Widget buildTitle() => MyTextFormField(
        controller: _title,
        labelText: 'عنوان العقد',
        isMandatory: true,
        onChanged: (value) {},
      );

  Widget buildFirstParty() => MyTextFormField(
        controller: _firstParty,
        labelText: 'الطرف الأول',
        isMandatory: true,
        onChanged: (value) {},
      );

  Widget buildSecondParty() => MyTextFormField(
        controller: _secondParty,
        labelText: 'الطرف الثاني',
        isMandatory: true,
        onChanged: (value) {},
      );

  Widget buildClauses(int contractId) {
    return Expanded(
      child: ListView.builder(
        itemCount: _filteredClauses.length,
        itemBuilder: (context, index) {
          final clause = _filteredClauses[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      clause.clauseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'تعديل البند الرئيسي',
                    onPressed: () => _editClause(clause),
                  ),
                ],
              ),
              children: [
                ClauseLinesWidget(clauseId: clause.id!),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة بند فرعي'),
                    onPressed: () {
                      _addClauseLine(clause.id!);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editClause(Clauses clause) {
    final TextEditingController controller =
        TextEditingController(text: clause.clauseName);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('تعديل البند الرئيسي'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم البند',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم البند مطلوب';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            child: const Text('حفظ'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await _updateClause(clause.id!, controller.text.trim());

              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateClause(int id, String name) async {
    try {
      setState(() => isLoading = true);

      final db = await FatooraDB.instance.database;
      await db.update(
        'clauses',
        {'clauseName': name},
        where: 'id = ?',
        whereArgs: [id],
      );

      // refresh list
      await _loadData();
    } catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addClauseLine(int clauseId) {
    final TextEditingController lineController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('إضافة بند فرعي'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: lineController,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'نص البند',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'نص البند مطلوب';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await _saveClauseLine(
                clauseId,
                lineController.text.trim(),
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClauseLine(int clauseId, String description) async {
    try {
      setState(() => isLoading = true);

      await createClauseLine(
        ClausesLines(
          clauseId: clauseId,
          description: description,
        ),
      );

      await _loadData(); // refresh clauses
    } catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<int> createClauseLine(ClausesLines line) async {
    final db = await FatooraDB.instance.database;

    return await db.insert('clauses_lines', {
      'clauseId': line.clauseId,
      'description': line.description,
    });
  }

  _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2021),
        lastDate: DateTime(2055));
    setState(() => _date.text = Utils.formatShortDate(picked!).toString());
  }

  void saveAndPreview() {
    addOrUpdateContract();
  }

  /// To add/update contract to database
  void addOrUpdateContract() async {
    final isValid = Platform.isAndroid ? true : _key1.currentState!.validate();

    if (isValid) {
      final isUpdating = widget.contract != null;
      setState(() {
        isLoading = true;
      });

      if (isUpdating) {
        await updateContract();
      } else {
        await addContract();
      }
      setState(() {
        isLoading = false;
      });
      ZatcaAPI.successMessage("تمت عملية الحفظ بنجاح");
      Get.to(() => const ContractsPg());
    }
  }

  Future updateContract() async {
    Contract contract = Contract(
      id: id,
      date: _date.text,
      total: num.parse(_total.text),
      firstParty: _firstParty.text,
      secondParty: _secondParty.text,
      title: _title.text,
    );

    await FatooraDB.instance.updateContract(contract);
  }

  Future addContract() async {
    Contract contract = Contract(
      id: id,
      date: _date.text,
      total: num.parse(_total.text),
      firstParty: _firstParty.text,
      secondParty: _secondParty.text,
      title: _title.text,
    );
    await FatooraDB.instance.createContract(contract);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ClauseLinesWidget extends StatefulWidget {
  final int clauseId;

  const ClauseLinesWidget({super.key, required this.clauseId});

  @override
  State<ClauseLinesWidget> createState() => _ClauseLinesWidgetState();
}

class _ClauseLinesWidgetState extends State<ClauseLinesWidget> {
  bool isLoading = false;
  late Future<List<ClausesLines>> _linesFuture;

  @override
  void initState() {
    super.initState();
    _loadClauseData();
  }

  Future<void> _loadClauseData() async {
    try {
      setState(() {
        _linesFuture = FatooraDB.instance.getLinesByClauseId(widget.clauseId);
      });
    } on Exception catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    }
  }

  Future<void> _updateClauseLine(int id, String description) async {
    try {
      setState(() => isLoading = true);

      await updateClauseLine(
        id: id,
        description: description,
      );

      await _loadClauseData(); // refresh UI
    } catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteClauseLine(int id) async {
    try {
      setState(() => isLoading = true);

      await deleteClauseLine(id);

      await _loadClauseData();
    } catch (e) {
      ZatcaAPI.errorMessage(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<int> updateClauseLine({
    required int id,
    required String description,
  }) async {
    final db = await FatooraDB.instance.database;

    return db.update(
      'clauses_lines',
      {'description': description},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteClauseLine(int id) async {
    final db = await FatooraDB.instance.database;

    return db.delete(
      'clauses_lines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClausesLines>>(
      future: _linesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'لا توجد بنود فرعية',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final lines = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(lines.length, (index) {
              final line = lines[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        line.description,
                        textAlign: TextAlign.justify,
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'تعديل',
                      onPressed: () => _editClauseLine(line, context),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                      tooltip: 'حذف',
                      onPressed: () => _confirmDeleteClauseLine(line, context),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _editClauseLine(ClausesLines line, BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: line.description);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('تعديل البند الفرعي'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'نص البند',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'نص البند مطلوب';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            child: const Text('حفظ'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              _updateClauseLine(line.id!, controller.text.trim());

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClauseLine(ClausesLines line, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا البند الفرعي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteClauseLine(line.id!);
            },
          ),
        ],
      ),
    );
  }
}
