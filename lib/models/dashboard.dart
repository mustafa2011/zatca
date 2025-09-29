
class DashboardTitleFields {
  static const String productsCount = 'productsCount';
  static const String invoicesCount = 'invoicesCount';
  static const String totalSales = 'totalSales';
  static const String totalVat = 'totalVat';
  static const String vat = 'vat';

  static List<String> getDashboardTitleFields() =>
      [productsCount,	invoicesCount,	totalSales,	totalVat,	vat];
}

class DashboardFormulaFields {
  static const String productsCount = '=IF(TEXT(COUNT(products!A:A),"#")="","0",TEXT(COUNT(products!A:A),"#"))';
  static const String invoicesCount = '=IF(TEXT(COUNT(invoices!A:A),"#")="","0",TEXT(COUNT(invoices!A:A),"#"))';
  static const String totalSales = '=IF(TEXT(SUM(invoices!F:F),"#,#0.00")="","0",TEXT(SUM(invoices!F:F),"#,#0.00"))';
  static const String totalVat = '=IF(TEXT(C2-(C2/(1+(E2/100))),"#,#0.00")="","0",TEXT(C2-(C2/(1+(E2/100))),"#,#0.00"))';
  static const String vat = '=TEXT(15,"#")';

  static List<String> getDashboardTitleFields() =>
      [productsCount,	invoicesCount,	totalSales,	totalVat,	vat];
}
