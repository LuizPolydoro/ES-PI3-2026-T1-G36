// lib/services/oferta_service.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Serviço do livro de ordens — criar, listar e executar ofertas

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/oferta_model.dart';

class OfertaResult {
  final bool success;
  final String? errorMessage;
  OfertaResult({required this.success, this.errorMessage});
}

class OfertaService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String? get _uid  => _auth.currentUser?.uid;
  String  get _nome => _auth.currentUser?.displayName ?? 'Usuário';

  CollectionReference get _ofertas => _db.collection('ofertas');
  CollectionReference get _users   => _db.collection('users');

  // ── Stream de todas as ofertas abertas ─────────────────────────────────────
  Stream<List<OfertaModel>> getOfertasAbertas({String? startupId}) {
    Query query = _ofertas.where('status', isEqualTo: 'aberta');
    if (startupId != null) {
      query = query.where('startup_id', isEqualTo: startupId);
    }
    return query
        .orderBy('preco_unitario')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OfertaModel.fromFirestore(d))
            .toList());
  }

  // ── Stream das minhas ofertas abertas ──────────────────────────────────────
  Stream<List<OfertaModel>> getMinhasOfertas() {
    if (_uid == null) return const Stream.empty();
    return _ofertas
        .where('vendedor_uid', isEqualTo: _uid)
        .where('status', isEqualTo: 'aberta')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OfertaModel.fromFirestore(d))
            .toList());
  }

  // ── Busca nome do usuário no Firestore ─────────────────────────────────────
  Future<String> _getNomeUsuario(String uid) async {
    try {
      final doc  = await _users.doc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['nome'] as String? ?? 'Usuário';
    } catch (_) {
      return 'Usuário';
    }
  }

  // ── CRIAR OFERTA DE VENDA ──────────────────────────────────────────────────
  Future<OfertaResult> criarOferta({
    required String startupId,
    required String startupNome,
    required int quantidade,
    required double precoUnitario,
  }) async {
    if (_uid == null) {
      return OfertaResult(
          success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (quantidade <= 0) {
      return OfertaResult(
          success: false, errorMessage: 'Quantidade inválida.');
    }
    if (precoUnitario <= 0) {
      return OfertaResult(
          success: false, errorMessage: 'Preço inválido.');
    }

    try {
      // Verifica se tem tokens suficientes
      final posDoc = await _users
          .doc(_uid)
          .collection('positions')
          .doc(startupId)
          .get();

      if (!posDoc.exists) {
        return OfertaResult(
            success: false,
            errorMessage: 'Você não possui tokens desta startup.');
      }

      final posData  = posDoc.data() as Map<String, dynamic>;
      final qtdAtual = (posData['quantidade'] ?? 0).toInt();

      // Verifica quantos tokens já estão em ofertas abertas
      final ofertasAbertas = await _ofertas
          .where('vendedor_uid', isEqualTo: _uid)
          .where('startup_id', isEqualTo: startupId)
          .where('status', isEqualTo: 'aberta')
          .get();

      final emOferta = ofertasAbertas.docs.fold<int>(0, (sum, d) {
        final data = d.data() as Map<String, dynamic>;
        return sum + (data['quantidade_restante'] as int? ?? 0);
      });

      final disponivel = qtdAtual - emOferta;

      if (disponivel < quantidade) {
        return OfertaResult(
            success: false,
            errorMessage:
                'Tokens disponíveis: $disponivel (${emOferta > 0 ? '$emOferta em outras ofertas' : ''})');
      }

      final nomeVendedor = await _getNomeUsuario(_uid!);

      // Cria a oferta
      await _ofertas.add({
        'startup_id':          startupId,
        'startup_nome':        startupNome,
        'vendedor_uid':        _uid,
        'vendedor_nome':       nomeVendedor,
        'quantidade':          quantidade,
        'quantidade_restante': quantidade,
        'preco_unitario':      precoUnitario,
        'status':              'aberta',
        'data':                FieldValue.serverTimestamp(),
      });

      return OfertaResult(success: true);
    } catch (e) {
      return OfertaResult(
          success: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── ACEITAR OFERTA (COMPRAR DO USUÁRIO) ────────────────────────────────────
  Future<OfertaResult> aceitarOferta({
    required OfertaModel oferta,
    required int quantidade,
  }) async {
    if (_uid == null) {
      return OfertaResult(
          success: false, errorMessage: 'Usuário não autenticado.');
    }
    if (_uid == oferta.vendedorUid) {
      return OfertaResult(
          success: false,
          errorMessage: 'Você não pode comprar sua própria oferta.');
    }
    if (quantidade <= 0 || quantidade > oferta.quantidadeRestante) {
      return OfertaResult(
          success: false,
          errorMessage:
              'Quantidade inválida. Disponível: ${oferta.quantidadeRestante}');
    }

    final total         = oferta.precoUnitario * quantidade;
    final ofertaRef     = _ofertas.doc(oferta.id);
    final compradorRef  = _users.doc(_uid);
    final vendedorRef   = _users.doc(oferta.vendedorUid);
    final posCompradorRef = compradorRef
        .collection('positions')
        .doc(oferta.startupId);
    final posVendedorRef  = vendedorRef
        .collection('positions')
        .doc(oferta.startupId);

    try {
      await _db.runTransaction((tx) async {
        // ── READS primeiro ──────────────────────────────────────────────────
        final ofertaSnap     = await tx.get(ofertaRef);
        final compradorSnap  = await tx.get(compradorRef);
        final vendedorSnap   = await tx.get(vendedorRef);
        final posCompSnap    = await tx.get(posCompradorRef);
        final posVendSnap    = await tx.get(posVendedorRef);

        // ── Validações ──────────────────────────────────────────────────────
        if (!ofertaSnap.exists) {
          throw Exception('Oferta não encontrada.');
        }

        final ofertaData = ofertaSnap.data() as Map<String, dynamic>;
        if (ofertaData['status'] != 'aberta') {
          throw Exception('Esta oferta não está mais disponível.');
        }

        final qtdRestante = (ofertaData['quantidade_restante'] ?? 0).toInt();
        if (quantidade > qtdRestante) {
          throw Exception('Quantidade indisponível. Restante: $qtdRestante');
        }

        final compradorData  = compradorSnap.data() as Map<String, dynamic>;
        final saldoComprador = (compradorData['saldo_carteira'] ?? 0).toDouble();

        if (saldoComprador < total) {
          throw Exception(
              'Saldo insuficiente. Disponível: R\$ ${saldoComprador.toStringAsFixed(2)}');
        }

        final vendedorData  = vendedorSnap.data() as Map<String, dynamic>;
        final saldoVendedor = (vendedorData['saldo_carteira'] ?? 0).toDouble();

        // Posição vendedor
        final qtdVendedor = posVendSnap.exists
            ? (posVendSnap.data() as Map<String, dynamic>)['quantidade'] as int? ?? 0
            : 0;

        if (qtdVendedor < quantidade) {
          throw Exception('Vendedor não possui tokens suficientes.');
        }

        // ── WRITES depois ───────────────────────────────────────────────────
        final novaQtdRestante = qtdRestante - quantidade;

        // Atualiza oferta
        if (novaQtdRestante == 0) {
          tx.update(ofertaRef, {
            'status':              'executada',
            'quantidade_restante': 0,
          });
        } else {
          tx.update(ofertaRef, {
            'quantidade_restante': novaQtdRestante,
          });
        }

        // Debita saldo do comprador
        tx.update(compradorRef, {
          'saldo_carteira': saldoComprador - total,
        });

        // Credita saldo do vendedor
        tx.update(vendedorRef, {
          'saldo_carteira': saldoVendedor + total,
        });

        // Atualiza posição do vendedor
        final novaQtdVendedor = qtdVendedor - quantidade;
        if (novaQtdVendedor == 0) {
          tx.delete(posVendedorRef);
        } else {
          tx.update(posVendedorRef, {'quantidade': novaQtdVendedor});
        }

        // Atualiza/cria posição do comprador
        if (posCompSnap.exists) {
          final posCompData   = posCompSnap.data() as Map<String, dynamic>;
          final qtdComp       = (posCompData['quantidade']  ?? 0).toInt();
          final precoMedComp  = (posCompData['preco_medio'] ?? 0).toDouble();
          final novaQtd       = qtdComp + quantidade;
          final novoPrecoMed  =
              ((precoMedComp * qtdComp) + (oferta.precoUnitario * quantidade)) /
                  novaQtd;
          tx.update(posCompradorRef, {
            'quantidade':  novaQtd,
            'preco_medio': novoPrecoMed,
            'preco_atual': oferta.precoUnitario,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(posCompradorRef, {
            'nome_startup':       oferta.startupNome,
            'quantidade':         quantidade,
            'preco_medio':        oferta.precoUnitario,
            'preco_atual':        oferta.precoUnitario,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          });
        }

        // Registra transação do comprador
        tx.set(
          compradorRef.collection('transacoes').doc(),
          {
            'startup_id':     oferta.startupId,
            'nome_startup':   oferta.startupNome,
            'tipo':           'compra',
            'origem':         'balcao',
            'vendedor_uid':   oferta.vendedorUid,
            'vendedor_nome':  oferta.vendedorNome,
            'quantidade':     quantidade,
            'preco_unitario': oferta.precoUnitario,
            'total':          total,
            'data':           FieldValue.serverTimestamp(),
          },
        );

        // Registra transação do vendedor
        tx.set(
          vendedorRef.collection('transacoes').doc(),
          {
            'startup_id':     oferta.startupId,
            'nome_startup':   oferta.startupNome,
            'tipo':           'venda',
            'origem':         'balcao',
            'comprador_uid':  _uid,
            'quantidade':     quantidade,
            'preco_unitario': oferta.precoUnitario,
            'total':          total,
            'data':           FieldValue.serverTimestamp(),
          },
        );
      });

      return OfertaResult(success: true);
    } catch (e) {
      return OfertaResult(
          success: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── CANCELAR OFERTA ────────────────────────────────────────────────────────
  Future<OfertaResult> cancelarOferta(String ofertaId) async {
    try {
      await _ofertas.doc(ofertaId).update({'status': 'cancelada'});
      return OfertaResult(success: true);
    } catch (e) {
      return OfertaResult(
          success: false,
          errorMessage: 'Erro ao cancelar oferta.');
    }
  }
}