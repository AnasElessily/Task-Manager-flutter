import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHelper {
  static final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static bool verifyPassword(String rawPassword, String storedPassword) {
    return hashPassword(rawPassword) == storedPassword;
  }

  static bool isHashed(String value) {
    return _sha256Pattern.hasMatch(value);
  }

  static String normalizeForStorage(String password) {
    return isHashed(password) ? password : hashPassword(password);
  }
}
