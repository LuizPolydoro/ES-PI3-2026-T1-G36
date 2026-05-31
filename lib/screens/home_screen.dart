// lib/screens/home_screen.dart
// Autor: João Vitor Roventini
// RA: 22005168
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/startup_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'carteira_screen.dart';
import 'startup_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? userModel;
  const HomeScreen({super.key, this.userModel});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _authService      = AuthService();
  final _firestoreService = FirestoreService();

  UserModel? _currentUser;
  String _filtro = 'todos';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    if (widget.userModel != null) _currentUser = widget.userModel;
    _loadUserData();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserData();
    if (mounted && user != null) setState(() => _currentUser = user);
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  onRefresh: _loadUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeBanner(),
                        const SizedBox(height: 28),
                        _buildSectionTitle(),
                        const SizedBox(height: 14),
                        _buildFilterRow(),
                        const SizedBox(height: 20),
                        _buildStartupsList(),
                        const SizedBox(height: 40),
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

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text('M',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.background,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 9),
              Text('MesclaInvest',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
            ],
          ),

          const Spacer(),

          // Sino
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppTheme.textSecondary, size: 24),
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Avatar com menu
          _buildUserMenu(),
        ],
      ),
    );
  }

  // ── Menu do usuário ────────────────────────────────────────────────────────
  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceLight),
      ),
      elevation: 10,
      onSelected: (value) {
        if (value == 'perfil')   _showPerfil();
        if (value == 'carteira') _abrirCarteira();
        if (value == 'logout')   _confirmLogout();
      },
      itemBuilder: (_) => [
        _menuItem(Icons.person_outline, 'Meu Perfil', 'perfil', AppTheme.textPrimary),
        _menuItem(Icons.account_balance_wallet_outlined, 'Minha Carteira', 'carteira', AppTheme.primary),
        const PopupMenuDivider(height: 1),
        _menuItem(Icons.logout_rounded, 'Sair', 'logout', AppTheme.error),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: AppTheme.surface,
          child: Text(
            _currentUser?.iniciais ?? '?',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      IconData icon, String label, String value, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ]),
    );
  }

  // ── Banner de boas-vindas ──────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF091929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${_currentUser?.nome.split(' ').first ?? 'Investidor'} 👋',
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Seu painel de\ninvestimentos',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppTheme.primary, size: 26),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppTheme.surfaceLight.withOpacity(0.5)),
          const SizedBox(height: 16),

          // Métricas
          Row(
            children: [
              Expanded(child: _bannerMetric(
                Icons.account_balance_wallet_outlined,
                'Saldo Disponível',
                _currentUser?.saldoFormatado ?? 'R\$ --',
                AppTheme.primary,
              )),
              Container(width: 1, height: 40, color: AppTheme.surfaceLight),
              Expanded(child: _bannerMetric(
                Icons.token_outlined,
                'Tokens',
                '0',
                AppTheme.gold,
              )),
              Container(width: 1, height: 40, color: AppTheme.surfaceLight),
              Expanded(child: _bannerMetric(
                Icons.shield_outlined,
                'Modo',
                'Simulado',
                AppTheme.accent,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerMetric(IconData icon, String label, String value, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 17),
      const SizedBox(height: 6),
      Text(value,
          style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          textAlign: TextAlign.center),
    ]);
  }

  // ── Título da seção ────────────────────────────────────────────────────────
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Startups em Destaque',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
              Text('Ecossistema Mescla · PUC-Campinas',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          // Badge live
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
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
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filtros ────────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    final filtros = [
      {'value': 'todos',    'label': 'Todos',       'icon': Icons.apps_rounded},
      {'value': 'nova',     'label': 'Novas',       'icon': Icons.fiber_new_outlined},
      {'value': 'operacao', 'label': 'Operação',    'icon': Icons.play_circle_outline},
      {'value': 'expansao', 'label': 'Expansão',    'icon': Icons.rocket_launch_outlined},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filtros[i];
          final selected = _filtro == f['value'];
          return GestureDetector(
            onTap: () => setState(() => _filtro = f['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Row(
                children: [
                  Icon(f['icon'] as IconData,
                      size: 13,
                      color: selected ? AppTheme.background : AppTheme.textSecondary),
                  const SizedBox(width: 5),
                  Text(f['label'] as String,
                      style: TextStyle(
                          color: selected ? AppTheme.background : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Lista de startups ──────────────────────────────────────────────────────
  Widget _buildStartupsList() {
    return StreamBuilder<List<StartupModel>>(
      stream: _firestoreService.getStartupsStream(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2),
                  SizedBox(height: 16),
                  Text('Carregando startups...',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(children: [
                const Icon(Icons.wifi_off_rounded,
                    color: AppTheme.error, size: 44),
                const SizedBox(height: 12),
                const Text('Erro ao carregar startups.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                Text('${snapshot.error}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                    textAlign: TextAlign.center),
              ]),
            ),
          );
        }

        final todas = snapshot.data ?? [];
        final lista = _filtro == 'todos'
            ? todas
            : todas.where((s) {
                final e = s.estagio.toLowerCase();
                return e == _filtro || e == 'em$_filtro' || e == 'em $_filtro';
              }).toList();

        if (lista.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(children: [
                Icon(todas.isEmpty
                    ? Icons.rocket_launch_outlined
                    : Icons.filter_list_off_rounded,
                    color: AppTheme.textMuted, size: 44),
                const SizedBox(height: 12),
                Text(
                  todas.isEmpty
                      ? 'Nenhuma startup cadastrada ainda.'
                      : 'Nenhuma startup neste filtro.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
              ]),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: lista.map((s) => _buildStartupCard(s)).toList(),
          ),
        );
      },
    );
  }

  // ── Card de startup profissional ───────────────────────────────────────────
  Widget _buildStartupCard(StartupModel s) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StartupDetailScreen(startup: s),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        s.nomeStartup.isNotEmpty
                            ? s.nomeStartup[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.background,
                            fontSize: 22,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, children: [
                          _badge(s.setor, AppTheme.accent),
                          _badge(s.estagioLabel, _estagioColor(s)),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textMuted, size: 13),
                ],
              ),
            ),

            // ── Descrição ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Text(s.descricao,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),

            // ── Sócios ────────────────────────────────────────────────────
            if (s.socios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Row(children: [
                  const Icon(Icons.people_outline,
                      color: AppTheme.textMuted, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.socios,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (s.participacaoSocietaria.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(s.participacaoSocietaria,
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ]),
              ),

            // ── Divisor ───────────────────────────────────────────────────
            const Divider(height: 1, color: AppTheme.surfaceLight),

            // ── Métricas + Botão ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Row(
                children: [
                  // Capital
                  _miniMetric(Icons.account_balance_wallet_outlined,
                      s.capitalFormatado, 'Capital', AppTheme.primary),
                  const SizedBox(width: 20),
                  // Tokens
                  _miniMetric(Icons.token_outlined,
                      s.tokensFormatado, 'Tokens', AppTheme.gold),

                  const Spacer(),

                  // Botão Ver detalhes
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StartupDetailScreen(startup: s),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text('Ver detalhes',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.background,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(IconData icon, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
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

  Color _estagioColor(StartupModel s) {
    switch (s.estagio.toLowerCase()) {
      case 'expansao':
      case 'em_expansao': return AppTheme.gold;
      case 'operacao':
      case 'em_operacao': return AppTheme.primary;
      default:            return AppTheme.accent;
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  void _showPerfil() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 70, height: 70,
              decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
              child: Center(
                child: Text(_currentUser?.iniciais ?? '?',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.background,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            Text(_currentUser?.nome ?? '—',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_currentUser?.email ?? '',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Saldo: ',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  Text(_currentUser?.saldoFormatado ?? 'R\$ --',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirCarteira() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CarteiraScreen()),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sair da conta',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Deseja realmente sair?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: const Text('Sair',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
