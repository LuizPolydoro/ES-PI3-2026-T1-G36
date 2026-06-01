# 🚀 MesclaInvest

> Plataforma de investimentos simulados em startups universitárias — PUC-Campinas
> Desenvolvido por **João Vitor Roventini**
> RA: **22004168**

---

# 📌 Visão Geral

O **MesclaInvest** é uma plataforma inovadora que simula um ambiente real de investimentos em startups, permitindo que usuários possam explorar, analisar e investir em projetos universitários de forma interativa, moderna e gamificada.

O objetivo do sistema é proporcionar uma experiência imersiva semelhante a plataformas reais de venture capital, combinando conceitos de:

* 📊 Mercado financeiro
* 🚀 Startups
* 💰 Tokenização
* 🔐 Segurança (2FA)
* 🎥 Apresentações em vídeo
* ☁️ Cloud computing com Firebase

---

# 🧠 Conceito do Projeto

A ideia central do MesclaInvest é transformar o processo de investimento em algo:

✔ Educacional
✔ Interativo
✔ Visual
✔ Simulado, porém realista

Cada startup cadastrada possui:

* Nome
* Descrição
* Setor
* Estágio
* Capital
* Tokens emitidos
* Estrutura societária
* Vídeo de apresentação

---

# 🎯 Objetivos

* Simular um ambiente de investimento
* Desenvolver habilidades em Flutter + Firebase
* Criar uma aplicação moderna com UI/UX profissional
* Integrar múltiplos serviços (Auth, Firestore, YouTube, Email)
* Aplicar conceitos de segurança (2FA)

---

# 🏗️ Arquitetura do Projeto

O projeto segue uma estrutura modular baseada em:

```
lib/
 ├── models/
 ├── screens/
 ├── services/
 ├── widgets/
 ├── theme/
 └── main.dart
```

---

# 📱 Funcionalidades

## 🔐 Autenticação

* Login com email e senha
* Cadastro de usuário
* Integração com Firebase Auth

---

## 🔐 Autenticação em Duas Etapas (2FA)

* Geração de código OTP
* Envio via email
* Validação antes do acesso ao sistema

---

## 🏠 Home

* Listagem de startups
* Filtros por categoria
* Interface moderna estilo fintech

---

## 📊 Detalhes da Startup

* Informações completas
* Métricas financeiras
* Estrutura societária
* Perguntas e respostas
* Player de vídeo integrado

---

## 🎥 Vídeos

* Integração com YouTube
* Reprodução dentro do app
* Demonstração de cada startup

---

## 💰 Wallet (Carteira)

* Simulação de saldo
* Compra de tokens
* Venda de tokens
* Histórico de transações

---

## 💬 Sistema de Q&A

* Perguntas sobre startups
* Respostas simuladas
* Interação do usuário

---

# 🎨 Design

O sistema utiliza um design inspirado em:

* Fintechs modernas
* Dark mode
* Gradientes
* Tipografia premium (Google Fonts)

---

## 🌙 Tema

* Dark Mode completo
* Paleta personalizada
* Componentes estilizados

---

# 🧪 Tecnologias Utilizadas

## 📱 Frontend

* Flutter
* Dart

## ☁️ Backend

* Firebase Auth
* Cloud Firestore
* Firebase Core

## 🎨 UI

* Google Fonts
* Material Design 3

## 🔧 Outros

* YouTube Player
* URL Launcher
* Mask Formatter

---

# 🔥 Integrações

* Firebase Authentication
* Firestore Database
* YouTube Embed
* Email Service (2FA)

---

# 🧾 Estrutura de Dados

## StartupModel

Contém:

* nomeStartup
* descricao
* setor
* estagio
* capital
* tokens
* videoDemo

---

## Wallet

* TokenPosition
* Transacoes
* Histórico financeiro

---

# 🔐 Segurança

O sistema implementa:

* Autenticação segura
* Validação de dados
* 2FA via código
* Proteção contra acesso indevido

---

# 🚀 Como Rodar o Projeto

```bash
flutter pub get
flutter run
```

---

# ⚙️ Configuração Firebase

1. Criar projeto no Firebase
2. Adicionar app Android
3. Baixar google-services.json
4. Colocar em:

```
android/app/google-services.json
```

---

# 📦 Dependências

```yaml
firebase_core
firebase_auth
cloud_firestore
google_fonts
flutter_svg
intl
```

---

# 📈 Futuras Melhorias

* 📊 Dashboard avançado
* 📉 Gráficos financeiros
* 🤖 IA para análise de startups
* 🌐 Versão web
* 💸 Sistema real de pagamentos

---

# 🧠 Aprendizados

Este projeto envolve:

* Arquitetura de software
* UI/UX design
* Integração com APIs
* Segurança digital
* Firebase ecosystem

---

# 🧑‍💻 Autor

**João Vitor Roventini**
RA: 22004168

---

# 📄 Licença

Este projeto é acadêmico e destinado exclusivamente para fins educacionais.

---

# 🚀 Considerações Finais

O MesclaInvest representa uma evolução no ensino de investimentos, trazendo uma abordagem moderna, interativa e tecnológica para o ambiente acadêmico.

---

# 💡 Extra

Este projeto pode ser expandido para:

* Startup real
* Plataforma educacional
* Simulador financeiro
* Sistema de investimento coletivo

---

# ⭐ Obrigado por utilizar o MesclaInvest!

---
