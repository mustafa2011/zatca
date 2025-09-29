
const String tableEstimates = 'estimates';
const String tableEstimateLines = 'estimate_lines';

class EstimateFields {
  static const String id = 'id';
  static const String estimateNo = 'estimateNo';
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


  static List<String> getEstimateFields() =>
      [id, estimateNo, date, supplyDate, sellerId, total, totalVat, posted, payerId, noOfLines, project, paymentMethod];
}

class Estimate {
  final int? id;
  final String estimateNo;
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


  Estimate(
      {this.id,
        this.estimateNo='',
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
      }); //: date = date ?? DateTime.now();

  Estimate copy(
      {int? id,
        String? estimateNo,
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

      }) =>
      Estimate(
        id: id?? this.id,
        estimateNo: estimateNo?? this.estimateNo,
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
      );

  factory Estimate.fromJson(dynamic json) {
    return Estimate(
      id: json[EstimateFields.id] as int,
      estimateNo: json[EstimateFields.estimateNo] as String,
      date: json[EstimateFields.date] as String,
      supplyDate: json[EstimateFields.supplyDate] as String,
      sellerId: json[EstimateFields.sellerId] as int,
      total: json[EstimateFields.total] as num,
      totalVat:  json[EstimateFields.totalVat] as num,
      posted:  json[EstimateFields.posted] as int,
      payerId: json[EstimateFields.payerId] as int,
      noOfLines: json[EstimateFields.noOfLines] as int,
      project: json[EstimateFields.project] ?? '',
      paymentMethod: json[EstimateFields.paymentMethod] ?? '',
    );
  }
  Map<String, dynamic> toJson() => {
    EstimateFields.id: id,
    EstimateFields.estimateNo: estimateNo,
    EstimateFields.date: date,
    EstimateFields.supplyDate: supplyDate,
    EstimateFields.sellerId: sellerId,
    EstimateFields.total: total,
    EstimateFields.totalVat: totalVat,
    EstimateFields.posted: posted,
    EstimateFields.payerId: payerId,
    EstimateFields.noOfLines: noOfLines,
    EstimateFields.project: project,
    EstimateFields.paymentMethod: paymentMethod,
  };
  String toParams() =>
      "?id=$id"
          "&estimateNo=$estimateNo"
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
  ;
}

class EstimateLinesFields {
  static const String recId = 'recId';
  static const String id = 'id';
  static const String productName = 'productName';
  static const String price = 'price';
  static const String qty = 'qty';


  static List<String> getEstimateLinesFields() =>
      [recId, id, productName, price, qty];
}

class EstimateLines {
  final int? id;
  final int recId;
  final String productName;
  final num price;
  final num qty;


  EstimateLines(
      {
        this.id,
        required this.recId,
        required this.productName,
        required this.price,
        this.qty = 1,
      });

  EstimateLines copy(
      {
        int? id,
        int? recId,
        String? productName,
        num? price,
        num? qty,
      }) =>
      EstimateLines(
        id: id?? this.id,
        recId: recId?? this.recId,
        productName: productName?? this.productName,
        price: price?? this.price,
        qty: qty?? this.qty,
      );

  factory EstimateLines.fromJson(dynamic json) {
    return EstimateLines(
      id: json[EstimateLinesFields.id] as int,
      recId: json[EstimateLinesFields.recId] as int,
      productName: json[EstimateLinesFields.productName],
      price: json[EstimateLinesFields.price] as num,
      qty:  json[EstimateLinesFields.qty] as num,
    );
  }
  Map<String, dynamic> toJson() => {
    EstimateLinesFields.id: id,
    EstimateLinesFields.recId: recId,
    EstimateLinesFields.productName: productName,
    EstimateLinesFields.price: price,
    EstimateLinesFields.qty: qty,

  };
  String toParams() =>
      "?id=$id"
      "&recId=$recId"
      "&productName=$productName"
      "&price=$price"
      "&qty=$qty"
  ;
}



