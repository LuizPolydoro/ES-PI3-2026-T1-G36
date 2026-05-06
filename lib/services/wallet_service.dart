// lib/services/wallet_service.dart
// Autor: [Seu Nome Completo]
// RA: [Seu RA]
// Serviço de carteira - compra/venda simulada de tokens no Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_models.dart';

class WalletResult {
  final bool success;
  final String? errorMessage;
  WalletResult({required this.success, this.errorMessage});
}

class WalletService {
  final FirebaseFirestore _db  = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Referências no Firestore ────────────────────────────────────────────────
  DocumentReference get _userRef =>
      _db.collection('users').doc(_uid);

  CollectionReference get _positionsRef =>
      _userRef.collection('positions');      // users/{uid}/positions

  CollectionReference get _transacoesRef =>
      _userRef.collection('transacoes');     // users/{uid}/transacoes

  // ── Saldo atual do usuário ──────────────────────────────────────────────────
  Future<double> getSaldo() async {
    try {
      final doc = await _userRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['saldo_carteira'] ?? 0).toDouble();
    } catch (_) {
      return 0;
    }
  }

  // ── Stream de posições em tempo real ───────────────────────────────────────
  Stream<List<TokenPosition>> getPositionsStream() {
    if (_uid == null) return const Stream.empty();
    return _positionsRef.snapshots().map((snap) => snap.docs
        .map((doc) => TokenPosition.fromMap(
            doc.id, doc.data() as Map<String, dynamic>))
        .where((p) => p.quantidade > 0)
        .toList());
  }

  // ── Stream de transações ───────────────────────────────────────────────────
  Stream<List<Transacao>> getTransacoesStream() {
    if (_uid == null) return const Stream.empty();
    return _transacoesRef
        .orderBy('data', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Transacao.fromFirestore(d)).toList());
  }

  // ── Preço atual simulado de um token ───────────────────────────────────────
  /// Calcula preço baseado no capital aportado / tokens emitidos
  /// com variação aleatória de ±5% para simular mercado
  double calcularPrecoAtual(double capitalAportado, int tokensEmitidos) {
    if (tokensEmitidos == 0) return 1.0;
    final base = capitalAportado / tokensEmitidos;
    // Variação simulada baseada no timestamp (determinística, sem random)
    final variacao = 1 + (DateTime.now().millisecond % 10 - 5) / 100;
    return double.parse((base * variacao).toStringAsFixed(2));
  }

  // ── COMPRAR TOKENS ─────────────────────────────────────────────────────────
  Future<WalletResult> comprarTokens({
    required String startupId,
    required String nomeStartup,
    required int quantidade,
    required double capitalAportado,
    required int tokensEmitidos,
  }) async {
    if (_uid == null) {
      return WalletResult(success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (quantidade <= 0) {
      return WalletResult(success: false, errorMessage: 'Quantidade inválida.');
    }

    final preco = calcularPrecoAtual(capitalAportado, tokensEmitidos);
    final total = preco * quantidade;

    try {
      // Transação atômica no Firestore
      await _db.runTransaction((tx) async {
        // 1. Verifica saldo
        final userSnap = await tx.get(_userRef);
        final userData = userSnap.data() as Map<String, dynamic>;
        final saldoAtual = (userData['saldo_carteira'] ?? 0).toDouble();

        if (saldoAtual < total) {
          throw Exception('Saldo insuficiente. Disponível: R\$ ${saldoAtual.toStringAsFixed(2)}');
        }

        // 2. Verifica posição existente
        final posSnap = await tx.get(_positionsRef.doc(startupId));

        double novoPrecoMedio;
        int novaQtd;

        if (posSnap.exists) {
          final posData = posSnap.data() as Map<String, dynamic>;
          final qtdAtual  = (posData['quantidade']  ?? 0).toInt();
          final precoAtual = (posData['preco_medio'] ?? 0).toDouble();
          // Preço médio ponderado
          novaQtd = qtdAtual + quantidade;
          novoPrecoMedio = ((precoAtual * qtdAtual) + (preco * quantidade)) / novaQtd;
        } else {
          novaQtd = quantidade;
          novoPrecoMedio = preco;
        }

        // 3. Atualiza posição
        tx.set(_positionsRef.doc(startupId), {
          'nome_startup':       nomeStartup,
          'quantidade':         novaQtd,
          'preco_medio':        novoPrecoMedio,
          'preco_atual':        preco,
          'ultima_atualizacao': FieldValue.serverTimestamp(),
        });

        // 4. Debita saldo
        tx.update(_userRef, {
          'saldo_carteira': saldoAtual - total,
        });

        // 5. Registra transação
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
      return WalletResult(success: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── VENDER TOKENS ──────────────────────────────────────────────────────────
  Future<WalletResult> venderTokens({
    required String startupId,
    required String nomeStartup,
    required int quantidade,
    required double capitalAportado,
    required int tokensEmitidos,
  }) async {
    if (_uid == null) {
      return WalletResult(success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (quantidade <= 0) {
      return WalletResult(success: false, errorMessage: 'Quantidade inválida.');
    }

    final preco = calcularPrecoAtual(capitalAportado, tokensEmitidos);
    final total = preco * quantidade;

    try {
      await _db.runTransaction((tx) async {
        // 1. Verifica posição
        final posSnap = await tx.get(_positionsRef.doc(startupId));
        if (!posSnap.exists) {
          throw Exception('Você não possui tokens desta startup.');
        }

        final posData  = posSnap.data() as Map<String, dynamic>;
        final qtdAtual = (posData['quantidade'] ?? 0).toInt();

        if (qtdAtual < quantidade) {
          throw Exception('Você possui apenas $qtdAtual tokens disponíveis.');
        }

        final novaQtd = qtdAtual - quantidade;

        // 2. Atualiza ou remove posição
        if (novaQtd == 0) {
          tx.delete(_positionsRef.doc(startupId));
        } else {
          tx.update(_positionsRef.doc(startupId), {
            'quantidade':         novaQtd,
            'preco_atual':        preco,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          });
        }

        // 3. Credita saldo
        final userSnap = await tx.get(_userRef);
        final userData = userSnap.data() as Map<String, dynamic>;
        final saldoAtual = (userData['saldo_carteira'] ?? 0).toDouble();

        tx.update(_userRef, {
          'saldo_carteira': saldoAtual + total,
        });

        // 4. Registra transação
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
      return WalletResult(success: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Histórico de preços simulado (para o gráfico) ──────────────────────────
  /// Gera pontos de preço histórico simulado baseado no capital aportado
  List<Map<String, dynamic>> gerarHistoricoPrecos({
    required double capitalAportado,
    required int tokensEmitidos,
    required String periodo, // 'diario' | 'semanal' | 'mensal' | '6meses' | 'ytd'
  }) {
    if (tokensEmitidos == 0) return [];

    final base = capitalAportado / tokensEmitidos;
    final agora = DateTime.now();
    final pontos = <Map<String, dynamic>>[];

    int quantidadePontos;
    Duration intervalo;

    switch (periodo) {
      case 'diario':
        quantidadePontos = 24;
        intervalo = const Duration(hours: 1);
        break;
      case 'semanal':
        quantidadePontos = 7;
        intervalo = const Duration(days: 1);
        break;
      case 'mensal':
        quantidadePontos = 30;
        intervalo = const Duration(days: 1);
        break;
      case '6meses':
        quantidadePontos = 26;
        intervalo = const Duration(days: 7);
        break;
      case 'ytd':
      default:
        quantidadePontos = agora.month;
        intervalo = const Duration(days: 30);
        break;
    }

    // Gera variação pseudo-aleatória determinística
    double preco = base * 0.8; // começa 20% abaixo
    for (int i = quantidadePontos; i >= 0; i--) {
      final data = agora.subtract(intervalo * i);
      // Variação baseada no índice para ser determinística
      final variacao = ((i * 7 + 3) % 11 - 5) / 100;
      preco = preco * (1 + variacao);
      if (preco < base * 0.5) preco = base * 0.5;

      pontos.add({
        'data':  data,
        'preco': double.parse(preco.toStringAsFixed(4)),
      });
    }

    // Último ponto é o preço atual real
    if (pontos.isNotEmpty) {
      pontos.last['preco'] = calcularPrecoAtual(capitalAportado, tokensEmitidos);
    }

    return pontos;
  }
}