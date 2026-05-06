// lib/models/user_model.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Model que representa um Usuário/Investidor no Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nome;
  final String email;
  final double saldoCarteira;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    this.saldoCarteira = 0.0,
    this.createdAt,
  });

  /// Cria UserModel a partir de documento Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:           doc.id,
      nome:          data['nome']     ?? '',
      email:         data['email']    ?? '',
      saldoCarteira: (data['saldo_carteira'] ?? 0.0).toDouble(),
      createdAt:     (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome':           nome,
      'email':          email,
      'saldo_carteira': saldoCarteira,
      'createdAt':      FieldValue.serverTimestamp(),
    };
  }

  /// Retorna as iniciais do nome para avatar
  String get iniciais {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return partes.first.isNotEmpty ? partes.first[0].toUpperCase() : '?';
  }

  /// Formata saldo em reais
  String get saldoFormatado {
    return 'R\$ ${saldoCarteira.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
