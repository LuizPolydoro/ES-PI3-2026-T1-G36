// lib/screens/login_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import 'cadastro_screen.dart';
import 'verify_mfa_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(
      email:    _emailCtrl.text,
      password: _senhaCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Gera e "envia" o código para o e-mail do usuário
      await _authService.enviarCodigoSeguranca(_emailCtrl.text);

      // Vai para a tela de código
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyMfaScreen(userModel: result.user),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(result.errorMessage ?? 'Erro ao fazer login.')),
          ]),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    }
  }

  void _handleEsqueciSenha() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recuperar Senha',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Informe seu e-mail para receber as instruções de redefinição.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'E-mail',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _authService.recuperarSenha(emailCtrl.text);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result.success
                    ? 'E-mail de recuperação enviado!'
                    : result.errorMessage ?? 'Erro'),
                backgroundColor: AppTheme.surfaceLight,
              ));
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'E-mail',
                            hint: 'seu@email.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Informe seu e-mail';
                              if (!val.contains('@')) return 'E-mail inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Senha',
                            hint: '••••••••',
                            controller: _senhaCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Informe sua senha';
                              if (val.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleEsqueciSenha,
                              child: const Text('Esqueci minha senha',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GradientButton(
                            text: 'Entrar',
                            onPressed: _isLoading ? null : _handleLogin,
                            isLoading: _isLoading,
                            icon: Icons.arrow_forward_rounded,
                          ),
                          const SizedBox(height: 32),
                          Row(children: [
                            const Expanded(child: Divider(color: AppTheme.surfaceLight)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13)),
                            ),
                            const Expanded(child: Divider(color: AppTheme.surfaceLight)),
                          ]),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const CadastroScreen()),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppTheme.surfaceLight, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Criar conta',
                                  style: GoogleFonts.dmSans(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text('M',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.background,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 28),
        Text('MesclaInvest',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(
                color: AppTheme.textSecondary, fontSize: 15),
            children: const [
              TextSpan(text: 'Invista no futuro das '),
              TextSpan(
                text: 'startups universitárias',
                style: TextStyle(color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
