// Autor: João Vitor Roventini
// RA: 22005168

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpService {
  static final _firestore = FirebaseFirestore.instance;

  static String gerarCodigo() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  static Future<void> salvarCodigo(String userId, String code) async {
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));

    await _firestore.collection('otps').doc(userId).set({
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
    });
  }

  static Future<bool> validarCodigo(String userId, String code) async {
    final doc = await _firestore.collection('otps').doc(userId).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final savedCode = data['code'];
    final expiresAt = DateTime.parse(data['expiresAt']);

    if (DateTime.now().isAfter(expiresAt)) return false;

    return savedCode == code;
  }
}