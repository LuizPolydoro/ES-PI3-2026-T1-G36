// lib/models/oferta_model.dart
// Autor: [Seu Nome Completo]
// RA: [Seu RA]
// Model de oferta de venda no balcão — livro de ordens

import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusOferta { aberta, executada, cancelada }

class OfertaModel {
  final String id;
  final String startupId;
  final String startupNome;
  final String vendedorUid;
  final String vendedorNome;
  final int quantidade;
  final int quantidadeRestante;
  final double precoUnitario;
  final StatusOferta status;
  final DateTime? data;

  OfertaModel({
    required this.id,
    required this.startupId,
    required this.startupNome,
    required this.vendedorUid,
    required this.vendedorNome,
    required this.quantidade,
    required this.quantidadeRestante,
    required this.precoUnitario,
    required this.status,
    this.data,
  });

  factory OfertaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    StatusOferta status;
    switch (d['status'] as String? ?? 'aberta') {
      case 'executada':  status = StatusOferta.executada;  break;
      case 'cancelada':  status = StatusOferta.cancelada;  break;
      default:           status = StatusOferta.aberta;
    }
    return OfertaModel(
      id:                 doc.id,
      startupId:          d['startup_id']          ?? '',
      startupNome:        d['startup_nome']         ?? '',
      vendedorUid:        d['vendedor_uid']         ?? '',
      vendedorNome:       d['vendedor_nome']        ?? '',
      quantidade:         (d['quantidade']          ?? 0).toInt(),
      quantidadeRestante: (d['quantidade_restante'] ?? 0).toInt(),
      precoUnitario:      (d['preco_unitario']      ?? 0).toDouble(),
      status:             status,
      data:               (d['data'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'startup_id':          startupId,
    'startup_nome':        startupNome,
    'vendedor_uid':        vendedorUid,
    'vendedor_nome':       vendedorNome,
    'quantidade':          quantidade,
    'quantidade_restante': quantidadeRestante,
    'preco_unitario':      precoUnitario,
    'status':              status.name,
    'data':                FieldValue.serverTimestamp(),
  };

  double get totalFormatado => quantidadeRestante * precoUnitario;

  String get dataFormatada {
    if (data == null) return '—';
    return '${data!.day.toString().padLeft(2,'0')}/'
        '${data!.month.toString().padLeft(2,'0')}/'
        '${data!.year}  '
        '${data!.hour.toString().padLeft(2,'0')}:'
        '${data!.minute.toString().padLeft(2,'0')}';
  }
}