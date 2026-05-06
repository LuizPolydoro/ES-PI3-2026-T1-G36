// lib/models/startup_model.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Model que representa uma Startup - espelha exatamente a collection "startups" do Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

class StartupModel {
  final String id;
  final String nomeStartup;
  final String descricao;
  final String sumarioExecutivo; // ← campo novo
  final String estagio;
  final String setor;
  final double capitalAportado;
  final int tokensEmitidos;
  final String status;
  final String socios;
  final String participacaoSocietaria;
  final String mentoresConselho;
  final String videoDemo;

  StartupModel({
    required this.id,
    required this.nomeStartup,
    required this.descricao,
    required this.sumarioExecutivo,
    required this.estagio,
    required this.setor,
    required this.capitalAportado,
    required this.tokensEmitidos,
    required this.status,
    required this.socios,
    required this.participacaoSocietaria,
    required this.mentoresConselho,
    required this.videoDemo,
  });

  factory StartupModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StartupModel(
      id:                     doc.id,
      nomeStartup:            d['nome_startup']             ?? '',
      descricao:              d['descricao']                ?? '',
      sumarioExecutivo:       d['sumario_executivo']        ?? '',
      estagio:                d['estagio']                  ?? '',
      setor:                  d['setor']                    ?? '',
      capitalAportado:        (d['capital_aportado'] ?? 0).toDouble(),
      tokensEmitidos:         (d['tokens_emitidos']  ?? 0).toInt(),
      status:                 d['status']                   ?? '',
      socios:                 d['socios']                   ?? '',
      participacaoSocietaria: d['participacao_societaria']  ?? '',
      mentoresConselho:       d['mentores_conselho']         ?? '',
      videoDemo:              d['video_demo']                ?? '',
    );
  }

  // Label legível do estágio
  String get estagioLabel {
    switch (estagio.toLowerCase()) {
      case 'em_expansao':
      case 'expansao':   return 'Em Expansão';
      case 'em_operacao':
      case 'operacao':   return 'Em Operação';
      case 'nova':       return 'Nova';
      default:           return estagio;
    }
  }

  // Capital formatado em K / M
  String get capitalFormatado {
    if (capitalAportado >= 1000000) {
      return 'R\$ ${(capitalAportado / 1000000).toStringAsFixed(1)}M';
    } else if (capitalAportado >= 1000) {
      return 'R\$ ${(capitalAportado / 1000).toStringAsFixed(0)}K';
    }
    return 'R\$ ${capitalAportado.toStringAsFixed(0)}';
  }

  // Tokens formatado em K / M
  String get tokensFormatado {
    if (tokensEmitidos >= 1000000) {
      return '${(tokensEmitidos / 1000000).toStringAsFixed(1)}M';
    } else if (tokensEmitidos >= 1000) {
      return '${(tokensEmitidos / 1000).toStringAsFixed(0)}K';
    }
    return tokensEmitidos.toString();
  }
}