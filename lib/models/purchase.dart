const String tablePurchases = 'purchases';

class PurchaseFields {
  static const String id = 'id';
  static const String date = 'date';
  static const String vendor = 'vendor';
  static const String vendorVatNumber = 'vendorVatNumber';
  static const String total = 'total';
  static const String totalVat = 'totalVat';
  static const String details = 'details';
  static const String paymentMethod = 'paymentMethod';

  static List<String> getPurchaseFields() => [
        id,
        date,
        vendor,
        vendorVatNumber,
        total,
        totalVat,
        details,
        paymentMethod
      ];
}

class Purchase {
  final int? id;
  final String date;
  final String vendor;
  final String vendorVatNumber;
  final num total;
  final num totalVat;
  final String details;
  final String paymentMethod;

  Purchase({
    this.id,
    this.date = '',
    this.vendor = '',
    this.vendorVatNumber = '',
    this.total = 0.0,
    this.totalVat = 0.0,
    this.details = '',
    this.paymentMethod = '',
  });

  Purchase copy({
    int? id,
    String? date,
    String? vendor,
    String? vendorVatNumber,
    num? total,
    num? totalVat,
    String? details,
    String? paymentMethod,
  }) =>
      Purchase(
        id: id ?? this.id,
        date: date ?? this.date,
        vendor: vendor ?? this.vendor,
        vendorVatNumber: vendorVatNumber ?? this.vendorVatNumber,
        total: total ?? this.total,
        totalVat: totalVat ?? this.totalVat,
        details: details ?? this.details,
        paymentMethod: paymentMethod ?? this.paymentMethod,
      );

  factory Purchase.fromJson(dynamic json) {
    return Purchase(
      id: json[PurchaseFields.id] as int,
      date: json[PurchaseFields.date] as String,
      vendor: json[PurchaseFields.vendor] as String,
      vendorVatNumber: json[PurchaseFields.vendorVatNumber] as String,
      total: json[PurchaseFields.total] as num,
      totalVat: json[PurchaseFields.totalVat] as num,
      details: json[PurchaseFields.details] as String,
      paymentMethod: json[PurchaseFields.paymentMethod] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        PurchaseFields.id: id,
        PurchaseFields.date: date,
        PurchaseFields.vendor: vendor,
        PurchaseFields.vendorVatNumber: vendorVatNumber,
        PurchaseFields.total: total,
        PurchaseFields.totalVat: totalVat,
        PurchaseFields.details: details,
        PurchaseFields.paymentMethod: paymentMethod,
      };

  String toParams() => "?id=$id"
      "&date=$date"
      "&vendor=$vendor"
      "&vendorVatNumber=$vendorVatNumber"
      "&total=$total"
      "&totalVat=$totalVat"
      "&details=$details"
      "&paymentMethod=$paymentMethod";
}
