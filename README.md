# Shape.log

**Shape.log** é uma aplicação Flutter moderna e robusta desenvolvida para ser o seu companheiro definitivo de treinos e monitoramento corporal. Com uma interface inspirada em estética Cyberpunk/Futurista ("Cyber-Bio Scanner") e foco em usabilidade, o app permite gerenciar rotinas de exercícios, registrar medidas corporais detalhadas e manter um perfil biológico como fonte fiel de dados.

## 🚀 Funcionalidades Principais

### 1. Gestão de Treinos (Workout Tracker)
- **Criação de Rotinas**: Crie treinos personalizados (ex: "Treino A - Peito e Tríceps").
- **Importação Flexível (AI-Pipeline)**: Importe treinos gerados por IA (ChatGPT/Gemini) via arquivos `.json` ou colando o texto diretamente.
- **Sanitização Inteligente**: O app gera novos IDs automaticamente, limpa caminhos de imagem externos e reseta datas para evitar conflitos.
- **Registro de Exercícios**: Adicione exercícios com detalhes de Séries, Repetições, Carga, **Tempo de Descanso** e Técnica.
- **Timer de Descanso**: Configure o tempo de descanso individual por exercício (padrão 60s), com slider e chips de seleção rápida.
- **Notificações Sensoriais**: Alerta de fim de descanso com **Som Embutido** (que não interrompe sua música) e **Feedback Tátil** (vibração), garantindo que você nunca perca o início da próxima série.
- **Histórico de Execução**: Marque treinos como concluídos e acompanhe logs passados.
- **Ordenação Automática**: Seus treinos são organizados automaticamente em ordem alfabética para fácil acesso.
- **Interface Polida**: Títulos de treinos longos utilizam efeito *Marquee* (texto deslizante) para visibilidade completa.
- **Genius Focus Mode**: Interface de execução imersiva com grade compacta, histórico de carga (`📈`) acessível e persistência em tempo real.
- **Smart Timer**: Lógica inteligente que avança exercícios automaticamente e detecta o fim do treino.

### 2. Monitoramento de Medidas (Body Tracker)
- **Cyber-Bio Scanner (Mapa Corporal Interativo)**: Interface visual 3D-like onde você toca na parte do corpo (ex: Bíceps, Coxa) para registrar a medida.
- **Bioimpedância Integrada**: Campo para `reportUrl` que permite armazenar e abrir links de balanças de bioimpedância diretamente no navegador.
- **Rastreamento de Circunferências**: Suporte completo para medidas de Pescoço, Ombros, Tórax, Cintura, Quadril, Bíceps, Antebraços, Coxas e Panturrilhas.
- **Card de Medidas Expandível**: Visualize todas as circunferências e detalhes técnicos ao expandir os registros na lista.
- **Seleção Multi-imagem**: Adicione múltiplas fotos de progresso simultaneamente via Galeria.
- **Interface Unificada**: Fluxo de adição de fotos padronizado entre Treinos e Medidas.
- **Animações Fluidas**: Feedback visual com animações de "scanning" ao selecionar áreas.
- **Histórico Visual**: Visualize as fotos diretamente no histórico de medidas ao expandir os registros.
- **Filtros Inteligentes**: Visualize a evolução nos últimos 7, 30 ou 90 dias.

### 3. Perfil Biológico (Bio-Data Source of Truth)
- **Perfil Centralizado**: Armazena dados imutáveis como Altura, Nível de Atividade e Peso Meta.
- **Foto de Perfil Customizável**: Importe sua própria foto da galeria para personalizar a experiência do "scanner".
- **Cálculo Automático de IMC**: O app utiliza a altura do seu perfil para recalcular automaticamente o IMC de todos os registros históricos, garantindo precisão sem retrabalho.
- **Classificação OMS**: Monitoramento rigoroso do IMC seguindo padrões da Organização Mundial da Saúde (incluindo Obesidade I, II e III).
- **Persistência Local**: Todos os dados são salvos localmente de forma segura e rápida.

### 4. Interface e Usabilidade
- **Design Moderno**: Tema escuro com acentos em `Cyan` e `Purple`, seguindo padrões modernos de UI.
- **Reatividade Ultra-fluida**: Interface que se auto-atualiza instantaneamente ao salvar novos dados (HIVE Listenables).
- **Navegação Intuitiva**: Barra de navegação inferior persistente e rotas fluidas.
- **Inputs Otimizados**: Uso de Sliders, Chips e Segmented Buttons para facilitar a entrada de dados.
- **Diálogos Padronizados**: Sistema customizado de modais e diálogos para uma experiência visual coesa em todo o app.

### 5. Biblioteca de Ativos (Assets Library)
- **Importação de Pacotes**: Importe arquivos `.zip` contendo centenas de imagens de equipamentos ou execução.
- **Super Picker**: Ao adicionar fotos aos exercícios, escolha entre **Câmera**, **Galeria** ou a **Biblioteca Interna**.
- **Busca Rápida**: Filtre equipamentos pelo nome diretamente no seletor, agilizando a montagem de treinos visuais.

### 6. Sistema de Backup & Restore Completo
- **Backup Unificado**: Gera um arquivo `.zip` contendo todo o banco de dados (treinos, histórico, perfil) E todas as custom images (Asset Library + Fotos do Body Tracker).
- **Portabilidade**: Salve seus backups em qualquer lugar (Google Drive, WhatsApp, Local).
- **Restauração Simples**: Importe o arquivo zip para restaurar o estado exato do app.

### 7. Detalhes de Exercício Premium
- **Informação Rica**: Visualização clara de Séries, Repetições, Carga e **Descanso**.
- **Ajuda Interativa**: Ícones de informação com Tooltips explicativos para cada campo.
- **Integração YouTube**: Card premium com gradiente para "Assistir Tutorial" na tela de detalhes.
- **YouTube Quick-Play**: No modo de execução (Focus Mode), um botão 'Play' vermelho permite abrir o vídeo tutorial instantaneamente no app do YouTube.

---

## 🤖 Padrão de Importação JSON (AI-Ready)

Para que o sistema de importação funcione corretamente (via arquivo ou texto), o JSON deve seguir a estrutura abaixo. O app é flexível e aceita tanto uma lista direta `[]` quanto um objeto contendo a chave `"workouts"`.

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

### Especificações Técnicas:
- **`type`**: "strength" (padrão) ou "cardio".
- **`scheduledDays`**: Lista de números de 1 (Segunda) a 7 (Domingo).
- **`expiryDate`**: Data de validade do treino no formato `YYYY-MM-DD` (Opcional).
- **`reps`**: (Strength) Aceita números (`12`) ou strings para intervalos (`"10-12"`).
- **`weight`**: (Strength) Valor numérico (double/float) representando o peso em kg.
- **`durationMinutes`**: (Cardio) Tempo em minutos.
- **`intensity`**: (Cardio) String livre para descrever velocidade/zona (ex: "Zona 2").
- **`restTime`** (ou `restSeconds`): Tempo de descanso em segundos (ex: `60`, `90`). Padrão: 60s.
- **`youtubeUrl`**: Link completo do vídeo tutorial no YouTube (Opcional).
- **Sanitização Automática**: Os campos `id`, `imagePaths` e `activeStartTime` são gerados ou resetados pelo app.

---

## �🛠 Tecnologias Utilizadas

O projeto segue os princípios de **Clean Architecture** para garantir escalabilidade e testabilidade.

- **Frontend**: [Flutter](https://flutter.dev) (Dart)
- **Gerenciamento de Estado**: [Riverpod 2.0](https://riverpod.dev) (Providers, Notifiers, AsyncNotifiers)
- **Banco de Dados Local**: [Hive](https://docs.hivedb.dev/) (NoSQL, rápido e leve)
- **Roteamento**: [GoRouter](https://pub.dev/packages/go_router)
- **Utilitários**:
  - `intl`: Formatação de datas.
  - `body_part_selector`: Base para o mapa corporal.
  - `google_fonts`: Tipografia premium (Inter).
  - `audioplayers`: Reprodução de sons.
  - `vibration`: Feedback tátil.

---

## 📂 Estrutura do Projeto

```
lib/
├── core/           # Configurações globais (Router, Theme, Constants)
├── features/       # Módulos funcionais
│   ├── workout/        # Lógica de Treinos
│   ├── body_tracker/   # Lógica de Medidas e Mapa Corporal
│   ├── profile/        # Perfil do Usuário e Dados Biológicos
│   ├── settings/       # Configurações do App
│   └── splash/         # Tela de Inicialização e Redirecionamento
└── main.dart       # Ponto de entrada
```

---

## ▶️ Como Rodar o Projeto

1. **Pré-requisitos**: Certifique-se de ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
2. **Instalar Dependências**:
   ```bash
   flutter pub get
   ```
3. **Gerar Adaptadores do Hive** (necessário para o banco de dados):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Executar**:
   ```bash
   flutter run
   ```

---

## 📱 Capturas de Tela (Conceito)

- **Home**: Dashboard com atalhos.
- **Treinos**: Lista de rotinas ativas.
- **Medidas**: Lista expandível com gráfico de IMC.
- **Scanner**: Modelo corporal interativo.

---

Desenvolvido com 💙 por **João Vieira**.
