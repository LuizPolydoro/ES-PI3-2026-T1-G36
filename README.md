# 🚀 MesclaInvest

Plataforma mobile de investimentos simulados em startups universitárias desenvolvida em Flutter/Dart com integração ao Firebase.

---

# 📱 Sobre o Projeto

O **MesclaInvest** é uma aplicação mobile criada com o objetivo de simular uma plataforma moderna de investimentos em startups acadêmicas.

A aplicação permite:

* Cadastro e login de usuários
* Visualização de startups cadastradas
* Tela detalhada das startups
* Simulação de compra e venda de tokens
* Reprodução de vídeos demonstrativos
* Integração em tempo real com Firebase Firestore
* Interface moderna estilo fintech

---

# 🛠 Tecnologias Utilizadas

## Frontend

* Flutter
* Dart

## Backend / Cloud

* Firebase Authentication
* Cloud Firestore

## Bibliotecas

* google_fonts
* flutter_svg
* youtube_player_flutter
* url_launcher
* intl
* mask_text_input_formatter

---

# 📂 Estrutura do Projeto

```plaintext
lib/
│
├── models/
│   └── startup_model.dart
│
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   └── startup_detail_screen.dart
│
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
│
├── theme/
│   └── app_theme.dart
│
├── widgets/
│   ├── gradient_button.dart
│   └── startup_card.dart
│
└── main.dart
```

---

# 🔥 Funcionalidades

## 🔐 Autenticação

* Cadastro com email e senha
* Login com Firebase Authentication
* Logout

---

## 🏢 Startups

* Listagem dinâmica via Firestore
* Cards modernos
* Informações financeiras
* Setor e estágio da startup
* Estrutura societária
* Mentores e conselho

---

## 🎥 Vídeos

* Reprodução de vídeos demonstrativos
* Integração com YouTube
* Abertura externa do vídeo

---

## 💰 Tokens

* Simulação de compra
* Simulação de venda
* Interface inspirada em plataformas de investimento

---

# ☁ Firebase

## Serviços utilizados

### Firebase Authentication

Responsável pelo sistema de login e cadastro.

### Cloud Firestore

Responsável pelo armazenamento das startups.

---

# 📊 Estrutura da Collection Firestore

Collection: `startups`

Exemplo:

```json
{
  "nome_startup": "EcoTech",
  "descricao": "Plataforma de monitoramento ambiental",
  "estagio": "operacao",
  "setor": "cleantech",
  "capital_aportado": 300000,
  "tokens_emitidos": 100000,
  "socios": "Ana Souza; Carlos Lima",
  "participacao_societaria": "60%; 40%",
  "mentores_conselho": "Mariana Prado",
  "video_demo": "https://www.youtube.com/watch?v=f4vl_Rya3mI",
  "status": "ativa"
}
```

---

# ▶ Como Executar

## 1. Clone o projeto

```bash
git clone https://github.com/seuusuario/mescla_invest.git
```

---

## 2. Entre na pasta

```bash
cd mescla_invest
```

---

## 3. Instale as dependências

```bash
flutter pub get
```

---

## 4. Configure o Firebase

Adicione o arquivo:

```plaintext
android/app/google-services.json
```

---

## 5. Execute o projeto

```bash
flutter run
```

---

# 🎨 Design

O aplicativo utiliza:

* Dark Theme
* Gradientes modernos
* Interface estilo fintech
* Componentes responsivos
* UX focada em mobile

---

# 📚 Objetivo Acadêmico

Projeto desenvolvido para fins acadêmicos visando aplicar conceitos de:

* Desenvolvimento Mobile
* Firebase
* Banco de Dados NoSQL
* UI/UX
* Arquitetura Flutter
* Integração em tempo real

---

# 👨‍💻 Desenvolvedor

Projeto desenvolvido por:
# 🚀 MesclaInvest

Plataforma mobile de investimentos simulados em startups universitárias desenvolvida em Flutter/Dart com integração ao Firebase.

---

# 📱 Sobre o Projeto

O **MesclaInvest** é uma aplicação mobile criada com o objetivo de simular uma plataforma moderna de investimentos em startups acadêmicas.

A aplicação permite:

* Cadastro e login de usuários
* Visualização de startups cadastradas
* Tela detalhada das startups
* Simulação de compra e venda de tokens
* Reprodução de vídeos demonstrativos
* Integração em tempo real com Firebase Firestore
* Interface moderna estilo fintech

---

# 🛠 Tecnologias Utilizadas

## Frontend

* Flutter
* Dart

## Backend / Cloud

* Firebase Authentication
* Cloud Firestore

## Bibliotecas

* google_fonts
* flutter_svg
* youtube_player_flutter
* url_launcher
* intl
* mask_text_input_formatter

---

# 📂 Estrutura do Projeto

```plaintext
lib/
│
├── models/
│   └── startup_model.dart
│# 🚀 MesclaInvest

Plataforma mobile de investimentos simulados em startups universitárias desenvolvida em Flutter/Dart com integração ao Firebase.

---

# 📱 Sobre o Projeto

O **MesclaInvest** é uma aplicação mobile criada com o objetivo de simular uma plataforma moderna de investimentos em startups acadêmicas.

A aplicação permite:

* Cadastro e login de usuários
* Visualização de startups cadastradas
* Tela detalhada das startups
* Simulação de compra e venda de tokens
* Reprodução de vídeos demonstrativos
* Integração em tempo real com Firebase Firestore
* Interface moderna estilo fintech

---

# 🛠 Tecnologias Utilizadas

## Frontend

* Flutter
* Dart

## Backend / Cloud

* Firebase Authentication
* Cloud Firestore

## Bibliotecas

* google_fonts
* flutter_svg
* youtube_player_flutter
* url_launcher
* intl
* mask_text_input_formatter

---

# 📂 Estrutura do Projeto

```plaintext
lib/
│
├── models/
│   ├── startup_model.dart
│   ├── user_model.dart
│   └── wallet_models.dart
│
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   └── startup_detail_screen.dart
│
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── wallet_service.dart
│ 
├── theme/
│   └── app_theme.dart
│
├── widgets/
│   ├── gradient_button.dart
│   ├── startup_card.dart
│   ├── startup_video_player.dart
│   └── custom_text.dart
│
└── main.dart
```

---

# 🔥 Funcionalidades

## 🔐 Autenticação

* Cadastro com email e senha
* Login com Firebase Authentication
* Logout

---

## 🏢 Startups

* Listagem dinâmica via Firestore
* Cards modernos
* Informações financeiras
* Setor e estágio da startup
* Estrutura societária
* Mentores e conselho

---

## 🎥 Vídeos

* Reprodução de vídeos demonstrativos
* Integração com YouTube
* Abertura externa do vídeo

---

## 💰 Tokens

* Simulação de compra
* Simulação de venda
* Interface inspirada em plataformas de investimento

---

# ☁ Firebase

## Serviços utilizados

### Firebase Authentication

Responsável pelo sistema de login e cadastro.

### Cloud Firestore

Responsável pelo armazenamento das startups.

---

# 📊 Estrutura da Collection Firestore

Collection: `startups`

Exemplo:

```json
{
  "nome_startup": "EcoTech",
  "descricao": "Plataforma de monitoramento ambiental",
  "estagio": "operacao",
  "setor": "cleantech",
  "capital_aportado": 300000,
  "tokens_emitidos": 100000,
  "socios": "Ana Souza; Carlos Lima",
  "participacao_societaria": "60%; 40%",
  "mentores_conselho": "Mariana Prado",
  "video_demo": "https://www.youtube.com/watch?v=f4vl_Rya3mI",
  "status": "ativa"
}
```

---

# ▶ Como Executar

## 1. Clone o projeto

```bash
git clone https://github.com/seuusuario/mescla_invest.git
```

---

## 2. Entre na pasta

```bash
cd mescla_invest
```

---

## 3. Instale as dependências

```bash
flutter pub get
```

---

## 4. Configure o Firebase

Adicione o arquivo:

```plaintext
android/app/google-services.json
```

---

## 5. Execute o projeto

```bash
flutter run
```

---

# 🎨 Design

O aplicativo utiliza:

* Dark Theme
* Gradientes modernos
* Interface estilo fintech
* Componentes responsivos
* UX focada em mobile

---

# 📚 Objetivo Acadêmico

Projeto desenvolvido para fins acadêmicos visando aplicar conceitos de:

* Desenvolvimento Mobile
* Firebase
* Banco de Dados NoSQL
* UI/UX
* Arquitetura Flutter
* Integração em tempo real

---

# 👨‍💻 Desenvolvedor

Projeto desenvolvido por:

**João Vitor Roventini**
**RA: 22005168**

PUC-Campinas — Projeto Integrador

---

# 📄 Licença

Projeto acadêmico sem fins comerciais.

├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   └── startup_detail_screen.dart
│
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
│
├── theme/
│   └── app_theme.dart
│
├── widgets/
│   ├── gradient_button.dart
│   └── startup_card.dart
│
└── main.dart
```

---

# 🔥 Funcionalidades

## 🔐 Autenticação

* Cadastro com email e senha
* Login com Firebase Authentication
* Logout

---

## 🏢 Startups

* Listagem dinâmica via Firestore
* Cards modernos
* Informações financeiras
* Setor e estágio da startup
* Estrutura societária
* Mentores e conselho

---

## 🎥 Vídeos

* Reprodução de vídeos demonstrativos
* Integração com YouTube
* Abertura externa do vídeo

---

## 💰 Tokens

* Simulação de compra
* Simulação de venda
* Interface inspirada em plataformas de investimento

---

# ☁ Firebase

## Serviços utilizados

### Firebase Authentication

Responsável pelo sistema de login e cadastro.

### Cloud Firestore

Responsável pelo armazenamento das startups.

---

# 📊 Estrutura da Collection Firestore

Collection: `startups`

Exemplo:

```json
{
  "nome_startup": "EcoTech",
  "descricao": "Plataforma de monitoramento ambiental",
  "estagio": "operacao",
  "setor": "cleantech",
  "capital_aportado": 300000,
  "tokens_emitidos": 100000,
  "socios": "Ana Souza; Carlos Lima",
  "participacao_societaria": "60%; 40%",
  "mentores_conselho": "Mariana Prado",
  "video_demo": "https://www.youtube.com/watch?v=f4vl_Rya3mI",
  "status": "ativa"
}
```

---

# ▶ Como Executar

## 1. Clone o projeto

```bash
git clone https://github.com/seuusuario/mescla_invest.git
```

---

## 2. Entre na pasta

```bash
cd mescla_invest
```

---

## 3. Instale as dependências

```bash
flutter pub get
```

---

## 4. Configure o Firebase

Adicione o arquivo:

```plaintext
android/app/google-services.json
```

---

## 5. Execute o projeto

```bash
flutter run
```

---

# 🎨 Design

O aplicativo utiliza:

* Dark Theme
* Gradientes modernos
* Interface estilo fintech
* Componentes responsivos
* UX focada em mobile

---

# 📚 Objetivo Acadêmico

Projeto desenvolvido para fins acadêmicos visando aplicar conceitos de:

* Desenvolvimento Mobile
* Firebase
* Banco de Dados NoSQL
* UI/UX
* Arquitetura Flutter
* Integração em tempo real

---

# 👨‍💻 Desenvolvedor

Projeto desenvolvido por:

**João Vitor Roventini**
**RA: 22005168**

PUC-Campinas — Projeto Integrador

---

# 📄 Licença

Projeto acadêmico sem fins comerciais.

**João Vitor Roventini**
**RA: 22005168**

PUC-Campinas — Projeto Integrador

---

# 📄 Licença

Projeto acadêmico sem fins comerciais.
