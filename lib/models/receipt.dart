const String tableReceipts = 'receipts';

class ReceiptFields {
  static const String id = 'id';
  static const String date = 'date';
  static const String receivedFrom = 'receivedFrom';
  static const String sumOf = 'sumOf';
  static const String amount = 'amount';
  static const String amountFor = 'amountFor';
  static const String payType = 'payType'; // Cash, Cheque or Transfer
  static const String chequeNo = 'chequeNo';
  static const String chequeDate = 'chequeDate';
  static const String transferNo = 'transferNo';
  static const String transferDate = 'transferDate';
  static const String bank = 'bank';
  static const String payTo = 'payTo';
  static const String receiptType = 'receiptType';

  static List<String> getReceiptFields() => [
        id,
        date,
        receivedFrom,
        sumOf,
        amount,
        amountFor,
        payType,
        chequeNo,
        chequeDate,
        transferNo,
        transferDate,
        bank,
        payTo,
        receiptType
      ];
}

class Receipt {
  final int? id;
  final String date;
  final String receivedFrom;
  final String sumOf;
  final num amount;
  final String amountFor;
  final String payType;
  final String chequeNo;
  final String chequeDate;
  final String transferNo;
  final String transferDate;
  final String bank;
  final String payTo;
  final String receiptType;

  Receipt({
    this.id,
    this.date = '',
    this.receivedFrom = '',
    this.sumOf = '',
    this.amount = 0.0,
    this.amountFor = '',
    this.payType = '',
    this.chequeNo = '',
    this.chequeDate = '',
    this.transferNo = '',
    this.transferDate = '',
    this.bank = '',
    this.payTo = '',
    this.receiptType = '',
  });

  Receipt copy({
    int? id,
    String? date,
    String? receivedFrom,
    String? sumOf,
    num? amount,
    String? amountFor,
    String? payType,
    String? chequeNo,
    String? chequeDate,
    String? transferNo,
    String? transferDate,
    String? bank,
    String? payTo,
    String? receiptType,
  }) =>
      Receipt(
        id: id ?? this.id,
        date: date ?? this.date,
        receivedFrom: receivedFrom ?? this.receivedFrom,
        sumOf: sumOf ?? this.sumOf,
        amount: amount ?? this.amount,
        amountFor: amountFor ?? this.amountFor,
        payType: payType ?? this.payType,
        chequeNo: chequeNo ?? this.chequeNo,
        chequeDate: chequeDate ?? this.chequeDate,
        transferNo: transferNo ?? this.transferNo,
        transferDate: transferDate ?? this.transferDate,
        bank: bank ?? this.bank,
        payTo: bank ?? this.payTo,
        receiptType: bank ?? this.receiptType,
      );

  factory Receipt.fromJson(dynamic json) {
    return Receipt(
      id: json[ReceiptFields.id] as int,
      date: json[ReceiptFields.date] as String,
      receivedFrom: json[ReceiptFields.receivedFrom] as String,
      sumOf: json[ReceiptFields.sumOf] as String,
      amount: json[ReceiptFields.amount] as num,
      amountFor: json[ReceiptFields.amountFor] as String,
      payType: json[ReceiptFields.payType] as String,
      chequeNo: json[ReceiptFields.chequeNo] as String,
      chequeDate: json[ReceiptFields.chequeDate] as String,
      transferNo: json[ReceiptFields.transferNo] as String,
      transferDate: json[ReceiptFields.transferDate] as String,
      bank: json[ReceiptFields.bank] as String,
      payTo: json[ReceiptFields.payTo] as String,
      receiptType: json[ReceiptFields.receiptType] as String,
    );
  }
  Map<String, dynamic> toJson() => {
        ReceiptFields.id: id,
        ReceiptFields.date: date,
        ReceiptFields.receivedFrom: receivedFrom,
        ReceiptFields.sumOf: sumOf,
        ReceiptFields.amount: amount,
        ReceiptFields.amountFor: amountFor,
        ReceiptFields.payType: payType,
        ReceiptFields.chequeNo: chequeNo,
        ReceiptFields.chequeDate: chequeDate,
        ReceiptFields.transferNo: transferNo,
        ReceiptFields.transferDate: transferDate,
        ReceiptFields.bank: bank,
        ReceiptFields.payTo: payTo,
        ReceiptFields.receiptType: receiptType,
      };
  String toParams() => "?id=$id"
      "&date=$date"
      "&receivedFrom=$receivedFrom"
      "&sumOf=$sumOf"
      "&amount=$amount"
      "&amountFor=$amountFor"
      "&payType=$payType"
      "&chequeNo=$chequeNo"
      "&chequeDate=$chequeDate"
      "&transferNo=$transferNo"
      "&transferDate=$transferDate"
      "&bank=$bank"
      "&payTo=$payTo"
      "&receiptType=$receiptType";
}
