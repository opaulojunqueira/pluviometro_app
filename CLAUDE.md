# CLAUDE.md — Pluviômetro Digital

Instruções persistentes para qualquer trabalho futuro neste repositório.

## O que é

App **Flutter** (Android) para produtores rurais registrarem e acompanharem a
chuva (precipitação em mm), **100% offline**. Público: produtores, técnicos e
estudantes de agro. A essência é simplicidade, clareza e confiança.

## Arquitetura

- **Organização por feature** em `lib/features/<feature>/` (cada tela e seus
  widgets ficam juntos).
- **Camada de dados:**
  - `lib/services/database_service.dart` — SQLite (`sqflite`), singleton
    `DatabaseService.instance`. Tabelas `rain_records` e `saved_reports`.
    Prefira queries SQL **enxutas e específicas** (SUM/LIKE/LIMIT) em vez de
    carregar todos os registros na memória.
  - `lib/services/preferences_service.dart` — `SharedPreferences`, singleton
    `PreferencesService.instance` (perfil, flags de onboarding, notificações).
- **Models:** `lib/models/` (`RainRecord`, `SavedReport`) — imutáveis, com
  `toMap`/`fromMap`/`copyWith`. Datas persistidas como `yyyy-MM-dd`.
- **Navegação:** Splash → Onboarding → SkipLogin (coleta nome/cidade) → Home.
  `HomeScreen` usa `IndexedStack` + `BottomNavigationBar` com 4 abas
  (Dashboard, Calendário, Relatórios, Ajustes) e faz `refresh()` na aba ao
  trocar (via `GlobalKey`).

## Design System (seguir SEMPRE)

Centralizado em `lib/theme/`:

- **`app_colors.dart` — `AppColors`:** fonte única de cores. **Nunca** declare
  cores soltas (`Color(0xFF...)`, `Colors.blue.shadeXXX`) nas telas; use os
  tokens. Identidade: **azul-chuva** (`primary`) como cor-mãe, **verde-agro**
  (`secondary`) como apoio, **âmbar/sol** (`amber`) para estiagem/destaques.
- **`app_theme.dart` — `AppTheme.light`:** tema global.
  - Tipografia: **Plus Jakarta Sans** (via `google_fonts`).
  - Cards **planos com borda sutil** (`AppColors.border`), sem sombra pesada.
  - **Evitar:** gradientes chamativos, glassmorphism, sombras pesadas, brilhos.
- **Widgets compartilhados** em `lib/shared/widgets/`:
  - `ScreenHeader` (cabeçalho padrão das abas), `LoadingView` (loading padrão),
    `SharedAppBar` (topo com logo + avatar).

Princípios de UI: muito respiro, hierarquia clara, ícones discretos, feedback
claro, consistência entre telas. Cores semânticas: `success`/`warning`/`danger`.

## Convenções

- Strings de UI em **pt-BR**. Datas/números formatados com `intl` (locale
  `pt_BR`, já inicializado em `main.dart`).
- `withValues(alpha:)` em vez de `withOpacity` (deprecated).
- Em código assíncrono com `BuildContext`, sempre cheque `if (!mounted) return;`
  após `await` antes de usar o `context`.
- `showDialog<T>` deve ser tipado de acordo com o que os botões retornam (não
  retorne `String` de um `showDialog<bool>`).

## Regras de negócio

- Novos registros só podem ser adicionados nos **últimos 30 dias** (edição de
  registros existentes não tem essa trava).
- Classificação de chuva mensal (`RainClassification.fromMillimeters`):
  0 = Sem Chuva · ≤50 = Leve · ≤100 = Moderada · ≤200 = Boa · >200 = Intensa.
- Alerta de estiagem: a partir de `kDroughtAlertDays` (10) dias sem chuva.

## Build / Testes

```bash
flutter pub get
flutter analyze
flutter test
flutter run            # dispositivo/emulador Android
```

Os testes em `test/widget_test.dart` são offline (sem DB/rede/timers): cobrem a
classificação de chuva e a renderização de um card.

## Ao alterar

- Não quebre o que funciona; preserve a essência e a identidade visual.
- Toda mudança visual deve aumentar clareza/confiança/usabilidade.
- Mudanças de cor/tipografia: ajuste em `lib/theme/`, não tela a tela.
- Mantenha as queries do `DatabaseService` específicas e performáticas.
