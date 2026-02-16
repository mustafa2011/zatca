import 'package:flutter/material.dart';

import '../widgets/widget.dart';

class SupplierFormWidget extends StatelessWidget {
  final String vatNumber;
  final String? name;
  final String? buildingNo;
  final String? streetName;
  final String? district;
  final String? city;
  final String? country;
  final String? postalCode;
  final String? additionalNo;
  final String? contactNumber;
  final ValueChanged<String> onChangedBuildingNo;
  final ValueChanged<String> onChangedStreetName;
  final ValueChanged<String> onChangedDistrict;
  final ValueChanged<String> onChangedCity;
  final ValueChanged<String> onChangedCountry;
  final ValueChanged<String> onChangedPostalCode;
  final ValueChanged<String> onChangedAdditionalNo;
  final ValueChanged<String> onChangedVatNumber;
  final ValueChanged<String> onChangedName;
  final ValueChanged<String> onChangedContactNumber;

  const SupplierFormWidget({
    super.key,
    this.vatNumber = '',
    this.name = '',
    this.buildingNo = '',
    this.streetName = '',
    this.district = '',
    this.city = 'الرياض',
    this.country = 'المملكة العربية السعوية',
    this.postalCode = '',
    this.additionalNo,
    this.contactNumber = '',
    required this.onChangedBuildingNo,
    required this.onChangedStreetName,
    required this.onChangedDistrict,
    required this.onChangedCity,
    required this.onChangedCountry,
    required this.onChangedPostalCode,
    required this.onChangedAdditionalNo,
    required this.onChangedVatNumber,
    required this.onChangedName,
    required this.onChangedContactNumber,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: buildName()),
                  const SizedBox(width: 20),
                  Expanded(child: buildContactNumber()),
                ],
              ),
              Row(
                children: [
                  Expanded(child: buildVatNumber()),
                  const SizedBox(width: 20),
                  Expanded(child: buildBuildingNo()),
                ],
              ),
              Row(
                children: [
                  Expanded(child: buildStreetName()),
                  const SizedBox(width: 20),
                  Expanded(child: buildDistrict()),
                ],
              ),
              Row(
                children: [
                  Expanded(child: buildCity()),
                  const SizedBox(width: 20),
                  Expanded(child: buildCountry()),
                ],
              ),
              Row(
                children: [
                  Expanded(child: buildPostalCode()),
                  const SizedBox(width: 20),
                  Expanded(child: buildAdditionalNo()),
                ],
              ),
            ],
          ),
        ),
      );

  Widget buildName() => MyTextFormField(
        initialValue: name,
        keyboardType: TextInputType.name,
        labelText: 'اسم المورد',
        isMandatory: true,
        onChanged: onChangedName,
      );

  Widget buildContactNumber() => MyTextFormField(
        initialValue: contactNumber,
        keyboardType: TextInputType.phone,
        labelText: 'رقم الجوال',
        isMandatory: true,
        onChanged: onChangedContactNumber,
      );

  Widget buildBuildingNo() => MyTextFormField(
        initialValue: buildingNo,
        keyboardType: TextInputType.number,
        labelText: 'رقم المبنى',
        onChanged: onChangedBuildingNo,
      );

  Widget buildStreetName() => MyTextFormField(
        initialValue: streetName,
        keyboardType: TextInputType.text,
        labelText: 'الشارع',
        onChanged: onChangedStreetName,
      );

  Widget buildDistrict() => MyTextFormField(
        initialValue: district,
        keyboardType: TextInputType.text,
        labelText: 'الحي',
        onChanged: onChangedDistrict,
      );

  Widget buildCity() => MyTextFormField(
        initialValue: city,
        keyboardType: TextInputType.text,
        labelText: 'المدينة',
        onChanged: onChangedCity,
      );

  Widget buildCountry() => MyTextFormField(
        initialValue: country,
        keyboardType: TextInputType.text,
        labelText: 'البلد',
        onChanged: onChangedCountry,
      );

  Widget buildPostalCode() => MyTextFormField(
        initialValue: postalCode,
        keyboardType: TextInputType.text,
        labelText: 'رمز البريد',
        onChanged: onChangedPostalCode,
      );

  Widget buildAdditionalNo() => MyTextFormField(
        initialValue: additionalNo,
        keyboardType: TextInputType.text,
        labelText: 'الرقم الإضافي للعنوان',
        onChanged: onChangedAdditionalNo,
      );

  Widget buildVatNumber() => MyTextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        initialValue: vatNumber.toString(),
        labelText: 'الرقم الضريبي',
        pattern: RegExp(r'^(3)([0-9]{10})(0003)$'),
        isMandatory: true,
        onChanged: (vatNumber) => onChangedVatNumber(vatNumber),
      );
}
