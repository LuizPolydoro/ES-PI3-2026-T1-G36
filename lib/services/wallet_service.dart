// lib/services/wallet_service.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Serviço de carteira - todos os reads ANTES dos writes (regra do Firestore)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';

class WalletResult {
  final bool success;
  final String? errorMessage;
  WalletResult({required this.success, this.errorMessage});
}

class WalletService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference  get _userRef      => _db.collection('users').doc(_uid);
  CollectionReference get _positionsRef => _userRef.collection('positions');
  CollectionReference get _transacoesRef => _userRef.collection('transacoes');

  // ── Saldo atual ─────────────────────────────────────────────────────────────
  Future<double> getSaldo() async {
    try {
      final doc  = await _userRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['saldo_carteira'] ?? 0).toDouble();
    } catch (_) {
      return 0;
    }
  }

  // ── Stream de posições ──────────────────────────────────────────────────────
  Stream<List<TokenPosition>> getPositionsStream() {
    if (_uid == null) return const Stream.empty();
    return _positionsRef.snapshots().map((snap) => snap.docs
        .map((d) => TokenPosition.fromMap(
            d.id, d.data() as Map<String, dynamic>))
        .where((p) => p.quantidade > 0)
        .toList());
  }

  // ── Stream de transações ────────────────────────────────────────────────────
  Stream<List<Transacao>> getTransacoesStream() {
    if (_uid == null) return const Stream.empty();
    return _transacoesRef
        .orderBy('data', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Transacao.fromFirestore(d)).toList());
  }

  // ── Preço calculado ─────────────────────────────────────────────────────────
  double calcularPreco(double capitalAportado, int tokensEmitidos) {
    if (tokensEmitidos == 0) return 1.0;
    return double.parse(
        (capitalAportado / tokensEmitidos).toStringAsFixed(4));
  }

  // ── COMPRAR ─────────────────────────────────────────────────────────────────
  Future<WalletResult> comprarTokens({
    required String startupId,
    required String nomeStartup,
    required int quantidade,
    required double capitalAportado,
    required int tokensEmitidos,
  }) async {
    if (_uid == null) {
      return WalletResult(
          success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (quantidade <= 0) {
      return WalletResult(
          success: false, errorMessage: 'Quantidade inválida.');
    }

    final preco = calcularPreco(capitalAportado, tokensEmitidos);
    final total = preco * quantidade;

    try {
      await _db.runTransaction((tx) async {
        // ── FASE 1: todos os READS primeiro ────────────────────────────────
        final userSnap = await tx.get(_userRef);
        final posSnap  = await tx.get(_positionsRef.doc(startupId));

        // ── FASE 2: validações ──────────────────────────────────────────────
        final userData   = userSnap.data() as Map<String, dynamic>;
        final saldoAtual = (userData['saldo_carteira'] ?? 0).toDouble();

        if (saldoAtual < total) {
          throw Exception(
              'Saldo insuficiente. Disponível: R\$ ${saldoAtual.toStringAsFixed(2)}');
        }

        double novoPrecoMedio;
        int    novaQtd;

        if (posSnap.exists) {
          final posData   = posSnap.data() as Map<String, dynamic>;
          final qtdAtual  = (posData['quantidade']  ?? 0).toInt();
          final precoAtual = (posData['preco_medio'] ?? 0).toDouble();
          novaQtd        = qtdAtual + quantidade;
          novoPrecoMedio = ((precoAtual * qtdAtual) + (preco * quantidade)) / novaQtd;
        } else {
          novaQtd        = quantidade;
          novoPrecoMedio = preco;
        }

        // ── FASE 3: todos os WRITES depois ─────────────────────────────────
        tx.set(_positionsRef.doc(startupId), {
          'nome_startup':       nomeStartup,
          'quantidade':         novaQtd,
          'preco_medio':        novoPrecoMedio,
          'preco_atual':        preco,
          'ultima_atualizacao': FieldValue.serverTimestamp(),
        });

        tx.update(_userRef, {'saldo_carteira': saldoAtual - total});

        tx.set(_transacoesRef.doc(), {
          'startup_id':     startupId,
          'nome_startup':   nomeStartup,
          'tipo':           'compra',
          'quantidade':     quantidade,
          'preco_unitario': preco,
          'total':          total,
          'data':           FieldValue.serverTimestamp(),
        });
      });

      return WalletResult(success: true);
    } catch (e) {
      return WalletResult(
          success: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── VENDER ──────────────────────────────────────────────────────────────────
  Future<WalletResult> venderTokens({
    required String startupId,
    required String nomeStartup,
    required int quantidade,
    required double capitalAportado,
    required int tokensEmitidos,
  }) async {
    if (_uid == null) {
      return WalletResult(
          success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (quantidade <= 0) {
      return WalletResult(
          success: false, errorMessage: 'Quantidade inválida.');
    }

    final preco = calcularPreco(capitalAportado, tokensEmitidos);
    final total = preco * quantidade;

    try {
      await _db.runTransaction((tx) async {
        // ── FASE 1: todos os READS primeiro ────────────────────────────────
        final posSnap  = await tx.get(_positionsRef.doc(startupId));
        final userSnap = await tx.get(_userRef);

        // ── FASE 2: validações ──────────────────────────────────────────────
        if (!posSnap.exists) {
          throw Exception('Você não possui tokens desta startup.');
        }

        final posData  = posSnap.data() as Map<String, dynamic>;
        final qtdAtual = (posData['quantidade'] ?? 0).toInt();

        if (qtdAtual < quantidade) {
          throw Exception(
              'Você possui apenas $qtdAtual tokens disponíveis.');
        }

        final userData   = userSnap.data() as Map<String, dynamic>;
        final saldoAtual = (userData['saldo_carteira'] ?? 0).toDouble();
        final novaQtd    = qtdAtual - quantidade;

        // ── FASE 3: todos os WRITES depois ─────────────────────────────────
        if (novaQtd == 0) {
          tx.delete(_positionsRef.doc(startupId));
        } else {
          tx.update(_positionsRef.doc(startupId), {
            'quantidade':         novaQtd,
            'preco_atual':        preco,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          });
        }

        tx.update(_userRef, {'saldo_carteira': saldoAtual + total});

        tx.set(_transacoesRef.doc(), {
          'startup_id':     startupId,
          'nome_startup':   nomeStartup,
          'tipo':           'venda',
          'quantidade':     quantidade,
          'preco_unitario': preco,
          'total':          total,
          'data':           FieldValue.serverTimestamp(),
        });
      });

      return WalletResult(success: true);
    } catch (e) {
      return WalletResult(
          success: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}