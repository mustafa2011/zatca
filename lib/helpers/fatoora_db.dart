import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:zatca/helpers/zatca_api.dart';
import 'package:zatca/models/customers.dart';
import 'package:zatca/models/invoice.dart';
import 'package:zatca/models/product.dart';
import 'package:zatca/models/purchase.dart';

import '/models/settings.dart';
import '../models/contract.dart';
import '../models/estimate.dart';
import '../models/po.dart';
import '../models/receipt.dart';
import '../models/suppliers.dart';
import 'utils.dart';

final currentYear = DateTime.now().year;
final lastFebDay = currentYear % 4 == 0 ? 29 : 28;
const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
const intType = 'INTEGER';
const textType = 'TEXT NOT NULL';
const text = 'TEXT';
const boolType = 'INTEGER NOT NULL';
const integerType = 'INTEGER NOT NULL';
const numType = 'NUMERIC NOT NULL';

class FatooraDB {
  static final FatooraDB instance = FatooraDB.init();

  static Database? _database;
  static String dbFileName = 'fatoora';
  static String? _pdfPath;

  FatooraDB.init();

  Future<String> get pdfPath async {
    if (_pdfPath != null) return _pdfPath!;
    _pdfPath = (await getApplicationDocumentsDirectory()).path;
    return _pdfPath!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb('$dbFileName.db');
    return _database!;
  }

  Future<Database> initDb(String filePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    String dbFilePath = '${appDir.path}${slash}Database$slash$filePath';
    return await databaseFactory.openDatabase(dbFilePath,
        options: OpenDatabaseOptions(
            version: 13,
            onConfigure: onConfigure,
            onCreate: (db, version) async {
              var batch = db.batch();
              _createTables(batch); // create all the tables
              await batch.commit();
            },
            onUpgrade: (db, oldVersion, newVersion) async {
              var batch = db.batch();
              if (oldVersion < 2) {
                /// Adding 4 columns to settings table:
                /// terms1,terms2,terms3 and terms4
              }
              if (oldVersion < 3) {
                /// Adding new three two models: estimate and receipt
                _updateToV3(batch);
              }
              if (oldVersion < 4) {
                /// Adding column details to purchase table
                _updateToV4(batch);
              }
              if (oldVersion < 5) {
                /// Adding new model po : purchase orders, same like estimates
                _updateToV5(batch);
              }
              if (oldVersion < 6) {
                /// Adding notes field to model po
                _updateToV6(batch);
              }
              if (oldVersion < 7) {
                /// Adding suppliers table
                _updateToV7(batch);
              }
              if (oldVersion < 8) {
                /// Adding 5 terms in table settings
              }
              if (oldVersion < 9) {
                /// update tables for zatca
                _updateToV9(batch);
              }
              if (oldVersion < 10) {
                /// Adding 2 Columns to table invoices:
                /// isCredit, lastCreditAmount
                _updateToV10(batch);
              }
              if (oldVersion < 11) {
                /// Adding a new column 'notes' to table estimate:
                _updateToV11(batch);
              }
              if (oldVersion < 12) {
                /// add col payerId to table receipts
                /// add paymentMethod to table purchases
                /// add new tables: contracts, clauses, clauses_lines
                _updateToV12(batch);
              }
              if (oldVersion < 13) {
                /// add cols environment, dev_authorization, sim_authorization,
                /// core_authorization to table receipts
                _updateToV13(batch);
              }
              await batch.commit();
            },
            onDowngrade: (db, oldVersion, newVersion) async {
              debugPrint('You did downgrade to version $newVersion');
              onDatabaseDowngradeDelete;
            }));
  }

  /// Let's use FOREIGN KEY constraints
  Future onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<List<String>> getTables(Database db) async {
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    return result.map((row) => row['name'] as String).toList();
  }

  Future<bool> validateNewDbStructure(File newDbFile) async {
    final newDb = await openDatabase(newDbFile.path);
    final List<Map<String, dynamic>> tables = await newDb
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final newTables = tables.map((e) => e['name'] as String).toSet();
    await newDb.close();

    final currentDb = await FatooraDB.instance.database;
    final List<Map<String, dynamic>> currentTablesList = await currentDb
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final currentTables =
        currentTablesList.map((e) => e['name'] as String).toSet();

    // Only validate that all required tables are in the new DB
    for (var table in currentTables) {
      if (!newTables.contains(table)) return false;
    }
    return true;
  }

  Future<void> replaceDatabaseSafely(File newDbFile) async {
    final isValid = await validateNewDbStructure(newDbFile);

    if (!isValid) {
      ZatcaAPI.errorMessage('❌ الملف غير متوافق مع قاعدة البيانات الحالية');
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}${slash}Database${slash}fatoora.db';

    // Close current db
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Replace file
    final existing = File(dbPath);
    if (await existing.exists()) {
      await existing.delete();
    }
    await newDbFile.copy(dbPath);

    // Reopen
    _database = await initDb('fatoora.db');

    ZatcaAPI.errorMessage('✅ تم استبدال قاعدة البيانات بنجاح');
  }

  Future<void> replaceDatabase(File newDbFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbFolder = Directory('${appDir.path}${slash}Database');
    final dbPath = '${dbFolder.path}${slash}fatoora.db';

    // Step 1: Close existing database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Step 2: Replace the file
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    // Step 3: Copy new file
    await newDbFile.copy(dbPath);

    // Step 4: Re-open the database
    _database = await initDb('fatoora.db');
  }

  /// Create tables
  void _createTables(Batch batch) {
    // Create settings table
    batch.execute('''
CREATE TABLE $tableSettings ( 
  ${SettingFields.id} $int,
  ${SettingFields.logo} $text,
  ${SettingFields.terms} $text,
  ${SettingFields.logoWidth} $intType,
  ${SettingFields.logoHeight} $intType
  )
''');

    // Create products table
    batch.execute('''
CREATE TABLE $tableProducts ( 
  ${ProductFields.id} $idType, 
  ${ProductFields.productName} $textType,
  ${ProductFields.price} $numType
  )
''');

    // Create customers table
    batch.execute('''
CREATE TABLE $tableCustomers ( 
  ${CustomerFields.id} $idType, 
  ${CustomerFields.name} $textType,
  ${CustomerFields.buildingNo} $text,
  ${CustomerFields.streetName} $text,
  ${CustomerFields.district} $text,
  ${CustomerFields.city} $text,
  ${CustomerFields.country} $text,
  ${CustomerFields.postalCode} $text,
  ${CustomerFields.additionalNo} $text,
  ${CustomerFields.vatNumber} $textType,
  ${CustomerFields.contactNumber} $text
  )
''');

    // Create invoices table
    batch.execute('''
CREATE TABLE $tableInvoices ( 
  ${InvoiceFields.id} $idType, 
  ${InvoiceFields.invoiceNo} $textType, 
  ${InvoiceFields.date} $textType,
  ${InvoiceFields.supplyDate} $text,
  ${InvoiceFields.sellerId} $intType,
  ${InvoiceFields.total} $numType,
  ${InvoiceFields.totalVat} $numType,
  ${InvoiceFields.posted} $boolType,
  ${InvoiceFields.payerId} $intType,
  ${InvoiceFields.noOfLines} $integerType,
  ${InvoiceFields.project} $text,
  ${InvoiceFields.paymentMethod} $text
  )
''');

    // Create purchases table
    batch.execute('''
CREATE TABLE $tablePurchases ( 
  ${PurchaseFields.id} $idType, 
  ${PurchaseFields.date} $textType,
  ${PurchaseFields.vendor} $textType,
  ${PurchaseFields.vendorVatNumber} $textType,
  ${PurchaseFields.total} $numType,
  ${PurchaseFields.totalVat} $numType
  )
''');

    // Create invoiceLines table
    batch.execute('''
CREATE TABLE $tableInvoiceLines ( 
  ${InvoiceLinesFields.id} $idType, 
  ${InvoiceLinesFields.recId} $integerType, 
  ${InvoiceLinesFields.productName} $textType,
  ${InvoiceLinesFields.price} $numType,
  ${InvoiceLinesFields.qty} $numType
  )
''');

    _updateToV3(batch);
    _updateToV4(batch);
    _updateToV5(batch);
    _updateToV6(batch);
    _updateToV7(batch);
    _updateToV9(batch);
    _updateToV10(batch);
    _updateToV11(batch);
    _updateToV12(batch);
    _updateToV13(batch);
  }

  void _updateToV3(Batch batch) {
    batch.execute('''
    CREATE TABLE $tableEstimates ( 
      ${EstimateFields.id} $idType, 
      ${EstimateFields.estimateNo} $textType, 
      ${EstimateFields.date} $textType,
      ${EstimateFields.supplyDate} $text,
      ${EstimateFields.sellerId} $intType,
      ${EstimateFields.total} $numType,
      ${EstimateFields.totalVat} $numType,
      ${EstimateFields.posted} $boolType,
      ${EstimateFields.payerId} $intType,
      ${EstimateFields.noOfLines} $integerType,
      ${EstimateFields.project} $text,
      ${EstimateFields.paymentMethod} $text
      )
    ''');
    batch.execute('''
    CREATE TABLE $tableEstimateLines ( 
      ${EstimateLinesFields.id} $idType, 
      ${EstimateLinesFields.recId} $integerType, 
      ${EstimateLinesFields.productName} $textType,
      ${EstimateLinesFields.price} $numType,
      ${EstimateLinesFields.qty} $numType
      )
    ''');
    batch.execute('''
    CREATE TABLE $tableReceipts ( 
      ${ReceiptFields.id} $idType, 
      ${ReceiptFields.date} $textType, 
      ${ReceiptFields.receivedFrom} $textType,
      ${ReceiptFields.sumOf} $textType,
      ${ReceiptFields.amount} $numType,
      ${ReceiptFields.amountFor} $textType,
      ${ReceiptFields.payType} $textType,
      ${ReceiptFields.chequeNo} $text,
      ${ReceiptFields.chequeDate} $text,
      ${ReceiptFields.transferNo} $text,
      ${ReceiptFields.transferDate} $text,
      ${ReceiptFields.bank} $text
      )
    ''');
  }

  void _updateToV4(Batch batch) {
    batch.execute('''
    CREATE TABLE TEMP ( 
      ${PurchaseFields.id} $idType, 
      ${PurchaseFields.date} $textType,
      ${PurchaseFields.vendor} $textType,
      ${PurchaseFields.vendorVatNumber} $textType,
      ${PurchaseFields.total} $numType,
      ${PurchaseFields.totalVat} $numType,
      ${PurchaseFields.details} $text
      )
    ''');
    batch.execute('''
    INSERT INTO TEMP ( 
      ${PurchaseFields.id}, 
      ${PurchaseFields.date},
      ${PurchaseFields.vendor},
      ${PurchaseFields.vendorVatNumber},
      ${PurchaseFields.total},  
      ${PurchaseFields.totalVat},
      ${PurchaseFields.details}
      ) SELECT 
      ${PurchaseFields.id}, 
      ${PurchaseFields.date},
      ${PurchaseFields.vendor},
      ${PurchaseFields.vendorVatNumber},
      ${PurchaseFields.total},
      ${PurchaseFields.totalVat},
      "" FROM $tablePurchases
    ''');
    batch.execute('''DROP TABLE $tablePurchases''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tablePurchases''');
  }

  void _updateToV5(Batch batch) {
    batch.execute('''
    CREATE TABLE $tablePo ( 
      ${PoFields.id} $idType, 
      ${PoFields.poNo} $textType, 
      ${PoFields.date} $textType,
      ${PoFields.supplyDate} $text,
      ${PoFields.sellerId} $intType,
      ${PoFields.total} $numType,
      ${PoFields.totalVat} $numType,
      ${PoFields.posted} $boolType,
      ${PoFields.payerId} $intType,
      ${PoFields.noOfLines} $integerType,
      ${PoFields.project} $text,
      ${PoFields.paymentMethod} $text
      )
    ''');
    batch.execute('''
    CREATE TABLE $tablePoLines ( 
      ${PoLinesFields.id} $idType, 
      ${PoLinesFields.recId} $integerType, 
      ${PoLinesFields.productName} $textType,
      ${PoLinesFields.price} $numType,
      ${PoLinesFields.qty} $numType
      )
    ''');
  }

  void _updateToV6(Batch batch) {
    batch.execute('''
    CREATE TABLE TEMP ( 
      ${PoFields.id} $idType, 
      ${PoFields.poNo} $textType, 
      ${PoFields.date} $textType,
      ${PoFields.supplyDate} $text,
      ${PoFields.sellerId} $intType,
      ${PoFields.total} $numType,
      ${PoFields.totalVat} $numType,
      ${PoFields.posted} $boolType,
      ${PoFields.payerId} $intType,
      ${PoFields.noOfLines} $integerType,
      ${PoFields.project} $text,
      ${PoFields.paymentMethod} $text,
      ${PoFields.notes} $text
      )
    ''');
    batch.execute('''
    INSERT INTO TEMP ( 
      ${PoFields.id}, 
      ${PoFields.poNo}, 
      ${PoFields.date},
      ${PoFields.supplyDate},
      ${PoFields.sellerId},
      ${PoFields.total},
      ${PoFields.totalVat},
      ${PoFields.posted},
      ${PoFields.payerId},
      ${PoFields.noOfLines},
      ${PoFields.project},
      ${PoFields.paymentMethod},
      ${PoFields.notes}
      ) SELECT 
      ${PoFields.id}, 
      ${PoFields.poNo}, 
      ${PoFields.date},
      ${PoFields.supplyDate},
      ${PoFields.sellerId},
      ${PoFields.total},
      ${PoFields.totalVat},
      ${PoFields.posted},
      ${PoFields.payerId},
      ${PoFields.noOfLines},
      ${PoFields.project},
      ${PoFields.paymentMethod},
      "-" FROM $tablePo
    ''');
    batch.execute('''DROP TABLE $tablePo''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tablePo''');
  }

  void _updateToV7(Batch batch) {
    String type = "قبض";

    /// Create table suppliers
    batch.execute('''
CREATE TABLE $tableSuppliers ( 
  ${SupplierFields.id} $idType, 
  ${SupplierFields.name} $textType,
  ${SupplierFields.buildingNo} $text,
  ${SupplierFields.streetName} $text,
  ${SupplierFields.district} $text,
  ${SupplierFields.city} $text,
  ${SupplierFields.country} $text,
  ${SupplierFields.postalCode} $text,
  ${SupplierFields.additionalNo} $text,
  ${SupplierFields.vatNumber} $textType,
  ${SupplierFields.contactNumber} $text
  )
''');

    /// Update table receipts by adding fields : payTo , receiptType
    batch.execute('''
    CREATE TABLE TEMP ( 
        ${ReceiptFields.id} $idType, 
        ${ReceiptFields.date} $textType, 
        ${ReceiptFields.receivedFrom} $textType,
        ${ReceiptFields.sumOf} $textType,
        ${ReceiptFields.amount} $numType,
        ${ReceiptFields.amountFor} $textType,
        ${ReceiptFields.payType} $textType,
        ${ReceiptFields.chequeNo} $text,
        ${ReceiptFields.chequeDate} $text,
        ${ReceiptFields.transferNo} $text,
        ${ReceiptFields.transferDate} $text,
        ${ReceiptFields.bank} $text,
        ${ReceiptFields.payTo} $text,
        ${ReceiptFields.receiptType} $text
      )
    ''');
    batch.execute('''
    INSERT INTO TEMP ( 
      ${ReceiptFields.id}, 
      ${ReceiptFields.date}, 
      ${ReceiptFields.receivedFrom}, 
      ${ReceiptFields.sumOf},
      ${ReceiptFields.amount},
      ${ReceiptFields.amountFor},
      ${ReceiptFields.payType},
      ${ReceiptFields.chequeNo},
      ${ReceiptFields.chequeDate},
      ${ReceiptFields.transferNo},
      ${ReceiptFields.transferDate},
      ${ReceiptFields.bank},
      ${ReceiptFields.payTo},
      ${ReceiptFields.receiptType}
      ) SELECT 
      ${ReceiptFields.id}, 
      ${ReceiptFields.date}, 
      ${ReceiptFields.receivedFrom},
      ${ReceiptFields.sumOf},
      ${ReceiptFields.amount},
      ${ReceiptFields.amountFor},
      ${ReceiptFields.payType},
      ${ReceiptFields.chequeNo},
      ${ReceiptFields.chequeDate},
      ${ReceiptFields.transferNo},
      ${ReceiptFields.transferDate},
      ${ReceiptFields.bank},
      "",
      "$type" FROM $tableReceipts
    ''');
    batch.execute('''DROP TABLE $tableReceipts''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tableReceipts''');
  }

  void _updateToV9(Batch batch) {
    batch.execute('''
    CREATE TABLE TEMP ( 
        ${InvoiceFields.id} $idType, 
        ${InvoiceFields.invoiceNo} $textType, 
        ${InvoiceFields.date} $textType,
        ${InvoiceFields.supplyDate} $text,
        ${InvoiceFields.sellerId} $intType,
        ${InvoiceFields.total} $numType,
        ${InvoiceFields.totalVat} $numType,
        ${InvoiceFields.posted} $boolType,
        ${InvoiceFields.payerId} $intType,
        ${InvoiceFields.noOfLines} $integerType,
        ${InvoiceFields.project} $text,
        ${InvoiceFields.paymentMethod} $text,
        ${InvoiceFields.icv} $intType,
        ${InvoiceFields.invoiceHash} $text,
        ${InvoiceFields.uuid} $text,
        ${InvoiceFields.qrCode} $text,
        ${InvoiceFields.statusCode} $text,
        ${InvoiceFields.status} $text,
        ${InvoiceFields.errorMessage} $text,
        ${InvoiceFields.warningMessage} $text,
        ${InvoiceFields.xml} $text,
        ${InvoiceFields.invoiceType} $text,
        ${InvoiceFields.invoiceKind} $text
        )
    ''');
    batch.execute('''
    INSERT INTO TEMP (
        ${InvoiceFields.id}, 
        ${InvoiceFields.invoiceNo}, 
        ${InvoiceFields.date},
        ${InvoiceFields.supplyDate},
        ${InvoiceFields.sellerId},
        ${InvoiceFields.total},
        ${InvoiceFields.totalVat},
        ${InvoiceFields.posted},
        ${InvoiceFields.payerId},
        ${InvoiceFields.noOfLines},
        ${InvoiceFields.project},
        ${InvoiceFields.paymentMethod},
        ${InvoiceFields.icv},
        ${InvoiceFields.invoiceHash},
        ${InvoiceFields.uuid},
        ${InvoiceFields.qrCode},
        ${InvoiceFields.statusCode},
        ${InvoiceFields.status},
        ${InvoiceFields.errorMessage},
        ${InvoiceFields.warningMessage},
        ${InvoiceFields.xml},
        ${InvoiceFields.invoiceType},
        ${InvoiceFields.invoiceKind} 
      ) SELECT
        ${InvoiceFields.id}, 
        ${InvoiceFields.invoiceNo}, 
        ${InvoiceFields.date},
        ${InvoiceFields.supplyDate},
        ${InvoiceFields.sellerId},
        ${InvoiceFields.total},
        ${InvoiceFields.totalVat},
        ${InvoiceFields.posted},
        ${InvoiceFields.payerId},
        ${InvoiceFields.noOfLines},
        ${InvoiceFields.project},
        ${InvoiceFields.paymentMethod},
        0,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "", 
        "simplified", 
        "invoice" 
      FROM $tableInvoices
    ''');
    batch.execute('''DROP TABLE $tableInvoices''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tableInvoices''');
  }

  void _updateToV10(Batch batch) {
    batch.execute('''
    CREATE TABLE TEMP ( 
        ${InvoiceFields.id} $idType, 
        ${InvoiceFields.invoiceNo} $textType, 
        ${InvoiceFields.date} $textType,
        ${InvoiceFields.supplyDate} $text,
        ${InvoiceFields.sellerId} $intType,
        ${InvoiceFields.total} $numType,
        ${InvoiceFields.totalVat} $numType,
        ${InvoiceFields.posted} $boolType,
        ${InvoiceFields.payerId} $intType,
        ${InvoiceFields.noOfLines} $integerType,
        ${InvoiceFields.project} $text,
        ${InvoiceFields.paymentMethod} $text,
        ${InvoiceFields.icv} $intType,
        ${InvoiceFields.invoiceHash} $text,
        ${InvoiceFields.uuid} $text,
        ${InvoiceFields.qrCode} $text,
        ${InvoiceFields.statusCode} $text,
        ${InvoiceFields.status} $text,
        ${InvoiceFields.errorMessage} $text,
        ${InvoiceFields.warningMessage} $text,
        ${InvoiceFields.xml} $text,
        ${InvoiceFields.invoiceType} $text,
        ${InvoiceFields.invoiceKind} $text,
        ${InvoiceFields.isCredit} $boolType,
        ${InvoiceFields.lastCreditAmount} $num
        )
    ''');
    batch.execute('''
    INSERT INTO TEMP (
        ${InvoiceFields.id}, 
        ${InvoiceFields.invoiceNo}, 
        ${InvoiceFields.date},
        ${InvoiceFields.supplyDate},
        ${InvoiceFields.sellerId},
        ${InvoiceFields.total},
        ${InvoiceFields.totalVat},
        ${InvoiceFields.posted},
        ${InvoiceFields.payerId},
        ${InvoiceFields.noOfLines},
        ${InvoiceFields.project},
        ${InvoiceFields.paymentMethod},
        ${InvoiceFields.icv},
        ${InvoiceFields.invoiceHash},
        ${InvoiceFields.uuid},
        ${InvoiceFields.qrCode},
        ${InvoiceFields.statusCode},
        ${InvoiceFields.status},
        ${InvoiceFields.errorMessage},
        ${InvoiceFields.warningMessage},
        ${InvoiceFields.xml},
        ${InvoiceFields.invoiceType},
        ${InvoiceFields.invoiceKind},
        ${InvoiceFields.isCredit},
        ${InvoiceFields.lastCreditAmount}
      ) SELECT
        ${InvoiceFields.id}, 
        ${InvoiceFields.invoiceNo}, 
        ${InvoiceFields.date},
        ${InvoiceFields.supplyDate},
        ${InvoiceFields.sellerId},
        ${InvoiceFields.total},
        ${InvoiceFields.totalVat},
        ${InvoiceFields.posted},
        ${InvoiceFields.payerId},
        ${InvoiceFields.noOfLines},
        ${InvoiceFields.project},
        ${InvoiceFields.paymentMethod},
        0,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "", 
        "simplified", 
        "invoice",
        0,
        0.0
      FROM $tableInvoices
    ''');
    batch.execute('''DROP TABLE $tableInvoices''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tableInvoices''');
  }

  void _updateToV11(Batch batch) {
    batch.execute('''
    CREATE TABLE TEMP ( 
        ${EstimateFields.id} $idType, 
        ${EstimateFields.estimateNo} $textType, 
        ${EstimateFields.date} $textType,
        ${EstimateFields.supplyDate} $text,
        ${EstimateFields.sellerId} $intType,
        ${EstimateFields.total} $numType,
        ${EstimateFields.totalVat} $numType,
        ${EstimateFields.posted} $boolType,
        ${EstimateFields.payerId} $intType,
        ${EstimateFields.noOfLines} $integerType,
        ${EstimateFields.project} $text,
        ${EstimateFields.notes} $text,
        ${EstimateFields.paymentMethod} $text
        )
    ''');
    batch.execute('''
    INSERT INTO TEMP (
        ${EstimateFields.id}, 
        ${EstimateFields.estimateNo}, 
        ${EstimateFields.date},
        ${EstimateFields.supplyDate},
        ${EstimateFields.sellerId},
        ${EstimateFields.total},
        ${EstimateFields.totalVat},
        ${EstimateFields.posted},
        ${EstimateFields.payerId},
        ${EstimateFields.noOfLines},
        ${EstimateFields.project},
        ${EstimateFields.notes},
        ${EstimateFields.paymentMethod}
      ) SELECT
        ${EstimateFields.id}, 
        ${EstimateFields.estimateNo}, 
        ${EstimateFields.date},
        ${EstimateFields.supplyDate},
        ${EstimateFields.sellerId},
        ${EstimateFields.total},
        ${EstimateFields.totalVat},
        ${EstimateFields.posted},
        ${EstimateFields.payerId},
        ${EstimateFields.noOfLines},
        ${EstimateFields.project},
        "",
        ${EstimateFields.paymentMethod}
      FROM $tableEstimates
    ''');
    batch.execute('''DROP TABLE $tableEstimates''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tableEstimates''');
  }

  void _updateToV12(Batch batch) {
    /// Update table receipts by adding fields : payerId
    batch.execute('''
    CREATE TABLE TEMP ( 
        ${ReceiptFields.id} $idType, 
        ${ReceiptFields.date} $textType, 
        ${ReceiptFields.receivedFrom} $textType,
        ${ReceiptFields.sumOf} $textType,
        ${ReceiptFields.amount} $numType,
        ${ReceiptFields.amountFor} $textType,
        ${ReceiptFields.payType} $textType,
        ${ReceiptFields.chequeNo} $text,
        ${ReceiptFields.chequeDate} $text,
        ${ReceiptFields.transferNo} $text,
        ${ReceiptFields.transferDate} $text,
        ${ReceiptFields.bank} $text,
        ${ReceiptFields.payTo} $text,
        ${ReceiptFields.receiptType} $text,
        ${ReceiptFields.payerId} $intType
      )
    ''');
    batch.execute('''
    INSERT INTO TEMP ( 
      ${ReceiptFields.id}, 
      ${ReceiptFields.date}, 
      ${ReceiptFields.receivedFrom}, 
      ${ReceiptFields.sumOf},
      ${ReceiptFields.amount},
      ${ReceiptFields.amountFor},
      ${ReceiptFields.payType},
      ${ReceiptFields.chequeNo},
      ${ReceiptFields.chequeDate},
      ${ReceiptFields.transferNo},
      ${ReceiptFields.transferDate},
      ${ReceiptFields.bank},
      ${ReceiptFields.payTo},
      ${ReceiptFields.receiptType},
      ${ReceiptFields.payerId}
      ) SELECT 
      ${ReceiptFields.id}, 
      ${ReceiptFields.date}, 
      ${ReceiptFields.receivedFrom},
      ${ReceiptFields.sumOf},
      ${ReceiptFields.amount},
      ${ReceiptFields.amountFor},
      ${ReceiptFields.payType},
      ${ReceiptFields.chequeNo},
      ${ReceiptFields.chequeDate},
      ${ReceiptFields.transferNo},
      ${ReceiptFields.transferDate},
      ${ReceiptFields.bank},
      ${ReceiptFields.payTo},
      ${ReceiptFields.receiptType},
      0 FROM $tableReceipts
    ''');
    batch.execute('''DROP TABLE $tableReceipts''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tableReceipts''');

    /// Update table purchases by adding fields : paymentMethod
    batch.execute('''
    CREATE TABLE TEMP ( 
      ${PurchaseFields.id} $idType, 
      ${PurchaseFields.date} $textType,
      ${PurchaseFields.vendor} $textType,
      ${PurchaseFields.vendorVatNumber} $textType,
      ${PurchaseFields.total} $numType,
      ${PurchaseFields.totalVat} $numType,
      ${PurchaseFields.details} $text,
      ${PurchaseFields.paymentMethod} $text
      )
    ''');
    batch.execute('''
    INSERT INTO TEMP ( 
      ${PurchaseFields.id}, 
      ${PurchaseFields.date},
      ${PurchaseFields.vendor},
      ${PurchaseFields.vendorVatNumber},
      ${PurchaseFields.total},  
      ${PurchaseFields.totalVat},
      ${PurchaseFields.details},
      ${PurchaseFields.paymentMethod}
      ) SELECT 
      ${PurchaseFields.id}, 
      ${PurchaseFields.date},
      ${PurchaseFields.vendor},
      ${PurchaseFields.vendorVatNumber},
      ${PurchaseFields.total},
      ${PurchaseFields.totalVat},
      ${PurchaseFields.details},
      "حوالة" FROM $tablePurchases
    ''');
    batch.execute('''DROP TABLE $tablePurchases''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tablePurchases''');

    /// Adding new tables: contract, clauses and clauses_lines
    batch.execute('''
    CREATE TABLE $tableContracts ( 
      ${ContractFields.id} $idType, 
      ${ContractFields.contractNo} $textType, 
      ${ContractFields.date} $textType,
      ${ContractFields.firstParty} $textType,
      ${ContractFields.secondParty} $textType,
      ${ContractFields.total} $numType,
      ${ContractFields.title} $textType
      )
    ''');
    batch.execute('''
    CREATE TABLE $tableClauses ( 
      ${ClausesFields.id} $idType, 
      ${ClausesFields.contractId} $integerType, 
      ${ClausesFields.clauseName} $textType,

    FOREIGN KEY (${ClausesFields.contractId})
      REFERENCES $tableContracts(${ContractFields.id})
      ON DELETE CASCADE
      )
    ''');
    batch.execute('''
    CREATE TABLE $tableClausesLines ( 
      ${ClausesLinesFields.id} $idType, 
      ${ClausesLinesFields.clauseId} $integerType, 
      ${ClausesLinesFields.description} $textType,

    FOREIGN KEY (${ClausesLinesFields.clauseId})
      REFERENCES $tableClauses(${ClausesFields.id})
      ON DELETE CASCADE
      )
    ''');
  }

  void _updateToV13(Batch batch) {
    /// add cols environment, dev_authorization, sim_authorization,
    /// core_authorization to table receipts
    batch.execute('''
    CREATE TABLE TEMP ( 
        ${SettingFields.id} $idType, 
        ${SettingFields.logo} $textType, 
        ${SettingFields.terms} $textType,
        ${SettingFields.logoWidth} $integerType,
        ${SettingFields.logoHeight} $integerType,
        ${SettingFields.environment} $textType,
        ${SettingFields.devAuthorization} $textType,
        ${SettingFields.simAuthorization} $textType,
        ${SettingFields.coreAuthorization} $textType
      )
    ''');
    batch.execute('''
    INSERT INTO TEMP ( 
      ${SettingFields.id}, 
      ${SettingFields.logo}, 
      ${SettingFields.terms}, 
      ${SettingFields.logoWidth},
      ${SettingFields.logoHeight},
      ${SettingFields.environment},
      ${SettingFields.devAuthorization},
      ${SettingFields.simAuthorization},
      ${SettingFields.coreAuthorization}
      ) SELECT 
      ${SettingFields.id}, 
      ${SettingFields.logo}, 
      ${SettingFields.terms},
      ${SettingFields.logoWidth},
      ${SettingFields.logoHeight},
      "",
      "",
      "",
      "" FROM $tableSettings
    ''');
    batch.execute('''DROP TABLE $tableSettings''');
    batch.execute('''ALTER TABLE TEMP RENAME TO $tableSettings''');
  }

  Future<List<Map<String, dynamic>>> getCustomerStatement(
      int payerId, String dateFrom, String dateTo) async {
    final db = await instance.database;

    final invoices = await db.rawQuery(
      """
      SELECT 
        ${InvoiceFields.date} AS date,
          'فاتورة رقم ' || ${InvoiceFields.invoiceNo} || ' ' || ${InvoiceFields.paymentMethod} AS description,
    
        CASE 
          WHEN ${InvoiceFields.paymentMethod} = 'آجل'
          THEN 0.0
          ELSE ${InvoiceFields.total}
        END AS credit,
    
        CASE 
          WHEN ${InvoiceFields.paymentMethod} = 'آجل'
          THEN ${InvoiceFields.total}
          ELSE ${InvoiceFields.total}
        END AS debit
    
      FROM $tableInvoices
      WHERE ${InvoiceFields.payerId} = ?
        AND ${InvoiceFields.date} >= ?
        AND ${InvoiceFields.date} <= ?
      """,
      [payerId, dateFrom, "$dateTo 23:59"],
    );

    // Fetch Receipts as Credits
    final receipts = await db.rawQuery(
        "SELECT ${ReceiptFields.date} as date, "
        "${ReceiptFields.amountFor} || ' سند رقم ' || ${ReceiptFields.id} || ' الدفع ' || ${ReceiptFields.payType} AS description, "
        "0.0 as debit, ${ReceiptFields.amount} as credit "
        "FROM $tableReceipts "
        "WHERE ${ReceiptFields.payerId} = ? AND ${ReceiptFields.date} >= ? AND ${ReceiptFields.date} <= ?",
        [payerId, dateFrom, "$dateTo 23:59"]);

    // Combine and Sort
    List<Map<String, dynamic>> combined = List.from(invoices)..addAll(receipts);
    combined.sort((a, b) => a['date'].compareTo(b['date']));

    // Calculate Running Balance
    double balance = 0;
    return combined.map((item) {
      double debit = (item['debit'] as num).toDouble();
      double credit = (item['credit'] as num).toDouble();
      balance += (debit - credit);
      return {
        ...item,
        'balance': balance,
      };
    }).toList();
  }

  /// Table settings CRUD operations
  Future<Setting> createSetting(Setting setting) async {
    final db = await instance.database;
    final id = await db.insert(tableSettings, setting.toJson());

    if (id > 0) {
      return setting.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<int?> databaseVersion() async {
    int? result = await _database?.getVersion();
    return result;
  }

  Future<List<Setting>> getAllSettings() async {
    final db = await instance.database;

    const orderBy = '${SettingFields.id} ASC';
    final result = await db.query(tableSettings, orderBy: orderBy);

    return result.map((json) => Setting.fromJson(json)).toList();
  }

  Future<int> updateSetting(Setting setting) async {
    final db = await instance.database;

    return db.update(
      tableSettings,
      setting.toJson(),
      // where: '${SettingFields.id} = ?',
      // whereArgs: [1],
    );
  }

  /// End table settings CRUD operations

  /// Table products CRUD operations
  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert(tableProducts, product.toJson());

    if (id > 0) {
      return product.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<int?> getProductsCount() async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableProducts'));
    return count;
  }

  Future<Product> getProductById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableProducts,
      columns: ProductFields.getProductsFields(),
      where: '${ProductFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;

    const orderBy = '${ProductFields.id} DESC';
    final result = await db.query(tableProducts, orderBy: orderBy);

    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;

    return db.update(
      tableProducts,
      product.toJson(),
      where: '${ProductFields.id} = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(Product product) async {
    final db = await instance.database;

    return await db.delete(
      tableProducts,
      where: '${ProductFields.id} = ?',
      whereArgs: [product.id],
    );
  }

  Future<int?> deleteProductSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'products'"));
    return count;
  }

  /// End table products CRUD operations

  /// Table customers CRUD operations
  Future<Customer> createCustomer(Customer customer) async {
    final db = await instance.database;
    final id = await db.insert(tableCustomers, customer.toJson());

    if (id > 0) {
      return customer.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<int?> getCustomerCount() async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableCustomers'));
    return count;
  }

  Future<int?> getSupplierCount() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableSuppliers'));
    return count;
  }

  Future<String?> getSupplierVatNumberById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableSuppliers,
      columns: SupplierFields.getSupplierFields(),
      where: '${SupplierFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Customer.fromJson(maps.first).vatNumber;
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<bool?> isFirstCustomerExist() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT * FROM $tableCustomers WHERE id=1'));

    return count != null ? true : false;
  }

  Future<bool?> isFirstSupplierExist() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT * FROM $tableSuppliers WHERE id=1'));

    return count != null ? true : false;
  }

  Future<Customer> getCustomerById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableCustomers,
      columns: CustomerFields.getCustomerFields(),
      where: '${CustomerFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Customer.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<Supplier> getSupplierById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableSuppliers,
      columns: SupplierFields.getSupplierFields(),
      where: '${SupplierFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Supplier.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<Customer> getCustomerByName(String name) async {
    final db = await instance.database;

    final maps = await db.query(
      tableCustomers,
      columns: CustomerFields.getCustomerFields(),
      where: '${CustomerFields.name} = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      return Customer.fromJson(maps.first);
    } else {
      throw Exception('Customer $name not found');
    }
  }

  Future<bool> customerExist(String name) async {
    final db = await instance.database;
    bool result = false;

    final maps = await db.query(
      tableCustomers,
      columns: CustomerFields.getCustomerFields(),
      where: '${CustomerFields.name} = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      result = true;
    }
    return result;
  }

  Future<bool> supplierExist(String name) async {
    final db = await instance.database;
    bool result = false;

    final maps = await db.query(
      tableSuppliers,
      columns: SupplierFields.getSupplierFields(),
      where: '${SupplierFields.name} = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      result = true;
    }
    return result;
  }

  Future<bool> productExist(String name) async {
    final db = await instance.database;
    bool result = false;

    final maps = await db.query(
      tableProducts,
      columns: ProductFields.getProductsFields(),
      where: '${ProductFields.productName} = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      result = true;
    }
    return result;
  }

  Future<String> getCustomerNameById(int id) async {
    Customer customer = await getCustomerById(id);
    return customer.name;
  }

  Future<int?> getCustomerIdByName(String name) async {
    Customer customer = await getCustomerByName(name);
    return customer.id;
  }

  Future<String> getCustomerVatNumberById(int id) async {
    Customer customer = await getCustomerById(id);
    return customer.vatNumber;
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;

    const orderBy = '${CustomerFields.id} DESC';
    final result = await db.query(tableCustomers, orderBy: orderBy);

    return result.map((json) => Customer.fromJson(json)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;

    return db.update(
      tableCustomers,
      customer.toJson(),
      where: '${CustomerFields.id} = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(Customer customer) async {
    final db = await instance.database;

    return await db.delete(
      tableCustomers,
      where: '${CustomerFields.id} = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int?> deleteCustomerSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'customers'"));
    return count;
  }

  /// End table customers CRUD operations

  /// Table suppliers CRUD operations
  Future<Supplier> createSupplier(Supplier supplier) async {
    final db = await instance.database;
    final id = await db.insert(tableSuppliers, supplier.toJson());

    if (id > 0) {
      return supplier.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<Supplier> getSupplierByName(String name) async {
    final db = await instance.database;

    final maps = await db.query(
      tableSuppliers,
      columns: SupplierFields.getSupplierFields(),
      where: '${SupplierFields.name} = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      return Supplier.fromJson(maps.first);
    } else {
      throw Exception('Supplier $name not found');
    }
  }

  Future<int?> getSupplierIdByVatNumber(String vat) async {
    final db = await instance.database;

    final maps = await db.query(
      tableSuppliers,
      columns: SupplierFields.getSupplierFields(),
      where: '${SupplierFields.vatNumber} = ?',
      whereArgs: [vat],
    );

    if (maps.isNotEmpty) {
      return Supplier.fromJson(maps.first).id;
    } else {
      throw Exception('Supplier $vat not found');
    }
  }

  Future<String> getSupplierNameById(int id) async {
    Supplier supplier = await getSupplierById(id);
    return supplier.name;
  }

  Future<int?> getSupplierIdByName(String name) async {
    Supplier supplier = await getSupplierByName(name);
    return supplier.id;
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await instance.database;

    const orderBy = '${SupplierFields.id} DESC';
    final result = await db.query(tableSuppliers, orderBy: orderBy);

    return result.map((json) => Supplier.fromJson(json)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await instance.database;

    return db.update(
      tableSuppliers,
      supplier.toJson(),
      where: '${SupplierFields.id} = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(Supplier supplier) async {
    final db = await instance.database;

    return await db.delete(
      tableSuppliers,
      where: '${SupplierFields.id} = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int?> deleteSupplierSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'suppliers'"));
    return count;
  }

  /// End table suppliers CRUD operations

  /// Table Invoices CRUD operations
  Future<Invoice> createInvoice(Invoice invoice) async {
    final db = await instance.database;
    final id = await db.insert(tableInvoices, invoice.toJson());

    if (id > 0) {
      return invoice.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<Po> createPo(Po po) async {
    final db = await instance.database;
    final id = await db.insert(tablePo, po.toJson());

    if (id > 0) {
      return po.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<Estimate> createEstimate(Estimate estimate) async {
    final db = await instance.database;
    final id = await db.insert(tableEstimates, estimate.toJson());

    if (id > 0) {
      return estimate.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<Receipt> createReceipt(Receipt receipt) async {
    final db = await instance.database;
    final id = await db.insert(tableReceipts, receipt.toJson());

    if (id > 0) {
      return receipt.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<Contract> createContract(Contract contract) async {
    final db = await instance.database;
    final id = await db.insert(tableContracts, contract.toJson());

    if (id > 0) {
      return contract.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<int?> getInvoicesCount() async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableInvoices'));
    return count;
  }

  Future<int?> getInvoicesCountInYear(int year) async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-01-01' AND ${InvoiceFields.date} <= '${year + 1}-01-01'"));
    return count;
  }

  Future<int?> getEstimatesCount() async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableEstimates'));
    return count;
  }

  Future<int?> getPoCount() async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tablePo'));
    return count;
  }

  Future<int?> getReceiptsCount() async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableReceipts'));
    return count;
  }

  Future<int?> getContractsCount() async {
    //database connection
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableContracts'));
    return count;
  }

  Future<int?> getNewInvoiceId() async {
    Database db = await database;
    // int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT id FROM $tableInvoices ORDER BY id DESC limit 1'));
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT seq FROM sqlite_sequence where name= '$tableInvoices'"));
    return count;
  }

  Future<int?> getNewEstimateId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT seq FROM sqlite_sequence where name= '$tableEstimates'"));
    return count;
  }

  Future<int?> getNewCustomerId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT seq FROM sqlite_sequence where name= '$tableCustomers'"));
    return count;
  }

  Future<int?> getNewSupplierId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT seq FROM sqlite_sequence where name= '$tableSuppliers'"));
    return count;
  }

  Future<int?> getNewProductId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT seq FROM sqlite_sequence where name= '$tableProducts'"));
    return count;
  }

  Future<int?> getNewPoId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("SELECT seq FROM sqlite_sequence where name= '$tablePo'"));
    return count;
  }

  Future<int?> getNewReceiptId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT seq FROM sqlite_sequence where name= '$tableReceipts'"));
    return count;
  }

  Future<int?> getNewContractId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT seq FROM sqlite_sequence where name= '$tableContracts'"));
    return count;
  }

  Future<int?> deleteAllInvoices() async {
    Database db = await database;
    int? count =
        Sqflite.firstIntValue(await db.rawQuery('DELETE FROM $tableInvoices'));
    return count;
  }

  Future<int?> deleteAllInvoiceLines() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('DELETE FROM $tableInvoiceLines'));
    return count;
  }

  Future<int?> deleteInvoiceSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'invoices'"));
    return count;
  }

  Future<int?> deleteInvoiceLinesSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'invoice_lines'"));
    return count;
  }

  Future<int?> deletePoLinesSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'po_lines'"));
    return count;
  }

  Future<int?> deleteEstimateLinesSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'estimate_lines'"));
    return count;
  }

  Future<num?> getTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery("SELECT "
        "SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "         WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "         ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-01-01' "
        "AND ${InvoiceFields.date} < '${year + 1}-01-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");

    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getJanTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-01-01' AND ${InvoiceFields.date} < '$year-02-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getFebTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-02-01' AND ${InvoiceFields.date} < '$year-03-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getMarTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-03-01' AND ${InvoiceFields.date} < '$year-04-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getAprTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-04-01' AND ${InvoiceFields.date} < '$year-05-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getMayTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-05-01' AND ${InvoiceFields.date} < '$year-06-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getJunTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-06-01' AND ${InvoiceFields.date} < '$year-07-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getJulTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-07-01' AND ${InvoiceFields.date} < '$year-08-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getAugTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-08-01' AND ${InvoiceFields.date} < '$year-09-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getSepTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-09-01' AND ${InvoiceFields.date} < '$year-10-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getOctTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-10-01' AND ${InvoiceFields.date} < '$year-11-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getNovTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-11-01' AND ${InvoiceFields.date} < '$year-12-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getDecTotalSales(int year) async {
    Database db = await database;
    var sum = await db.rawQuery(
        "SELECT SUM(CASE WHEN ${InvoiceFields.invoiceKind} = 'invoice' THEN ${InvoiceFields.total} "
        "               WHEN ${InvoiceFields.invoiceKind} = 'credit' THEN -${InvoiceFields.total} "
        "               ELSE 0 END) AS ttl "
        "FROM $tableInvoices "
        "WHERE ${InvoiceFields.date} >= '$year-12-01' AND ${InvoiceFields.date} < '${year + 1}-01-01' "
        "AND (${InvoiceFields.statusCode} = 'CLEARED' OR ${InvoiceFields.statusCode} = 'REPORTED')");
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getTotalCreditNotes() async {
    Database db = await database;
    var sum = (await db.rawQuery(
        'SELECT SUM(${InvoiceFields.total}) AS ttl FROM $tableInvoices WHERE ${InvoiceFields.total} < 0'));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<Invoice> getInvoiceById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableInvoices,
      columns: InvoiceFields.getInvoiceFields(),
      where: '${InvoiceFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Invoice.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<Estimate> getEstimateById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableEstimates,
      columns: EstimateFields.getEstimateFields(),
      where: '${EstimateFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Estimate.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<Po> getPoById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tablePo,
      columns: PoFields.getPoFields(),
      where: '${PoFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Po.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<Receipt> getReceiptById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableReceipts,
      columns: ReceiptFields.getReceiptFields(),
      where: '${ReceiptFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Receipt.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;

    const orderBy = '${InvoiceFields.id} DESC';

    List<Map<String, dynamic>> result;

    if (Utils.showAllData == 1) {
      // Get all invoices
      result = await db.query(
        tableInvoices,
        orderBy: orderBy,
      );
    } else {
      // Get invoices for current year only
      final int currentYear = DateTime.now().year;
      final String yearStart = '$currentYear-01-01';
      final String yearEnd = '$currentYear-12-31 23:59';

      result = await db.query(
        tableInvoices,
        where: "${InvoiceFields.date} >= ? AND ${InvoiceFields.date} <= ?",
        whereArgs: [yearStart, yearEnd],
        orderBy: orderBy,
      );
    }

    return result.map((json) => Invoice.fromJson(json)).toList();
  }

  Future<int?> getLastICV() async {
    final db = await instance.database;
    List<Invoice> invoices;
    final result = await db.rawQuery(
        "SELECT * FROM $tableInvoices WHERE ${InvoiceFields.statusCode} = 'REPORTED' OR ${InvoiceFields.statusCode} = 'CLEARED' ORDER BY ${InvoiceFields.icv} DESC");
    invoices = result.map((json) => Invoice.fromJson(json)).toList();
    return invoices.isEmpty ? 0 : invoices.first.icv;
  }

  Future<String?> getLastInvoiceHash() async {
    final db = await instance.database;
    List<Invoice> invoices;
    final result = await db.rawQuery(
        "SELECT * FROM $tableInvoices WHERE ${InvoiceFields.statusCode} = 'REPORTED' OR ${InvoiceFields.statusCode} = 'CLEARED' ORDER BY ${InvoiceFields.icv} DESC");
    invoices = result.map((json) => Invoice.fromJson(json)).toList();
    return invoices.isEmpty
        ? "NWZlY2ViNjZmZmM4NmYzOGQ5NTI3ODZjNmQ2OTZjNzljMmRiYzIzOWRkNGU5MWI0NjcyOWQ3M2EyN2ZiNTdlOQ=="
        : invoices.first.invoiceHash;
  }

  Future<List<Clauses>> getClausesByContractId(int contractId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        "SELECT * FROM $tableClauses WHERE ${ClausesFields.contractId} = $contractId");
    return result.map((json) => Clauses.fromJson(json)).toList();
  }

  Future<List<ClausesLines>> getLinesByClauseId(int clauseId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        "SELECT * FROM $tableClausesLines WHERE ${ClausesLinesFields.clauseId} = $clauseId");
    return result.map((json) => ClausesLines.fromJson(json)).toList();
  }

  Future<List<Invoice>> getAllInvoicesBetweenTwoDates(
      String dateFrom, String dateTo) async {
    final db = await instance.database;

    final result = await db.rawQuery(
        "SELECT * FROM $tableInvoices WHERE ${InvoiceFields.date} >= '$dateFrom' AND ${InvoiceFields.date} <= '$dateTo 23:59'");

    return result.map((json) => Invoice.fromJson(json)).toList();
  }

  Future<List<Purchase>> getAllPurchasesBetweenTwoDates(
      String dateFrom, String dateTo) async {
    final db = await instance.database;

    final result = await db.rawQuery(
        "SELECT * FROM $tablePurchases WHERE ${PurchaseFields.date} >= '$dateFrom' AND ${PurchaseFields.date} <= '$dateTo 23:59'");

    return result.map((json) => Purchase.fromJson(json)).toList();
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await instance.database;

    return db.update(
      tableInvoices,
      invoice.toJson(),
      where: '${InvoiceFields.id} = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<int> updateEstimate(Estimate estimate) async {
    final db = await instance.database;

    return db.update(
      tableEstimates,
      estimate.toJson(),
      where: '${EstimateFields.id} = ?',
      whereArgs: [estimate.id],
    );
  }

  Future<int> updatePo(Po po) async {
    final db = await instance.database;

    return db.update(
      tablePo,
      po.toJson(),
      where: '${PoFields.id} = ?',
      whereArgs: [po.id],
    );
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await instance.database;

    return db.update(
      tableReceipts,
      receipt.toJson(),
      where: '${ReceiptFields.id} = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> updateContract(Contract contract) async {
    final db = await instance.database;

    return db.update(
      tableContracts,
      contract.toJson(),
      where: '${ContractFields.id} = ?',
      whereArgs: [contract.id],
    );
  }

  Future<int> deleteInvoice(Invoice invoice) async {
    final db = await instance.database;

    await deleteInvoiceLines(invoice.id!);

    return await db.delete(
      tableInvoices,
      where: '${InvoiceFields.id} = ?',
      whereArgs: [invoice.id],
    );
  }

  /// End table invoices CRUD operations

  /// Table Purchases CRUD operations
  Future<Purchase> createPurchase(Purchase purchase) async {
    final db = await instance.database;
    final id = await db.insert(tablePurchases, purchase.toJson());

    if (id > 0) {
      return purchase.copy(id: id);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<int?> getPurchasesCount() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tablePurchases'));
    return count;
  }

  Future<int?> getPurchasesCountInYear(int year) async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM $tablePurchases "
        "WHERE ${PurchaseFields.date} >= '$year-01-01' AND ${PurchaseFields.date} <= '${year + 1}-01-01'"));
    return count;
  }

  Future<int?> getNewPurchaseId() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery('SELECT id FROM $tablePurchases ORDER BY id DESC limit 1'));
    return count;
  }

  Future<int?> deleteAllPurchases() async {
    Database db = await database;
    int? count =
        Sqflite.firstIntValue(await db.rawQuery('DELETE FROM $tablePurchases'));
    return count;
  }

  Future<int?> deletePurchaseSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'purchases'"));
    return count;
  }

  Future<int?> deleteEstimateSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'estimates'"));
    return count;
  }

  Future<int?> deletePoSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(
        await db.rawQuery("DELETE FROM sqlite_sequence where name= 'po'"));
    return count;
  }

  Future<int?> deleteReceiptSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'receipts'"));
    return count;
  }

  Future<int?> deleteContractSequence() async {
    Database db = await database;
    int? count = Sqflite.firstIntValue(await db
        .rawQuery("DELETE FROM sqlite_sequence where name= 'contracts'"));
    return count;
  }

  Future<num?> getTotalExpenses(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${ReceiptFields.amount}) AS ttl FROM $tableReceipts  "
        "WHERE ${ReceiptFields.date} >= '$year-01-01' AND ${ReceiptFields.date} <= '${year + 1}-01-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-01-01' AND ${PurchaseFields.date} <= '${year + 1}-01-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getTotalEstimates(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${EstimateFields.total}) AS ttl FROM $tableEstimates  "
        "WHERE ${EstimateFields.date} >= '$year-01-01' AND ${EstimateFields.date} <= '${year + 1}-01-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getTotalPo(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PoFields.total}) AS ttl FROM $tablePo  "
        "WHERE ${PoFields.date} >= '$year-01-01' AND ${PoFields.date} <= '${year + 1}-01-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getTotalReceipts(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${ReceiptFields.amount}) AS ttl FROM $tableReceipts  "
        "WHERE ${ReceiptFields.date} >= '$year-01-01' AND ${ReceiptFields.date} <= '${year + 1}-01-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getJanTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases "
        "WHERE ${PurchaseFields.date} >= '$year-01-01' AND ${PurchaseFields.date} <= '$year-02-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getFebTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-02-01' AND ${PurchaseFields.date} <= '$year-03-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getMarTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-03-01' AND ${PurchaseFields.date} <= '$year-04-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getAprTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-04-01' AND ${PurchaseFields.date} <= '$year-05-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getMayTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-05-01' AND ${PurchaseFields.date} <= '$year-06-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getJunTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-06-01' AND ${PurchaseFields.date} <= '$year-07-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getJulTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-07-01' AND ${PurchaseFields.date} <= '$year-08-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getAugTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-08-01' AND ${PurchaseFields.date} <= '$year-09-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getSepTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-09-01' AND ${PurchaseFields.date} <= '$year-10-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getOctTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-10-01' AND ${PurchaseFields.date} <= '$year-11-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getNovTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-11-01' AND ${PurchaseFields.date} <= '$year-12-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<num?> getDecTotalPurchases(int year) async {
    Database db = await database;
    var sum = (await db.rawQuery(
        "SELECT SUM(${PurchaseFields.total}) AS ttl FROM $tablePurchases  "
        "WHERE ${PurchaseFields.date} >= '$year-12-01' AND ${PurchaseFields.date} <= '${year + 1}-01-01'"));
    return sum[0]['ttl'] == null ? 0 : num.parse('${sum[0]['ttl']}');
  }

  Future<Purchase> getPurchaseById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tablePurchases,
      columns: PurchaseFields.getPurchaseFields(),
      where: '${PurchaseFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Purchase.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found in the local database');
    }
  }

  Future<List<Purchase>> getAllPurchases() async {
    final db = await instance.database;

    const orderBy = '${PurchaseFields.id} DESC';

    List<Map<String, dynamic>> result;

    if (Utils.showAllData == 1) {
      // Get all data
      result = await db.query(
        tablePurchases,
        orderBy: orderBy,
      );
    } else {
      // Get data for current year only
      final int currentYear = DateTime.now().year;
      final String yearStart = '$currentYear-01-01';
      final String yearEnd = '$currentYear-12-31 23:59';

      result = await db.query(
        tablePurchases,
        where: "${PurchaseFields.date} >= ? AND ${PurchaseFields.date} <= ?",
        whereArgs: [yearStart, yearEnd],
        orderBy: orderBy,
      );
    }

    return result.map((json) => Purchase.fromJson(json)).toList();
  }

  Future<List<Estimate>> getAllEstimates() async {
    final db = await instance.database;

    const orderBy = '${EstimateFields.id} DESC';

    List<Map<String, dynamic>> result;

    if (Utils.showAllData == 1) {
      // Get all data
      result = await db.query(
        tableEstimates,
        orderBy: orderBy,
      );
    } else {
      // Get data for current year only
      final int currentYear = DateTime.now().year;
      final String yearStart = '$currentYear-01-01';
      final String yearEnd = '$currentYear-12-31 23:59';

      result = await db.query(
        tableEstimates,
        where: "${EstimateFields.date} >= ? AND ${EstimateFields.date} <= ?",
        whereArgs: [yearStart, yearEnd],
        orderBy: orderBy,
      );
    }

    return result.map((json) => Estimate.fromJson(json)).toList();
  }

  Future<List<Po>> getAllPo() async {
    final db = await instance.database;

    const orderBy = '${PoFields.id} DESC';

    List<Map<String, dynamic>> result;

    if (Utils.showAllData == 1) {
      // Get all data
      result = await db.query(
        tablePo,
        orderBy: orderBy,
      );
    } else {
      // Get data for current year only
      final int currentYear = DateTime.now().year;
      final String yearStart = '$currentYear-01-01';
      final String yearEnd = '$currentYear-12-31 23:59';

      result = await db.query(
        tablePo,
        where: "${PoFields.date} >= ? AND ${PoFields.date} <= ?",
        whereArgs: [yearStart, yearEnd],
        orderBy: orderBy,
      );
    }

    return result.map((json) => Po.fromJson(json)).toList();
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await instance.database;

    const orderBy = '${ReceiptFields.id} DESC';

    List<Map<String, dynamic>> result;

    if (Utils.showAllData == 1) {
      // Get all data
      result = await db.query(
        tableReceipts,
        orderBy: orderBy,
      );
    } else {
      // Get data for current year only
      final int currentYear = DateTime.now().year;
      final String yearStart = '$currentYear-01-01';
      final String yearEnd = '$currentYear-12-31 23:59';

      result = await db.query(
        tableReceipts,
        where: "${ReceiptFields.date} >= ? AND ${ReceiptFields.date} <= ?",
        whereArgs: [yearStart, yearEnd],
        orderBy: orderBy,
      );
    }

    return result.map((json) => Receipt.fromJson(json)).toList();
  }

  Future<List<Contract>> getAllContracts() async {
    final db = await instance.database;

    const orderBy = '${ContractFields.id} DESC';

    List<Map<String, dynamic>> result;

    if (Utils.showAllData == 1) {
      // Get all data
      result = await db.query(
        tableContracts,
        orderBy: orderBy,
      );
    } else {
      // Get data for current year only
      final int currentYear = DateTime.now().year;
      final String yearStart = '$currentYear-01-01';
      final String yearEnd = '$currentYear-12-31 23:59';

      result = await db.query(
        tableContracts,
        where: "${ContractFields.date} >= ? AND ${ContractFields.date} <= ?",
        whereArgs: [yearStart, yearEnd],
        orderBy: orderBy,
      );
    }

    return result.map((json) => Contract.fromJson(json)).toList();
  }

  Future<int> updatePurchase(Purchase invoice) async {
    final db = await instance.database;

    return db.update(
      tablePurchases,
      invoice.toJson(),
      where: '${PurchaseFields.id} = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<int> deletePurchaseById(int id) async {
    final db = await instance.database;

    return await db.delete(
      tablePurchases,
      where: '${PurchaseFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEstimateById(int id) async {
    final db = await instance.database;
    await deleteEstimateLines(id);
    return await db.delete(
      tableEstimates,
      where: '${EstimateFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePoById(int id) async {
    final db = await instance.database;
    await deletePoLines(id);
    return await db.delete(
      tablePo,
      where: '${PoFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReceiptById(int id) async {
    final db = await instance.database;

    return await db.delete(
      tableReceipts,
      where: '${ReceiptFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteContractById(int id) async {
    final db = await instance.database;

    return await db.delete(
      tableContracts,
      where: '${ContractFields.id} = ?',
      whereArgs: [id],
    );
  }

  /// End table invoices CRUD operations

  /// Table InvoiceLines CRUD operations
  Future<InvoiceLines> createInvoiceLines(
      InvoiceLines invoiceLines, int recId) async {
    final db = await instance.database;
    final id = await db.insert(tableInvoiceLines, invoiceLines.toJson());

    if (id > 0) {
      return invoiceLines.copy(id: id, recId: recId);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<EstimateLines> createEstimateLines(
      EstimateLines estimateLines, int recId) async {
    final db = await instance.database;
    final id = await db.insert(tableEstimateLines, estimateLines.toJson());

    if (id > 0) {
      return estimateLines.copy(id: id, recId: recId);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<PoLines> createPoLines(PoLines poLines, int recId) async {
    final db = await instance.database;
    final id = await db.insert(tablePoLines, poLines.toJson());

    if (id > 0) {
      return poLines.copy(id: id, recId: recId);
    } else {
      throw Exception('Record NOT created');
    }
  }

  Future<List<InvoiceLines>> getInvoiceLinesById(int recId) async {
    final db = await instance.database;

    final maps = await db.query(
      tableInvoiceLines,
      columns: InvoiceLinesFields.getInvoiceLinesFields(),
      where: '${InvoiceLinesFields.recId} = ?',
      orderBy: InvoiceLinesFields.id,
      whereArgs: [recId],
    );

    if (maps.isNotEmpty) {
      return maps.map((json) => InvoiceLines.fromJson(json)).toList();
    } else {
      throw Exception('المسلسل $recId متكرر قم بحذف هذا المسلسل');
    }
  }

  Future<List<EstimateLines>> getEstimateLinesById(int recId) async {
    final db = await instance.database;

    final maps = await db.query(
      tableEstimateLines,
      columns: EstimateLinesFields.getEstimateLinesFields(),
      where: '${EstimateLinesFields.recId} = ?',
      orderBy: EstimateLinesFields.id,
      whereArgs: [recId],
    );

    if (maps.isNotEmpty) {
      return maps.map((json) => EstimateLines.fromJson(json)).toList();
    } else {
      throw Exception('ID $recId not found in the local database');
    }
  }

  Future<List<PoLines>> getPoLinesById(int recId) async {
    final db = await instance.database;

    final maps = await db.query(
      tablePoLines,
      columns: PoLinesFields.getPoLinesFields(),
      where: '${PoLinesFields.recId} = ?',
      orderBy: PoLinesFields.id,
      whereArgs: [recId],
    );

    if (maps.isNotEmpty) {
      return maps.map((json) => PoLines.fromJson(json)).toList();
    } else {
      throw Exception('ID $recId not found in the local database');
    }
  }

  Future<List<InvoiceLines>> getAllInvoiceLines() async {
    final db = await instance.database;

    const orderBy = '${InvoiceLinesFields.recId}, ${InvoiceLinesFields.id} ASC';
    final result = await db.query(tableInvoiceLines, orderBy: orderBy);

    return result.map((json) => InvoiceLines.fromJson(json)).toList();
  }

  Future<int> updateInvoiceLines(InvoiceLines invoiceLines) async {
    final db = await instance.database;

    return db.update(
      tableInvoiceLines,
      invoiceLines.toJson(),
      where: '${InvoiceLinesFields.id} = ?',
      whereArgs: [invoiceLines.id],
    );
  }

  Future<int> updateEstimateLines(EstimateLines estimateLines) async {
    final db = await instance.database;

    return db.update(
      tableInvoiceLines,
      estimateLines.toJson(),
      where: '${EstimateLinesFields.id} = ?',
      whereArgs: [estimateLines.id],
    );
  }

  Future<int> updatePoLines(PoLines poLines) async {
    final db = await instance.database;

    return db.update(
      tableInvoiceLines,
      poLines.toJson(),
      where: '${PoLinesFields.id} = ?',
      whereArgs: [poLines.id],
    );
  }

  Future deleteInvoiceLines(int recId) async {
    final db = await instance.database;

    return await db
        .rawQuery('DELETE FROM $tableInvoiceLines WHERE recId=$recId');
  }

  Future deleteEstimateLines(int recId) async {
    final db = await instance.database;

    return await db
        .rawQuery('DELETE FROM $tableEstimateLines WHERE recId=$recId');
  }

  Future deletePoLines(int recId) async {
    final db = await instance.database;

    return await db.rawQuery('DELETE FROM $tablePoLines WHERE recId=$recId');
  }

  /// End table invoiceLines CRUD operations

  Future<String> get version async {
    int? result = await _database?.getVersion();
    String ver = '$result';
    return ver;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
