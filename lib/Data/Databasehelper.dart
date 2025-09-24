import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'package:intl/intl.dart';
import 'package:kskfinance/Utilities/Reports/Custrans/pdf_generator2.dart';

class DatabaseHelper {
  /*static Future<void> getDatabasePath() async {
    // Request manage external storage permission
    PermissionStatus manageExternalStorageStatus =
        await Permission.manageExternalStorage.request();

    if (!manageExternalStorageStatus.isGranted) {
      // Handle the case where manageExternalStorage permission is not granted
      throw Exception('Manage external storage permission not granted');
    }

    // If manageExternalStorage permission is granted, request storage permission
    PermissionStatus storageStatus = await Permission.storage.request();

    if (!storageStatus.isGranted) {
      // Handle the case where storage permission is not granted
      throw Exception('Storage permission not granted');
    }

    /*String customDirPath = '/storage/emulated/0/digivas/database/';
    final directory = Directory(customDirPath);

    // Create the directory if it doesn't exist
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Set the path to your database file
    final dbPath = customDirPath;
    print('Path to DB: $dbPath');
    return dbPath;*/
  }*/

  static Future<List<int>> getLenIdsByLineName(String lineName) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: ['LenId'],
      where: 'LineName = ?',
      whereArgs: [lineName],
    );

    return result.map((row) => row['LenId'] as int).toList();
  }

  static Future<String?> getPartyNameByLenId(int lenId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: ['PartyName'],
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    if (result.isNotEmpty) {
      return result.first['PartyName'] as String?;
    } else {
      return null;
    }
  }

  static Future<int?> getLenId(String lineName, String partyName) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: ['LenId'],
      where: 'LineName = ? AND PartyName = ?',
      whereArgs: [lineName, partyName],
    );

    if (result.isNotEmpty) {
      return result.first['LenId'] as int?;
    } else {
      return null;
    }
  }

  static Future<String?> getStatus(int lenId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: ['status'],
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    if (result.isNotEmpty) {
      return result.first['status'] as String?;
    } else {
      return null;
    }
  }

  static Future<sql.Database> getDatabase() async {
    // Get the database path
    final dbPath = await sql.getDatabasesPath();

    //final dbPath1 = await getDatabasePath();

    // Open the database
    final db = await sql.openDatabase(
      path.join(dbPath, 'finance3.db'),
      version: 1,
      onCreate: (db, version) async {
        var batch = db.batch();

        // Create LineTable
        batch.execute('''
  CREATE TABLE Line (
    Linename TEXT PRIMARY KEY,
    Amtgiven REAL,
    Profit REAL,
    expense REAL,
    Amtrecieved REAL
  )
''');

        // Create LendingTable
        await db.execute('''
      CREATE TABLE Lending (
           LenId INTEGER,
           LineName TEXT NOT NULL,
          PartyName TEXT NOT NULL,
          PartyAdd Text,
          PartyPhnone Text,
          sms bool,
          amtgiven REAL NOT NULL,
          profit REAL,
           amtcollected REAL,
          Lentdate date,
    duedays INTEGER,
    
   
    status TEXT,
    PRIMARY KEY (LineName, PartyName)  
  )
''');

        // Create CollectionTable
        await db.execute('''
  CREATE TABLE Collection (
    cid INTEGER PRIMARY KEY,
    LenId INTEGER NOT NULL,
    Date date NOT NULL,
    CrAmt REAL,
    DrAmt REAL
   
  )
''');

        await batch.commit();
      },
    );
    return db;
  }

  static Future<void> dropDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    //final dbPath = await getDatabasePath();
    final pathToDb = path.join(dbPath, 'finance3.db');
    await sql.deleteDatabase(pathToDb);
  }
}

//LINE OPERATIONS

class dbline {
  static Future<void> deleteLine(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    await db.delete(
      'Line',
      where: 'Linename = ?',
      whereArgs: [lineName],
    );
  }

  static Future<void> updateLineNameInLending({
    required String oldLineName,
    required String newLineName,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    await db.update(
      'Lending',
      {'LineName': newLineName},
      where: 'LineName = ?',
      whereArgs: [oldLineName],
    );
  }

  static Future<Map<String, dynamic>> getLineDetails(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Line',
      where: 'Linename = ?',
      whereArgs: [lineName],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      throw Exception('No data found for LineName: $lineName');
    }
  }

  static Future<double> fetchAmtRecieved(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Line',
      columns: ['Amtrecieved', 'Amtgiven', 'Profit'],
      where: 'Linename = ?',
      whereArgs: [lineName],
    );

    if (result.isNotEmpty) {
      return (result.first['Amtrecieved'] ?? 0.0) as double;
    } else {
      throw Exception('No data found for LineName: $lineName');
    }
  }

  static Future<Map<String, double>> allLineDetails() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        SUM(Amtgiven) as totalAmtGiven, 
        SUM(Profit) as totalProfit, 
        SUM(Amtrecieved) as totalAmtRecieved,
        sum(expense) as totalexpense 
      FROM Line
    ''');

    if (result.isNotEmpty) {
      return {
        'totalAmtGiven': result.first['totalAmtGiven'] as double? ?? 0.0,
        'totalProfit': result.first['totalProfit'] as double? ?? 0.0,
        'totalAmtRecieved': result.first['totalAmtRecieved'] as double? ?? 0.0,
        'totalexpense': result.first['totalexpense'] as double? ?? 0.0,
      };
    } else {
      return {
        'totalAmtGiven': 0.0,
        'totalProfit': 0.0,
        'totalAmtRecieved': 0.0,
        'totalexpense': 0.0,
      };
    }
  }

  static Future<void> updateLine({
    required String lineName,
    required Map<String, dynamic> updatedValues,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    // Update the existing entry
    await db.update(
      'Line',
      updatedValues,
      where: 'LOWER(Linename) = ?',
      whereArgs: [lineName.toLowerCase()],
    );
  }

  static Future<void> updateLineAmounts({
    required String lineName,
    required double amtGiven,
    required double profit,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    // Update the existing entry
    await db.update(
      'Line',
      {
        'Amtgiven': amtGiven,
        'Profit': profit,
      },
      where: 'LOWER(Linename) = ?',
      whereArgs: [lineName.toLowerCase()],
    );
  }

  static Future<void> insertLine(String lineName) async {
    final db = await DatabaseHelper.getDatabase();

    // Check if the entry already exists (case-insensitive)
    final List<Map<String, dynamic>> existingEntries = await db.query(
      'Line',
      where: 'LOWER(Linename) = ?',
      whereArgs: [lineName.toLowerCase()],
    );

    if (existingEntries.isNotEmpty) {
      // Entry already exists
      throw Exception('Cannot insert: Line name already exists.');
    } else {
      // Insert the new entry
      await db.insert(
        'Line',
        {
          'Linename': lineName,
          'Amtgiven': 0.0,
          'Profit': 0.0,
          'expense': 0.0,
          'Amtrecieved': 0.0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<List<String>> getLineNames() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> maps =
        await db.query('Line', columns: ['Linename']);

    return List.generate(maps.length, (i) {
      return maps[i]['Linename'] as String;
    });
  }
}

class dbLending {
  static Future<List<Map<String, dynamic>>> getActiveParties() async {
    final db = await DatabaseHelper.getDatabase();
    return await db.query(
      'Lending',
      columns: [
        'PartyName',
        'amtgiven',
        'profit',
        'amtcollected',
        'duedays',
        'PartyPhnone',
        'status',
        'lentdate'
      ],
      where: 'status = ?',
      whereArgs: ['active'],
    );
  }

  static Future<List<Map<String, dynamic>>>
      getActiveLendingSummaryWithCollections() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> lendings = await db.query(
      'Lending',
      columns: [
        'LenId',
        'PartyName',
        'amtgiven',
        'profit',
        'amtcollected',
        'Lentdate',
        'duedays',
      ],
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'PartyName ASC',
    );

    List<Map<String, dynamic>> summaryList = [];
    for (final l in lendings) {
      final lenId = l['LenId'];
      final partyName = l['PartyName'] ?? '';
      final amtGiven = (l['amtgiven'] ?? 0.0) as double;
      final profit = (l['profit'] ?? 0.0) as double;
      final amtCollected = (l['amtcollected'] ?? 0.0) as double;
      final totalGiven = amtGiven + profit;
      final lentDate = l['Lentdate'] ?? '';
      final dueDays = l['duedays'] ?? 0;
      String dueDate = '';
      if (lentDate != null && lentDate != '' && dueDays != null) {
        try {
          final dt = DateFormat('yyyy-MM-dd').parse(lentDate);
          dueDate =
              DateFormat('dd-MM-yyyy').format(dt.add(Duration(days: dueDays)));
        } catch (_) {}
      }

      // Fetch collection entries for this LenId after or equal to Lentdate, sorted by date
      List<Map<String, dynamic>> collections = [];
      if (lentDate != null && lentDate != '') {
        collections = await db.query(
          'Collection',
          where: 'LenId = ? AND Date > ?',
          whereArgs: [lenId, lentDate],
          orderBy: 'Date ASC',
        );
      }

      summaryList.add({
        'LenId': lenId,
        'PartyName': partyName,
        'TotalGiven': totalGiven,
        'AmtCollected': amtCollected,
        'LentDate': lentDate,
        'DueDate': dueDate,
        'DueDays': dueDays,
        'Collections': collections, // List of collection entries for this LenId
      });
    }
    return summaryList;
  }

  static Future<Map<String, dynamic>> getLendingDetails(int lenId) async {
    final db = await DatabaseHelper.getDatabase();

    // Query to fetch the required details
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: [
        'amtgiven',
        'profit',
        'amtcollected',
        'duedays'
      ], // Select required columns
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    if (result.isNotEmpty) {
      final double amtGiven = result.first['amtgiven'] as double? ?? 0.0;
      final double profit = result.first['profit'] as double? ?? 0.0;
      final double amtCollected =
          result.first['amtcollected'] as double? ?? 0.0;
      final int dueDays = result.first['duedays'] as int? ?? 0;

      return {
        'totalAmtGivenWithProfit': amtGiven + profit, // amtGiven + profit
        'amtCollected': amtCollected, // amtcollected
        'dueDays': dueDays, // duedays
      };
    } else {
      return {
        'totalAmtGivenWithProfit': 0.0,
        'amtCollected': 0.0,
        'dueDays': 0,
      };
    }
  }

  static Future<List<Map<String, dynamic>>?> getLendingDetailsByLineName(
      String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: [
        'LenId',
        'PartyName',
        'amtgiven',
        'sms',
        'profit',
        'amtcollected',
        'duedays',
        'status',
        'PartyPhnone'
      ],
      where: 'LineName = ? AND status = ?',
      whereArgs: [lineName, 'active'],
    );

    if (result.isNotEmpty) {
      return result;
    } else {
      return null;
    }
  }

  static Future<List<PdfEntry>> fetchLendingEntries() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query('Lending');

    return result.map((entry) {
      return PdfEntry(
        lineName: entry['LineName'],
        partyName: entry['PartyName'],
        amtGiven: entry['amtgiven'],
        profit: entry['profit'],
        amtCollected: entry['amtcollected'],
        balanceAmt:
            (entry['amtgiven'] + entry['profit']) - entry['amtcollected'],
      );
    }).toList();
  }

  static Future<String?> getStatusByLenId(int lenId) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: ['status'],
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    if (result.isNotEmpty) {
      return result.first['status'] as String?;
    }
    return null;
  }

  static Future<Map<String, double>> getPartyDetailss(
      String lineName, String partyName) async {
    final db = await DatabaseHelper.getDatabase();
    final result = await db.rawQuery('''
    SELECT 
      amtgiven, 
      profit, 
      amtcollected
    FROM Lending
    WHERE LineName = ? AND PartyName = ?
  ''', [lineName, partyName]);

    if (result.isNotEmpty) {
      return {
        'amtgiven': result.first['amtgiven'] as double? ?? 0.0,
        'profit': result.first['profit'] as double? ?? 0.0,
        'amtcollected': result.first['amtcollected'] as double? ?? 0.0,
      };
    } else {
      return {
        'amtgiven': 0.0,
        'profit': 0.0,
        'amtcollected': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> getPartyDetforUpdate(
      String lineName, String partyName) async {
    final db = await DatabaseHelper.getDatabase();
    final result = await db.rawQuery('''
    SELECT 
      LenId, 
      PartyName,
      PartyPhnone,
      PartyAdd,
      sms
    FROM Lending
    WHERE LineName = ? AND PartyName = ?
  ''', [lineName, partyName]);

    if (result.isNotEmpty) {
      return {
        'LenId': result.first['LenId'] as int? ?? 0,
        'PartyName': result.first['PartyName'] as String? ?? '',
        'PartyPhnone': result.first['PartyPhnone'] as String? ?? '',
        'PartyAdd': result.first['PartyAdd'] as String? ?? '',
        'sms': result.first['sms'] as int? ?? 0,
      };
    } else {
      return {
        'LenId': 0,
        'PartyName': '',
        'PartyPhnone': '',
        'PartyAdd': '',
        'sms': 0,
      };
    }
  }

  static Future<List<int>> getLenIdsByLineName(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: ['LenId'],
      where: 'LineName = ?',
      whereArgs: [lineName],
    );

    return result.map((row) => row['LenId'] as int).toList();
  }

  static Future<void> deleteLendingByLineName(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    await db.delete(
      'Lending',
      where: 'LineName = ?',
      whereArgs: [lineName],
    );
  }

  static Future<void> deleteLendingAndCollections(
      int lenId, String linename) async {
    final db = await DatabaseHelper.getDatabase();

    // Delete all entries from the Collection table for the given lenId
    await db.delete(
      'Collection',
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    // get the amtgiven and profit and amtcollected for the given lenId
    final lendingData = await fetchLendingData(lenId);
    final amtgiven = lendingData['amtgiven'];
    final profit = lendingData['profit'];
    final amtcollected = lendingData['amtcollected'];

    await db.delete(
      'Lending',
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    //get the amtgiven ,profit and amtrecieved for the given line table for line name
    final lineData = await db.query(
      'Line',
      columns: ['Amtgiven', 'Profit', 'Amtrecieved'],
      where: 'Linename = ?',
      whereArgs: [linename],
    );

    if (lineData.isNotEmpty) {
      double lineamtgiven = lineData.first['Amtgiven'] as double? ?? 0.0;
      double lineprofit = lineData.first['Profit'] as double? ?? 0.0;
      double lineamtrecieved = lineData.first['Amtrecieved'] as double? ?? 0.0;

      lineamtgiven -= amtgiven;
      lineprofit -= profit;
      lineamtrecieved -= amtcollected;

      await db.update(
        'Line',
        {
          'Amtgiven': lineamtgiven,
          'Profit': lineprofit,
          'Amtrecieved': lineamtrecieved,
        },
        where: 'Linename = ?',
        whereArgs: [linename],
      );
    } else {
      throw Exception('No data found for Linename: $linename');
    }

    //update the line table with the new values
  }

  static Future<void> updatePartyDetails({
    required String lineName,
    required String partyName,
    required int lenId,
    required Map<String, dynamic> updatedValues,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    await db.update(
      'Lending',
      updatedValues,
      where: 'LenId = ?',
      whereArgs: [lenId],
    );
  }

  static Future<Map<String, dynamic>?> getPartyDetails(int lenId) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  static Future<void> updateAmtCollectedAndGiven({
    required String lineName,
    required String partyName,
    required int lenId,
    required Map<String, dynamic> updatedValues,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    // Fetch current values

    await db.update(
      'Lending',
      updatedValues,
      where: 'LenId = ?',
      whereArgs: [lenId],
    );
  }

  static Future<Map<String, dynamic>> fetchLendingData(int lenId) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: [
        ' amtgiven',
        'profit',
        'amtcollected',
        'PartyPhnone',
        'sms',
        'Lentdate',
        'duedays',
        'status'
      ],
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      throw Exception('No data found for LenId: $lenId');
    }
  }

  static Future<void> updateLendingAmounts({
    required int lenId,
    required double newAmtCollected,
    required String status,
  }) async {
    try {
      final db = await DatabaseHelper.getDatabase();
      final updatedValues = {'amtcollected': newAmtCollected, 'status': status};

      await db.update(
        'Lending',
        updatedValues,
        where: 'LenId = ?',
        whereArgs: [lenId],
      );
      print('Update successful');
    } catch (e) {
      print('Error updating Lending table: ${e.toString()}');
    }
  }

  static Future<Map<String, double>> getLineSums(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final result = await db.rawQuery('''
    SELECT 
      SUM(Amtgiven) as totalAmtGiven, 
      SUM(Profit) as totalProfit, 
      SUM(Amtrecieved) as totalAmtCollected,
      SUM(expense) as totalexpense
    FROM Line
    WHERE Linename = ?
  ''', [lineName]);

    if (result.isNotEmpty) {
      return {
        'totalAmtGiven': result.first['totalAmtGiven'] as double? ?? 0.0,
        'totalProfit': result.first['totalProfit'] as double? ?? 0.0,
        'totalAmtCollected':
            result.first['totalAmtCollected'] as double? ?? 0.0,
        'totalexpense': result.first['totalexpense'] as double? ?? 0.0,
      };
    } else {
      return {
        'totalAmtGiven': 0.0,
        'totalProfit': 0.0,
        'totalAmtCollected': 0.0,
        'totalexpense': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> getPartySums(int Lenid) async {
    final db = await DatabaseHelper.getDatabase();
    final result = await db.rawQuery('''
      SELECT 
        SUM(amtgiven) as totalAmtGiven, 
        SUM(profit) as totalProfit, 
        SUM(amtcollected) as totalAmtCollected,
        Lentdate as lentdate,
        duedays as duedays,
        status as status
      
      FROM Lending
      WHERE LenId = ?
    ''', [Lenid]);

    if (result.isNotEmpty) {
      return {
        'totalAmtGiven': result.first['totalAmtGiven'] as double? ?? 0.0,
        'totalProfit': result.first['totalProfit'] as double? ?? 0.0,
        'totalAmtCollected':
            result.first['totalAmtCollected'] as double? ?? 0.0,
        'lentdate': result.first['lentdate'] as String? ?? '',
        'duedays': result.first['duedays'] as int? ?? 0,
        'status': result.first['status'] as String? ?? 'passive',
      };
    } else {
      return {
        'totalAmtGiven': 0.0,
        'totalProfit': 0.0,
        'totalAmtCollected': 0.0,
        'lentdate': 'N/A',
        'duedays': 0,
        'status': 'passive',
      };
    }
  }

  static Future<List<String>> getPartyNames(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'Lending',
      columns: ['PartyName'],
      where: 'LineName = ?',
      whereArgs: [lineName],
    );

    return List.generate(maps.length, (i) {
      return maps[i]['PartyName'] as String;
    });
  }

  static Future<void> insertParty({
    required String lineName,
    required String partyName,
    required String partyPhoneNumber,
    required String address,
    required int lenId,
    required bool sms, // Add this parameter
  }) async {
    final db = await DatabaseHelper.getDatabase();

    // Check if the entry already exists
    final List<Map<String, dynamic>> existingEntries = await db.query(
      'Lending',
      where: 'LineName = ? AND PartyName = ?',
      whereArgs: [lineName, partyName],
    );

    if (existingEntries.isNotEmpty) {
      // Entry already exists
      throw Exception('Cannot insert: Party already exists for this line.');
    }

    // Check if the LenId already exists
    final List<Map<String, dynamic>> existingLenIdEntries = await db.query(
      'Lending',
      where: 'LenId = ?',
      whereArgs: [lenId],
    );

    if (existingLenIdEntries.isNotEmpty) {
      // LenId already exists
      throw Exception('Cannot insert: LenId already exists.');
    }

    // Insert the new entry
    await db.insert(
      'Lending',
      {
        'LenId': lenId,
        'LineName': lineName,
        'PartyName': partyName,
        'PartyAdd': address,
        'PartyPhnone': partyPhoneNumber,
        'amtgiven': 0.0,
        'profit': 0.0,
        'amtcollected': 0.0,
        'Lentdate': null,
        'duedays': 0,
        'status': 'passive',
        'sms': sms ? 1 : 0, // Store as integer (1 for true, 0 for false)
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateDueAmt({
    required int lenId,
    required Map<String, dynamic> updatedValues,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    // Update the entry
    await db.update(
      'Lending',
      updatedValues,
      where: 'LenId = ?',
      whereArgs: [lenId],
    );
  }

  static Future<void> updateLending({
    required String lineName,
    required String partyName,
    required int lenId,
    required Map<String, dynamic> updatedValues,
    int? cid,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    // Update the entry
    await db.update(
      'Lending',
      updatedValues,
      where: 'LineName = ? AND PartyName = ?',
      whereArgs: [lineName, partyName],
    );

    final lentDate = updatedValues['Lentdate'];
    final total = updatedValues['amtgiven'] + updatedValues['profit'];
    await db.insert(
      'Collection',
      {
        'cid': cid,
        'LenId': lenId,
        'Date': lentDate,
        'CrAmt': total,
        'DrAmt': 0.0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateLending2({
    required String lineName,
    required String partyName,
    required int lenId,
    required Map<String, dynamic> updatedValues,
    int? cid,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    // Update the entry
    await db.update(
      'Lending',
      updatedValues,
      where: 'LineName = ? AND PartyName = ?',
      whereArgs: [lineName, partyName],
    );
  }

  // New function to get unique addresses for a specific line name
  static Future<List<String>> getUniqueAddressesByLineName(
      String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: ['PartyAdd'],
      where: 'LineName = ? AND status = ?',
      whereArgs: [lineName, 'active'],
      distinct: true,
    );

    // Filter out null, empty, and 'unknown' addresses
    List<String> addresses = [];
    for (var row in result) {
      String address = row['PartyAdd']?.toString().trim() ?? '';
      if (address.isNotEmpty &&
          address.toLowerCase() != 'unknown' &&
          address.toLowerCase() != 'null') {
        addresses.add(address);
      }
    }

    // Remove duplicates and sort
    return addresses.toSet().toList()..sort();
  }

  // New function to get lending details with addresses for address-based filtering
  static Future<List<Map<String, dynamic>>?>
      getLendingDetailsWithAddressByLineName(String lineName) async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'Lending',
      columns: [
        'LenId',
        'PartyName',
        'PartyAdd',
        'amtgiven',
        'sms',
        'profit',
        'amtcollected',
        'duedays',
        'status',
        'PartyPhnone'
      ],
      where: 'LineName = ? AND status = ?',
      whereArgs: [lineName, 'active'],
    );

    if (result.isNotEmpty) {
      return result;
    } else {
      return null;
    }
  }
}

class CollectionDB {
  static Future<List<Map<String, dynamic>>> getEntriesForCustomerBetweenDates(
      int lenId, DateTime startDate, DateTime endDate) async {
    final Database db = await DatabaseHelper.getDatabase();

    final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
    // Query to fetch entries for the specific customer within the date range
    final List<Map<String, dynamic>> result = await db.query('Collection',
        where: 'LenId = ? AND Date BETWEEN ? AND ?',
        whereArgs: [lenId, startDateStr, endDateStr],
        orderBy: 'Date ASC');

    return result;

    /*final List<Map<String, dynamic>> result = await db.query(
      'Transactions', // Replace with your table name
      where: 'LenId = ? AND Date BETWEEN ? AND ?',
      whereArgs: [lenId, startDate, endDate],
      orderBy: 'Date ASC', // Sort by date in ascending order
    );

    return result;*/
  }

  static Future<List<Map<String, dynamic>>> getCollectionSumByDate({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await DatabaseHelper.getDatabase();
    // Assuming your date is stored as 'yyyy-MM-dd' or similar
    return await db.rawQuery('''
    SELECT Date, SUM(CrAmt) as totalCrAmt, SUM(DrAmt) as totalDrAmt
    FROM Collection
    WHERE Date BETWEEN ? AND ?
    GROUP BY Date
    ORDER BY Date ASC
  ''', [fromDate, toDate]);
  }

  static Future<int> getLenIdForCid(int cid) async {
    final db = await DatabaseHelper.getDatabase();
    final result = await db.query(
      'Collection',
      columns: ['LenId'], // Replace with your actual column name
      where: 'cid = ?',
      whereArgs: [cid],
    );

    if (result.isNotEmpty) {
      return result.first['LenId'] as int;
    } else {
      throw Exception('LenId not found for cid: $cid');
    }
  }

  static Future<Map<String, double>> getCollectionAndGivenByDate(
      String date) async {
    final db = await DatabaseHelper.getDatabase();

    // Query the database for the given date
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT 
      SUM(CASE WHEN DrAmt IS NOT NULL THEN DrAmt ELSE 0 END) AS totalDrAmt,
      SUM(CASE WHEN CrAmt IS NOT NULL THEN CrAmt ELSE 0 END) AS totalCrAmt
    FROM Collection
    WHERE Date = ?
  ''', [date]);

    if (result.isNotEmpty) {
      return {
        'totalDrAmt': result[0]['totalDrAmt'] ?? 0.0,
        'totalCrAmt': result[0]['totalCrAmt'] ?? 0.0,
      };
    } else {
      return {'totalDrAmt': 0.0, 'totalCrAmt': 0.0};
    }
  }

  static Future<void> deleteEntriesByLenId(int lenId) async {
    final db = await DatabaseHelper.getDatabase();
    await db.delete(
      'Collection',
      where: 'LenId = ?',
      whereArgs: [lenId],
    );
  }

  static Future<void> deleteEntry(int cid) async {
    final db = await DatabaseHelper.getDatabase();
    await db.delete(
      'Collection',
      where: 'cid = ?',
      whereArgs: [cid],
    );
  }

  static Future<void> updateCollection({
    required int cid,
    required int lenId,
    required String date,
    required double crAmt,
    required double drAmt,
  }) async {
    final db = await DatabaseHelper.getDatabase();
    await db.update(
      'Collection',
      {
        'LenId': lenId,
        'Date': date,
        'CrAmt': crAmt,
        'DrAmt': drAmt,
      },
      where: 'cid = ?',
      whereArgs: [cid],
    );
  }

  static Future<List<Map<String, dynamic>>> getEntriesBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final db = await DatabaseHelper.getDatabase();

    // Format the DateTime objects as dd-MM-yyyy strings
    final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // Query the database
    final List<Map<String, dynamic>> result = await db.query(
      'Collection',
      where: 'Date >= ? AND Date <= ?',
      whereArgs: [startDateStr, endDateStr],
    );

    return result;
  }

  static Future<void> insertCollection({
    required int cid,
    required int lenId,
    required String date,
    required double crAmt,
    required double drAmt,
  }) async {
    final db = await DatabaseHelper.getDatabase();

    await db.insert(
      'Collection',
      {
        'LenId': lenId,
        'Date': date,
        'CrAmt': crAmt,
        'DrAmt': drAmt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getCollectionEntries(
      int lenId) async {
    final db = await DatabaseHelper.getDatabase();
    return await db.query(
      'Collection',
      where: 'LenId = ?',
      whereArgs: [lenId],
      orderBy: 'Date Desc',
    );
  }
}
