// lib/models/wallet_model.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Model da carteira do usuário e de posições em tokens

import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa uma posição do usuário em tokens de uma startup
class TokenPosition {
  final String startupId;
  final String nomeStartup;
  final int quantidade;
  final double precoMedio;       // preço médio de compra por token
  final double precoAtual;       // preço atual simulado
  final DateTime? ultimaAtualizacao;

  TokenPosition({
    required this.startupId,
    required this.nomeStartup,
    required this.quantidade,
    required this.precoMedio,
    required this.precoAtual,
    this.ultimaAtualizacao,
  });

  factory TokenPosition.fromMap(String startupId, Map<String, dynamic> data) {
    return TokenPosition(
      startupId:  startupId,
      nomeStartup: data['nome_startup'] ?? '',
      quantidade:  (data['quantidade']  ?? 0).toInt(),
      precoMedio:  (data['preco_medio'] ?? 0).toDouble(),
      precoAtual:  (data['preco_atual'] ?? 0).toDouble(),
      ultimaAtualizacao: (data['ultima_atualizacao'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nome_startup':        nomeStartup,
    'quantidade':          quantidade,
    'preco_medio':         precoMedio,
    'preco_atual':         precoAtual,
    'ultima_atualizacao':  FieldValue.serverTimestamp(),
  };

  // Valor total da posição
  double get valorTotal => quantidade * precoAtual;

  // Lucro/Prejuízo em reais
  double get lucroReais => (precoAtual - precoMedio) * quantidade;

  // Lucro/Prejuízo em %
  double get lucroPercent => precoMedio > 0
      ? ((precoAtual - precoMedio) / precoMedio) * 100
      : 0;

  String get valorFormatado {
    final v = valorTotal;
    if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'R\$ ${(v / 1000).toStringAsFixed(0)}K';
    return 'R\$ ${v.toStringAsFixed(2)}';
  }
}

/// Representa uma transação registrada no Firestore
class Transacao {
  final String id;
  final String startupId;
  final String nomeStartup;
  final String tipo;          // 'compra' | 'venda'
  final int quantidade;
  final double precoUnitario;
  final double total;
  final DateTime? data;

  Transacao({
    required this.id,
    required this.startupId,
    required this.nomeStartup,
    required this.tipo,
    required this.quantidade,
    required this.precoUnitario,
    required this.total,
    this.data,
  });

  factory Transacao.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Transacao(
      id:             doc.id,
      startupId:      d['startup_id']    ?? '',
      nomeStartup:    d['nome_startup']  ?? '',
      tipo:           d['tipo']          ?? '',
      quantidade:     (d['quantidade']   ?? 0).toInt(),
      precoUnitario:  (d['preco_unitario'] ?? 0).toDouble(),
      total:          (d['total']        ?? 0).toDouble(),
      data:           (d['data'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'startup_id':      startupId,
    'nome_startup':    nomeStartup,
    'tipo':            tipo,
    'quantidade':      quantidade,
    'preco_unitario':  precoUnitario,
    'total':           total,
    'data':            FieldValue.serverTimestamp(),
  };

  String get totalFormatado =>
      'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';

  String get dataFormatada {
    if (data == null) return '—';
    return '${data!.day.toString().padLeft(2,'0')}/'
        '${data!.month.toString().padLeft(2,'0')}/'
        '${data!.year}';
  }
}