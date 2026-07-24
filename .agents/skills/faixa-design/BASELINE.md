# Baseline — dívida visual conhecida (auditoria de 2026-07-16)

Inventário do estado atual que a skill `faixa-design` remove. Use para localizar a dívida; à medida que telas forem restilizadas, risque os itens desta lista. Quando o grep final da SKILL.md passar limpo em todo o `lib/`, este arquivo pode ser apagado.

## 1. Resíduo de exportação Stitch (a "cara de IA" declarada no código)

- `lib/app/theme/app_theme.dart:5,33-34` — comentários "Stitch primary" / "no design Stitch".
- `lib/app/theme/app_theme.dart:37-41` — classe `StitchColors`, usada como alias em dezenas de widgets de auth.
- `lib/app/theme/app_theme.dart:34` — `stitchAppBar = #B86E00` (marrom), usado nas home dos portais via `faixa_app_bar.dart:29`; telas internas já usam o amarelo `#FF9E1B` (`faixa_app_bar.dart:66`). Unificar.
- Tokens cruft: `warning`/`warningDark` sobrepostos (`app_theme.dart:19-20`), `shadowDark`/`shadowExtraDark` idênticos (`app_theme.dart:30-31`), `mapBackground` cinza-azulado `#8BA0B0` (`app_theme.dart:24`).

## 2. Monotonia de cards (uma receita só em tudo)

`Container` branco + borda `E5E7EB` 50% + radius 16 + `BoxShadow` blur 8 offset (0,2):

- `lib/features/**/dashboard_metric_grid.dart:31-44`
- `lib/features/**/dashboard_action_grid.dart:41-54`
- `lib/features/parent_portal/presentation/pages/parent_dashboard_page.dart:223-227`
- `lib/app/widgets/app_shared_widgets.dart:147-153, 211-215`
- Card-herói de rota hoje é pastel tímido: `dashboard_status_card.dart:31` → candidato a L1 amarelo cheio.

## 3. Ícone colorido em quadradinho com alpha 0.08 (clichê admin-template)

- `dashboard_metric_grid.dart:29-30` (`iconColor.withValues(alpha: 0.08)`)
- `app_shared_widgets.dart:213, 416-418, 456-458`
- `dashboard_status_card.dart:56-59`
- Labels de métricas em CAIXA ALTA: `dashboard_metric_grid.dart:69` → sentence case + display numérico.

## 4. Tipografia split-brain (39 chamadas GoogleFonts em 11 arquivos)

Tema declara Poppins/Inter bundladas (`app_theme.dart:89-123`, `pubspec.yaml:104-117`), mas telas chamam `GoogleFonts.poppins/inter` direto com tamanhos/pesos hardcoded:

- `lib/app/widgets/faixa_app_bar.dart:3,41`
- auth: `login_form.dart:87-90`, `auth_shell.dart:59-75` e demais telas de auth
- grep de verificação: `grep -rn "GoogleFonts\." lib/ | wc -l` → alvo: 0, depois remover `google_fonts` do `pubspec.yaml`.

## 5. Marca sem faixa e sem glyph próprio

- Lockup da AppBar = `Icons.school_rounded` + texto caps (`faixa_app_bar.dart:37-48`).
- Splash = container amarelo com `Icons.airport_shuttle_rounded` 64px (`splash_page.dart:65-92`).
- Fallbacks silenciosos para ícone stock: `auth_shell.dart:156-165`, `splash_page.dart:33-42`.
- Assets de marca existentes: apenas `assets/logo.png` e `logo_launcher.png`. Não existe motivo faixa/listra em lugar nenhum — o `CustomClipper` de `auth_shell.dart:200-223` é o ponto de entrada (curva genérica → faixa diagonal reta).

## 6. Copy gerada

- "Bem-vindo!" (`login_page.dart:22`), "Olá, $firstName!" + subtítulo (`dashboard_header.dart:27-35`).
- Tagline "Transporte Escolar Inteligente" (`auth_shell.dart:182`, `splash_page.dart:57`).

## O que já é bom — preservar

- Tokens `AppColors/AppSpacing/AppRadius` adotados de verdade (quase nenhum `Color(0x` fora do tema; só 4, sombras em auth/splash).
- `ThemeData` completo (`app_theme.dart:181-353`), aplicado em `app.dart:131`.
- Estados vazios/erro centralizados e usados: `FaixaEmptyState`/`FaixaErrorState` (`app_shared_widgets.dart:17-131`); skeletons; `AppPulsingDot` para "ao vivo".
- Bottom nav com par outlined/filled por item (`faixa_bottom_nav.dart`).
- Zero emoji na UI; sem gradiente roxo/azul.
