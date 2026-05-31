// lib/screens/balcao_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Tela de Balcão — interface específica de negociação de tokens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/startup_model.dart';
import '../services/wallet_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class BalcaoScreen extends StatefulWidget {
  const BalcaoScreen({super.key});

  @override
  State<BalcaoScreen> createState() => _BalcaoScreenState();
}

class _BalcaoScreenState extends State<BalcaoScreen>
    with SingleTickerProviderStateMixin {
  final _walletService    = WalletService();
  final _firestoreService = FirestoreService();
  late TabController _tabCtrl;

  // Filtro de estágio
  String _filtro = 'todos';

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
            _buildSaldoStrip(),
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
                  Tab(text: 'COMPRAR'),
                  Tab(text: 'VENDER'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildListaCompra(),
                  _buildListaVenda(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
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
          const Icon(Icons.storefront_outlined,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balcão de Tokens',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const Text('Negociação Simulada · Mescla',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
          const Spacer(),
          // Badge ao vivo
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
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
                    color: AppTheme.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text('AO VIVO',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Strip de saldo ──────────────────────────────────────────────────────────
  Widget _buildSaldoStrip() {
    return FutureBuilder<double>(
      future: _walletService.getSaldo(),
      builder: (_, snap) {
        final saldo = snap.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
          color: AppTheme.surface,
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Text('Saldo disponível:',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                'R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.shield_outlined,
                  color: AppTheme.textMuted, size: 13),
              const SizedBox(width: 4),
              const Text('Simulado',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  // ── Lista de startups para COMPRAR ─────────────────────────────────────────
  Widget _buildListaCompra() {
    return StreamBuilder<List<StartupModel>>(
      stream: _firestoreService.getStartupsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2),
          );
        }

        final startups = snap.data ?? [];
        if (startups.isEmpty) {
          return _buildEmpty('Nenhuma startup disponível.');
        }

        return Column(
          children: [
            _buildFiltros(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: startups.length,
                itemBuilder: (_, i) => _buildOfertaCard(
                  startup: startups[i],
                  tipo: 'comprar',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Lista de posições para VENDER ──────────────────────────────────────────
  Widget _buildListaVenda() {
    return StreamBuilder(
      stream: _walletService.getPositionsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2),
          );
        }

        final positions = snap.data ?? [];
        if (positions.isEmpty) {
          return _buildEmpty(
              'Você não possui tokens para vender.\nCompre tokens primeiro!');
        }

        return FutureBuilder<List<StartupModel>>(
          future: _firestoreService.getStartupsStream().first,
          builder: (context, startupSnap) {
            final startups = startupSnap.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: positions.length,
              itemBuilder: (_, i) {
                final pos = positions[i];
                // Encontra a startup correspondente
                StartupModel? startup;
                try {
                  startup = startups.firstWhere(
                      (s) => s.id == pos.startupId);
                } catch (_) {}

                return _buildVendaCard(pos, startup);
              },
            );
          },
        );
      },
    );
  }

  // ── Filtros de estágio ──────────────────────────────────────────────────────
  Widget _buildFiltros() {
    final filtros = [
      {'value': 'todos',    'label': 'Todos'},
      {'value': 'nova',     'label': 'Novas'},
      {'value': 'operacao', 'label': 'Operação'},
      {'value': 'expansao', 'label': 'Expansão'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f        = filtros[i];
          final selected = _filtro == f['value'];
          return GestureDetector(
            onTap: () => setState(() => _filtro = f['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(f['label']!,
                  style: TextStyle(
                      color: selected
                          ? AppTheme.background
                          : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }

  // ── Card de oferta de compra ────────────────────────────────────────────────
  Widget _buildOfertaCard({
    required StartupModel startup,
    required String tipo,
  }) {
    final preco = startup.tokensEmitidos > 0
        ? startup.capitalAportado / startup.tokensEmitidos
        : 0.0;

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
          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    startup.nomeStartup.isNotEmpty
                        ? startup.nomeStartup[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.background,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(startup.nomeStartup,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Row(children: [
                      _badgeSmall(startup.setor, AppTheme.accent),
                      const SizedBox(width: 4),
                      _badgeSmall(
                          startup.estagioLabel, _estagioColor(startup)),
                    ]),
                  ],
                ),
              ),
              // Preço
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('R\$ ${preco.toStringAsFixed(4)}',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const Text('por token',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.surfaceLight, height: 1),
          const SizedBox(height: 12),

          // Métricas + Botão
          Row(
            children: [
              _miniInfo('Capital', startup.capitalFormatado),
              const SizedBox(width: 16),
              _miniInfo('Tokens', startup.tokensFormatado),
              const Spacer(),
              GestureDetector(
                onTap: () => _showDialogNegociacao(startup, 'comprar'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.add_rounded,
                        color: AppTheme.background, size: 14),
                    const SizedBox(width: 4),
                    Text('Comprar',
                        style: GoogleFonts.dmSans(
                            color: AppTheme.background,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card de posição para venda ──────────────────────────────────────────────
  Widget _buildVendaCard(dynamic pos, StartupModel? startup) {
    final isPositivo = pos.lucroReais >= 0;
    final cor        = isPositivo ? AppTheme.primary : AppTheme.error;

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
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    pos.nomeStartup.isNotEmpty
                        ? pos.nomeStartup[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.background,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pos.nomeStartup,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('${pos.quantidade} tokens em carteira',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(pos.valorFormatado,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Row(children: [
                    Icon(
                      isPositivo
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: cor, size: 11,
                    ),
                    Text(
                      '${pos.lucroPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: cor,
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

          Row(
            children: [
              _miniInfo('Preço médio',
                  'R\$ ${pos.precoMedio.toStringAsFixed(4)}'),
              const SizedBox(width: 12),
              _miniInfo('Resultado',
                  '${isPositivo ? '+' : ''}R\$ ${pos.lucroReais.toStringAsFixed(2)}',
                  cor: cor),
              const Spacer(),
              if (startup != null)
                GestureDetector(
                  onTap: () => _showDialogNegociacao(startup, 'vender'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.gold.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.remove_rounded,
                          color: AppTheme.gold, size: 14),
                      const SizedBox(width: 4),
                      Text('Vender',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dialog de negociação ────────────────────────────────────────────────────
  void _showDialogNegociacao(StartupModel startup, String tipo) {
    final ctrl     = TextEditingController();
    final isCompra = tipo == 'comprar';
    final color    = isCompra ? AppTheme.primary : AppTheme.gold;
    final preco    = startup.tokensEmitidos > 0
        ? startup.capitalAportado / startup.tokensEmitidos
        : 0.0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final qtd   = int.tryParse(ctrl.text) ?? 0;
          final total = qtd * preco;

          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Icon(
                isCompra
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                color: color, size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCompra
                      ? 'Comprar — ${startup.nomeStartup}'
                      : 'Vender — ${startup.nomeStartup}',
                  style: TextStyle(color: color, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Preço/token:',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12)),
                      Text('R\$ ${preco.toStringAsFixed(4)}',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (_) => setModal(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    suffixText: 'tokens',
                    suffixStyle: TextStyle(
                        color: AppTheme.textSecondary),
                  ),
                ),
                if (qtd > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total a ${isCompra ? 'pagar' : 'receber'}:',
                            style: TextStyle(
                                color: color, fontSize: 12)),
                        Text('R\$ ${total.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(
                        color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: qtd <= 0
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _executarNegociacao(startup, tipo, qtd);
                      },
                child: Text(
                  isCompra ? 'Confirmar Compra' : 'Confirmar Venda',
                  style: TextStyle(
                      color: qtd > 0 ? color : AppTheme.textMuted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executarNegociacao(
      StartupModel startup, String tipo, int qtd) async {
    final result = tipo == 'comprar'
        ? await _walletService.comprarTokens(
            startupId:       startup.id,
            nomeStartup:     startup.nomeStartup,
            quantidade:      qtd,
            capitalAportado: startup.capitalAportado,
            tokensEmitidos:  startup.tokensEmitidos,
          )
        : await _walletService.venderTokens(
            startupId:       startup.id,
            nomeStartup:     startup.nomeStartup,
            quantidade:      qtd,
            capitalAportado: startup.capitalAportado,
            tokensEmitidos:  startup.tokensEmitidos,
          );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? tipo == 'comprar'
              ? '✅ Compra de $qtd tokens realizada!'
              : '✅ Venda de $qtd tokens realizada!'
          : '❌ ${result.errorMessage}'),
      backgroundColor:
          result.success ? AppTheme.surfaceLight : AppTheme.error,
    ));

    // Recarrega saldo
    setState(() {});
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_outlined,
              color: AppTheme.textMuted, size: 52),
          const SizedBox(height: 14),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value, {Color? cor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: cor ?? AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _badgeSmall(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600)),
    );
  }

  Color _estagioColor(StartupModel s) {
    switch (s.estagio.toLowerCase()) {
      case 'expansao':
      case 'em_expansao': return AppTheme.gold;
      case 'operacao':
      case 'em_operacao': return AppTheme.primary;
      default:            return AppTheme.accent;
    }
  }
}