// lib/screens/startup_detail_screen.dart
// Detalhe completo de uma Startup — Versão com redirecionamento para o YouTube

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/startup_model.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class StartupDetailScreen extends StatefulWidget {
  final StartupModel startup;
  const StartupDetailScreen({super.key, required this.startup});

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen> {
  // Função para abrir o link do YouTube externamente
  Future<void> _abrirYoutube() async {
    final urlStr = widget.startup.videoDemo.trim();
    if (urlStr.isEmpty) return;

    final Uri url = Uri.parse(urlStr);

    try {
      // No Android 11+, precisamos tentar o modo inAppBrowserView primeiro
      // ou externalNonBrowserApplication para que o sistema encontre o app do YouTube
      final sucesso = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!sucesso) {
        throw 'O sistema não conseguiu abrir o link.';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir o vídeo. Verifique se o link está correto.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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
              // AppBar
              Padding(
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
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(s),
                      const SizedBox(height: 16),
                      _buildMetrics(s),
                      const SizedBox(height: 20),

                      // Botão de Vídeo / Pitch
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

  // ── Botão Assistir no YouTube ─────────────────────────────────────────────
  Widget _buildVideoButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFCD201F).withOpacity(0.1), // Cor oficial do YouTube (suave)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCD201F).withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _abrirYoutube,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: Color(0xFFCD201F), size: 24),
                const SizedBox(width: 12),
                Text(
                  'ASSISTIR PITCH NO YOUTUBE',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
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
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                s.nomeStartup.isNotEmpty ? s.nomeStartup[0].toUpperCase() : '?',
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

  // ── Métricas ───────────────────────────────────────────────────────────────
  Widget _buildMetrics(StartupModel s) {
    return Row(
      children: [
        Expanded(
            child: _metricCard(
          Icons.account_balance_wallet_outlined,
          'Capital Aportado',
          s.capitalFormatado,
          AppTheme.primary,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _metricCard(
          Icons.token_outlined,
          'Tokens Emitidos',
          s.tokensFormatado,
          AppTheme.gold,
        )),
      ],
    );
  }

  Widget _metricCard(IconData icon, String label, String value, Color color) {
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
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Seção de texto genérica ─────────────────────────────────────────────────
  Widget _buildInfoSection(String title, String content, IconData icon) {
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
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
        ),
      ],
    );
  }

  // ── Estrutura societária ───────────────────────────────────────────────────
  Widget _buildSocietaria(StartupModel s) {
    final sociosList = s.socios.split(';').map((e) => e.trim()).toList();
    final participacoes =
        s.participacaoSocietaria.split(';').map((e) => e.trim()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.people_outline, color: AppTheme.accent, size: 16),
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
            children: List.generate(sociosList.length, (i) {
              final participacao =
                  i < participacoes.length ? participacoes[i] : '';
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i < sociosList.length - 1 ? 10 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          sociosList[i].isNotEmpty
                              ? sociosList[i][0].toUpperCase()
                              : '?',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.background,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(sociosList[i],
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

  // ── Q&A ───────────────────────────────────────────────────────────────────
  Widget _buildQnA(StartupModel s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ]),
            TextButton.icon(
              onPressed: _showPergunta,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Perguntar', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                backgroundColor: AppTheme.primary.withOpacity(0.08),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _qnaItem(
          'Qual o modelo de receita?',
          'Modelo SaaS com planos mensais e anuais, além de receita por transação para funcionalidades premium.',
        ),
        const SizedBox(height: 8),
        _qnaItem(
          'A startup tem clientes pagantes?',
          'Sim! Temos usuários ativos e contratos B2B em fase de negociação.',
        ),
      ],
    );
  }

  Widget _qnaItem(String pergunta, String resposta) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.help_outline, color: AppTheme.accent, size: 13),
            const SizedBox(width: 6),
            Expanded(
              child: Text(pergunta,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.chat_bubble_outline,
                color: AppTheme.primary, size: 13),
            const SizedBox(width: 6),
            Expanded(
              child: Text(resposta,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.5)),
            ),
          ]),
        ],
      ),
    );
  }

  void _showPergunta() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Fazer Pergunta',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escreva sua pergunta...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Pergunta enviada!'),
                backgroundColor: AppTheme.surfaceLight,
              ));
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ── Negociação de tokens ───────────────────────────────────────────────────
  Widget _buildNegociacao(StartupModel s) {
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
            const Icon(Icons.token_outlined, color: AppTheme.gold, size: 18),
            const SizedBox(width: 8),
            Text('Negociação de Tokens',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Adquira ou venda tokens representativos de participação nesta startup.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
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
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showNegociacao('vender'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.gold,
                      side: const BorderSide(color: AppTheme.gold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    label: Text('Vender',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 13)),
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isCompra ? 'Comprar Tokens' : 'Vender Tokens',
          style: TextStyle(color: color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quantidade de tokens de ${widget.startup.nomeStartup}:',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ex: 100',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                suffixText: 'tokens',
                suffixStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isCompra
                    ? 'Oferta de compra registrada!'
                    : 'Oferta de venda registrada!'),
                backgroundColor: AppTheme.surfaceLight,
              ));
            },
            child: Text(isCompra ? 'Comprar' : 'Vender',
                style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
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
      case 'em_expansao':
        return AppTheme.gold;
      case 'operacao':
      case 'em_operacao':
        return AppTheme.primary;
      default:
        return AppTheme.accent;
    }
  }
}
