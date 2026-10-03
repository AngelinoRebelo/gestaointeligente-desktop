#!/usr/bin/env bash
# Instala o Gestão Inteligente (Ubuntu/Linux) a partir do GitHub Releases.
# Uso:
#   curl -fsSL https://www.gestaointeligente.com.br/install-linux.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/AngelinoRebelo/gestaointeligente/main/scripts/install-linux.sh | bash
set -euo pipefail

REPO="${GI_GITHUB_REPO:-AngelinoRebelo/gestaointeligente-desktop}"
TAG="${GI_RELEASE_TAG:-desktop-linux}"
APPIMAGE_NAME="${GI_APPIMAGE_NAME:-Gestao-Inteligente-Linux.AppImage}"
DOWNLOAD_URL="${GI_DOWNLOAD_URL:-https://github.com/${REPO}/releases/download/${TAG}/${APPIMAGE_NAME}}"

INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/GestaoInteligente"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
APP_PATH="${INSTALL_DIR}/${APPIMAGE_NAME}"
DESKTOP_PATH="${APP_DIR}/gestaointeligente.desktop"

echo "→ Gestão Inteligente — instalador Linux"
echo "  Fonte: ${DOWNLOAD_URL}"

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$APP_DIR" "$ICON_DIR"
TMP="$(mktemp)"
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

echo "→ Baixando aplicativo…"
if command -v curl >/dev/null 2>&1; then
  curl -fL --progress-bar -o "$TMP" "$DOWNLOAD_URL"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$TMP" "$DOWNLOAD_URL"
else
  echo "Erro: precisa de curl ou wget." >&2
  exit 1
fi

# Sanity: AppImage costuma ter alguns MB
SIZE="$(wc -c < "$TMP" | tr -d ' ')"
if [ "${SIZE:-0}" -lt 1000000 ]; then
  echo "Erro: download inválido (${SIZE} bytes). Verifique se o release ${TAG} existe no GitHub." >&2
  exit 1
fi

install -m 755 "$TMP" "$APP_PATH"
ln -sfn "$APP_PATH" "${BIN_DIR}/gestaointeligente"

# Ícone embutido (fallback) — tenta extrair do AppImage se possível
ICON_DST="${ICON_DIR}/gestaointeligente.png"
if [ ! -f "$ICON_DST" ]; then
  if command -v "$APP_PATH" >/dev/null 2>&1; then
    EXTRACT_DIR="$(mktemp -d)"
    if (cd "$EXTRACT_DIR" && "$APP_PATH" --appimage-extract "*.png" >/dev/null 2>&1); then
      FOUND="$(find "$EXTRACT_DIR" -type f -name '*.png' | head -n 1 || true)"
      if [ -n "${FOUND:-}" ]; then
        install -m 644 "$FOUND" "$ICON_DST"
      fi
    fi
    rm -rf "$EXTRACT_DIR"
  fi
fi

ICON_LINE="Icon=gestaointeligente"
if [ ! -f "$ICON_DST" ]; then
  ICON_LINE="Icon=application-x-executable"
fi

cat > "$DESKTOP_PATH" <<EOF
[Desktop Entry]
Type=Application
Name=Gestão Inteligente
Comment=Gestão para igrejas — local-first com sincronização
Exec=${APP_PATH}
${ICON_LINE}
Terminal=false
Categories=Office;Finance;
StartupWMClass=Gestao Inteligente
EOF
chmod 644 "$DESKTOP_PATH"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

echo
echo "✓ Instalado em: ${APP_PATH}"
echo "✓ Atalho no menu: Gestão Inteligente"
echo "✓ Comando: gestaointeligente   (se ${BIN_DIR} estiver no PATH)"
echo
echo "Abra pelo menu de aplicativos ou execute:"
echo "  ${APP_PATH}"
echo
echo "Na primeira abertura: entre com a conta no navegador e crie um PIN de 6 dígitos."
