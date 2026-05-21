// lib/screens/carteira_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Tela de Carteira — saldo, posições em tokens e histórico de transações

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wallet_model.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';

class CarteiraScreen extends StatefulWidget {
  const CarteiraScreen({super.key});

  @override
  State<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends State<CarteiraScreen>
    with SingleTickerProviderStateMixin {
  final _walletService = WalletService();
  final _authService   = AuthService();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSaldoBanner(),
            Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2,
                labelStyle: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'MEUS TOKENS'),
                  Tab(text: 'HISTÓRICO'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildPosicoes(),
                  _buildHistorico(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Text('Minha Carteira',
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Banner de saldo ─────────────────────────────────────────────────────────
  Widget _buildSaldoBanner() {
    return FutureBuilder<double>(
      future: _walletService.getSaldo(),
      builder: (context, snapshot) {
        final saldo = snapshot.data ?? 0.0;
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D2137), Color(0xFF091929)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saldo Disponível',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('SIMULADO',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.surfaceLight),
              const SizedBox(height: 12),

              // Stream de posições para calcular total investido
              StreamBuilder<List<TokenPosition>>(
                stream: _walletService.getPositionsStream(),
                builder: (context, snap) {
                  final positions = snap.data ?? [];
                  final totalInvestido = positions.fold(
                      0.0, (sum, p) => sum + p.valorTotal);
                  final totalPosicoes = positions.length;

                  return Row(
                    children: [
                      Expanded(child: _bannerMetric(
                        'Total Investido',
                        'R\$ ${totalInvestido.toStringAsFixed(2)}',
                        Icons.trending_up_rounded,
                        AppTheme.gold,
                      )),
                      Container(width: 1, height: 36,
                          color: AppTheme.surfaceLight),
                      Expanded(child: _bannerMetric(
                        'Startups',
                        '$totalPosicoes',
                        Icons.rocket_launch_outlined,
                        AppTheme.accent,
                      )),
                      Container(width: 1, height: 36,
                          color: AppTheme.surfaceLight),
                      Expanded(child: _bannerMetric(
                        'Patrimônio',
                        'R\$ ${(saldo + totalInvestido).toStringAsFixed(0)}',
                        Icons.account_balance_outlined,
                        AppTheme.primary,
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bannerMetric(
      String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 5),
      Text(value,
          style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
          textAlign: TextAlign.center),
    ]);
  }

  // ── Tab 1: Posições em tokens ───────────────────────────────────────────────
  Widget _buildPosicoes() {
    return StreamBuilder<List<TokenPosition>>(
      stream: _walletService.getPositionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2),
          );
        }

        final positions = snapshot.data ?? [];

        if (positions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.token_outlined,
                    color: AppTheme.textMuted, size: 52),
                const SizedBox(height: 14),
                Text('Nenhum token adquirido ainda.',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textSecondary, fontSize: 15)),
                const SizedBox(height: 6),
                const Text('Explore as startups e faça sua primeira compra!',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: positions.length,
          itemBuilder: (_, i) => _buildPositionCard(positions[i]),
        );
      },
    );
  }

  Widget _buildPositionCard(TokenPosition p) {
    final isPositivo = p.lucroReais >= 0;
    final corLucro = isPositivo ? AppTheme.primary : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    p.nomeStartup.isNotEmpty
                        ? p.nomeStartup[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.background,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nomeStartup,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text('${p.quantidade} tokens',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              // Valor total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(p.valorFormatado,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Row(children: [
                    Icon(
                      isPositivo
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: corLucro, size: 12,
                    ),
                    Text(
                      '${p.lucroPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: corLucro,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.surfaceLight, height: 1),
          const SizedBox(height: 12),

          // Detalhes
          Row(
            children: [
              Expanded(child: _positionDetail(
                  'Preço médio',
                  'R\$ ${p.precoMedio.toStringAsFixed(4)}')),
              Expanded(child: _positionDetail(
                  'Preço atual',
                  'R\$ ${p.precoAtual.toStringAsFixed(4)}')),
              Expanded(child: _positionDetail(
                  'Resultado',
                  '${isPositivo ? '+' : ''}R\$ ${p.lucroReais.toStringAsFixed(2)}',
                  cor: corLucro)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _positionDetail(String label, String value, {Color? cor}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10),
            textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                color: cor ?? AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Tab 2: Histórico de transações ─────────────────────────────────────────
  Widget _buildHistorico() {
    return StreamBuilder<List<Transacao>>(
      stream: _walletService.getTransacoesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2),
          );
        }

        final transacoes = snapshot.data ?? [];

        if (transacoes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: AppTheme.textMuted, size: 52),
                const SizedBox(height: 14),
                Text('Nenhuma transação ainda.',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: transacoes.length,
          itemBuilder: (_, i) => _buildTransacaoCard(transacoes[i]),
        );
      },
    );
  }

  Widget _buildTransacaoCard(Transacao t) {
    final isCompra = t.tipo == 'compra';
    final cor = isCompra ? AppTheme.primary : AppTheme.gold;
    final icone = isCompra
        ? Icons.add_circle_outline_rounded
        : Icons.remove_circle_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isCompra ? 'Compra' : 'Venda'} — ${t.nomeStartup}',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  '${t.quantidade} tokens · R\$ ${t.precoUnitario.toStringAsFixed(4)}/token',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(t.dataFormatada,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Text(
            '${isCompra ? '-' : '+'}${t.totalFormatado}',
            style: TextStyle(
                color: cor,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}