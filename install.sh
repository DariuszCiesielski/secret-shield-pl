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

REPO_RAW="https://raw.githubusercontent.com/DariuszCiesielski/secret-shield-pl/main"
CONFIG_URL="$REPO_RAW/.gitleaks.toml"
HOOK_URL="$REPO_RAW/hooks/pre-push"

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
  echo "⚠️  gitleaks nie jest zainstalowany."
  echo ""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   macOS:   brew install gitleaks"
  fi
  echo "   Linux:   https://github.com/gitleaks/gitleaks#installing"
  echo "   Windows: scoop install gitleaks  (lub https://github.com/gitleaks/gitleaks/releases)"
  echo ""
  read -r -p "Kontynuować instalację mimo to? (hook będzie pomijać skan dopóki nie zainstalujesz gitleaks) [t/N] " ans
  if [[ ! "$ans" =~ ^[tTyY]$ ]]; then
    echo "Przerwano."
    exit 0
  fi
fi

# === 3. Konflikty — .gitleaks.toml ===

if [ -f ".gitleaks.toml" ]; then
  echo "⚠️  W repo już jest .gitleaks.toml."
  read -r -p "Nadpisać konfigiem Secret Shield PL? [t/N] " ans
  if [[ ! "$ans" =~ ^[tTyY]$ ]]; then
    echo "ℹ️  Zachowuję istniejący .gitleaks.toml."
    SKIP_CONFIG=1
  fi
fi

# === 4. Pobieranie konfiguracji ===

if [ -z "${SKIP_CONFIG:-}" ]; then
  echo "→ Pobieranie .gitleaks.toml"
  curl -fsSL "$CONFIG_URL" -o .gitleaks.toml
fi

# === 5. Instalacja hooka pre-push ===

HOOK_PATH=".git/hooks/pre-push"

if [ -f "$HOOK_PATH" ]; then
  echo "⚠️  Istnieje już $HOOK_PATH."
  read -r -p "Zachować jako $HOOK_PATH.backup i zainstalować Secret Shield? [T/n] " ans
  if [[ "$ans" =~ ^[nN]$ ]]; then
    echo "Przerwano. Konfig został zainstalowany, hook NIE."
    exit 0
  fi
  cp "$HOOK_PATH" "$HOOK_PATH.backup"
  echo "   Backup: $HOOK_PATH.backup"
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
