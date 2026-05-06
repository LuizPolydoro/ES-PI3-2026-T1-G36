// lib/widgets/startup_card.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Card visual de Startup — campos do Firestore real

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/startup_model.dart';
import '../theme/app_theme.dart';

class StartupCard extends StatelessWidget {
  final StartupModel startup;
  final VoidCallback? onTap;

  const StartupCard({super.key, required this.startup, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildDescricao(),
            const SizedBox(height: 12),
            _buildSocios(),
            const SizedBox(height: 12),
            _buildMetrics(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ── Cabeçalho: avatar + nome + setor + estágio ──────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                startup.nomeStartup.isNotEmpty
                    ? startup.nomeStartup[0].toUpperCase()
                    : '?',
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.background,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startup.nomeStartup,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  children: [
                    _badge(startup.setor, AppTheme.accent),
                    _badge(startup.estagioLabel, _estagioColor()),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted, size: 13),
        ],
      ),
    );
  }

  // ── Descrição ───────────────────────────────────────────────────────────────
  Widget _buildDescricao() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        startup.descricao,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Sócios ──────────────────────────────────────────────────────────────────
  Widget _buildSocios() {
    if (startup.socios.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.people_outline,
              color: AppTheme.textMuted, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              startup.socios,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (startup.participacaoSocietaria.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              startup.participacaoSocietaria,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Métricas: Capital + Tokens ───────────────────────────────────────────────
  Widget _buildMetrics() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metricItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Capital',
              value: startup.capitalFormatado,
              color: AppTheme.primary,
            ),
          ),
          Container(width: 1, height: 32, color: AppTheme.surfaceLight),
          Expanded(
            child: _metricItem(
              icon: Icons.token_outlined,
              label: 'Tokens',
              value: startup.tokensFormatado,
              color: AppTheme.gold,
            ),
          ),
          if (startup.mentoresConselho.isNotEmpty) ...[
            Container(width: 1, height: 32, color: AppTheme.surfaceLight),
            Expanded(
              child: _metricItem(
                icon: Icons.star_outline_rounded,
                label: 'Mentor',
                value: startup.mentoresConselho.split(';').first.trim(),
                color: AppTheme.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

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

  Color _estagioColor() {
    switch (startup.estagio.toLowerCase()) {
      case 'expansao':
      case 'em_expansao': return AppTheme.gold;
      case 'operacao':
      case 'em_operacao': return AppTheme.primary;
      default:            return AppTheme.accent;
    }
  }
}