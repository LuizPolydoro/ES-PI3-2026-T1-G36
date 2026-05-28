// lib/services/wallet_service.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Serviço de carteira com histórico de preços para o gráfico

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

  DocumentReference   get _userRef       => _db.collection('users').doc(_uid);
  CollectionReference get _positionsRef  => _userRef.collection('positions');
  CollectionReference get _transacoesRef => _userRef.collection('transacoes');

  // Referência para histórico de preços de uma startup
  CollectionReference _historicoRef(String startupId) =>
      _db.collection('startups').doc(startupId).collection('historico_precos');

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

  // ── Calcula novo preço baseado em oferta/demanda ────────────────────────────
  // Compra → preço sobe 0.5% | Venda → preço cai 0.3%
  double calcularNovoPreco({
    required double precoAtual,
    required String tipo,
    required int quantidade,
    required int totalTokens,
  }) {
    if (totalTokens == 0) return precoAtual;
    final impacto = quantidade / totalTokens;
    if (tipo == 'compra') {
      return precoAtual * (1 + impacto * 0.5);
    } else {
      return precoAtual * (1 - impacto * 0.3);
    }
  }

  double calcularPrecoBase(double capitalAportado, int tokensEmitidos) {
    if (tokensEmitidos == 0) return 1.0;
    return double.parse(
        (capitalAportado / tokensEmitidos).toStringAsFixed(4));
  }

  // ── Busca preço atual da startup no Firestore ───────────────────────────────
  Future<double> getPrecoAtual(
      String startupId, double capitalAportado, int tokensEmitidos) async {
    try {
      final doc = await _db.collection('startups').doc(startupId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final preco = data?['preco_atual'];
      if (preco != null) return (preco as num).toDouble();
    } catch (_) {}
    return calcularPrecoBase(capitalAportado, tokensEmitidos);
  }

  // ── Salva snapshot do preço no histórico ────────────────────────────────────
  Future<void> _salvarHistoricoPreco(
      String startupId, double novoPreco) async {
    try {
      await _historicoRef(startupId).add({
        'preco':     novoPreco,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Atualiza preço atual na startup
      await _db.collection('startups').doc(startupId).update({
        'preco_atual': novoPreco,
      });
    } catch (_) {}
  }

  // ── Busca histórico de preços para o gráfico ────────────────────────────────
  Future<List<PrecoSnapshot>> getHistoricoPrecos({
    required String startupId,
    required String periodo,
    required double capitalAportado,
    required int tokensEmitidos,
  }) async {
    try {
      final agora  = DateTime.now();
      DateTime from;

      switch (periodo) {
        case 'diario':
          from = agora.subtract(const Duration(hours: 24));
          break;
        case 'semanal':
          from = agora.subtract(const Duration(days: 7));
          break;
        case 'mensal':
          from = agora.subtract(const Duration(days: 30));
          break;
        case '6meses':
          from = agora.subtract(const Duration(days: 180));
          break;
        case 'ytd':
          from = DateTime(agora.year, 1, 1);
          break;
        default:
          from = agora.subtract(const Duration(days: 30));
      }

      final snap = await _historicoRef(startupId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .orderBy('timestamp')
          .get();

      if (snap.docs.isEmpty) {
        // Gera histórico simulado se não há dados reais
        return _gerarHistoricoSimulado(
          capitalAportado: capitalAportado,
          tokensEmitidos:  tokensEmitidos,
          periodo:         periodo,
        );
      }

      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        final ts   = (data['timestamp'] as Timestamp?)?.toDate() ?? agora;
        final preco = (data['preco'] as num).toDouble();
        return PrecoSnapshot(data: ts, preco: preco);
      }).toList();

    } catch (_) {
      return _gerarHistoricoSimulado(
        capitalAportado: capitalAportado,
        tokensEmitidos:  tokensEmitidos,
        periodo:         periodo,
      );
    }
  }

  // ── Histórico simulado (quando não há transações ainda) ─────────────────────
  List<PrecoSnapshot> _gerarHistoricoSimulado({
    required double capitalAportado,
    required int tokensEmitidos,
    required String periodo,
  }) {
    final base   = calcularPrecoBase(capitalAportado, tokensEmitidos);
    final agora  = DateTime.now();
    final pontos = <PrecoSnapshot>[];

    int    qtd;
    Duration intervalo;

    switch (periodo) {
      case 'diario':
        qtd = 24; intervalo = const Duration(hours: 1); break;
      case 'semanal':
        qtd = 7;  intervalo = const Duration(days: 1);  break;
      case 'mensal':
        qtd = 30; intervalo = const Duration(days: 1);  break;
      case '6meses':
        qtd = 26; intervalo = const Duration(days: 7);  break;
      case 'ytd':
        qtd = agora.month; intervalo = const Duration(days: 30); break;
      default:
        qtd = 30; intervalo = const Duration(days: 1);
    }

    double preco = base * 0.85;
    for (int i = qtd; i >= 0; i--) {
      final dt       = agora.subtract(intervalo * i);
      final variacao = ((i * 13 + 7) % 15 - 7) / 100.0;
      preco = (preco * (1 + variacao)).clamp(base * 0.5, base * 2.0);
      pontos.add(PrecoSnapshot(
          data:  dt,
          preco: double.parse(preco.toStringAsFixed(4))));
    }

    // Último ponto = preço base real
    if (pontos.isNotEmpty) {
      pontos.last = PrecoSnapshot(data: agora, preco: base);
    }

    return pontos;
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
      return WalletResult(success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (quantidade <= 0) {
      return WalletResult(success: false, errorMessage: 'Quantidade inválida.');
    }

    final precoAtual = await getPrecoAtual(startupId, capitalAportado, tokensEmitidos);
    final novoPreco  = calcularNovoPreco(
      precoAtual:   precoAtual,
      tipo:         'compra',
      quantidade:   quantidade,
      totalTokens:  tokensEmitidos,
    );
    final total = precoAtual * quantidade;

    try {
      await _db.runTransaction((tx) async {
        // READS primeiro
        final userSnap = await tx.get(_userRef);
        final posSnap  = await tx.get(_positionsRef.doc(startupId));

        final userData   = userSnap.data() as Map<String, dynamic>;
        final saldoAtual = (userData['saldo_carteira'] ?? 0).toDouble();

        if (saldoAtual < total) {
          throw Exception(
              'Saldo insuficiente. Disponível: R\$ ${saldoAtual.toStringAsFixed(2)}');
        }

        double novoPrecoMedio;
        int    novaQtd;

        if (posSnap.exists) {
          final posData    = posSnap.data() as Map<String, dynamic>;
          final qtdAtual   = (posData['quantidade']  ?? 0).toInt();
          final precoMedio = (posData['preco_medio'] ?? 0).toDouble();
          novaQtd        = qtdAtual + quantidade;
          novoPrecoMedio = ((precoMedio * qtdAtual) + (precoAtual * quantidade)) / novaQtd;
        } else {
          novaQtd        = quantidade;
          novoPrecoMedio = precoAtual;
        }

        // WRITES depois
        tx.set(_positionsRef.doc(startupId), {
          'nome_startup':       nomeStartup,
          'quantidade':         novaQtd,
          'preco_medio':        novoPrecoMedio,
          'preco_atual':        novoPreco,
          'ultima_atualizacao': FieldValue.serverTimestamp(),
        });

        tx.update(_userRef, {'saldo_carteira': saldoAtual - total});

        tx.set(_transacoesRef.doc(), {
          'startup_id':     startupId,
          'nome_startup':   nomeStartup,
          'tipo':           'compra',
          'quantidade':     quantidade,
          'preco_unitario': precoAtual,
          'total':          total,
          'data':           FieldValue.serverTimestamp(),
        });
      });

      // Salva histórico fora da transação
      await _salvarHistoricoPreco(startupId, novoPreco);

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
      return WalletResult(success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (quantidade <= 0) {
      return WalletResult(success: false, errorMessage: 'Quantidade inválida.');
    }

    final precoAtual = await getPrecoAtual(startupId, capitalAportado, tokensEmitidos);
    final novoPreco  = calcularNovoPreco(
      precoAtual:  precoAtual,
      tipo:        'venda',
      quantidade:  quantidade,
      totalTokens: tokensEmitidos,
    );
    final total = precoAtual * quantidade;

    try {
      await _db.runTransaction((tx) async {
        // READS primeiro
        final posSnap  = await tx.get(_positionsRef.doc(startupId));
        final userSnap = await tx.get(_userRef);

        if (!posSnap.exists) {
          throw Exception('Você não possui tokens desta startup.');
        }

        final posData  = posSnap.data() as Map<String, dynamic>;
        final qtdAtual = (posData['quantidade'] ?? 0).toInt();

        if (qtdAtual < quantidade) {
          throw Exception('Você possui apenas $qtdAtual tokens disponíveis.');
        }

        final userData   = userSnap.data() as Map<String, dynamic>;
        final saldoAtual = (userData['saldo_carteira'] ?? 0).toDouble();
        final novaQtd    = qtdAtual - quantidade;

        // WRITES depois
        if (novaQtd == 0) {
          tx.delete(_positionsRef.doc(startupId));
        } else {
          tx.update(_positionsRef.doc(startupId), {
            'quantidade':         novaQtd,
            'preco_atual':        novoPreco,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          });
        }

        tx.update(_userRef, {'saldo_carteira': saldoAtual + total});

        tx.set(_transacoesRef.doc(), {
          'startup_id':     startupId,
          'nome_startup':   nomeStartup,
          'tipo':           'venda',
          'quantidade':     quantidade,
          'preco_unitario': precoAtual,
          'total':          total,
          'data':           FieldValue.serverTimestamp(),
        });
      });

      await _salvarHistoricoPreco(startupId, novoPreco);

      return WalletResult(success: true);
    } catch (e) {
      return WalletResult(
          success: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}