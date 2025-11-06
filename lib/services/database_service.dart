import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._privateConstructor();
  static Database? _database;

  DatabaseService._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'order_qr.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE orders (
        order_id INTEGER PRIMARY KEY,
        order_number TEXT NOT NULL,
        business_id INTEGER NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        customer_email TEXT,
        folio_number TEXT NOT NULL,
        description TEXT,
        total_amount TEXT NOT NULL,
        qr_code_url TEXT NOT NULL,
        qr_token TEXT NOT NULL,
        pickup_token TEXT NOT NULL,
        status TEXT NOT NULL,
        mobile_user_id INTEGER,
        associated_at TEXT,
        ready_at TEXT,
        delivered_at TEXT,
        cancelled_at TEXT,
        cancellation_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Eliminar la tabla antigua y crear la nueva
      await db.execute('DROP TABLE IF EXISTS orders');
      await _onCreate(db, newVersion);
    }
  }

  // Insertar o actualizar orden
  Future<void> insertOrder(Order order) async {
    final db = await database;
    await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todas las órdenes
  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // Obtener órdenes por estado
  Future<List<Order>> getOrdersByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // Obtener órdenes activas (pending o ready)
  Future<List<Order>> getActiveOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'ready'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // Obtener orden por ID
  Future<Order?> getOrderById(int orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  // Actualizar orden
  Future<void> updateOrder(Order order) async {
    final db = await database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'order_id = ?',
      whereArgs: [order.orderId],
    );
  }

  // Eliminar orden
  Future<void> deleteOrder(int orderId) async {
    final db = await database;
    await db.delete(
      'orders',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // Eliminar todas las órdenes
  Future<void> deleteAllOrders() async {
    final db = await database;
    await db.delete('orders');
  }

  // Sincronizar órdenes desde el servidor
  Future<void> syncOrders(List<Order> orders) async {
    final db = await database;
    final batch = db.batch();

    for (final order in orders) {
      batch.insert(
        'orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Cerrar base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
