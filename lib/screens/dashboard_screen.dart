// lib/screens/dashboard_screen.dart
// Autor: [Seu Nome Completo]
// RA: [Seu RA]
// Dashboard de valorização de tokens — gráfico por período (5.4 do documento)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/startup_model.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final StartupModel startup;
  const DashboardScreen({super.key, required this.startup});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _walletService = WalletService();
  String _periodo = 'mensal';
  List<PrecoSnapshot> _historico = [];
  bool _loading = true;

  final _periodos = [
    {'value': 'diario',  'label': '1D'},
    {'value': 'semanal', 'label': '7D'},
    {'value': 'mensal',  'label': '1M'},
    {'value': '6meses',  'label': '6M'},
    {'value': 'ytd',     'label': 'YTD'},
  ];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _loading = true);
    final s = widget.startup;
    final data = await _walletService.getHistoricoPrecos(
      startupId:       s.id,
      periodo:         _periodo,
      capitalAportado: s.capitalAportado,
      tokensEmitidos:  s.tokensEmitidos,
    );
    if (mounted) setState(() {
      _historico = data;
      _loading   = false;
    });
  }

  // ── Variação percentual do período ─────────────────────────────────────────
  double get _variacaoPercent {
    if (_historico.length < 2) return 0;
    final inicio = _historico.first.preco;
    final fim    = _historico.last.preco;
    if (inicio == 0) return 0;
    return ((fim - inicio) / inicio) * 100;
  }

  double get _precoAtual =>
      _historico.isNotEmpty ? _historico.last.preco : 0;

  double get _precoInicio =>
      _historico.isNotEmpty ? _historico.first.preco : 0;

  bool get _positivo => _variacaoPercent >= 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.startup;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
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
                    _buildPrecoAtual(),
                    const SizedBox(height: 20),
                    _buildGrafico(),
                    const SizedBox(height: 16),
                    _buildPeriodos(),
                    const SizedBox(height: 24),
                    _buildEstatisticas(),
                    const SizedBox(height: 24),
                    _buildLegenda(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(StartupModel s) {
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
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                s.nomeStartup.isNotEmpty
                    ? s.nomeStartup[0].toUpperCase()
                    : '?',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.background,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nomeStartup,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text('Valorização do Token',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.show_chart_rounded,
              color: AppTheme.primary, size: 22),
        ],
      ),
    );
  }

  // ── Preço atual + variação ──────────────────────────────────────────────────
  Widget _buildPrecoAtual() {
    final cor = _positivo ? AppTheme.primary : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF091929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preço Atual do Token',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _loading
                    ? '—'
                    : 'R\$ ${_precoAtual.toStringAsFixed(4)}',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 12),
              if (!_loading)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(
                      _positivo
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: cor, size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${_variacaoPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: cor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _loading
                ? ''
                : 'Início do período: R\$ ${_precoInicio.toStringAsFixed(4)}',
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Gráfico ─────────────────────────────────────────────────────────────────
  Widget _buildGrafico() {
    if (_loading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 2),
        ),
      );
    }

    if (_historico.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
        child: const Center(
          child: Text('Sem dados para o período.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ),
      );
    }

    final precos  = _historico.map((e) => e.preco).toList();
    final minPreco = precos.reduce((a, b) => a < b ? a : b);
    final maxPreco = precos.reduce((a, b) => a > b ? a : b);
    final margem   = (maxPreco - minPreco) * 0.1;
    final corLinha = _positivo ? AppTheme.primary : AppTheme.error;

    final spots = _historico.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.preco)).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxPreco - minPreco) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.surfaceLight,
              strokeWidth: 0.8,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, _) => Text(
                  'R\$${value.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (_historico.length / 4).ceilToDouble(),
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _historico.length) {
                    return const SizedBox.shrink();
                  }
                  final dt = _historico[idx].data;
                  String label;
                  switch (_periodo) {
                    case 'diario':
                      label = '${dt.hour}h';
                      break;
                    case 'semanal':
                      const dias = ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'];
                      label = dias[dt.weekday - 1];
                      break;
                    default:
                      label = '${dt.day}/${dt.month}';
                  }
                  return Text(label,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9));
                },
              ),
            ),
            topTitles:   const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (_historico.length - 1).toDouble(),
          minY: (minPreco - margem).clamp(0, double.infinity),
          maxY: maxPreco + margem,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: corLinha,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    corLinha.withOpacity(0.25),
                    corLinha.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.surfaceLight,
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  'R\$ ${s.y.toStringAsFixed(4)}',
                  const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Seletor de período ──────────────────────────────────────────────────────
  Widget _buildPeriodos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _periodos.map((p) {
        final selected = _periodo == p['value'];
        return GestureDetector(
          onTap: () {
            setState(() => _periodo = p['value']!);
            _carregarHistorico();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Text(
              p['label']!,
              style: TextStyle(
                  color: selected
                      ? AppTheme.background
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Estatísticas do período ─────────────────────────────────────────────────
  Widget _buildEstatisticas() {
    if (_historico.isEmpty) return const SizedBox.shrink();

    final precos  = _historico.map((e) => e.preco).toList();
    final minP    = precos.reduce((a, b) => a < b ? a : b);
    final maxP    = precos.reduce((a, b) => a > b ? a : b);
    final media   = precos.reduce((a, b) => a + b) / precos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estatísticas do Período',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _estatCard(
                'Mínimo', 'R\$ ${minP.toStringAsFixed(4)}',
                Icons.arrow_downward_rounded, AppTheme.error)),
            const SizedBox(width: 10),
            Expanded(child: _estatCard(
                'Máximo', 'R\$ ${maxP.toStringAsFixed(4)}',
                Icons.arrow_upward_rounded, AppTheme.primary)),
            const SizedBox(width: 10),
            Expanded(child: _estatCard(
                'Média', 'R\$ ${media.toStringAsFixed(4)}',
                Icons.horizontal_rule_rounded, AppTheme.accent)),
          ],
        ),
      ],
    );
  }

  Widget _estatCard(
      String label, String value, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Legenda ─────────────────────────────────────────────────────────────────
  Widget _buildLegenda() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline,
            color: AppTheme.textMuted, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'A variação de preço é calculada com base no volume de compras e vendas realizadas na plataforma.',
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11, height: 1.4),
          ),
        ),
      ]),
    );
  }
}