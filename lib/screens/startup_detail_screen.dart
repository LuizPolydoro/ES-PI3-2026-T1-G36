// lib/screens/startup_detail_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Detalhe completo — regra do investidor + perguntas privadas + balcão real

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/startup_model.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class StartupDetailScreen extends StatefulWidget {
  final StartupModel startup;
  const StartupDetailScreen({super.key, required this.startup});

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen> {
  final _perguntaCtrl  = TextEditingController();
  final _walletService = WalletService();
  bool _enviandoPergunta = false;
  bool _perguntaPrivada  = false;
  bool _isInvestidor     = false;
  TokenPosition? _minhaPosition;

  @override
  void initState() {
    super.initState();
    _verificarInvestidor();
  }

  @override
  void dispose() {
    _perguntaCtrl.dispose();
    super.dispose();
  }

  // ── Verifica se o usuário já é investidor desta startup ─────────────────────
  Future<void> _verificarInvestidor() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('positions')
          .doc(widget.startup.id)
          .get();

      if (doc.exists && mounted) {
        final pos = TokenPosition.fromMap(
            widget.startup.id, doc.data() as Map<String, dynamic>);
        setState(() {
          _isInvestidor  = pos.quantidade > 0;
          _minhaPosition = pos;
        });
      }
    } catch (_) {}
  }

  // ── Abre YouTube ─────────────────────────────────────────────────────────────
  Future<void> _abrirYoutube() async {
    final urlStr = widget.startup.videoDemo.trim();
    if (urlStr.isEmpty) return;
    final uri = Uri.parse(urlStr);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'Não foi possível abrir.';
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao abrir o vídeo.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  // ── Envia pergunta (pública ou privada) ─────────────────────────────────────
  Future<void> _enviarPergunta() async {
    final texto = _perguntaCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviandoPergunta = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance
          .collection('startups')
          .doc(widget.startup.id)
          .collection('perguntas')
          .add({
        'uid':      uid,
        'pergunta': texto,
        'resposta': '',
        'data':     FieldValue.serverTimestamp(),
        'publica':  !_perguntaPrivada, // privada = só o empreendedor vê
      });

      _perguntaCtrl.clear();
      setState(() => _perguntaPrivada = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_perguntaPrivada
              ? '🔒 Pergunta privada enviada!'
              : '✅ Pergunta pública enviada!'),
          backgroundColor: AppTheme.surfaceLight,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _enviandoPergunta = false);
    }
  }

  // ── Compra/Venda real ────────────────────────────────────────────────────────
  Future<void> _processarNegociacao(String tipo, int quantidade) async {
    final s = widget.startup;
    WalletResult result;

    if (tipo == 'comprar') {
      result = await _walletService.comprarTokens(
        startupId:       s.id,
        nomeStartup:     s.nomeStartup,
        quantidade:      quantidade,
        capitalAportado: s.capitalAportado,
        tokensEmitidos:  s.tokensEmitidos,
      );
    } else {
      result = await _walletService.venderTokens(
        startupId:       s.id,
        nomeStartup:     s.nomeStartup,
        quantidade:      quantidade,
        capitalAportado: s.capitalAportado,
        tokensEmitidos:  s.tokensEmitidos,
      );
    }

    if (!mounted) return;

    if (result.success) {
      // Atualiza status de investidor após compra
      await _verificarInvestidor();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? tipo == 'comprar'
              ? '✅ Compra de $quantidade tokens realizada!'
              : '✅ Venda de $quantidade tokens realizada!'
          : '❌ ${result.errorMessage}'),
      backgroundColor:
          result.success ? AppTheme.surfaceLight : AppTheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.startup;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(s),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(s),
                      const SizedBox(height: 16),

                      // Banner exclusivo para investidores
                      if (_isInvestidor) ...[
                        _buildInvestidorBanner(),
                        const SizedBox(height: 16),
                      ],

                      _buildMetrics(s),
                      const SizedBox(height: 20),

                      if (s.videoDemo.isNotEmpty) ...[
                        _buildVideoButton(),
                        const SizedBox(height: 20),
                      ],

                      _buildInfoSection(
                          'Descrição', s.descricao, Icons.info_outline),
                      const SizedBox(height: 16),

                      _buildSocietaria(s),
                      const SizedBox(height: 16),

                      if (s.mentoresConselho.isNotEmpty) ...[
                        _buildInfoSection(
                          'Mentores / Conselho',
                          s.mentoresConselho,
                          Icons.star_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildQnA(s),
                      const SizedBox(height: 16),

                      _buildNegociacao(s),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(StartupModel s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(s.nomeStartup,
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ),
          // Ícone de investidor
          if (_isInvestidor)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.verified_rounded,
                    color: AppTheme.gold, size: 13),
                const SizedBox(width: 4),
                Text('Investidor',
                    style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Banner exclusivo investidor ──────────────────────────────────────────────
  Widget _buildInvestidorBanner() {
    final p = _minhaPosition;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withOpacity(0.15),
            AppTheme.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.verified_rounded,
                color: AppTheme.gold, size: 16),
            const SizedBox(width: 8),
            Text('Você é investidor desta startup',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          if (p != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _investidorMetric(
                    'Meus Tokens', '${p.quantidade}')),
                Expanded(child: _investidorMetric(
                    'Valor Atual', p.valorFormatado)),
                Expanded(child: _investidorMetric(
                    'Resultado',
                    '${p.lucroReais >= 0 ? '+' : ''}R\$ ${p.lucroReais.toStringAsFixed(2)}',
                    cor: p.lucroReais >= 0
                        ? AppTheme.primary
                        : AppTheme.error)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _investidorMetric(String label, String value, {Color? cor}) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: cor ?? AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Botão YouTube ────────────────────────────────────────────────────────────
  Widget _buildVideoButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFCD201F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCD201F).withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _abrirYoutube,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: Color(0xFFCD201F), size: 24),
                const SizedBox(width: 12),
                Text('ASSISTIR PITCH NO YOUTUBE',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(StartupModel s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                s.nomeStartup.isNotEmpty
                    ? s.nomeStartup[0].toUpperCase()
                    : '?',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.background,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nomeStartup,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [
                  _badge(s.setor, AppTheme.accent),
                  _badge(s.estagioLabel, _estagioColor(s)),
                  _badge(s.status.toUpperCase(), AppTheme.primary),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Métricas ─────────────────────────────────────────────────────────────────
  Widget _buildMetrics(StartupModel s) {
    return Row(
      children: [
        Expanded(child: _metricCard(
          Icons.account_balance_wallet_outlined,
          'Capital Aportado',
          s.capitalFormatado,
          AppTheme.primary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _metricCard(
          Icons.token_outlined,
          'Tokens Emitidos',
          s.tokensFormatado,
          AppTheme.gold,
        )),
      ],
    );
  }

  Widget _metricCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Seção de texto ───────────────────────────────────────────────────────────
  Widget _buildInfoSection(
      String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Text(content,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.6)),
        ),
      ],
    );
  }

  // ── Estrutura Societária ─────────────────────────────────────────────────────
  Widget _buildSocietaria(StartupModel s) {
    final socios = s.socios
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final participacoes =
        s.participacaoSocietaria.split(';').map((e) => e.trim()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.people_outline,
              color: AppTheme.accent, size: 16),
          const SizedBox(width: 8),
          Text('Estrutura Societária',
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            children: List.generate(socios.length, (i) {
              final participacao =
                  i < participacoes.length ? participacoes[i] : '';
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i < socios.length - 1 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          socios[i].isNotEmpty
                              ? socios[i][0].toUpperCase()
                              : '?',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.background,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(socios[i],
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    if (participacao.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(participacao,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Q&A com perguntas privadas ──────────────────────────────────────────────
  Widget _buildQnA(StartupModel s) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.chat_bubble_outline,
              color: AppTheme.accent, size: 16),
          const SizedBox(width: 8),
          Text('Perguntas & Respostas',
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          if (_isInvestidor) ...[
            const SizedBox(width: 8),
            _badge('Investidor', AppTheme.gold),
          ],
        ]),
        const SizedBox(height: 12),

        // Campo de envio
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _perguntaCtrl,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Envie uma pergunta...',
                      hintStyle: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _enviandoPergunta ? null : _enviarPergunta,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _enviandoPergunta
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.background))
                        : const Icon(Icons.send_rounded,
                            color: AppTheme.background, size: 18),
                  ),
                ),
              ],
            ),

            // Toggle pergunta privada — só para investidores
            if (_isInvestidor) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _perguntaPrivada = !_perguntaPrivada),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: _perguntaPrivada
                            ? AppTheme.gold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _perguntaPrivada
                                ? AppTheme.gold
                                : AppTheme.textMuted),
                      ),
                      child: _perguntaPrivada
                          ? const Icon(Icons.check_rounded,
                              color: AppTheme.background, size: 13)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Row(children: [
                      const Icon(Icons.lock_outline,
                          color: AppTheme.gold, size: 13),
                      const SizedBox(width: 4),
                      Text('Pergunta privada (só o empreendedor vê)',
                          style: TextStyle(
                              color: _perguntaPrivada
                                  ? AppTheme.gold
                                  : AppTheme.textMuted,
                              fontSize: 11)),
                    ]),
                  ],
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Lista do Firestore — públicas para todos, privadas só para o autor
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('startups')
              .doc(s.id)
              .collection('perguntas')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // Filtra: mostra públicas + privadas do próprio usuário
            final visiveis = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final publica = data['publica'] as bool? ?? true;
              final autorUid = data['uid'] as String? ?? '';
              return publica || autorUid == uid;
            }).toList();

            if (visiveis.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceLight),
                ),
                child: const Center(
                  child: Text(
                    'Nenhuma pergunta ainda.\nSeja o primeiro a perguntar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              );
            }

            return Column(
              children: visiveis.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final pergunta = data['pergunta'] as String? ?? '';
                final resposta = data['resposta'] as String? ?? '';
                final publica  = data['publica']  as bool?   ?? true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _qnaItem(pergunta, resposta, publica),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _qnaItem(String pergunta, String resposta, bool publica) {
    final temResposta = resposta.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !publica
              ? AppTheme.gold.withOpacity(0.3)
              : temResposta
                  ? AppTheme.primary.withOpacity(0.2)
                  : AppTheme.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
              !publica ? Icons.lock_outline : Icons.help_outline,
              color: !publica ? AppTheme.gold : AppTheme.accent,
              size: 13,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(pergunta,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4)),
            ),
            if (!publica)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('PRIVADA',
                    style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          if (temResposta) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppTheme.primary, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(resposta,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            const Text('Aguardando resposta...',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  // ── Balcão de tokens ─────────────────────────────────────────────────────────
  Widget _buildNegociacao(StartupModel s) {
    final preco = s.tokensEmitidos > 0
        ? s.capitalAportado / s.tokensEmitidos
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2E4A), Color(0xFF0D1E33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.token_outlined,
                color: AppTheme.gold, size: 18),
            const SizedBox(width: 8),
            Text('Balcão de Tokens',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.monetization_on_outlined,
                color: AppTheme.primary, size: 13),
            const SizedBox(width: 6),
            Text(
              'Preço atual: R\$ ${preco.toStringAsFixed(4)}/token',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Comprar',
                  onPressed: () => _showNegociacao('comprar'),
                  icon: Icons.add_rounded,
                  height: 44,
                ),
              ),
              const SizedBox(width: 10),
              // Vender só aparece se for investidor
              if (_isInvestidor)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _showNegociacao('vender'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.gold,
                        side:
                            const BorderSide(color: AppTheme.gold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.remove_rounded, size: 16),
                      label: Text('Vender',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNegociacao(String tipo) {
    final ctrl = TextEditingController();
    final isCompra = tipo == 'comprar';
    final color = isCompra ? AppTheme.primary : AppTheme.gold;
    final s = widget.startup;
    final preco = s.tokensEmitidos > 0
        ? s.capitalAportado / s.tokensEmitidos
        : 0.0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final qtd = int.tryParse(ctrl.text) ?? 0;
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
              Text(
                isCompra ? 'Comprar Tokens' : 'Vender Tokens',
                style: TextStyle(color: color, fontSize: 16),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Startup: ${s.nomeStartup}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                Text('Preço: R\$ ${preco.toStringAsFixed(4)}/token',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (_) => setModal(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de tokens',
                    suffixText: 'tokens',
                    suffixStyle: TextStyle(
                        color: AppTheme.textSecondary),
                  ),
                ),
                if (qtd > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:',
                            style: TextStyle(
                                color: color, fontSize: 13)),
                        Text(
                          'R\$ ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: color,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
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
                    : () {
                        Navigator.pop(ctx);
                        _processarNegociacao(tipo, qtd);
                      },
                child: Text(
                  isCompra
                      ? 'Confirmar Compra'
                      : 'Confirmar Venda',
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

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
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