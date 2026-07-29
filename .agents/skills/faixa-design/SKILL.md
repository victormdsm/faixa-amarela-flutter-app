---
name: faixa-design
description: Faixa Amarela brand system for Flutter UI. Use when creating or restyling any screen or widget in app_faixa_amarela — theme, cards, AppBars, icons, splash/auth, empty states, copy.
---

# faixa-design

**Faixa** (the stripe) is the leading word: traffic signage, school-bus livery, safety. Every screen should read as *safety equipment for school transport* — a tool parents and drivers trust — not an admin dashboard.

The test for any visual decision: *does this look like it belongs on the side of a school bus, or in a SaaS template?* Pick the school bus.

## Tokens

Single source of truth: `lib/app/theme/app_theme.dart` (`AppColors`, `AppSpacing`, `AppRadius`, `textTheme`). Screens consume tokens; they do not invent local values.

- **Brand yellow `#FF9E1B`** is the only brand color. It carries all emphasis: hero surfaces, active states, the faixa itself.
- **Ink on yellow**: text and icons on yellow surfaces are dark, never white — white on `#FF9E1B` fails contrast.
- **AppBar**: white with a 4px yellow faixa on its bottom edge, app-wide. Full yellow only on splash/auth.
- Dead tokens — delete on touch: `StitchColors`, `stitchAppBar` (`#B86E00`), the `warning`/`warningDark` and `shadowDark`/`shadowExtraDark` duplicates (`app_theme.dart:19-20, 30-31`).

## Surfaces — three levels, nothing in between

Every surface on a screen declares its level:

- **L1 Hero** — exactly one per screen: the thing that matters now (active route, live boarding). Solid brand yellow, ink text, no shadow.
- **L2 List items** — hairline divider only. No shadow, no border, no per-item rounded card.
- **L3 Metrics** — small and borderless. Number in Poppins Bold 28+; label sentence-case beneath it; number and label never compete at the same weight.

Shadow is reserved for what floats: map, bottom sheet, FAB, floating banner.

## Typography

Only `Theme.of(context).textTheme`. Poppins for display and numbers, Inter for body — both bundled in `assets/fonts/`. `GoogleFonts.*` downloads at runtime what we already ship: remove every call, then drop the dependency from `pubspec.yaml`.

## Iconography and brand marks

- Brand source of truth: `assets/brand/logo.svg` (official: Pantone 1375C yellow square with black FA monogram, black wordmark and the school-van glyph with yellow faixa under the wordmark). Rendered assets: `assets/images/logo.png` + density variants; launcher icons regenerate via `dart run flutter_launcher_icons` (input `assets/brand/logo-icon-1024.png`, gitignored, rendered from the SVG). A missing asset fails visibly (error widget) — a silent stock-icon fallback turns the brand into clip-art.
- On yellow surfaces the yellow square disappears: use the transparent variant `assets/brand/logo-transparent.svg` (legacy composition: yellow F, ink A) or set the square logo on a white tile.
- Vehicle glyph: the van with faixa. Until a custom asset exists, `Icons.directions_bus_rounded` set on a yellow faixa — the bare `airport_shuttle`/`school` stock icons are out.
- Icons sit plain, or ink on yellow. The colored-icon-inside-a-tinted-square (alpha ≈ 0.08) is the admin-template cliché this redesign exists to remove.
- The **faixa** motif: a yellow diagonal stripe, signage-style (~45°), reused at the splash/auth header (the existing `CustomClipper` in `auth_shell.dart` becomes a straight diagonal), section dividers, empty states, and the hero card's foot.

## Profiles — same system, different voice

One design system, two readings. Structure (shell, nav, surfaces) is identical; vocabulary and heroes differ.

- **Parent portal (`/pais`)**: the child is the subject. Vocabulary: "criança"/"filho" — never "aluno" or "cliente". L1 hero: the child's live route (map, van, boarding status). Tone: calm reassurance.
- **Driver portal (`/motorista`)**: the work is the subject. Vocabulary: "aluno"/"responsável" — "cliente" only in business contexts (coverage, billing). L1 hero: route execution (next stop, progress). Tone: tool-like efficiency.
- Children glyphs come from the family/person icon set — the stock `Icons.school` is out (it's the app-avatar cliché and the semantic of a building, not a child).

## Copy

Voice: the calm confidence of people trusted with children. Safety and presence over "smart".

- Tagline: "Seu filho a caminho, você acompanhando" — "Transporte Escolar Inteligente" is retired.
- Screen titles name the thing ("Rota de hoje"); buttons are verb + object ("Acompanhar rota"). Greeting headers ("Bem-vindo!", "Olá, $name!") that carry no information are replaced by the screen's actual state.
- Empty/error states keep their existing copy; swap the grey stock icon for the van-with-faixa illustration.

## Restyling a screen

1. Inventory the screen's deviations from this file. For the known debt list, read [BASELINE.md](BASELINE.md).
2. Apply in order: colors/brand → surfaces → type → icons → copy.
3. Done when, across the touched files: `grep -nE "StitchColors|GoogleFonts|0xFFB86E00|airport_shuttle|school_rounded|alpha: 0\.08"` returns empty; exactly one L1 hero exists; `flutter analyze` is clean.

## Creating a screen

Start from the surface levels: pick the single L1 hero first, then L2 lists, then L3 metrics. If nothing on the screen deserves L1, the screen ships without a hero. Done when the same checks as above pass.
