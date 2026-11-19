# MCP-серверы

OpenCode V2 держит серверы в `mcp.servers`. Два транспорта:

- **local** — процесс по stdio (`command` + `environment`), живёт на вашей машине;
- **remote** — Streamable HTTP по `url`, OAuth включён по умолчанию.

```jsonc
{
  "mcp": {
    "servers": {
      "my-server": { "type": "local", "command": ["npx", "-y", "some-mcp"] },
      "other": { "type": "remote", "url": "https://mcp.example.com/mcp" }
    }
  }
}
```

Добавлять через CLI удобнее — он не ломает остальной конфиг:

```sh
opencode mcp add <name> --global --url <url>          # remote
opencode mcp add <name> --global -- <command> [args]  # local
opencode mcp list                                     # статусы
```

`--global` = `~/.config/opencode/opencode.jsonc`. Без него сервер попадёт в проект.

## Что настроено

| Сервер | Тип | Назначение |
|---|---|---|
| `browse` | local | Реальный Chrome пользователя через расширение |
| `context7` | remote | Документация библиотек и API |
| `gh_grep` | remote | Поиск кода по публичным репозиториям |
| `parallel` | remote | Веб-поиск, fetch, research, вертикали |
| `memory` | local | Персистентная память между сессиями |
| `sequential-thinking` | local | Пошаговые рассуждения |
| `drawio` | local | Диаграммы |
| `word` | local | Word-документы |
| `excel` | local | Excel-книги |
| `playwright` | local | Headless-браузер для E2E |

## Команды добавления по отдельности

```sh
# Браузер (сначала: curl -fsSL https://opencode.ai/browse/install | bash)
opencode mcp add browse --global -- "$HOME/.local/bin/browse" mcp

# Документация
opencode mcp add context7 --global --url https://mcp.context7.com/mcp

# Код
opencode mcp add gh_grep --global --url https://mcp.grep.app

# Веб-поиск и research
opencode mcp add parallel --global --url https://mcp.parallel.ai/mcp

# Память
opencode mcp add memory --global \
  --env MEMORY_FILE_PATH="$HOME/.local/share/opencode/memory/memory.json" \
  -- npx -y @modelcontextprotocol/server-memory

# Рассуждения
opencode mcp add sequential-thinking --global -- \
  npx -y @modelcontextprotocol/server-sequential-thinking

# Диаграммы
opencode mcp add drawio --global -- npx -y @drawio/mcp

# Офис
opencode mcp add word --global -- uvx --from office-word-mcp-server word_mcp_server
opencode mcp add excel --global -- uvx excel-mcp-server stdio

# Playwright
opencode mcp add playwright --global -- \
  npx -y @playwright/mcp@latest --browser chrome --headless
```

## Полезные поля

| Поле | Смысл |
|---|---|
| `disabled: true` | сервер настроен, но не подключается |
| `codemode: false` | инструменты попадают в контекст напрямую, а не через `execute` |
| `pool: true` | одно соединение на несколько каталогов/проектов |
| `timeout` | `startup` / `catalog` / `execution` в миллисекундах |
| `environment` | переменные только для этого сервера |
| `oauth: false` | выключить OAuth, если сервер живёт на одном API-ключе |

Секреты в конфиг не пишем:

```jsonc
"environment": { "MCP_API_KEY": "{env:MCP_API_KEY}" }
```

## Имена инструментов

OpenCode собирает имя как `<server>_<tool>`, заменяя недопустимые символы на `_`:

```
context7 + resolve.library/id  →  context7_resolve_library_id
```

Промпты MCP становятся командами: `/context7:find_docs`.

## Проверка и диагностика

```sh
opencode mcp list        # connected / pending / needs authentication
```

- `pending` сразу после добавления — нормально, каталог подтягивается через несколько секунд.
- `needs authentication` — `/mcps` в TUI, выбрать сервер, войти. OAuth-креденшелы хранятся вне конфига.
- `opencode mcp logout <name>` — сбросить вход и войти другим аккаунтом.
- Сервер не стартует — проверьте, что бинарник есть в `PATH` (у `browse` путь абсолютный).

## Отключение

Заменить `"type"`-блок на `"disabled": true` или удалить ключ целиком:

```sh
opencode mcp list
# затем удалить блок из ~/.config/opencode/opencode.jsonc
```

Полное удаление сервера через CLI не предусмотрено — правьте конфиг (изменения применяются без перезапуска).
