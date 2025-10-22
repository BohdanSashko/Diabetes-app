import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _secureKeyName = 'hive_key_v1'; // rotate if you ever need a new key

Future<HiveAesCipher> buildCipher() async {
  const storage = FlutterSecureStorage();
  String? stored = await storage.read(key: _secureKeyName);

  if (stored == null) {
    final key = Hive.generateSecureKey();                // 32 bytes
    stored = base64UrlEncode(key);
    await storage.write(key: _secureKeyName, value: stored);
  }
  return HiveAesCipher(base64Url.decode(stored));
}

/// --- password helpers (salted SHA-256) ---

String generateSalt([int len = 16]) {
  final r = Random.secure();
  final bytes = List<int>.generate(len, (_) => r.nextInt(256));
  return base64UrlEncode(bytes);
}

String hashPassword(String password, String salt) {
  final data = utf8.encode('$salt::$password');
  return sha256.convert(data).toString();
}
void debugPrintAllUsers() {
  final box = Hive.box('secure_users');
  for (var key in box.keys) {
    final value = box.get(key);
    print('User: $key => $value');
  }
}
