import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../helpers/fatoora_db.dart';
import '../models/suppliers.dart';
import '../widgets/supplier_form_widget.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';

class AddEditSupplierPage extends StatefulWidget {
  final dynamic supplier;

  const AddEditSupplierPage({
    super.key,
    this.supplier,
  });

  @override
  State<AddEditSupplierPage> createState() => _AddEditSupplierPageState();
}

class _AddEditSupplierPageState extends State<AddEditSupplierPage> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String vatNumber;
  String buildingNo = '';
  String streetName = '';
  String district = '';
  String city = '';
  String country = '';
  String postalCode = '';
  String additionalNo = '';
  String contactNumber = '';

  @override
  void initState() {
    super.initState();
    name = widget.supplier?.name ?? '';
    vatNumber = widget.supplier?.vatNumber ?? '';
    buildingNo = widget.supplier?.buildingNo ?? '';
    streetName = widget.supplier?.streetName ?? '';
    district = widget.supplier?.district ?? '';
    city = widget.supplier?.city ?? '';
    country = widget.supplier?.country ?? '';
    postalCode = widget.supplier?.postalCode ?? '';
    additionalNo = widget.supplier?.additionalNo ?? '';
    contactNumber = widget.supplier?.contactNumber ?? '';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("صفحة المورد"),
          backgroundColor: Utils.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: addOrUpdateSupplier,
              icon: Icon(
                Icons.save,
                size: 35,
              ),
            ),
          ],
          leading: IconButton(
              onPressed: () => Get.back(result: true),
              icon: const Icon(Icons.arrow_back)),
        ),
        body: Form(
          key: _formKey,
          child: SupplierFormWidget(
            vatNumber: vatNumber,
            name: name,
            buildingNo: buildingNo,
            streetName: streetName,
            district: district,
            city: city,
            country: country,
            postalCode: postalCode,
            additionalNo: additionalNo,
            contactNumber: contactNumber,
            onChangedVatNumber: (vatNumber) =>
                setState(() => this.vatNumber = vatNumber),
            onChangedBuildingNo: (buildingNo) =>
                setState(() => this.buildingNo = buildingNo),
            onChangedStreetName: (streetName) =>
                setState(() => this.streetName = streetName),
            onChangedDistrict: (district) =>
                setState(() => this.district = district),
            onChangedCity: (city) => setState(() => this.city = city),
            onChangedCountry: (country) =>
                setState(() => this.country = country),
            onChangedPostalCode: (postalCode) =>
                setState(() => this.postalCode = postalCode),
            onChangedAdditionalNo: (additionalNo) =>
                setState(() => this.additionalNo = additionalNo),
            onChangedContactNumber: (contactNumber) =>
                setState(() => this.contactNumber = contactNumber),
            onChangedName: (name) => setState(() => this.name = name),
          ),
        ),
      );

  void addOrUpdateSupplier() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      final isUpdating = widget.supplier != null;

      if (isUpdating) {
        await updateSupplier();
      } else {
        await addSupplier();
      }

      ZatcaAPI.successMessage("تمت عملية الحفظ بنجاح");
    }
  }

  Future updateSupplier() async {
    final supplier = widget.supplier!.copy(
      vatNumber: vatNumber,
      name: name,
      buildingNo: buildingNo,
      streetName: streetName,
      district: district,
      city: city,
      country: country,
      postalCode: postalCode,
      additionalNo: additionalNo,
      contactNumber: contactNumber,
    );
    await FatooraDB.instance.updateSupplier(supplier);
  }

  Future addSupplier() async {
    final supplier = Supplier(
      name: name,
      vatNumber: vatNumber,
      buildingNo: buildingNo,
      streetName: streetName,
      district: district,
      city: city,
      country: country,
      postalCode: postalCode,
      additionalNo: additionalNo,
      contactNumber: contactNumber,
    );
    await FatooraDB.instance.createSupplier(supplier);
  }
}
