import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/fatoora_db.dart';
import '../helpers/utils.dart';
import '../helpers/zatca_api.dart';
import '../models/customers.dart';
import '../widgets/customer_form_widget.dart';

class AddEditCustomerPage extends StatefulWidget {
  final dynamic customer;

  const AddEditCustomerPage({
    super.key,
    this.customer,
  });

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String vatNumber;
  late String buildingNo;

  late String streetName;

  late String district;

  late String city;
  late String country;
  late String postalCode;
  late String additionalNo;
  late String contactNumber;

  @override
  void initState() {
    super.initState();
    name = widget.customer?.name ?? '';
    vatNumber = widget.customer?.vatNumber ?? '399999999900003';
    buildingNo = widget.customer?.buildingNo ?? Utils.buildingNo;
    streetName = widget.customer?.streetName ?? Utils.street;
    district = widget.customer?.district ?? Utils.district;
    city = widget.customer?.city ?? Utils.city;
    country = widget.customer?.country ?? 'السعودية';
    postalCode = widget.customer?.postalCode ?? Utils.postalCode;
    additionalNo = widget.customer?.additionalNo ?? Utils.secondaryNo;
    contactNumber = widget.customer?.contactNumber ?? Utils.contactNumber;
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          title: const Text("صفحة العميل"),
          backgroundColor: Utils.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: addOrUpdateCustomer,
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
          child: CustomerFormWidget(
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

  void addOrUpdateCustomer() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      final isUpdating = widget.customer != null;

      if (isUpdating) {
        await updateCustomer();
      } else {
        await addCustomer();
      }
      ZatcaAPI.successMessage("تمت عملية الحفظ بنجاح");
    }
  }

  Future updateCustomer() async {
    final customer = widget.customer!.copy(
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
    await FatooraDB.instance.updateCustomer(customer);
  }

  Future addCustomer() async {
    final customer = Customer(
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
    await FatooraDB.instance.createCustomer(customer);
  }
}
