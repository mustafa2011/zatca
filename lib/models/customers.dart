const String tableCustomers = 'customers';

class CustomerFields {
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

  static List<String> getCustomerFields() => [
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

class Customer {
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

  const Customer({
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

  Customer copy({
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
      Customer(
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

  factory Customer.fromJson(dynamic json) {
    return Customer(
      id: json[CustomerFields.id] as int,
      name: json[CustomerFields.name] as String,
      buildingNo: json[CustomerFields.buildingNo] ?? '',
      streetName: json[CustomerFields.streetName] ?? '',
      district: json[CustomerFields.district] ?? '',
      city: json[CustomerFields.city] ?? '',
      country: json[CustomerFields.country] ?? '',
      postalCode: json[CustomerFields.postalCode] ?? '',
      additionalNo: json[CustomerFields.additionalNo] ?? '',
      vatNumber: json[CustomerFields.vatNumber] as String,
      contactNumber: json[CustomerFields.contactNumber] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        CustomerFields.id: id,
        CustomerFields.name: name,
        CustomerFields.buildingNo: buildingNo,
        CustomerFields.streetName: streetName,
        CustomerFields.district: district,
        CustomerFields.city: city,
        CustomerFields.country: country,
        CustomerFields.postalCode: postalCode,
        CustomerFields.additionalNo: additionalNo,
        CustomerFields.vatNumber: vatNumber,
        CustomerFields.contactNumber: contactNumber,
      };
}
