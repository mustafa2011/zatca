const String tableSuppliers = 'suppliers';

class SupplierFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String buildingNo = 'buildingNo';
  static const String streetName = 'streetName';
  static const String district = 'district';
  static const String city = 'city';
  static const String country = 'country';
  static const String postalCode = 'postalCode';
  static const String additionalNo = 'additionalNo';
  static const String vatNumber = 'vatNumber';
  static const String contactNumber = 'contactNumber';

  static List<String> getSupplierFields() => [
        id,
        name,
        buildingNo,
        streetName,
        district,
        city,
        country,
        postalCode,
        additionalNo,
        vatNumber,
        contactNumber
      ];
}

class Supplier {
  final int? id;
  final String name;
  final String buildingNo;
  final String streetName;
  final String district;
  final String city;
  final String country;
  final String postalCode;
  final String additionalNo;
  final String vatNumber;
  final String contactNumber;

  const Supplier({
    this.id,
    required this.name,
    this.buildingNo = '',
    this.streetName = '',
    this.district = '',
    this.city = 'الرياض',
    this.country = 'السعودية',
    this.postalCode = '',
    this.additionalNo = '',
    this.vatNumber = '399999999900003',
    this.contactNumber = '',
  });

  Supplier copy({
    int? id,
    String? name,
    String? buildingNo,
    String? streetName,
    String? district,
    String? city,
    String? country,
    String? postalCode,
    String? additionalNo,
    String? vatNumber,
    String? contactNumber,
  }) =>
      Supplier(
        id: id ?? this.id,
        name: name ?? this.name,
        buildingNo: buildingNo ?? this.buildingNo,
        streetName: streetName ?? this.streetName,
        district: district ?? this.district,
        city: city ?? this.city,
        country: country ?? this.country,
        postalCode: postalCode ?? this.postalCode,
        additionalNo: additionalNo ?? this.additionalNo,
        vatNumber: vatNumber ?? this.vatNumber,
        contactNumber: contactNumber ?? this.contactNumber,
      );

  factory Supplier.fromJson(dynamic json) {
    return Supplier(
      id: json[SupplierFields.id] as int,
      name: json[SupplierFields.name] as String,
      buildingNo: json[SupplierFields.buildingNo] ?? '',
      streetName: json[SupplierFields.streetName] ?? '',
      district: json[SupplierFields.district] ?? '',
      city: json[SupplierFields.city] ?? '',
      country: json[SupplierFields.country] ?? '',
      postalCode: json[SupplierFields.postalCode] ?? '',
      additionalNo: json[SupplierFields.additionalNo] ?? '',
      vatNumber: json[SupplierFields.vatNumber] as String,
      contactNumber: json[SupplierFields.contactNumber] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        SupplierFields.id: id,
        SupplierFields.name: name,
        SupplierFields.buildingNo: buildingNo,
        SupplierFields.streetName: streetName,
        SupplierFields.district: district,
        SupplierFields.city: city,
        SupplierFields.country: country,
        SupplierFields.postalCode: postalCode,
        SupplierFields.additionalNo: additionalNo,
        SupplierFields.vatNumber: vatNumber,
        SupplierFields.contactNumber: contactNumber,
      };
}
