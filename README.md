# 🌧️ Pluviômetro Digital

> App mobile para registro e análise de precipitação pluviométrica — desenvolvido para o produtor rural brasileiro.

---

## 📱 Sobre o App

O **Pluviômetro Digital** é um aplicativo Flutter voltado para produtores rurais que precisam acompanhar a chuva de forma simples, rápida e offline. Com ele é possível registrar a precipitação diária, visualizar estatísticas mensais e anuais, gerar relatórios em PDF e exportar os dados para backup.

### ✅ Funcionalidades atuais

| Funcionalidade | Descrição |
|---|---|
| 📅 **Calendário** | Visualize dias com chuva (marcadores verdes), selecione um dia e registre ou edite a precipitação |
| 📊 **Dashboard** | Destaque da última leitura com **alerta de estiagem**, totais mensal e anual, dias com chuva, classificação de intensidade, gráfico dos últimos 6 meses, média histórica e **comparativo anual** |
| 📄 **Relatórios** | Geração de PDF com resumo e log diário; compartilhamento e salvamento local |
| ⚙️ **Configurações** | Perfil do usuário (nome, cidade, propriedade), gerenciamento de dados (export/import JSON, exclusão) e toggle de notificações |
| 💾 **Armazenamento local** | Banco de dados SQLite 100% offline — nenhum dado sai do dispositivo |

### 🌧️ Classificação de intensidade

| Faixa (mm/mês) | Classificação |
|---|---|
| 0 mm | Sem Chuva ☀️ |
| 1 – 50 mm | Chuva Leve 🌤️ |
| 51 – 100 mm | Chuva Moderada 🌧️ |
| 101 – 200 mm | Chuva Boa 🌨️ |
| > 200 mm | Chuva Intensa ⛈️ |

---

## 🛠️ Tecnologias utilizadas

- **[Flutter](https://flutter.dev/)** — framework cross-platform (Dart)
- **[sqflite](https://pub.dev/packages/sqflite)** — banco de dados SQLite local
- **[shared_preferences](https://pub.dev/packages/shared_preferences)** — persistência de preferências do usuário
- **[table_calendar](https://pub.dev/packages/table_calendar)** — calendário interativo
- **[pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing)** — geração e visualização de relatórios PDF
- **[share_plus](https://pub.dev/packages/share_plus)** — compartilhamento de arquivos
- **[file_picker](https://pub.dev/packages/file_picker)** — seleção de arquivos para importação
- **[url_launcher](https://pub.dev/packages/url_launcher)** — links externos e e-mail
- **[intl](https://pub.dev/packages/intl)** — formatação de datas em pt_BR
- **[google_fonts](https://pub.dev/packages/google_fonts)** — tipografia (Plus Jakarta Sans)

---

## 📂 Estrutura do projeto

```
lib/
├── main.dart                     # Ponto de entrada e tema global
├── models/                       # Entidades de dados
│   ├── rain_record.dart
│   └── saved_report.dart
├── services/                     # Lógica de negócio e acesso a dados
│   ├── database_service.dart     # SQLite (singleton)
│   └── preferences_service.dart  # SharedPreferences (singleton)
├── shared/
│   └── widgets/
│       └── shared_app_bar.dart   # AppBar reutilizável
└── features/                     # Organização por funcionalidade
    ├── auth/                     # Login, registro, recuperação de senha
    ├── home/                     # HomeScreen (BottomNavigationBar)
    ├── splash/                   # SplashScreen
    ├── onboarding/               # Tela de boas-vindas
    ├── dashboard/                # Tab inicial com analytics
    │   └── widgets/              # StatCard, RainyDaysCard, BarChart, etc.
    ├── calendar/                 # Tab de calendário e registros
    ├── reports/                  # Tab de relatórios + geração de PDF
    ├── settings/                 # Tab de configurações
    ├── profile/                  # Tela de perfil do usuário
    ├── add_record/               # Tela de adicionar/editar registro
    └── data_management/          # Exportar, importar e excluir dados
```

---

## 🚀 Roadmap — Melhorias futuras

### ☁️ Previsão do tempo (Weather API)
> Integrar uma API de meteorologia (ex: [OpenWeatherMap](https://openweathermap.org/), [Open-Meteo](https://open-meteo.com/)) para exibir no dashboard a previsão de chuva para os próximos dias, ajudando o produtor a planejar atividades no campo.

### 🔐 Autenticação e sincronização em nuvem
> Adicionar login com e-mail/Google via **Firebase Auth** e salvar os registros no **Cloud Firestore**, permitindo:
> - Acesso aos dados em múltiplos dispositivos
> - Backup automático na nuvem
> - Compartilhamento de dados entre usuários da mesma propriedade

### 📈 Análises avançadas
> - Comparação entre anos
> - Alertas de seca ou excesso de chuva
> - Gráfico de dispersão por mês/ano

### 🔔 Notificações inteligentes
> Lembretes diários configuráveis para registrar a chuva, e alertas automáticos baseados em dados de previsão.

### 🗺️ Múltiplas propriedades
> Permitir que o usuário cadastre mais de uma propriedade e alterne entre elas facilmente.

---

## 📸 Plataformas suportadas

| Plataforma | Status |
|---|---|
| Android | ✅ Suportado |

---

## 👨‍💻 Autor

Desenvolvido por **Paulo Junqueira**  
🌐 [paulojunqueira.com](https://paulojunqueira.com) · ✉️ contato@paulojunqueira.com

---

*Feito com ❤️ para o produtor rural brasileiro.*
