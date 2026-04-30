package com.example.myapplication.ui.theme

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.TrendingUp
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.firebase.auth.FirebaseAuth


// ═══════════════════════════════════════════════════════════════════
//  MODELOS DE DADOS
// ═══════════════════════════════════════════════════════════════════

/**
 * Representa os estágios possíveis de uma startup.
 * Cada estágio carrega a cor do badge exibido na tela.
 */
enum class EstagioStartup(val label: String, val cor: Color) {
    NOVA("Nova", Color(0xFF4CAF50)),
    OPERACAO("Operação", Color(0xFF2196F3)),
    EXPANSAO("Expansão", Color(0xFFFF9800))
}

/**
 * Modelo de dados de uma Startup.
 *
 * @param id          Identificador único.
 * @param nome        Nome da startup.
 * @param descricao   Breve descrição do negócio.
 * @param estagio     Estágio atual da empresa.
 * @param setor       Setor de atuação (ex: Fintech, Saúde).
 * @param valorToken  Valor simulado do token em reais.
 */
data class Startup(
    val id: Int,
    val nome: String,
    val descricao: String,
    val estagio: EstagioStartup,
    val setor: String,
    val valorToken: Double
)


// ═══════════════════════════════════════════════════════════════════
//  DADOS MOCKADOS
// ═══════════════════════════════════════════════════════════════════

/** Lista simulada de startups. Substituir por chamada de API futuramente. */
val startupsMock = listOf(
    Startup(
        id = 1,
        nome = "NutriAI",
        descricao = "Plataforma de nutrição personalizada com inteligência artificial e acompanhamento em tempo real.",
        estagio = EstagioStartup.EXPANSAO,
        setor = "HealthTech",
        valorToken = 12.50
    ),
    Startup(
        id = 2,
        nome = "UrbanFlow",
        descricao = "Solução de mobilidade urbana que conecta ciclistas, pedestres e transporte público.",
        estagio = EstagioStartup.OPERACAO,
        setor = "MobilityTech",
        valorToken = 5.80
    ),
    Startup(
        id = 3,
        nome = "AgroMesh",
        descricao = "Rede de sensores IoT para monitoramento de lavouras e otimização do uso de água.",
        estagio = EstagioStartup.NOVA,
        setor = "AgriTech",
        valorToken = 3.20
    ),
    Startup(
        id = 4,
        nome = "EduBlocks",
        descricao = "Certificações educacionais em blockchain para micro-credenciais e aprendizado contínuo.",
        estagio = EstagioStartup.OPERACAO,
        setor = "EdTech",
        valorToken = 8.75
    ),
    Startup(
        id = 5,
        nome = "ClearPay",
        descricao = "Fintech de pagamentos instantâneos para microempreendedores sem conta bancária.",
        estagio = EstagioStartup.EXPANSAO,
        setor = "Fintech",
        valorToken = 21.00
    ),
    Startup(
        id = 6,
        nome = "EcoWatt",
        descricao = "Marketplace de energia solar distribuída para condomínios e pequenos comércios.",
        estagio = EstagioStartup.NOVA,
        setor = "CleanTech",
        valorToken = 2.90
    )
)


// ═══════════════════════════════════════════════════════════════════
//  TELA PRINCIPAL
// ═══════════════════════════════════════════════════════════════════

/**
 * Tela Home do MesclaInvest.
 *
 * @param auth      Instância do FirebaseAuth para leitura do usuário e logout.
 * @param onLogout  Callback executado após o signOut(); navega de volta ao login.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TelaHome(
    auth: FirebaseAuth,
    onLogout: () -> Unit
) {
    // E-mail do usuário logado, com fallback seguro
    val userEmail = auth.currentUser?.email ?: "usuário"

    // Controla abertura/fechamento do DropdownMenu da TopAppBar
    var menuExpandido by remember { mutableStateOf(false) }

    Scaffold(
        // ── TopAppBar ────────────────────────────────────────────────
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.TrendingUp,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = "MesclaInvest",
                            fontWeight = FontWeight.Bold,
                            fontSize = 20.sp
                        )
                    }
                },
                actions = {
                    // Ícone de usuário que abre o dropdown
                    IconButton(onClick = { menuExpandido = true }) {
                        Icon(
                            imageVector = Icons.Filled.AccountCircle,
                            contentDescription = "Menu do usuário",
                            modifier = Modifier.size(30.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }

                    // ── DropdownMenu ─────────────────────────────────
                    DropdownMenu(
                        expanded = menuExpandido,
                        onDismissRequest = { menuExpandido = false }
                    ) {
                        // Cabeçalho com e-mail do usuário
                        Column(
                            modifier = Modifier
                                .padding(horizontal = 16.dp, vertical = 8.dp)
                                .widthIn(min = 200.dp)
                        ) {
                            Text(
                                text = userEmail,
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        HorizontalDivider()

                        // Opção: Perfil
                        DropdownMenuItem(
                            text = { Text("Perfil") },
                            leadingIcon = {
                                Icon(Icons.Outlined.Person, contentDescription = null)
                            },
                            onClick = { menuExpandido = false /* TODO: navegar para Perfil */ }
                        )

                        // Opção: Configurações
                        DropdownMenuItem(
                            text = { Text("Configurações") },
                            leadingIcon = {
                                Icon(Icons.Outlined.Settings, contentDescription = null)
                            },
                            onClick = { menuExpandido = false /* TODO: navegar para Configurações */ }
                        )

                        HorizontalDivider()

                        // Opção: Logout
                        DropdownMenuItem(
                            text = {
                                Text(
                                    "Logout",
                                    color = MaterialTheme.colorScheme.error
                                )
                            },
                            leadingIcon = {
                                Icon(
                                    Icons.AutoMirrored.Outlined.Logout,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error
                                )
                            },
                            onClick = {
                                menuExpandido = false
                                auth.signOut()
                                onLogout()
                            }
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    scrolledContainerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { innerPadding ->

        // ── Conteúdo principal ────────────────────────────────────────
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(bottom = 24.dp)
        ) {

            // ── Seção de boas-vindas ──────────────────────────────────
            item {
                Spacer(Modifier.height(8.dp))
                CartaoBemVindo(email = userEmail)
                Spacer(Modifier.height(8.dp))
            }

            // ── Cabeçalho da lista ────────────────────────────────────
            item {
                Text(
                    text = "Startups Disponíveis",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "${startupsMock.size} oportunidades encontradas",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(4.dp))
            }

            // ── Itens da lista de startups ────────────────────────────
            items(items = startupsMock, key = { it.id }) { startup ->
                CartaoStartup(startup = startup)
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════════
//  COMPONENTES INTERNOS
// ═══════════════════════════════════════════════════════════════════

/**
 * Card de boas-vindas exibido no topo do feed.
 * Traz um gradiente sutil e o e-mail do usuário.
 */
@Composable
private fun CartaoBemVindo(email: String) {
    val gradienteBemVindo = Brush.horizontalGradient(
        colors = listOf(
            MaterialTheme.colorScheme.primary,
            MaterialTheme.colorScheme.tertiary
        )
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(brush = gradienteBemVindo)
            .padding(20.dp)
    ) {
        Column {
            Text(
                text = "Bem-vindo! 👋",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = email,
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.85f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(Modifier.height(16.dp))
            Text(
                text = "Explore as melhores oportunidades de investimento em startups.",
                style = MaterialTheme.typography.bodySmall,
                color = Color.White.copy(alpha = 0.75f),
                lineHeight = 18.sp
            )
        }
    }
}

/**
 * Card individual de uma startup no feed.
 *
 * @param startup Dados da startup a exibir.
 */
@Composable
private fun CartaoStartup(startup: Startup) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .animateContentSize(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainerLow
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {

            // ── Linha superior: nome + badge de estágio ───────────────
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Ícone da letra inicial + nome
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = startup.nome.first().toString(),
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            fontSize = 18.sp
                        )
                    }
                    Spacer(Modifier.width(10.dp))
                    Column {
                        Text(
                            text = startup.nome,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = startup.setor,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Badge de estágio
                BadgeEstagio(estagio = startup.estagio)
            }

            Spacer(Modifier.height(10.dp))

            // ── Descrição ─────────────────────────────────────────────
            Text(
                text = startup.descricao,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                lineHeight = 20.sp
            )

            Spacer(Modifier.height(14.dp))

            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)

            Spacer(Modifier.height(12.dp))

            // ── Rodapé: valor do token + botão ────────────────────────
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Valor do token",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "R$ ${"%.2f".format(startup.valorToken)}",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                // Botão "Ver detalhes" — sem navegação real ainda
                FilledTonalButton(
                    onClick = { /* TODO: navegar para detalhes da startup */ },
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Text(
                        text = "Ver detalhes",
                        style = MaterialTheme.typography.labelMedium
                    )
                    Spacer(Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

/**
 * Badge colorido que indica o estágio da startup.
 *
 * @param estagio Estágio a ser exibido.
 */
@Composable
private fun BadgeEstagio(estagio: EstagioStartup) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(estagio.cor.copy(alpha = 0.15f))
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .clip(CircleShape)
                    .background(estagio.cor)
            )
            Spacer(Modifier.width(5.dp))
            Text(
                text = estagio.label,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.SemiBold,
                color = estagio.cor
            )
        }
    }
}


// ═══════════════════════════════════════════════════════════════════
//  PREVIEW
// ═══════════════════════════════════════════════════════════════════

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true, showSystemUi = true)
@Composable
private fun TelaHomePreview() {
    MaterialTheme {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Outlined.TrendingUp,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(22.dp)
                            )
                            Spacer(Modifier.width(8.dp))
                            Text("MesclaInvest", fontWeight = FontWeight.Bold)
                        }
                    },
                    actions = {
                        IconButton(onClick = {}) {
                            Icon(
                                Icons.Filled.AccountCircle,
                                contentDescription = null,
                                modifier = Modifier.size(30.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                )
            }
        ) { padding ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                contentPadding = PaddingValues(bottom = 24.dp)
            ) {
                item {
                    Spacer(Modifier.height(8.dp))
                    CartaoBemVindo(email = "preview@mescla.com")
                    Spacer(Modifier.height(8.dp))
                }
                item {
                    Text("Startups Disponíveis", fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(4.dp))
                }
                items(startupsMock, key = { it.id }) { startup ->
                    CartaoStartup(startup = startup)
                }
            }
        }
    }
}