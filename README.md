# Shape.log

**Shape.log** é uma aplicação Flutter moderna e robusta desenvolvida para ser o seu companheiro definitivo de treinos e monitoramento corporal. Com uma interface inspirada em estética Cyberpunk/Futurista ("Cyber-Bio Scanner") e foco em usabilidade, o app permite gerenciar rotinas de exercícios, registrar medidas corporais detalhadas e manter um perfil biológico como fonte fiel de dados.

## 🚀 Funcionalidades Principais

### 1. Gestão de Treinos (Workout Tracker)
- **Criação de Rotinas**: Crie treinos personalizados (ex: "Treino A - Peito e Tríceps").
- **Importação Flexível (AI-Pipeline)**: Importe treinos gerados por IA (ChatGPT/Gemini) via arquivos `.json` ou colando o texto diretamente.
- **Sanitização Inteligente**: O app gera novos IDs automaticamente, limpa caminhos de imagem externos e reseta datas para evitar conflitos.
- **Registro de Exercícios**: Adicione exercícios com detalhes de Séries, Repetições, Carga e Descanso.
- **Histórico de Execução**: Marque treinos como concluídos e acompanhe logs passados.
- **Interface Polida**: Títulos de treinos longos utilizam efeito *Marquee* (texto deslizante) para visibilidade completa.

### 2. Monitoramento de Medidas (Body Tracker)
- **Cyber-Bio Scanner (Mapa Corporal Interativo)**: Interface visual 3D-like onde você toca na parte do corpo (ex: Bíceps, Coxa) para registrar a medida.
- **Registro de Fotos de Progresso**: Adicione múltiplas fotos via galeria ou câmera para cada medição, permitindo o acompanhamento visual da evolução.
- **Animações Fluidas**: Feedback visual com animações de "scanning" ao selecionar áreas.
- **Histórico Visul**: Visualize as fotos diretamente no histórico de medidas ao expandir os registros.
- **Filtros Inteligentes**: Visualize a evolução nos últimos 7, 30 ou 90 dias.

### 3. Perfil Biológico (Bio-Data Source of Truth)
- **Perfil Centralizado**: Armazena dados imutáveis como Altura, Nível de Atividade e Peso Meta.
- **Cálculo Automático de IMC**: O app utiliza a altura do seu perfil para recalcular automaticamente o IMC de todos os registros históricos, garantindo precisão sem retrabalho.
- **Persistência Local**: Todos os dados são salvos localmente de forma segura e rápida.

### 4. Interface e Usabilidade
- **Design Moderno**: Tema escuro com acentos em `Cyan` e `Purple`, seguindo padrões modernos de UI.
- **Navegação Intuitiva**: Barra de navegação inferior persistente e rotas fluidas.
- **Inputs Otimizados**: Uso de Sliders, Chips e Segmented Buttons para facilitar a entrada de dados.

---

## � Padrão de Importação JSON (AI-Ready)

Para que o sistema de importação funcione corretamente (via arquivo ou texto), o JSON deve seguir a estrutura abaixo. O app é flexível e aceita tanto uma lista direta `[]` quanto um objeto contendo a chave `"workouts"`.

### Exemplo de Estrutura Completa
```json
{
  "workouts": [
    {
      "name": "Nome do Treino",
      "scheduledDays": [1, 3, 5],
      "targetDurationMinutes": 60,
      "notes": "Observações gerais",
      "exercises": [
        {
          "name": "Nome do Exercício",
          "sets": 4,
          "reps": "12",
          "weight": 30.0,
          "technique": "Opcional: Instrução técnica",
          "equipmentNumber": "Opcional: ID da máquina"
        }
      ]
    }
  ]
}
```

### Especificações Técnicas:
- **`scheduledDays`**: Lista de números de 1 (Segunda) a 7 (Domingo).
- **`reps`**: Aceita números (`12`) ou strings para intervalos (`"10-12"`).
- **`weight`**: Valor numérico (double/float) representando o peso em kg.
- **Sanitização Automática**: Os campos `id`, `imagePaths` e `activeStartTime` são gerados ou resetados pelo app, portanto, não precisam ser enviados no JSON.

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
