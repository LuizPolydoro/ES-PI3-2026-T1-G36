// lib/screens/cadastro_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Tela de Cadastro Simplificada - Firebase Authentication + Firestore

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import 'verify_mfa_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // ─── Controllers ────────────────────────────────────────────────────────────
  final _formKey      = GlobalKey<FormState>();
  final _nomeCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  final _authService = AuthService();
  bool _isLoading    = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  // ─── Cadastro ────────────────────────────────────────────────────────────────
  Future<void> _handleCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Removido CPF e Telefone da chamada do serviço
    final result = await _authService.cadastrar(
      nome:     _nomeCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _senhaCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // 1. Gera e "envia" o código para o e-mail cadastrado
      await _authService.enviarCodigoSeguranca(_emailCtrl.text.trim());

      if (!mounted) return;

      // 2. Notifica o usuário e vai para a tela de verificação
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            const Text('Conta criada! Verifique seu terminal para o código.'),
          ]),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );

      // Pequeno delay para o usuário ler a snackbar antes da transição
      await Future.delayed(const Duration(seconds: 1));

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
            Expanded(child: Text(result.errorMessage ?? 'Erro ao cadastrar.')),
          ]),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ─── AppBar customizada ────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Criar Conta',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Formulário ─────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preencha seus dados para criar\nsua conta de investidor.',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ─── Seção: Dados Pessoais ─────────────────────
                        _buildSectionTitle('Dados Pessoais'),
                        const SizedBox(height: 14),

                        CustomTextField(
                          label: 'Nome Completo',
                          hint: 'Seu nome completo',
                          controller: _nomeCtrl,
                          prefixIcon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Informe seu nome';
                            }
                            if (val.trim().split(' ').length < 2) {
                              return 'Informe nome e sobrenome';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // ─── Seção: Acesso ─────────────────────────────
                        _buildSectionTitle('Dados de Acesso'),
                        const SizedBox(height: 14),

                        CustomTextField(
                          label: 'E-mail',
                          hint: 'seu@email.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Informe seu e-mail';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(val)) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        CustomTextField(
                          label: 'Senha',
                          hint: 'Mínimo 6 caracteres',
                          controller: _senhaCtrl,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Crie uma senha';
                            }
                            if (val.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        CustomTextField(
                          label: 'Confirmar Senha',
                          hint: 'Repita a senha',
                          controller: _confirmaCtrl,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (val) {
                            if (val != _senhaCtrl.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // ─── Informação de saldo inicial ───────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppTheme.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ao criar sua conta, você receberá R\$ 10.000,00 em saldo simulado para investir.',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        GradientButton(
                          text: 'Criar Minha Conta',
                          onPressed: _isLoading ? null : _handleCadastro,
                          isLoading: _isLoading,
                          icon: Icons.person_add_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}