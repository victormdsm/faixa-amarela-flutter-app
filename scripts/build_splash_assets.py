#!/usr/bin/env python3
"""Gera os assets nativos de splash a partir de assets/brand/logo.svg.

Uso:
    python3 -m venv .splash-venv
    .splash-venv/bin/pip install cairosvg
    .splash-venv/bin/python scripts/build_splash_assets.py

A arte final é o lockup oficial (quadrado amarelo #FF9E1B com monograma FA,
wordmark e a van) renderizado com margem transparente de ~25%: o fundo
amarelo fica por conta do launch_background.xml (Android) e do
LaunchScreen.storyboard (iOS), então a borda do bitmap some no fundo.

Saídas:
    android/app/src/main/res/drawable-<dpi>/launch_image.png
    ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage[@2x/@3x].png
    build/splash/master-2048.png (master para inspeção visual)
"""

from pathlib import Path

import cairosvg

ROOT = Path(__file__).resolve().parent.parent
LOGO_SVG = ROOT / "assets" / "brand" / "logo.svg"

# viewBox original 1500x1501 -> 2000x2000: conteúdo passa a ocupar 75% do
# canvas, centrado; a faixa extra fica transparente (o fundo nativo é a cor
# da marca).
PADDED_VIEWBOX = 'viewBox="-250 -250 2000 2000"'
ORIGINAL_VIEWBOX = 'viewBox="0 0 1500 1501"'

TARGETS = {
    # Android: bitmap centralizado, ~288dp de lado em qualquer densidade.
    "android/app/src/main/res/drawable-mdpi/launch_image.png": 288,
    "android/app/src/main/res/drawable-hdpi/launch_image.png": 432,
    "android/app/src/main/res/drawable-xhdpi/launch_image.png": 576,
    "android/app/src/main/res/drawable-xxhdpi/launch_image.png": 864,
    "android/app/src/main/res/drawable-xxxhdpi/launch_image.png": 1152,
    # iOS: LaunchImage 1x/2x/3x exibida a 200pt (contentMode=center).
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png": 200,
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png": 400,
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png": 600,
    # Master em alta resolução para inspeção (build/ é gitignored).
    "build/splash/master-2048.png": 2048,
}


def main() -> None:
    svg = LOGO_SVG.read_text(encoding="utf-8")
    if ORIGINAL_VIEWBOX not in svg:
        raise SystemExit(f"viewBox esperado não encontrado em {LOGO_SVG}")
    padded = svg.replace(ORIGINAL_VIEWBOX, PADDED_VIEWBOX, 1)

    for relative, size in TARGETS.items():
        out = ROOT / relative
        out.parent.mkdir(parents=True, exist_ok=True)
        cairosvg.svg2png(
            bytestring=padded.encode("utf-8"),
            write_to=str(out),
            output_width=size,
            output_height=size,
        )
        print(f"{relative}: {size}x{size}")


if __name__ == "__main__":
    main()
