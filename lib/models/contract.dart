const String tableContracts = 'contracts';
const String tableClauses = 'clauses';
const String tableClausesLines = 'clauses_lines';

/// contract -> clause -> clauseLine [->: one to many relation]
class ContractFields {
  static const String id = 'id';
  static const String contractNo = 'contractNo';
  static const String date = 'date';
  static const String firstParty = 'firstParty';
  static const String secondParty = 'secondParty';
  static const String total = 'total';
  static const String title = 'title';

  static List<String> getContractFields() => [
        id,
        contractNo,
        date,
        firstParty,
        secondParty,
        total,
        title,
      ];
}

class Contract {
  final int? id; // auto increment id
  final String contractNo;
  final String date;
  final String firstParty;
  final String secondParty;
  final num total;
  final String title;

  Contract({
    this.id,
    this.contractNo = '',
    this.date = '',
    this.firstParty = '',
    this.secondParty = '',
    this.total = 0.0,
    this.title = '',
  });

  Contract copy({
    int? id,
    String? contractNo,
    String? date,
    String? firstParty,
    String? secondParty,
    num? total,
    String? title,
  }) =>
      Contract(
        id: id ?? this.id,
        contractNo: contractNo ?? this.contractNo,
        date: date ?? this.date,
        firstParty: firstParty ?? this.firstParty,
        secondParty: secondParty ?? this.secondParty,
        total: total ?? this.total,
        title: title ?? this.title,
      );

  factory Contract.fromJson(dynamic json) {
    return Contract(
      id: json[ContractFields.id] as int,
      contractNo: json[ContractFields.contractNo] as String,
      date: json[ContractFields.date] as String,
      firstParty: json[ContractFields.firstParty] as String,
      secondParty: json[ContractFields.secondParty] as String,
      total: json[ContractFields.total] as num,
      title: json[ContractFields.title] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        ContractFields.id: id,
        ContractFields.contractNo: contractNo,
        ContractFields.date: date,
        ContractFields.firstParty: firstParty,
        ContractFields.secondParty: secondParty,
        ContractFields.total: total,
        ContractFields.title: title,
      };

  String toParams() => "?id=$id"
      "&contractNo=$contractNo"
      "&date=$date"
      "&firstParty=$firstParty"
      "&secondParty=$secondParty"
      "&total=$total"
      "&title=$title";
}

class ClausesFields {
  static const String id = 'id';
  static const String contractId = 'contractId';
  static const String clauseName = 'clauseName';

  static List<String> getClausesFields() => [id, contractId, clauseName];
}

class Clauses {
  final int? id; // auto increment id
  final int contractId;
  final String clauseName;

  Clauses({
    this.id,
    required this.contractId,
    required this.clauseName,
  });

  Clauses copy({
    int? id,
    int? contractId,
    String? clauseName,
  }) =>
      Clauses(
        id: id ?? this.id,
        contractId: contractId ?? this.contractId,
        clauseName: clauseName ?? this.clauseName,
      );

  factory Clauses.fromJson(dynamic json) {
    return Clauses(
      id: json[ClausesFields.id] as int,
      contractId: json[ClausesFields.contractId] as int,
      clauseName: json[ClausesFields.clauseName],
    );
  }

  Map<String, dynamic> toJson() => {
        ClausesFields.id: id,
        ClausesFields.contractId: contractId,
        ClausesFields.clauseName: clauseName,
      };

  String toParams() => "?id=$id"
      "&contractId=$contractId"
      "&clauseName=$clauseName";
}

class ClausesLinesFields {
  static const String id = 'id';
  static const String clauseId = 'clauseId';
  static const String description = 'description';

  static List<String> getClausesLinesFields() => [id, clauseId, description];
}

class ClausesLines {
  final int? id; // auto increment id
  final int clauseId;
  final String description;

  ClausesLines({
    this.id,
    required this.clauseId,
    required this.description,
  });

  ClausesLines copy({
    int? id,
    int? clauseId,
    String? description,
  }) =>
      ClausesLines(
        id: id ?? this.id,
        clauseId: clauseId ?? this.clauseId,
        description: description ?? this.description,
      );

  factory ClausesLines.fromJson(dynamic json) {
    return ClausesLines(
      id: json[ClausesLinesFields.id] as int,
      clauseId: json[ClausesLinesFields.clauseId] as int,
      description: json[ClausesLinesFields.description],
    );
  }

  Map<String, dynamic> toJson() => {
        ClausesLinesFields.id: id,
        ClausesLinesFields.clauseId: clauseId,
        ClausesLinesFields.description: description,
      };

  String toParams() => "?id=$id"
      "&clauseId=$clauseId"
      "&description=$description";
}
