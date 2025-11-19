import 'package:chicken_dilivery/Model/ItemModel.dart';
import 'package:chicken_dilivery/Model/RootModel.dart';
import 'package:chicken_dilivery/Model/ShopModel.dart';
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
      version: 3, // Increased version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}