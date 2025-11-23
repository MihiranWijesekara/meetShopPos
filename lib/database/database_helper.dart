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
      version: 5, // bump version for amount column
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE roots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        root_id INTEGER,
        FOREIGN KEY (root_id) REFERENCES roots (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        stock_price INTEGER NOT NULL,
        quantity_kg INTEGER,
        remain_quantity REAL,
        amount REAL DEFAULT 0,            -- NEW COLUMN
        QTY REAL,
        added_date TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE SET NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS roots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shops (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shop_name TEXT NOT NULL,
          root_id INTEGER,
          FOREIGN KEY (root_id) REFERENCES roots (id) ON DELETE SET NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Stock (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          stock_price INTEGER NOT NULL,
          quantity_kg INTEGER,
          remain_quantity REAL,
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
  }

  // Debug method to check if table exists
  Future<bool> doesTableExist(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    return result.isNotEmpty;
  }

  // Debug method to get all table names
  Future<List<String>> getAllTableNames() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    return result.map((map) => map['name'] as String).toList();
  }

  // Insert item
  Future<int> insertItem(ItemModel item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  // Insert root
  Future<int> insertRoot(RootModel root) async {
    final db = await database;
    return await db.insert('roots', root.toMap());
  }

  // Insert shop
  Future<int> insertShop(Shopmodel shop) async {
    final db = await database;
    return await db.insert('shops', shop.toMap());
  }

  // Insert stock
  Future<int> insertStock(StockModel stock) async {
    final db = await database;
    return await db.insert('Stock', stock.toMap());
  }

  // Get all items
  Future<List<ItemModel>> getAllItems() async {
    final db = await database;
    final result = await db.query('items', orderBy: 'id ASC');
    return result.map((map) => ItemModel.fromMap(map)).toList();
  }

  // Get all roots
  Future<List<RootModel>> getAllRoots() async {
    final db = await database;
    final result = await db.query('roots', orderBy: 'id ASC');
    return result.map((map) => RootModel.fromMap(map)).toList();
  }

  // Get all shops
  Future<List<Shopmodel>> getAllShops() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT shops.*, roots.name as root_name
      FROM shops
      LEFT JOIN roots ON shops.root_id = roots.id
      ORDER BY shops.id ASC
    ''');
    return result.map((map) => Shopmodel.fromMap(map)).toList();
  }

  // Get all stock
  Future<List<StockModel>> getAllStock() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT Stock.*, items.name as item_name
      FROM Stock
      LEFT JOIN items ON Stock.item_id = items.id
      ORDER BY Stock.id ASC
    ''');
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

  // Delete item
  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete root
  Future<int> deleteRoot(int id) async {
    final db = await database;
    return await db.delete(
      'roots',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete shop
  Future<int> deleteShop(int id) async {
    final db = await database;
    return await db.delete(
      'shops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete stock
  Future<int> deleteStock(int id) async {
    final db = await database;
    return await db.delete(
      'Stock',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}