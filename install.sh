#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# opencode_config bootstrap
#
# Устанавливает глобальную конфигурацию OpenCode V2 на чистую машину:
# config -> ~/.config/opencode/opencode.jsonc
# rules  -> ~/.config/opencode/AGENTS.md
# плюс MCP-серверы (через конфиг), наборы навыков и опционально browse.
#
# Использование:
#   ./install.sh                 # конфиг + навыки
#   ./install.sh --all           # + browse + parallel-cli
#   ./install.sh --dry-run       # показать, что будет сделано
#   ./install.sh --no-skills     # только конфиг и правила
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

WITH_BROWSE=0
WITH_PARALLEL_CLI=0
WITH_SKILLS=1
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --all                 install everything: config, skills, browse, parallel-cli
  --with-browse         install browse (drives your real Chrome)
  --with-parallel-cli   install parallel-cli (paid deep research, optional)
  --no-skills           skip skill packs
  --dry-run             print actions without changing anything
  -h, --help            this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --all) WITH_BROWSE=1; WITH_PARALLEL_CLI=1 ;;
    --with-browse) WITH_BROWSE=1 ;;
    --with-parallel-cli) WITH_PARALLEL_CLI=1 ;;
    --no-skills) WITH_SKILLS=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 2 ;;
  esac
done

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[32m  ok\033[0m %s\n' "$*"; }
warn() { printf '\033[33m  warn\033[0m %s\n' "$*"; }

need() {
  command -v "$1" >/dev/null 2>&1
}

# --- 1. Prerequisites -------------------------------------------------------
step "Проверка окружения"

need curl || { echo "curl is required"; exit 1; }
need git || warn "git не найден (нужен только для работы с этим репозиторием)"
need node || { echo "node is required (https://nodejs.org)"; exit 1; }
need npx  || { echo "npx is required (comes with node)"; exit 1; }
ok "node $(node --version), npx $(npx --version 2>/dev/null | head -1)"

if need uvx; then
  ok "uvx найден (word/excel MCP будут работать)"
else
  warn "uvx не найден: MCP 'word' и 'excel' не запустятся. Установите uv: https://docs.astral.sh/uv/"
fi

if need opencode; then
  ok "opencode $(opencode --version 2>/dev/null | head -1)"
else
  step "Установка OpenCode"
  run bash -c 'curl -fsSL https://opencode.ai/install | bash'
  warn "Откройте новый терминал, чтобы PATH подхватил ~/.opencode/bin"
fi

# --- 2. Configuration -------------------------------------------------------
step "Установка конфигурации"

mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_DIR/opencode.json" ]; then
  warn "найден $CONFIG_DIR/opencode.json — он может конфликтовать с opencode.jsonc. Удалите или объедините вручную."
fi

if [ -f "$CONFIG_DIR/opencode.jsonc" ]; then
  backup="$CONFIG_DIR/opencode.jsonc.bak.$(date +%Y%m%d-%H%M%S)"
  run cp "$CONFIG_DIR/opencode.jsonc" "$backup"
  ok "бэкап прежнего конфига: $backup"
fi

# __HOME__ -> реальный путь пользователя
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  [dry-run] render opencode.jsonc -> $CONFIG_DIR/opencode.jsonc"
else
  sed "s|__HOME__|$HOME|g" "$REPO_DIR/opencode.jsonc" > "$CONFIG_DIR/opencode.jsonc"
  ok "конфиг записан: $CONFIG_DIR/opencode.jsonc"
fi

if [ -f "$CONFIG_DIR/AGENTS.md" ]; then
  run cp "$CONFIG_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md.bak.$(date +%Y%m%d-%H%M%S)"
fi
run cp "$REPO_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
ok "правила записаны: $CONFIG_DIR/AGENTS.md"

# --- 3. Skills --------------------------------------------------------------
if [ "$WITH_SKILLS" -eq 1 ]; then
  step "Установка навыков"
  run npx -y skills add parallel-web/parallel-agent-skills --all --global -y
  run npx -y skills add https://github.com/firecrawl/web-agent --skill deep-research -g -y
  ok "навыки в ~/.agents/skills (OpenCode читает этот путь)"
else
  warn "навыки пропущены (--no-skills)"
fi

# --- 4. browse (опционально) ------------------------------------------------
if [ "$WITH_BROWSE" -eq 1 ]; then
  step "Установка browse (ваш Chrome)"
  run bash -c 'curl -fsSL https://opencode.ai/browse/install | bash'
  warn "Следуйте подсказкам установщика: он откроет Chrome и попросит подтвердить расширение."
fi

# --- 5. parallel-cli (опционально) ------------------------------------------
if [ "$WITH_PARALLEL_CLI" -eq 1 ]; then
  step "Установка parallel-cli"
  run bash -c 'curl -fsSL https://parallel.ai/install.sh | bash'
  if [ "$DRY_RUN" -eq 0 ]; then
    warn "Авторизация: parallel-cli login (device-код, откроется браузер). Платный Task API — по желанию."
  fi
fi

# --- 6. Verification --------------------------------------------------------
step "Проверка"
if need opencode && [ "$DRY_RUN" -eq 0 ]; then
  opencode mcp list || warn "не удалось получить список MCP (перезапустите терминал)"
  echo
  echo "Быстрая проверка в OpenCode:"
  echo "  1) запустите opencode"
  echo "  2) введите: перечисли доступные MCP-серверы со статусами"
  echo "  3) проверьте поиск: найди в вебе официальную доку OpenCode про MCP"
else
  echo "  [dry-run] opencode mcp list"
fi

printf '\n\033[32mГотово.\033[0m Если статус сервера pending/needs authentication:\n'
echo "  - remote с OAuth: /mcps в TUI → выбрать сервер → войти"
echo "  - browse: проверить, что Chrome запущен и расширение подключено"
echo "  - подробности: docs/troubleshooting.md"
