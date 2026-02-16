import 'package:chicken_dilivery/Model/ItemModel.dart';
import 'package:chicken_dilivery/Model/RootModel.dart';
import 'package:chicken_dilivery/Model/ShopModel.dart';
import 'package:chicken_dilivery/Model/StockModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chicken_delivery.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = kIsWeb ? filePath : join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
      version: 6, // bump version for Sales table and consistency
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY,
        userName TEXT,
        password TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        stock_price INTEGER NOT NULL,
        selling_price INTEGER NOT NULL,
        quantity_grams  INTEGER,           -- Total stock in grams
        remain_quantity INTEGER,           -- Remaining stock in grams
        amount REAL DEFAULT 0,             -- NEW COLUMN
        QTY REAL,
        added_date TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_no TEXT NOT NULL,
        shop_id INTEGER,
        item_id INTEGER NOT NULL,
        selling_price INTEGER NOT NULL,
        quantity_grams INTEGER,
        amount REAL DEFAULT 0,            -- NEW COLUMN
        Vat_Number TEXT,
        QTY INTEGER,
        added_date TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE SET NULL,
        FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE SET NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ensure legacy databases get the `user` table if it was introduced later.
    // Use IF NOT EXISTS so this is safe to run on any version.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user (
        id INTEGER PRIMARY KEY,
        userName TEXT,
        password TEXT,
        status TEXT
      )
    ''');

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Stock (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          stock_price INTEGER NOT NULL,
          selling_price INTEGER NOT NULL,
          quantity_grams INTEGER,
          remain_quantity INTEGER,
          amount REAL DEFAULT 0,
          QTY REAL,
          added_date TEXT,
          FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE SET NULL
        )
      ''');
    }

    // Migration to add amount column
    if (oldVersion < 5) {
      final columns = await db.rawQuery('PRAGMA table_info(Stock)');
      final hasAmount = columns.any((c) => c['name'] == 'amount');
      if (!hasAmount) {
        await db.execute('ALTER TABLE Stock ADD COLUMN amount REAL DEFAULT 0');
      }
    }

    // Add Sales table for existing users
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill_no TEXT NOT NULL,
          shop_id INTEGER,
          item_id INTEGER NOT NULL,
          selling_price INTEGER NOT NULL,
          quantity_grams INTEGER,
          amount REAL DEFAULT 0,
          Vat_Number TEXT,
          added_date TEXT,
          FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE SET NULL,
          FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE SET NULL
        )
      ''');
    }
  }

  // Debug method to check if table exists
  Future<bool> doesTableExist(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Debug method to get all table names
  Future<List<String>> getAllTableNames() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    return result.map((map) => map['name'] as String).toList();
  }

  // Insert item
  Future<int> insertItem(ItemModel item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  // Insert stock
  Future<int> insertStock(StockModel stock) async {
    final db = await database;
    return await db.insert('Stock', stock.toMap());
  }

  Future<int> insertSaleFIFO(Map<String, dynamic> sale) async {
    final db = await database;

    final int itemId = sale['item_id'] as int;
    num qtyToSell = (sale['quantity_grams'] ?? 0) as num;

    if (qtyToSell <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    return await db.transaction<int>((txn) async {
      final stockList = await txn.query(
        'Stock',
        where: 'item_id = ? AND COALESCE(remain_quantity, 0) > 0',
        whereArgs: [itemId],
        orderBy: 'added_date ASC, id ASC',
      );

      for (var stock in stockList) {
        final double remainQty = ((stock['remain_quantity'] ?? 0) as num)
            .toDouble();

        if (remainQty >= qtyToSell) {
          final newRemain = remainQty - qtyToSell;

          await txn.update(
            'Stock',
            {'remain_quantity': newRemain},
            where: 'id = ?',
            whereArgs: [stock['id']],
          );

          qtyToSell = 0;
          break;
        } else {
          qtyToSell -= remainQty;

          await txn.update(
            'Stock',
            {'remain_quantity': 0},
            where: 'id = ?',
            whereArgs: [stock['id']],
          );
        }
      }

      if (qtyToSell > 0) {
        throw Exception('Insufficient stock for item ID $itemId');
      }

      // ✅ correct amount: grams -> kg * pricePerKg
      final num grams = (sale['quantity_grams'] ?? 0) as num;
      final num pricePerKg = (sale['selling_price'] ?? 0) as num;
      sale['amount'] = (grams / 1000.0) * pricePerKg;

      // ✅ prevent schema errors
      sale.remove('quantity_kg');
      sale.remove('id');

      final allowed = <String>{
        'bill_no',
        'shop_id',
        'item_id',
        'selling_price',
        'quantity_grams',
        'amount',
        'Vat_Number',
        'added_date',
        'QTY',
      };
      sale.removeWhere((k, v) => !allowed.contains(k));

      final saleId = await txn.insert('Sales', sale);
      return saleId;
    });
  }

  //Daily total Profit (Correct)
  Future<double> getTodayTotalProfit() async {
    final db = await database;
    final today = DateTime.now();
    final padded =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    final unpadded = '${today.day}/${today.month}/${today.year}';
    // For each sale today, get the latest stock_price for the item
    final rows = await db.rawQuery(
      '''
      SELECT S.selling_price, S.Quantity_grams, St.stock_price
      FROM Sales S
      LEFT JOIN (
        SELECT item_id, MAX(id) as max_stock_id
        FROM Stock
        GROUP BY item_id
      ) latestStock ON S.item_id = latestStock.item_id
      LEFT JOIN Stock St ON St.id = latestStock.max_stock_id
      WHERE S.added_date = ? OR S.added_date = ?
    ''',
      [padded, unpadded],
    );

    double totalProfit = 0.0;
    for (final row in rows) {
      final sellingPrice = (row['selling_price'] ?? 0) as num;
      final stockPrice = (row['stock_price'] ?? 0) as num;
      final qtyGrams = (row['quantity_grams'] ?? 0) as num;
      final profit = (sellingPrice - stockPrice) * (qtyGrams / 1000.0);
      totalProfit += profit;
    }
    return totalProfit;
  }

  // Get all items
  Future<List<ItemModel>> getAllItems() async {
    final db = await database;
    final result = await db.query('items', orderBy: 'id ASC');
    return result.map((map) => ItemModel.fromMap(map)).toList();
  }

  // Get all stock
  Future<List<StockModel>> getStockByMonthAndYear(int month, int year) async {
    final db = await database;
    final paddedMonth = month.toString().padLeft(2, '0');
    final yyyy = year.toString();

    final result = await db.rawQuery(
      '''
      SELECT Stock.*, items.name as item_name
      FROM Stock
      LEFT JOIN items ON Stock.item_id = items.id
     WHERE added_date LIKE ? OR added_date LIKE ?
    ORDER BY Stock.id ASC
  ''',
      [
        '%/$paddedMonth/$yyyy%', // DD/MM/YYYY (01/01/2026)
        '%/$month/$yyyy%', // D/M/YYYY (1/1/2026)
      ],
    );

    return result.map((m) => StockModel.fromMap(m)).toList();
  }

  // Get all available stock (remain_quantity > 0)
  Future<List<StockModel>> getACurrentStock() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT Stock.*, items.name as item_name
      FROM Stock
      LEFT JOIN items ON Stock.item_id = items.id
      WHERE COALESCE(Stock.remain_quantity, 0) > 0
      ORDER BY Stock.id ASC
    ''');
    return result.map((m) => StockModel.fromMap(m)).toList();
  }

  // Get all sales
  Future<List<Map<String, dynamic>>> getSalesByMonthAndYear(
    int month,
    int year,
  ) async {
    final db = await database;
    final paddedMonth = month.toString().padLeft(2, '0');
    final yyyy = year.toString();

    return await db.rawQuery(
      '''
    SELECT Sales.*, items.name as item_name, shops.shop_name
    FROM Sales
    LEFT JOIN items ON Sales.item_id = items.id
    LEFT JOIN shops ON Sales.shop_id = shops.id
    WHERE (added_date LIKE ? OR added_date LIKE ?)
    ORDER BY Sales.id DESC
    ''',
      [
        '%/$paddedMonth/$yyyy%', // DD/MM/YYYY (01/01/2026)
        '%/$month/$yyyy%', // D/M/YYYY (1/1/2026)
      ],
    );
  }

  //Today sales
  Future<List<Map<String, dynamic>>> getTodaySales() async {
    final db = await database;
    final today = DateTime.now();
    // Change to DD/MM/YYYY format to match your database
    final todayString = '${today.day}/${today.month}/${today.year}';

    print('🔍 Querying for date: $todayString'); // Debug

    final result = await db.rawQuery(
      '''
    SELECT Sales.*, items.name as item_name, shops.shop_name
    FROM Sales
    LEFT JOIN items ON Sales.item_id = items.id
    LEFT JOIN shops ON Sales.shop_id = shops.id
    WHERE Sales.added_date = ?
    ORDER BY Sales.id DESC
  ''',
      [todayString],
    );

    print('✅ Found ${result.length} records'); // Debug
    return result;
  }

  //Weekly sales
  Future<List<Map<String, dynamic>>> getWeeklySales() async {
    final db = await database;
    final now = DateTime.now();

    // Get the start of the week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Generate all dates in the current week as D/M/YYYY (no leading zeros)
    List<String> weekDates = [];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      weekDates.add('${date.day}/${date.month}/${date.year}');
    }

    print('🗓️ Week dates: $weekDates'); // Debug

    // Create placeholders for the IN clause
    final placeholders = List.filled(weekDates.length, '?').join(',');

    final result = await db.rawQuery('''
    SELECT Sales.*, items.name as item_name, shops.shop_name
    FROM Sales
    LEFT JOIN items ON Sales.item_id = items.id
    LEFT JOIN shops ON Sales.shop_id = shops.id
    WHERE Sales.added_date IN ($placeholders)
    ORDER BY Sales.id DESC
  ''', weekDates);

    print('✅ Found ${result.length} weekly records'); // Debug
    return result;
  }

  //Monthly sales
  Future<List<Map<String, dynamic>>> getMonthlySales() async {
    final db = await database;
    final now = DateTime.now();

    // Get the first day of the current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Get the last day of the current month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Generate all dates in the current month
    List<String> monthDates = [];
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      final date = firstDayOfMonth.add(Duration(days: i));
      monthDates.add('${date.day}/${date.month}/${date.year}');
    }

    print('📆 Month dates: ${monthDates.length} dates generated'); // Debug

    // Create placeholders for the IN clause
    final placeholders = List.filled(monthDates.length, '?').join(',');

    final result = await db.rawQuery('''
    SELECT Sales.*, items.name as item_name, shops.shop_name
    FROM Sales
    LEFT JOIN items ON Sales.item_id = items.id
    LEFT JOIN shops ON Sales.shop_id = shops.id
    WHERE Sales.added_date IN ($placeholders)
    ORDER BY Sales.id DESC
  ''', monthDates);

    print('✅ Found ${result.length} monthly records'); // Debug
    return result;
  }

  //Today Sales Amount Total Price
  Future<double> getTodaySalesTotalAmount() async {
    final db = await database;
    final now = DateTime.now();
    final padded =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final unpadded = '${now.day}/${now.month}/${now.year}';
    final rows = await db.rawQuery(
      '''
    SELECT IFNULL(SUM(amount),0) AS total_amount
    FROM Sales
    WHERE added_date = ? OR added_date = ?
  ''',
      [padded, unpadded],
    );
    return (rows.first['total_amount'] as num).toDouble();
  }

  //Yesterday Sales Amount Total Price
  Future<double> getYesterdaySalesTotalAmount() async {
    final db = await database;
    final y = DateTime.now().subtract(const Duration(days: 1));
    final padded =
        '${y.day.toString().padLeft(2, '0')}/${y.month.toString().padLeft(2, '0')}/${y.year}';
    final unpadded = '${y.day}/${y.month}/${y.year}';
    final rows = await db.rawQuery(
      '''
    SELECT IFNULL(SUM(amount),0) AS total_amount
    FROM Sales
    WHERE added_date = ? OR added_date = ?
  ''',
      [padded, unpadded],
    );
    return (rows.first['total_amount'] as num).toDouble();
  }

  // Update item
  Future<int> updateItem(ItemModel item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Update root
  Future<int> updateRoot(RootModel root) async {
    final db = await database;
    return await db.update(
      'roots',
      root.toMap(),
      where: 'id = ?',
      whereArgs: [root.id],
    );
  }

  // Update shop
  Future<int> updateShop(Shopmodel shop) async {
    final db = await database;
    return await db.update(
      'shops',
      shop.toMap(),
      where: 'id = ?',
      whereArgs: [shop.id],
    );
  }

  // Update stock
  Future<int> updateStock(StockModel stock) async {
    final db = await database;
    return await db.update(
      'Stock',
      stock.toMap(),
      where: 'id = ?',
      whereArgs: [stock.id],
    );
  }

  // Update sale
  Future<int> updateSale(int id, Map<String, dynamic> sale) async {
    final db = await database;
    return await db.update('Sales', sale, where: 'id = ?', whereArgs: [id]);
  }

  // Delete item
  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // Delete stock
  Future<int> deleteStock(int id) async {
    final db = await database;
    return await db.delete('Stock', where: 'id = ?', whereArgs: [id]);
  }

  // Delete sale and restore stock
  Future<int> deleteSale(int id) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      // Get the sale to know how much stock to restore
      final saleList = await txn.query(
        'Sales',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (saleList.isEmpty) return 0;

      final sale = saleList.first;
      final itemId = sale['item_id'] as int;
      final quantityToRestore = (sale['quantity_grams'] ?? 0) as num;

      // Restore stock in reverse FIFO order (newest stock first)
      if (quantityToRestore > 0) {
        final stockList = await txn.query(
          'Stock',
          where: 'item_id = ?',
          whereArgs: [itemId],
          orderBy: 'added_date DESC, id DESC',
        );

        num remainingToRestore = quantityToRestore.toDouble();

        for (var stock in stockList) {
          if (remainingToRestore <= 0) break;

          final currentRemain = ((stock['remain_quantity'] ?? 0) as num)
              .toDouble();
          final totalQty = ((stock['quantity_grams'] ?? 0) as num).toDouble();
          final canRestore = totalQty - currentRemain; // How much was sold

          if (canRestore > 0) {
            final restoreAmount = remainingToRestore > canRestore
                ? canRestore
                : remainingToRestore;

            final newRemain = currentRemain + restoreAmount;

            await txn.update(
              'Stock',
              {'remain_quantity': newRemain},
              where: 'id = ?',
              whereArgs: [stock['id']],
            );

            remainingToRestore -= restoreAmount;
          }
        }
      }

      // Delete the sale
      return await txn.delete('Sales', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Get next bill number
  Future<String> getNextBillNumber() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT bill_no FROM Sales ORDER BY CAST(bill_no AS INTEGER) DESC LIMIT 1',
    );

    if (result.isEmpty) {
      return '000001';
    }

    final lastBillNo = result.first['bill_no'] as String;
    final nextNumber = (int.parse(lastBillNo) + 1).toString().padLeft(6, '0');
    return nextNumber;
  }

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }

  // ------------------------
  // Local user helpers
  // ------------------------
  /// Save or update a user record locally.
  Future<void> saveUserCredentials(
    String userName,
    String password,
    String status,
  ) async {
    final db = await database;
    final existing = await db.query(
      'user',
      where: 'userName = ?',
      whereArgs: [userName],
      limit: 1,
    );

    final values = {
      'userName': userName,
      'password': password,
      'status': status,
    };

    if (existing.isEmpty) {
      await db.insert('user', values);
    } else {
      await db.update(
        'user',
        values,
        where: 'userName = ?',
        whereArgs: [userName],
      );
    }
  }

  /// Get a local saved user. If [userName] is omitted returns the first saved user.
  Future<Map<String, dynamic>?> getLocalUser([String? userName]) async {
    final db = await database;
    List<Map<String, Object?>> rows;
    if (userName == null) {
      rows = await db.query('user', limit: 1);
    } else {
      rows = await db.query(
        'user',
        where: 'userName = ?',
        whereArgs: [userName],
        limit: 1,
      );
    }

    if (rows.isEmpty) return null;
    final r = rows.first;
    return {
      'id': r['id'],
      'userName': r['userName'],
      'password': r['password'],
      'status': r['status'],
    };
  }

  /// Delete a local saved user by username.
  Future<int> deleteLocalUser(String userName) async {
    final db = await database;
    return await db.delete(
      'user',
      where: 'userName = ?',
      whereArgs: [userName],
    );
  }
}
