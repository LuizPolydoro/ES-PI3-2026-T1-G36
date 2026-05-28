// lib/screens/mfa_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Tela de configuração MFA/2FA — autenticação multifator (requisito 5.5)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class MfaScreen extends StatefulWidget {
  const MfaScreen({super.key});

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  bool _mfaAtivo    = false;
  bool _loading     = true;
  bool _salvando    = false;
  bool _verificando = false;

  // Código gerado (simulado — TOTP visual)
  String _codigoAtual = '';
  int    _segundosRestantes = 30;

  final _codigoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarStatus();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data() as Map<String, dynamic>?;
      final mfa  = data?['mfa_ativo'] as bool? ?? false;

      if (mounted) {
        setState(() {
          _mfaAtivo = mfa;
          _loading  = false;
          if (mfa) _gerarCodigo();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Gera código TOTP simulado baseado no tempo
  void _gerarCodigo() {
    final agora   = DateTime.now();
    final periodo = agora.second ~/ 30; // muda a cada 30s
    final base    = (agora.millisecondsSinceEpoch ~/ 30000) % 1000000;
    _codigoAtual      = base.toString().padLeft(6, '0');
    _segundosRestantes = 30 - (agora.second % 30);

    // Atualiza a cada segundo
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _mfaAtivo) {
        _gerarCodigo();
        setState(() {});
      }
    });
  }

  // Ativa o MFA
  Future<void> _ativarMFA() async {
    setState(() => _salvando = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'mfa_ativo': true, 'mfa_ativado_em': FieldValue.serverTimestamp()});

      setState(() {
        _mfaAtivo = true;
        _salvando = false;
      });
      _gerarCodigo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Autenticação 2FA ativada com sucesso!'),
          backgroundColor: AppTheme.surfaceLight,
        ));
      }
    } catch (e) {
      setState(() => _salvando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  // Desativa o MFA
  Future<void> _desativarMFA() async {
    setState(() => _salvando = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'mfa_ativo': false});

      setState(() {
        _mfaAtivo    = false;
        _codigoAtual = '';
        _salvando    = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('2FA desativado.'),
          backgroundColor: AppTheme.surfaceLight,
        ));
      }
    } catch (e) {
      setState(() => _salvando = false);
    }
  }

  // Verifica código inserido
  void _verificarCodigo() {
    final inserido = _codigoCtrl.text.trim();
    setState(() => _verificando = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _verificando = false);

      if (inserido == _codigoAtual) {
        _codigoCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Código verificado com sucesso!'),
          backgroundColor: AppTheme.surfaceLight,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Código inválido ou expirado.'),
          backgroundColor: AppTheme.error,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      if (_mfaAtivo) ...[
                        _buildCodigoAtual(),
                        const SizedBox(height: 20),
                        _buildVerificarCodigo(),
                        const SizedBox(height: 20),
                        _buildDesativarBtn(),
                      ] else ...[
                        _buildExplicacao(),
                        const SizedBox(height: 20),
                        GradientButton(
                          text: 'Ativar Autenticação 2FA',
                          onPressed: _salvando ? null : _ativarMFA,
                          isLoading: _salvando,
                          icon: Icons.security_rounded,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildInfoBox(),
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
          const Icon(Icons.security_rounded,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Text('Autenticação 2FA',
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Card de status ──────────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _mfaAtivo
              ? [const Color(0xFF0D2A1A), const Color(0xFF061610)]
              : [const Color(0xFF1A1A2E), const Color(0xFF0D0D1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _mfaAtivo
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: (_mfaAtivo ? AppTheme.primary : AppTheme.textMuted)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _mfaAtivo
                  ? Icons.verified_user_rounded
                  : Icons.shield_outlined,
              color: _mfaAtivo ? AppTheme.primary : AppTheme.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mfaAtivo ? 'Proteção Ativa' : 'Proteção Inativa',
                  style: GoogleFonts.spaceGrotesk(
                      color: _mfaAtivo
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _mfaAtivo
                      ? 'Sua conta está protegida com 2FA'
                      : 'Ative o 2FA para maior segurança',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (_mfaAtivo ? AppTheme.primary : AppTheme.error)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _mfaAtivo ? 'ATIVO' : 'INATIVO',
              style: TextStyle(
                  color: _mfaAtivo ? AppTheme.primary : AppTheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Código TOTP atual ───────────────────────────────────────────────────────
  Widget _buildCodigoAtual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.timer_outlined,
              color: AppTheme.gold, size: 16),
          const SizedBox(width: 8),
          Text('Código Atual (TOTP)',
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Código em destaque
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _codigoAtual.split('').asMap().entries.map((e) {
                  return Container(
                    margin: EdgeInsets.only(
                        left: e.key == 3 ? 12 : 4, right: 4),
                    width: 38, height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.gold.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        e.value,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              // Barra de progresso
              Row(children: [
                const Icon(Icons.hourglass_bottom_rounded,
                    color: AppTheme.textMuted, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _segundosRestantes / 30,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _segundosRestantes > 10
                            ? AppTheme.primary
                            : AppTheme.error,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${_segundosRestantes}s',
                    style: TextStyle(
                        color: _segundosRestantes > 10
                            ? AppTheme.textMuted
                            : AppTheme.error,
                        fontSize: 11)),
              ]),
              const SizedBox(height: 8),
              // Botão copiar
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _codigoAtual));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado!'),
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copiar código'),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Verificar código ────────────────────────────────────────────────────────
  Widget _buildVerificarCodigo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.verified_outlined,
              color: AppTheme.accent, size: 16),
          const SizedBox(width: 8),
          Text('Verificar Código',
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    letterSpacing: 6),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: const TextStyle(
                      color: AppTheme.textMuted, letterSpacing: 6),
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _verificando ? null : _verificarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _verificando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Text('Verificar',
                        style: TextStyle(
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Botão desativar ─────────────────────────────────────────────────────────
  Widget _buildDesativarBtn() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _salvando ? null : _desativarMFA,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: const BorderSide(color: AppTheme.error),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.shield_outlined, size: 18),
        label: Text('Desativar 2FA',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  // ── Explicação ──────────────────────────────────────────────────────────────
  Widget _buildExplicacao() {
    return Column(
      children: [
        _infoStep('1', Icons.security_rounded,
            'Ative o 2FA', 'Clique em "Ativar" para habilitar a autenticação de dois fatores.'),
        const SizedBox(height: 10),
        _infoStep('2', Icons.timer_outlined,
            'Código temporário', 'Um código de 6 dígitos será gerado e renovado a cada 30 segundos.'),
        const SizedBox(height: 10),
        _infoStep('3', Icons.verified_outlined,
            'Verificação', 'Insira o código para confirmar operações sensíveis na plataforma.'),
      ],
    );
  }

  Widget _infoStep(String num, IconData icon, String titulo, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(desc,
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline,
            color: AppTheme.accent, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'O MFA implementado é funcional para fins acadêmicos. Em produção, utilizaria um app autenticador como Google Authenticator ou Authy.',
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.4),
          ),
        ),
      ]),
    );
  }
}