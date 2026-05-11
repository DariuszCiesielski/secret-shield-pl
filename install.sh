#!/usr/bin/env bash
# Secret Shield PL — instalator
# https://github.com/DariuszCiesielski/secret-shield-pl
#
# Użycie (z roota dowolnego repo git):
#   curl -fsSL https://raw.githubusercontent.com/DariuszCiesielski/secret-shield-pl/main/install.sh | bash
#
# Lub po pobraniu lokalnym:
#   bash install.sh

set -e

REPO_CDN="https://cdn.jsdelivr.net/gh/DariuszCiesielski/secret-shield-pl@main"
CONFIG_URL="$REPO_CDN/.gitleaks.toml"
HOOK_URL="$REPO_CDN/hooks/pre-push"

# === 1. Sprawdzenia środowiska ===

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  echo "❌ Nie wykryto repozytorium git."
  echo "   Uruchom z katalogu w którym jest folder .git/"
  exit 1
fi

cd "$REPO_ROOT"

echo "🛡️  Secret Shield PL — instalator"
echo "   Repo: $REPO_ROOT"
echo ""

# === 2. Sprawdzenie gitleaks ===

if ! command -v gitleaks &> /dev/null; then
  echo "ℹ️  gitleaks nie jest zainstalowany — hook zainstaluję, ale skan będzie pomijany."
  echo "   Aby aktywować ochronę:"
  echo "     macOS:   brew install gitleaks"
  echo "     Linux:   https://github.com/gitleaks/gitleaks#installing"
  echo "     Windows: scoop install gitleaks"
  echo ""
fi

# === 3. Konflikty — .gitleaks.toml ===
# Domyślnie: NIE nadpisuj istniejącego configu (safe default).
# Aby wymusić nadpisanie: SECRET_SHIELD_FORCE_CONFIG=1 curl ... | bash

SKIP_CONFIG=0
if [ -f ".gitleaks.toml" ]; then
  if [ "${SECRET_SHIELD_FORCE_CONFIG:-0}" = "1" ]; then
    cp .gitleaks.toml .gitleaks.toml.backup
    echo "⚠️  Istnieje .gitleaks.toml — nadpisuję (backup: .gitleaks.toml.backup)"
  else
    echo "ℹ️  Istnieje .gitleaks.toml — zachowuję. Aby nadpisać:"
    echo "   SECRET_SHIELD_FORCE_CONFIG=1 curl ... | bash"
    SKIP_CONFIG=1
  fi
fi

# === 4. Pobieranie konfiguracji ===

if [ "$SKIP_CONFIG" = "0" ]; then
  echo "→ Pobieranie .gitleaks.toml"
  curl -fsSL "$CONFIG_URL" -o .gitleaks.toml
fi

# === 5. Instalacja hooka pre-push ===

HOOK_PATH=".git/hooks/pre-push"

if [ -f "$HOOK_PATH" ]; then
  echo "⚠️  Istnieje już $HOOK_PATH — robię backup do $HOOK_PATH.backup"
  cp "$HOOK_PATH" "$HOOK_PATH.backup"
fi

echo "→ Pobieranie hooka pre-push"
curl -fsSL "$HOOK_URL" -o "$HOOK_PATH"
chmod +x "$HOOK_PATH"

# === 6. Smoke test (opcjonalny) ===

echo ""
echo "✅ Secret Shield PL zainstalowany."
echo ""
echo "   Pliki:"
echo "   • .gitleaks.toml         — konfiguracja wzorców (commit do repo)"
echo "   • $HOOK_PATH    — hook (lokalny, nie commitowany)"
echo ""
echo "   Każdy push będzie teraz skanowany. Sekrety = blokada."
echo ""
echo "   Test ręczny:"
echo "     1. Utwórz plik test-leak.js z kluczem sk-proj- + 40 losowych znaków"
echo "     2. git add . && git commit -m test && git push"
echo "     3. Push powinien zostać ZABLOKOWANY"
echo "     4. rm test-leak.js && git reset --hard HEAD~1   # cofnij"
echo ""
echo "   Dokumentacja: https://github.com/DariuszCiesielski/secret-shield-pl"
