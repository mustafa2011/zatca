
const String tablePo = 'po';
const String tablePoLines = 'po_lines';

class PoFields {
  static const String id = 'id';
  static const String poNo = 'poNo';
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
  static const String notes = 'notes';


  static List<String> getPoFields() =>
      [id, poNo, date, supplyDate, sellerId, total, totalVat, posted, payerId, noOfLines, project, paymentMethod, notes];
}

class Po {
  final int? id;
  final String poNo;
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
  final String notes;


  Po(
      {this.id,
        this.poNo='',
        this.date='',
        this.supplyDate='',
        this.sellerId,
        this.total=0.0,
        this.totalVat=0.0,
        this.posted = 0,
        this.payerId,
        this.noOfLines=0,
        this.project='',
        this.paymentMethod='',
        this.notes='',
      }); //: date = date ?? DateTime.now();

  Po copy(
      {int? id,
        String? poNo,
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
        String? notes,

      }) =>
      Po(
        id: id?? this.id,
        poNo: poNo?? this.poNo,
        date: date?? this.date,
        supplyDate: supplyDate?? this.supplyDate,
        sellerId: sellerId?? this.sellerId,
        total: total?? this.total,
        totalVat: totalVat?? this.totalVat,
        posted: posted?? this.posted,
        payerId: payerId?? this.payerId,
        noOfLines: noOfLines ?? this.noOfLines,
        project: project ?? this.project,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        notes: notes ?? this.notes,
      );

  factory Po.fromJson(dynamic json) {
    return Po(
      id: json[PoFields.id] as int,
      poNo: json[PoFields.poNo] as String,
      date: json[PoFields.date] as String,
      supplyDate: json[PoFields.supplyDate] as String,
      sellerId: json[PoFields.sellerId] as int,
      total: json[PoFields.total] as num,
      totalVat:  json[PoFields.totalVat] as num,
      posted:  json[PoFields.posted] as int,
      payerId: json[PoFields.payerId] as int,
      noOfLines: json[PoFields.noOfLines] as int,
      project: json[PoFields.project] ?? '',
      paymentMethod: json[PoFields.paymentMethod] ?? '',
      notes: json[PoFields.notes] ?? '',
    );
  }
  Map<String, dynamic> toJson() => {
    PoFields.id: id,
    PoFields.poNo: poNo,
    PoFields.date: date,
    PoFields.supplyDate: supplyDate,
    PoFields.sellerId: sellerId,
    PoFields.total: total,
    PoFields.totalVat: totalVat,
    PoFields.posted: posted,
    PoFields.payerId: payerId,
    PoFields.noOfLines: noOfLines,
    PoFields.project: project,
    PoFields.paymentMethod: paymentMethod,
    PoFields.notes: notes,
  };
  String toParams() =>
      "?id=$id"
          "&poNo=$poNo"
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
          "&notes=$notes"
  ;
}

class PoLinesFields {
  static const String recId = 'recId';
  static const String id = 'id';
  static const String productName = 'productName';
  static const String price = 'price';
  static const String qty = 'qty';


  static List<String> getPoLinesFields() =>
      [recId, id, productName, price, qty];
}

class PoLines {
  final int? id;
  final int recId;
  final String productName;
  final num price;
  final num qty;


  PoLines(
      {
        this.id,
        required this.recId,
        required this.productName,
        required this.price,
        this.qty = 1,
      });

  PoLines copy(
      {
        int? id,
        int? recId,
        String? productName,
        num? price,
        num? qty,
      }) =>
      PoLines(
        id: id?? this.id,
        recId: recId?? this.recId,
        productName: productName?? this.productName,
        price: price?? this.price,
        qty: qty?? this.qty,
      );

  factory PoLines.fromJson(dynamic json) {
    return PoLines(
      id: json[PoLinesFields.id] as int,
      recId: json[PoLinesFields.recId] as int,
      productName: json[PoLinesFields.productName],
      price: json[PoLinesFields.price] as num,
      qty:  json[PoLinesFields.qty] as num,
    );
  }
  Map<String, dynamic> toJson() => {
    PoLinesFields.id: id,
    PoLinesFields.recId: recId,
    PoLinesFields.productName: productName,
    PoLinesFields.price: price,
    PoLinesFields.qty: qty,

  };
  String toParams() =>
      "?id=$id"
      "&recId=$recId"
      "&productName=$productName"
      "&price=$price"
      "&qty=$qty"
  ;
}



