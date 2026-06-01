// lib/screens/balcao_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Balcão de negociação — livro de ordens entre usuários

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/oferta_model.dart';
import '../models/startup_model.dart';
import '../services/oferta_service.dart';
import '../services/wallet_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class BalcaoScreen extends StatefulWidget {
  final StartupModel? startupFiltro; // se vier da tela de startup
  const BalcaoScreen({super.key, this.startupFiltro});

  @override
  State<BalcaoScreen> createState() => _BalcaoScreenState();
}

class _BalcaoScreenState extends State<BalcaoScreen>
    with SingleTickerProviderStateMixin {
  final _ofertaService    = OfertaService();
  final _walletService    = WalletService();
  final _firestoreService = FirestoreService();

  late TabController _tabCtrl;
  StartupModel? _startupSelecionada;
  List<StartupModel> _startups = [];
  double _saldoAtual = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _startupSelecionada = widget.startupFiltro;
    _carregarDados();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final startups = await _firestoreService.getStartupsStream().first;
    final saldo    = await _walletService.getSaldo();
    if (mounted) {
      setState(() {
        _startups   = startups;
        _saldoAtual = saldo;
        _startupSelecionada ??= startups.isNotEmpty ? startups.first : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildInfoStrip(),
            // Seletor de startup
            if (_startups.isNotEmpty) _buildStartupSelector(),
            // Tabs
            Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2,
                labelStyle: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'OFERTAS'),
                  Tab(text: 'VENDER'),
                  Tab(text: 'MINHAS OFERTAS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildOfertasAbertas(),
                  _buildCriarOferta(),
                  _buildMinhasOfertas(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balcão de Negociação',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Text('Compre e venda tokens entre investidores',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
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
  Widget _buildInfoStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppTheme.primary, size: 15),
          const SizedBox(width: 6),
          Text('Saldo: ',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          Text(
            'R\$ ${_saldoAtual.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const Icon(Icons.info_outline,
              color: AppTheme.textMuted, size: 13),
          const SizedBox(width: 4),
          const Text('Simulado',
              style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  // ── Seletor de startup ──────────────────────────────────────────────────────
  Widget _buildStartupSelector() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _startups.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s        = _startups[i];
            final selected = _startupSelecionada?.id == s.id;
            return GestureDetector(
              onTap: () => setState(() => _startupSelecionada = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  if (selected)
                    const Icon(Icons.circle, color: AppTheme.background, size: 7),
                  if (selected) const SizedBox(width: 5),
                  Text(s.nomeStartup,
                      style: TextStyle(
                          color: selected
                              ? AppTheme.background
                              : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — OFERTAS ABERTAS (livro de ordens)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOfertasAbertas() {
    if (_startupSelecionada == null) {
      return const Center(
        child: Text('Selecione uma startup acima.',
            style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return StreamBuilder<List<OfertaModel>>(
      stream: _ofertaService.getOfertasAbertas(
          startupId: _startupSelecionada!.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2),
          );
        }

        final ofertas = snap.data ?? [];
        final uid     = FirebaseAuth.instance.currentUser?.uid ?? '';

        // Separa: minhas ofertas e de outros
        final outrasOfertas = ofertas
            .where((o) => o.vendedorUid != uid)
            .toList();
        final minhasNaLista = ofertas
            .where((o) => o.vendedorUid == uid)
            .toList();

        if (ofertas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined,
                    color: AppTheme.textMuted, size: 52),
                const SizedBox(height: 14),
                Text(
                  'Nenhuma oferta aberta para\n${_startupSelecionada!.nomeStartup}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vá em "Vender" para criar a primeira oferta!',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Cabeçalho do livro de ordens
            _buildLivroHeader(_startupSelecionada!),
            const SizedBox(height: 12),

            if (outrasOfertas.isNotEmpty) ...[
              _buildSectionLabel('Ofertas Disponíveis',
                  Icons.shopping_cart_outlined, AppTheme.primary),
              const SizedBox(height: 8),
              ...outrasOfertas.map((o) => _buildOfertaCard(o, podeComprar: true)),
              const SizedBox(height: 16),
            ],

            if (minhasNaLista.isNotEmpty) ...[
              _buildSectionLabel('Minhas Ofertas no Balcão',
                  Icons.person_outline, AppTheme.gold),
              const SizedBox(height: 8),
              ...minhasNaLista.map((o) => _buildOfertaCard(o, podeComprar: false)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLivroHeader(StartupModel s) {
    final preco = s.tokensEmitidos > 0
        ? s.capitalAportado / s.tokensEmitidos
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF091929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                s.nomeStartup[0].toUpperCase(),
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
                Text(s.nomeStartup,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(s.setor,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('R\$ ${preco.toStringAsFixed(4)}',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Text('preço base',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, Color cor) {
    return Row(children: [
      Icon(icon, color: cor, size: 14),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildOfertaCard(OfertaModel oferta, {required bool podeComprar}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: podeComprar
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.gold.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Info da oferta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    podeComprar
                        ? Icons.person_outline
                        : Icons.person_rounded,
                    color: podeComprar
                        ? AppTheme.textSecondary
                        : AppTheme.gold,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    podeComprar
                        ? oferta.vendedorNome
                        : 'Minha oferta',
                    style: TextStyle(
                        color: podeComprar
                            ? AppTheme.textSecondary
                            : AppTheme.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Quantidade
                    _ofertaInfo(
                      '${oferta.quantidadeRestante} tokens',
                      Icons.token_outlined,
                      AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 16),
                    // Preço
                    _ofertaInfo(
                      'R\$ ${oferta.precoUnitario.toStringAsFixed(4)}',
                      Icons.monetization_on_outlined,
                      AppTheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(oferta.dataFormatada,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 9)),
              ],
            ),
          ),

          // Botão ação
          if (podeComprar)
            GestureDetector(
              onTap: () => _showDialogComprarOferta(oferta),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
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
                child: Text('Comprar',
                    style: GoogleFonts.dmSans(
                        color: AppTheme.background,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            )
          else
            GestureDetector(
              onTap: () => _cancelarOferta(oferta),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Text('Cancelar',
                    style: GoogleFonts.dmSans(
                        color: AppTheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ofertaInfo(String value, IconData icon, Color cor) {
    return Row(children: [
      Icon(icon, color: cor, size: 12),
      const SizedBox(width: 4),
      Text(value,
          style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — CRIAR OFERTA DE VENDA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCriarOferta() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: AppTheme.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coloque seus tokens à venda no balcão. Outros investidores poderão comprar diretamente de você pelo preço que definir.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Seleciona startup
          Text('Startup',
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          if (_startupSelecionada != null)
            _buildStartupSelecionadaCard(_startupSelecionada!),

          const SizedBox(height: 20),

          // Formulário
          _buildFormOferta(),
        ],
      ),
    );
  }

  Widget _buildStartupSelecionadaCard(StartupModel s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                s.nomeStartup[0].toUpperCase(),
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
                Text(s.nomeStartup,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                  'Preço base: R\$ ${s.tokensEmitidos > 0 ? (s.capitalAportado / s.tokensEmitidos).toStringAsFixed(4) : "—"}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _tabCtrl.animateTo(0),
            child: const Text('Trocar',
                style: TextStyle(
                    color: AppTheme.primary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormOferta() {
    final qtdCtrl   = TextEditingController();
    final precoCtrl = TextEditingController();

    // Pre-preenche preço sugerido
    if (_startupSelecionada != null &&
        _startupSelecionada!.tokensEmitidos > 0) {
      final precoBase = _startupSelecionada!.capitalAportado /
          _startupSelecionada!.tokensEmitidos;
      precoCtrl.text = precoBase.toStringAsFixed(4);
    }

    return StatefulBuilder(
      builder: (ctx, setForm) {
        final qtd   = int.tryParse(qtdCtrl.text)    ?? 0;
        final preco = double.tryParse(precoCtrl.text) ?? 0;
        final total = qtd * preco;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quantidade
            Text('Quantidade de tokens',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: qtdCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              onChanged: (_) => setForm(() {}),
              decoration: InputDecoration(
                hintText: 'Ex: 100',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                suffixText: 'tokens',
                suffixStyle: const TextStyle(
                    color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Preço
            Text('Preço por token (R\$)',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: precoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              onChanged: (_) => setForm(() {}),
              decoration: InputDecoration(
                hintText: 'Ex: 3.5000',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixText: 'R\$ ',
                prefixStyle: const TextStyle(
                    color: AppTheme.primary),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Total estimado
            if (qtd > 0 && preco > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.gold.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Você receberá',
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11)),
                        Text('R\$ ${total.toStringAsFixed(2)}',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.gold,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Tokens à venda',
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11)),
                        Text('$qtd',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Botão publicar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: qtd > 0 && preco > 0
                      ? AppTheme.primaryGradient
                      : const LinearGradient(
                          colors: [AppTheme.textMuted, AppTheme.textMuted]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: qtd <= 0 || preco <= 0 || _startupSelecionada == null
                      ? null
                      : () => _publicarOferta(qtdCtrl, precoCtrl, setForm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.storefront_outlined,
                      color: AppTheme.background, size: 18),
                  label: Text('Publicar Oferta no Balcão',
                      style: GoogleFonts.dmSans(
                          color: AppTheme.background,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — MINHAS OFERTAS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMinhasOfertas() {
    return StreamBuilder<List<OfertaModel>>(
      stream: _ofertaService.getMinhasOfertas(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2),
          );
        }

        final ofertas = snap.data ?? [];
        if (ofertas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sell_outlined,
                    color: AppTheme.textMuted, size: 52),
                const SizedBox(height: 14),
                const Text('Você não tem ofertas abertas.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 6),
                const Text('Vá em "Vender" para criar uma oferta!',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: ofertas.length,
          itemBuilder: (_, i) => _buildMinhaOfertaCard(ofertas[i]),
        );
      },
    );
  }

  Widget _buildMinhaOfertaCard(OfertaModel o) {
    final total = o.quantidadeRestante * o.precoUnitario;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    o.startupNome.isNotEmpty
                        ? o.startupNome[0].toUpperCase()
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
                    Text(o.startupNome,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text(o.dataFormatada,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              // Badge status
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ABERTA',
                    style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.surfaceLight, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip('${o.quantidadeRestante}/${o.quantidade} tokens',
                  Icons.token_outlined, AppTheme.textPrimary),
              const SizedBox(width: 12),
              _infoChip('R\$ ${o.precoUnitario.toStringAsFixed(4)}/un',
                  Icons.monetization_on_outlined, AppTheme.primary),
              const Spacer(),
              GestureDetector(
                onTap: () => _cancelarOferta(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Text('Cancelar',
                      style: GoogleFonts.dmSans(
                          color: AppTheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progresso da oferta
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: o.quantidadeRestante / o.quantidade,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.gold),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Valor: R\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoChip(String label, IconData icon, Color cor) {
    return Row(children: [
      Icon(icon, color: cor, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: cor,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    ]);
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────
  void _showDialogComprarOferta(OfertaModel oferta) {
    final ctrl = TextEditingController(
        text: oferta.quantidadeRestante.toString());

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final qtd   = int.tryParse(ctrl.text) ?? 0;
          final total = qtd * oferta.precoUnitario;

          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.shopping_cart_outlined,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Comprar do Balcão',
                  style: TextStyle(
                      color: AppTheme.primary, fontSize: 15)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info do vendedor
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Vendedor:',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11)),
                          Text(oferta.vendedorNome,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Startup:',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11)),
                          Text(oferta.startupNome,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Preço/token:',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11)),
                          Text(
                            'R\$ ${oferta.precoUnitario.toStringAsFixed(4)}',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Disponível:',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11)),
                          Text('${oferta.quantidadeRestante} tokens',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (_) => setModal(() {}),
                  decoration: InputDecoration(
                    labelText: 'Quantidade a comprar',
                    suffixText: 'tokens',
                    helperText:
                        'Máx: ${oferta.quantidadeRestante}',
                    helperStyle: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10),
                  ),
                ),
                if (qtd > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total a pagar:',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12)),
                        Text('R\$ ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 15,
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
                onPressed: qtd <= 0 ||
                        qtd > oferta.quantidadeRestante
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _aceitarOferta(oferta, qtd);
                      },
                child: Text(
                  'Confirmar Compra',
                  style: TextStyle(
                      color: qtd > 0 &&
                              qtd <= oferta.quantidadeRestante
                          ? AppTheme.primary
                          : AppTheme.textMuted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Ações ────────────────────────────────────────────────────────────────────
  Future<void> _publicarOferta(TextEditingController qtdCtrl,
      TextEditingController precoCtrl, StateSetter setForm) async {
    final qtd   = int.tryParse(qtdCtrl.text)    ?? 0;
    final preco = double.tryParse(precoCtrl.text) ?? 0;

    final result = await _ofertaService.criarOferta(
      startupId:     _startupSelecionada!.id,
      startupNome:   _startupSelecionada!.nomeStartup,
      quantidade:    qtd,
      precoUnitario: preco,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? '✅ Oferta publicada no balcão!'
          : '❌ ${result.errorMessage}'),
      backgroundColor:
          result.success ? AppTheme.surfaceLight : AppTheme.error,
    ));

    if (result.success) {
      qtdCtrl.clear();
      setForm(() {});
      _tabCtrl.animateTo(2); // vai para "Minhas Ofertas"
    }
  }

  Future<void> _aceitarOferta(OfertaModel oferta, int qtd) async {
    final result = await _ofertaService.aceitarOferta(
        oferta: oferta, quantidade: qtd);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? '✅ Compra realizada! $qtd tokens adquiridos de ${oferta.vendedorNome}'
          : '❌ ${result.errorMessage}'),
      backgroundColor:
          result.success ? AppTheme.surfaceLight : AppTheme.error,
    ));

    if (result.success) {
      final saldo = await _walletService.getSaldo();
      if (mounted) setState(() => _saldoAtual = saldo);
    }
  }

  Future<void> _cancelarOferta(OfertaModel oferta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar oferta?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Sua oferta de ${oferta.quantidadeRestante} tokens de ${oferta.startupNome} será removida do balcão.',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar oferta',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final result = await _ofertaService.cancelarOferta(oferta.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? '✅ Oferta cancelada.'
          : '❌ ${result.errorMessage}'),
      backgroundColor: AppTheme.surfaceLight,
    ));
  }
}