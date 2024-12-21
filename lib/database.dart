import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  final String _deviceKey = 'device_id';
  String? deviceId;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _initializeDeviceId();
    return _database!;
  }

  // Ma'lumotlar bazasini yaratish
  Future<Database> _initDatabase() async {
    // Ma'lumotlar bazasi yo'lini olish
    String path = join(await getDatabasesPath(), 'KundalikMobile.db');
    // Ma'lumotlar bazasini ochish
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          '''CREATE TABLE datas (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )''',
        );
        await db.execute(
          '''CREATE TABLE logins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            login TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            holat INTEGER NOT NULL
          )''',
        );
      },
    );
  }

  // device_id ni yaratish yoki olish
  Future<void> _initializeDeviceId() async {
    deviceId = await getData(_deviceKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await setData(_deviceKey, deviceId!);
    }
  }

  // Datas jadvallariga yangi qiymat qo'shish
  Future<void> setData(String key, String data) async {
    final db = await database;
    final existingData =
        await db.query('datas', where: 'key = ?', whereArgs: [key]);

    if (existingData.isNotEmpty) {
      await db.update('datas', {'data': data},
          where: 'key = ?', whereArgs: [key]);
    } else {
      try {
        await db.insert('datas', {'key': key, 'data': data});
      } catch (e) {}
    }
  }

  // Datas jadvalidan qiymat olish
  Future<String?> getData(String key) async {
    final db = await database;
    final result = await db.query('datas', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['data'] as String?;
    }
    return null;
  }

  // Barcha datas qiymatlarini bir vaqtning o'zida o'rnatish
  Future<void> setDatas(Map<String, String> datas) async {
    for (var entry in datas.entries) {
      await setData(entry.key, entry.value);
    }
  }

  Future<String> addLogin(String name, String login, String password) async {
    final db = await database;

    // Bazadagi mavjud loginlar sonini tekshirish
    final int count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM logins')) ??
        0;

    if (count >= 80) {
      // Agar loginlar soni 80 dan ortiq bo'lsa
      return 'Hozircha 80 ta login qo\'shish mumkin';
    }

    // Bazadan loginni tekshirish
    final existingLogin = await db.query(
      'logins',
      where: 'login = ?',
      whereArgs: [login],
    );

    if (existingLogin.isNotEmpty) {
      // Agar login allaqachon mavjud bo'lsa
      return 'Bunday login bilan foydalanuvchi mavjud';
    }

    // Agar login mavjud bo'lmasa, yangi foydalanuvchini qo'shish
    await db.insert(
      'logins',
      {
        'name': name,
        'login': login,
        'password': password,
        'holat': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Login muvaffaqiyatli qo'shilgan bo'lsa
    return '';
  }

  // Login ma'lumotlarini olish
  Future<Map<String, dynamic>?> getLogin(int id) async {
    final db = await database;
    final result = await db.query('logins', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Login ma'lumotlarini o'chirish
  Future<void> deleteLogin(String login) async {
    final db = await database;
    await db.delete('logins', where: 'login = ?', whereArgs: [login]);
  }

  // Login ma'lumotlarini yangilash
  Future<void> updateLogin(String? login,
      {String? name, String? password, int? holat}) async {
    final db = await database;
    Map<String, dynamic> values = {};
    if (name != null) values['name'] = name;
    if (password != null) values['password'] = password;
    if (holat != null) values['holat'] = holat;

    await db.update('logins', values, where: 'login = ?', whereArgs: [login]);
  }

  // Barcha loginlarni olish (holat bo'yicha ajratilgan)
  Future<Map<String, Map<String, dynamic>>> getLogins() async {
    final db = await database;
    final loginDatas = await db.query('logins');
    Map<String, Map<String, dynamic>> result = {};

    for (var loginData in loginDatas) {
      String login = loginData['login'] as String;
      result[login] = loginData;
    }
    return result;
  }

  // Barcha loginlarni olish (holat bo'yicha ajratilgan)
  Future<Map<String, Map<String, dynamic>>> getLoginsErrors() async {
    final db = await database;
    final loginDatas = await db.query('logins');
    Map<String, Map<String, dynamic>> resultErr = {};

    for (var loginData in loginDatas) {
      String login = loginData['login'] as String;
      if (loginData['holat'] != 1) {
        resultErr[login] = loginData;
      } else {}
    }
    return resultErr;
  }

  // Logout funksiyasi (tokenni o'chirish)
  Future<void> logout() async {
    final db = await database;
    await db.delete('datas', where: 'key = ?', whereArgs: ['token']);
    await db.delete('datas', where: 'key = ?', whereArgs: ['full_name']);
  }

  // Ma'lumotlar bazasini yopish
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
