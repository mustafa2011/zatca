class Address {
  final String buildingNo;
  final String streetName;
  final String district;
  final String city;
  final String country;
  final String postalCode;
  final String additionalNo;
  final String vatNumber;

  const Address({
    this.buildingNo = '',
    this.streetName = '',
    this.district = '',
    this.city = 'الرياض',
    this.country = 'السعودية',
    this.postalCode = '',
    this.additionalNo = '',
    this.vatNumber = '399999999900003',
  });
}
