// lib/screens/verify_mfa_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Tela de verificação de código dinâmico (Simulação de e-mail)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class VerifyMfaScreen extends StatefulWidget {
  final UserModel? userModel;
  const VerifyMfaScreen({super.key, this.userModel});

  @override
  State<VerifyMfaScreen> createState() => _VerifyMfaScreenState();
}

class _VerifyMfaScreenState extends State<VerifyMfaScreen> {
  final _codigoCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleVerificar() async {
    if (_codigoCtrl.text.trim().length < 6) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    // Valida o código gerado no AuthService
    final sucesso = _authService.verificarCodigo(_codigoCtrl.text.trim());

    if (sucesso) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(userModel: widget.userModel)),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Código incorreto ou expirado. Verifique o terminal.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _reenviarCodigo() async {
    final email = widget.userModel?.email ?? "usuário";
    await _authService.enviarCodigoSeguranca(email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Novo código enviado para seu e-mail (veja no terminal).'),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: AppTheme.primary, size: 48),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verificação de E-mail',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enviamos um código de segurança para\n${widget.userModel?.email ?? "seu e-mail"}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 48),

                TextField(
                  controller: _codigoCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.3), letterSpacing: 8),
                    counterText: '',
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 32),

                GradientButton(
                  text: 'Verificar e Entrar',
                  onPressed: _isLoading ? null : _handleVerificar,
                  isLoading: _isLoading,
                  icon: Icons.login_rounded,
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isLoading ? null : _reenviarCodigo,
                  child: const Text(
                    'Não recebi o código? Reenviar',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dica acadêmica: O código aparece no console (terminal) onde o Flutter está rodando.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
