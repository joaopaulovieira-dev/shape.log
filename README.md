# Shape.log — A Interface Física para sua I.A.

Uma aplicação Flutter robusta que atua como o elo definitivo entre o seu planejamento digital e a execução real. Com estética Cyberpunk, o Shape.log permite importar treinos via JSON gerados por Inteligência Artificial, monitorar bioimpedância com precisão clínica e gerar relatórios de dados para análise contínua.

A I.A. planeja. Você executa. O Shape.log conecta.

**Versão atual:** `1.4.0`

---

## 🚀 Funcionalidades Principais

### 1. Gestão de Treinos (Workout Tracker)
- **Criação de Rotinas**: Crie treinos personalizados (ex: "Treino A - Peito e Tríceps").
- **Importação Flexível (AI-Pipeline)**: Importe treinos gerados por IA (ChatGPT/Gemini) via arquivos `.json` ou colando o texto diretamente.
- **Sanitização Inteligente**: O app gera novos IDs automaticamente, limpa caminhos de imagem externos e reseta datas para evitar conflitos.
- **Registro de Exercícios**: Adicione exercícios com detalhes de Séries, Repetições, Carga, **Tempo de Descanso** e Técnica.
- **Timer de Descanso**: Configure o tempo de descanso individual por exercício (padrão 60s), com slider e chips de seleção rápida.
- **Notificações Sensoriais**: Alerta de fim de descanso com **Som Embutido** (que não interrompe sua música) e **Feedback Tátil** (vibração).
- **Histórico de Execução**: Marque treinos como concluídos e acompanhe logs passados.
- **Ordenação Automática**: Treinos organizados automaticamente em ordem alfabética.
- **Genius Focus Mode**: Interface de execução imersiva com grade compacta, histórico de carga (`📈`) acessível e persistência em tempo real.
- **Smart Timer**: Lógica inteligente que avança exercícios automaticamente e detecta o fim do treino.
- **Sincronização em Tempo Real**: Ao salvar ou excluir um treino com conta Google ativa, a operação é espelhada imediatamente no Firestore.

### 2. Monitoramento de Medidas (Body Tracker)
- **Cyber-Bio Scanner (Mapa Corporal Interativo)**: Interface visual 3D-like onde você toca na parte do corpo para registrar a medida.
- **Bioimpedância Integrada**: Campo para `reportUrl` para armazenar e abrir links de balanças diretamente no navegador.
- **Rastreamento de Circunferências**: Pescoço, Ombros, Tórax, Cintura, Quadril, Bíceps, Antebraços, Coxas e Panturrilhas.
- **Card de Medidas Expandível**: Visualize todas as circunferências e detalhes ao expandir registros.
- **Seleção Multi-imagem**: Adicione múltiplas fotos de progresso simultaneamente via Galeria.
- **Histórico Visual**: Visualize fotos diretamente no histórico ao expandir registros.
- **Filtros Inteligentes**: Evolução nos últimos 7, 30 ou 90 dias.
- **Sincronização em Tempo Real**: Medidas salvas e excluídas são sincronizadas com o Firestore automaticamente.

### 3. Perfil Biológico (Bio-Data Source of Truth)
- **Perfil Centralizado**: Armazena dados como Altura, Nível de Atividade e Peso Meta.
- **Foto de Perfil Customizável**: Importe sua própria foto da galeria.
- **Cálculo Automático de IMC**: Recalcula automaticamente o IMC de todos os registros históricos.
- **Classificação OMS**: Monitoramento rigoroso seguindo padrões da OMS.
- **Persistência Local + Nuvem**: Dados salvos localmente no Hive e espelhados no Firestore.

### 4. Autenticação & Sincronização com Firebase (v1.2)
- **Login com Google**: Autenticação via Google Sign-In integrada ao Firebase Auth.
- **Modo Convidado (Offline)**: Use o app completamente offline sem conta — dados ficam no Hive local.
- **Sincronização Bidirecional**:
  - **Upload pós-login**: Dados locais são enviados ao Firestore após o login com Google.
  - **Download em novo dispositivo**: Ao logar em um dispositivo diferente, todos os dados da nuvem são restaurados automaticamente.
- **Operações em Tempo Real**: Salvar ou excluir treinos, histórico e medidas reflete imediatamente no Firestore quando autenticado.
- **Exclusão Permanente**: Ao deletar um item com conta ativa, ele é removido definitivamente do Firestore (sem soft-delete).
- **Batch Inteligente**: Upload usa batches independentes por coleção (até 400 ops cada) para não atingir o limite do Firestore, com log por coleção para diagnóstico.

### 5. Backup & Restore Completo
- **Backup Unificado**: Gera um `.zip` contendo todo o banco de dados (treinos, histórico, perfil, medidas) + imagens customizadas (Asset Library + fotos do Body Tracker).
- **Portabilidade**: Salve backups no Google Drive, WhatsApp ou localmente.
- **Restauração Simples**: Importe o `.zip` para restaurar o estado exato do app.
- **Sincronização Pós-Restore**: Ao restaurar um backup com conta Google ativa, todos os dados são automaticamente enviados ao Firebase, incluindo a biblioteca de imagens.
- **Loading Contextual**: Tela de progresso dedicada durante o envio dos arquivos ao Firebase após o restore.
- **Compatibilidade Legada**: Suporte a backups antigos que contêm apenas a biblioteca de imagens.

### 6. Firebase Storage — Imagens na Nuvem (v1.2)
- **Upload Automático de Imagens**: Fotos de perfil, histórico de treinos e medidas corporais são enviadas ao Firebase Storage durante a sincronização.
- **Renderização Híbrida**: O app detecta automaticamente se um caminho de imagem é local ou uma URL remota do Firebase, usando `FileImage` ou `NetworkImage` conforme necessário — sem erros ou telas em branco.
- **Biblioteca de Ativos no Storage**: Durante o restore de backup, a biblioteca de imagens é enviada ao Storage em background (sem bloquear a UI).

### 7. Biblioteca de Ativos (Assets Library)
- **Importação de Pacotes**: Importe arquivos `.zip` contendo centenas de imagens de equipamentos ou execução.
- **Super Picker**: Ao adicionar fotos, escolha entre **Câmera**, **Galeria** ou a **Biblioteca Interna**.
- **Busca Rápida**: Filtre equipamentos pelo nome diretamente no seletor.

### 8. Interface e Usabilidade
- **Design Moderno**: Tema escuro com acentos Neon, seguindo padrões modernos de UI.
- **Reatividade Ultra-fluida**: Interface que se auto-atualiza instantaneamente (Hive Listenables + Riverpod).
- **Navegação Intuitiva**: Barra de navegação inferior persistente e rotas fluidas via GoRouter.
- **Diálogos Padronizados**: Sistema customizado de modais e diálogos — incluindo loading dialog com mensagem descritiva para operações longas.
- **Correções de Layout**: Todos os `ListTile` dentro de containers coloridos envolvem corretamente um `Material` transparente para evitar artefatos visuais.

---

## 🔥 Estrutura no Firebase

```
Firestore
└── users/
    └── {uid}/                        ← perfil do usuário
        ├── workouts/
        │   └── {workoutId}           ← treino completo (com exercícios embutidos)
        ├── history/
        │   └── {historyId}           ← sessão de treino concluída
        └── measurements/
            └── {measurementId}       ← medida corporal

Firebase Storage
└── users/
    └── {uid}/
        ├── profile_picture.png
        ├── history/{id}_0.png
        ├── measurements/{id}_0.png
        └── library/{filename}        ← biblioteca de ativos (via restore)
```

**Regras do Firebase Storage** (mínimo necessário):
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 🤖 Padrão de Importação JSON (AI-Ready)

Para que o sistema de importação funcione corretamente (via arquivo ou texto), o JSON deve seguir a estrutura abaixo. O app aceita tanto uma lista direta `[]` quanto um objeto com a chave `"workouts"`.

### Exemplo de Estrutura Completa (Híbrido)
```json
{
  "workouts": [
    {
      "name": "Treino Híbrido (Peito + Cardio)",
      "scheduledDays": [1, 3, 5],
      "targetDurationMinutes": 60,
      "expiryDate": "2024-12-31",
      "notes": "Foco em progressão de carga e resistência",
      "exercises": [
        {
          "name": "Supino Reto",
          "type": "strength",
          "sets": 4,
          "reps": "8-10",
          "weight": 30.0,
          "restTime": 90,
          "technique": "Cadência 3-0-1",
          "equipmentNumber": "12",
          "youtubeUrl": "https://www.youtube.com/watch?v=video_id"
        },
        {
          "name": "Corrida na Esteira",
          "type": "cardio",
          "sets": 1,
          "durationMinutes": 30,
          "intensity": "Velocidade 8-10km/h",
          "technique": "Manter postura ereta",
          "restTime": 60
        }
      ]
    }
  ]
}
```

### Especificações Técnicas
- **`type`**: `"strength"` (padrão) ou `"cardio"`.
- **`scheduledDays`**: Lista de números de 1 (Segunda) a 7 (Domingo).
- **`expiryDate`**: Data de validade no formato `YYYY-MM-DD` (Opcional).
- **`reps`**: Aceita números (`12`) ou strings para intervalos (`"10-12"`).
- **`weight`**: Valor numérico em kg.
- **`durationMinutes`**: (Cardio) Tempo em minutos.
- **`intensity`**: (Cardio) String livre (ex: `"Zona 2"`).
- **`restTime`** (ou `restSeconds`): Tempo de descanso em segundos. Padrão: `60`.
- **`youtubeUrl`**: Link completo do tutorial no YouTube (Opcional).
- **Sanitização Automática**: `id`, `imagePaths` e `activeStartTime` são gerados ou resetados pelo app.

---

## 🛠 Tecnologias Utilizadas

O projeto segue os princípios de **Clean Architecture**.

| Camada | Tecnologia |
|---|---|
| Frontend | Flutter (Dart) |
| Estado | Riverpod 2.0 |
| Banco local | Hive CE (NoSQL) |
| Autenticação | Firebase Auth (Google Sign-In) |
| Banco nuvem | Cloud Firestore |
| Storage nuvem | Firebase Storage |
| Roteamento | GoRouter |
| Tipografia | Google Fonts (Outfit) |
| Áudio | audioplayers |
| Feedback tátil | vibration |
| Datas | intl |

---

## 📂 Estrutura do Projeto

```
lib/
├── core/
│   ├── constants/       # Cores, temas
│   ├── presentation/    # Widgets reutilizáveis (AppDialogs, AppModals)
│   ├── services/        # SyncService, AuthService
│   └── utils/           # ImagePathResolver, SnackbarUtils
├── features/
│   ├── workout/         # Treinos, exercícios, sessão, histórico
│   ├── body_tracker/    # Medidas corporais e mapa interativo
│   ├── profile/         # Perfil do usuário
│   ├── reports/         # Relatórios e análises
│   ├── settings/        # Backup, restore, biblioteca de ativos
│   ├── image_library/   # Gerenciamento da biblioteca local de imagens
│   ├── dashboard/       # Tela inicial
│   └── splash/          # Splash, welcome e autenticação
└── main.dart
```

---

## ▶️ Como Rodar o Projeto

1. **Pré-requisitos**: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
2. **Instalar dependências**:
   ```bash
   flutter pub get
   ```
3. **Gerar adaptadores do Hive**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Configurar Firebase**: Adicione os arquivos `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) gerados no Firebase Console.
5. **Executar no iOS/Android**:
   ```bash
   flutter run
   ```
6. **Executar no Chrome (web)**:
   ```bash
   flutter run -d chrome
   ```

---

## 🌐 Build Web + Deploy Firebase Hosting

### Pré-requisitos
- [Firebase CLI](https://firebase.google.com/docs/cli) instalado: `npm install -g firebase-tools`
- Autenticado: `firebase login`

### 1. Aplicar CORS no Firebase Storage (primeira vez)
Necessário para que imagens do Storage carreguem no browser:
```bash
# Instalar Google Cloud SDK (se não tiver)
brew install --cask google-cloud-sdk

# Autenticar
gcloud auth login

# Aplicar regras CORS
gsutil cors set cors.json gs://shape-log-app.firebasestorage.app

# Verificar
gsutil cors get gs://shape-log-app.firebasestorage.app
```

### 2. Build Web
```bash
flutter build web --release
```
O output é gerado em `build/web/`.

### 3. Deploy no Firebase Hosting
```bash
firebase deploy --only hosting --project shape-log-app
```
Após o deploy, o app estará disponível em:
- **https://shape-log-app.web.app**
- **https://shape-log-app.firebaseapp.com**

### Script único (build + deploy)
```bash
./apply_cors.sh
```
O script `apply_cors.sh` na raiz do projeto executa CORS + build + deploy em sequência.

---

## 📋 Changelog

### v1.4.0
- **Offline-first para treinos**: treino salvo no Hive antes de tentar Firebase; sessão sempre limpa mesmo sem internet
- Firebase vira fire-and-forget no repositório — erros de rede não interrompem o fluxo de save
- Startup com upload de registros offline antes do download (preserva treinos salvos sem conexão)
- Download do Firebase por merge: não apaga registros locais pendentes de sync
- Pull-to-refresh na aba "Logs e IA" sincroniza bidirecional com Firebase (inclusive exclusões feitas na web)
- Barra de carregamento verde na splash page
- Cardio com duração < 1 minuto exibe segundos corretamente (ex: 30s, 1min 30s)
- Correção: app não ficava preso na splash sem internet (timeout de 6s no upload)

### v1.3.0
- Dashboard web SaaS com KPIs, gráfico de frequência semanal, atividade recente e preferência por dia
- Sidebar colapsável com animação suave e ícone da logo real
- Telas web adaptadas: Nova Medição, Editar Treino, Novo Exercício
- Mapa corporal interativo na tela de Nova Medição na web
- Layout anatômico dos campos de medida (topo → base, bilateral lado a lado)
- Ícones de ajuda (?) com explicação contextual em Analytics e Dashboard
- Coluna RPE (X/5) no histórico de treinos
- Correção do percentual de conclusão no histórico (estava sempre 1%)
- Imagens de exercícios disponíveis offline via cache persistente em disco (CachedNetworkImage)
- Logo real do app substituindo ícone genérico no menu e login web

### v1.2.0
- Sincronização bidirecional completa com Firebase (Firestore + Storage)
- Login com Google + modo convidado offline
- Exclusão permanente de treinos, histórico e medidas no Firestore
- Batch uploads por coleção com limite de 400 ops para evitar estouro
- Renderização híbrida de imagens: local (`FileImage`) e remota (`NetworkImage`) via `ImagePathResolver.resolveToImageProvider`
- Loading dialog com mensagem descritiva durante sincronização pós-restore
- Biblioteca de ativos enviada ao Storage em background durante restore
- Correções de `ListTile` dentro de `DecoratedBox` sem `Material` intermediário

### v1.1.0
- Sistema de backup e restore completo (`.zip`)
- Biblioteca de ativos com importação via `.zip`
- Suporte a exercícios cardio
- Timer de descanso configurável por exercício

### v1.0.0
- Lançamento inicial
- Gestão de treinos e exercícios
- Body Tracker com mapa corporal interativo
- Perfil biológico com cálculo de IMC
- Modo offline com persistência no Hive

---

Desenvolvido com 💙 por **João Paulo**.
