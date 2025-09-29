const String tableInvoices = 'invoices';
const String tableInvoiceLines = 'invoice_lines';

class InvoiceFields {
  static const String id = 'id';
  static const String invoiceNo = 'invoiceNo';
  static const String date = 'date';
  static const String supplyDate = 'supplyDate';
  static const String sellerId = 'sellerId';
  static const String total = 'total';
  static const String totalVat = 'totalVat';
  static const String posted = 'posted';
  static const String payerId = 'payerId';
  static const String noOfLines = 'noOfLines';
  static const String project = 'project';
  static const String paymentMethod = 'paymentMethod';
  static const String icv = 'icv';
  static const String invoiceHash = 'invoiceHash';
  static const String uuid = 'uuid';
  static const String qrCode = 'qrCode';
  static const String statusCode = 'statusCode';
  static const String status = 'status';
  static const String errorMessage = 'errorMessage';
  static const String warningMessage = 'warningMessage';
  static const String xml = 'xml';
  static const String invoiceType = 'invoiceType';
  static const String invoiceKind = 'invoiceKind';
  static const String isCredit = 'isCredit';
  static const String lastCreditAmount = 'lastCreditAmount';

  static List<String> getInvoiceFields() => [
        id,
        invoiceNo,
        date,
        supplyDate,
        sellerId,
        total,
        totalVat,
        posted,
        payerId,
        noOfLines,
        project,
        paymentMethod,
        icv,
        invoiceHash,
        uuid,
        qrCode,
        statusCode,
        status,
        errorMessage,
        warningMessage,
        xml,
        invoiceType,
        invoiceKind,
        isCredit,
        lastCreditAmount
      ];
}

class Invoice {
  final int? id;
  final String invoiceNo;
  final String date;
  final String supplyDate;
  final int? sellerId;
  final num total;
  final num totalVat;
  final int posted;
  final int? payerId;
  final int noOfLines;
  final String project;
  final String paymentMethod;
  final int? icv;
  final String? invoiceHash;
  final String? uuid;
  final String? qrCode;
  final String? statusCode;
  final String? status;
  final String? errorMessage;
  final String? warningMessage;
  final String? xml;
  final String invoiceType;
  final String invoiceKind;
  final int isCredit;
  final num lastCreditAmount;

  Invoice({
    this.id,
    this.invoiceNo = '',
    this.date = '',
    this.supplyDate = '',
    this.sellerId,
    this.total = 0.0,
    this.totalVat = 0.0,
    this.posted = 0,
    this.payerId,
    this.noOfLines = 0,
    this.project = '',
    this.paymentMethod = '',
    this.icv = 0,
    this.invoiceHash = '',
    this.uuid = '',
    this.qrCode = '',
    this.statusCode = '',
    this.status = '',
    this.errorMessage = '',
    this.warningMessage = '',
    this.xml = '',
    this.invoiceType = 'simplified',
    this.invoiceKind = 'invoice',
    this.isCredit = 0,
    this.lastCreditAmount = 0.0,
  });

  Invoice copy({
    int? id,
    String? invoiceNo,
    String? date,
    String? supplyDate,
    int? sellerId,
    num? total,
    num? totalVat,
    int? posted,
    int? payerId,
    int? noOfLines,
    String? project,
    String? paymentMethod,
    int? icv,
    String? invoiceHash,
    String? uuid,
    String? qrCode,
    String? statusCode,
    String? status,
    String? errorMessage,
    String? warningMessage,
    String? xml,
    String? invoiceType,
    String? invoiceKind,
    int? isCredit,
    num? lastCreditAmount,
  }) =>
      Invoice(
        id: id ?? this.id,
        invoiceNo: invoiceNo ?? this.invoiceNo,
        date: date ?? this.date,
        supplyDate: supplyDate ?? this.supplyDate,
        sellerId: sellerId ?? this.sellerId,
        total: total ?? this.total,
        totalVat: totalVat ?? this.totalVat,
        posted: posted ?? this.posted,
        payerId: payerId ?? this.payerId,
        noOfLines: noOfLines ?? this.noOfLines,
        project: project ?? this.project,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        icv: icv ?? this.icv,
        invoiceHash: invoiceHash ?? this.invoiceHash,
        uuid: uuid ?? this.uuid,
        qrCode: qrCode ?? this.qrCode,
        statusCode: statusCode ?? this.statusCode,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        warningMessage: warningMessage ?? this.warningMessage,
        xml: xml ?? this.xml,
        invoiceType: invoiceType ?? this.invoiceType,
        invoiceKind: invoiceKind ?? this.invoiceKind,
        isCredit: isCredit ?? this.isCredit,
        lastCreditAmount: lastCreditAmount ?? this.lastCreditAmount,
      );

  factory Invoice.fromJson(dynamic json) {
    return Invoice(
      id: json[InvoiceFields.id] as int,
      invoiceNo: json[InvoiceFields.invoiceNo] as String,
      date: json[InvoiceFields.date] as String,
      supplyDate: json[InvoiceFields.supplyDate] as String,
      sellerId: json[InvoiceFields.sellerId] as int,
      total: json[InvoiceFields.total] as num,
      totalVat: json[InvoiceFields.totalVat] as num,
      posted: json[InvoiceFields.posted] as int,
      payerId: json[InvoiceFields.payerId] as int,
      noOfLines: json[InvoiceFields.noOfLines] as int,
      project: json[InvoiceFields.project] ?? '',
      paymentMethod: json[InvoiceFields.paymentMethod] ?? '',
      icv: json[InvoiceFields.icv] ?? 0,
      invoiceHash: json[InvoiceFields.invoiceHash] ?? '',
      uuid: json[InvoiceFields.uuid] ?? '',
      qrCode: json[InvoiceFields.qrCode] ?? '',
      statusCode: json[InvoiceFields.statusCode] ?? '',
      status: json[InvoiceFields.status] ?? '',
      errorMessage: json[InvoiceFields.errorMessage] ?? '',
      warningMessage: json[InvoiceFields.warningMessage] ?? '',
      xml: json[InvoiceFields.xml] ?? '',
      invoiceType: json[InvoiceFields.invoiceType] ?? '',
      invoiceKind: json[InvoiceFields.invoiceKind] ?? '',
      isCredit: json[InvoiceFields.isCredit] ?? 0,
      lastCreditAmount: json[InvoiceFields.lastCreditAmount] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        InvoiceFields.id: id,
        InvoiceFields.invoiceNo: invoiceNo,
        InvoiceFields.date: date,
        InvoiceFields.supplyDate: supplyDate,
        InvoiceFields.sellerId: sellerId,
        InvoiceFields.total: total,
        InvoiceFields.totalVat: totalVat,
        InvoiceFields.posted: posted,
        InvoiceFields.payerId: payerId,
        InvoiceFields.noOfLines: noOfLines,
        InvoiceFields.project: project,
        InvoiceFields.paymentMethod: paymentMethod,
        InvoiceFields.icv: icv,
        InvoiceFields.invoiceHash: invoiceHash,
        InvoiceFields.uuid: uuid,
        InvoiceFields.qrCode: qrCode,
        InvoiceFields.statusCode: statusCode,
        InvoiceFields.status: status,
        InvoiceFields.errorMessage: errorMessage,
        InvoiceFields.warningMessage: warningMessage,
        InvoiceFields.xml: xml,
        InvoiceFields.invoiceType: invoiceType,
        InvoiceFields.invoiceKind: invoiceKind,
        InvoiceFields.isCredit: isCredit,
        InvoiceFields.lastCreditAmount: lastCreditAmount,
      };

  String toParams() => "?id=$id"
      "&invoiceNo=$invoiceNo"
      "&date=$date"
      "&supplyDate=$supplyDate"
      "&sellerId=$sellerId"
      "&total=$total"
      "&totalVat=$totalVat"
      "&posted=$posted"
      "&payerId=$payerId"
      "&noOfLines=$noOfLines"
      "&project=$project"
      "&paymentMethod=$paymentMethod"
      "&icv=$icv"
      "&invoiceHash=$invoiceHash"
      "&uuid=$uuid"
      "&qrCode=$qrCode"
      "&statusCode=$statusCode"
      "&status=$status"
      "&errorMessage=$errorMessage"
      "&warningMessage=$warningMessage"
      "xml&=$xml"
      "invoiceType&=$invoiceType"
      "invoiceKind&=$invoiceKind"
      "isCredit&=$isCredit"
      "lastCreditAmount&=$lastCreditAmount";
}

class InvoiceLinesFields {
  static const String recId = 'recId';
  static const String id = 'id';
  static const String productName = 'productName';
  static const String price = 'price';
  static const String qty = 'qty';

  static List<String> getInvoiceLinesFields() =>
      [recId, id, productName, price, qty];
}

class InvoiceLines {
  final int? id;
  final int recId;
  final String productName;
  final num price;
  final num qty;

  InvoiceLines({
    this.id,
    required this.recId,
    required this.productName,
    required this.price,
    this.qty = 1,
  });

  InvoiceLines copy({
    int? id,
    int? recId,
    String? productName,
    num? price,
    num? qty,
  }) =>
      InvoiceLines(
        id: id ?? this.id,
        recId: recId ?? this.recId,
        productName: productName ?? this.productName,
        price: price ?? this.price,
        qty: qty ?? this.qty,
      );

  factory InvoiceLines.fromJson(dynamic json) {
    return InvoiceLines(
      id: json[InvoiceLinesFields.id] as int,
      recId: json[InvoiceLinesFields.recId] as int,
      productName: json[InvoiceLinesFields.productName],
      price: json[InvoiceLinesFields.price] as num,
      qty: json[InvoiceLinesFields.qty] as num,
    );
  }

  Map<String, dynamic> toJson() => {
        InvoiceLinesFields.id: id,
        InvoiceLinesFields.recId: recId,
        InvoiceLinesFields.productName: productName,
        InvoiceLinesFields.price: price,
        InvoiceLinesFields.qty: qty,
      };

  String toParams() => "?id=$id"
      "&recId=$recId"
      "&productName=$productName"
      "&price=$price"
      "&qty=$qty";
}
