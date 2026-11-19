# Архитектура

Схема инфраструктуры: [architecture.drawio](architecture.drawio) · [architecture.png](architecture.png).
Открыть и отредактировать можно в [draw.io](https://app.diagrams.net) или в расширении draw.io для VS Code.

## Слои

| Слой | Что входит | Роль |
|---|---|---|
| 1. Взаимодействие | TUI/CLI, проект, `opencode.json(c)`, handoff | Пользователь ставит задачу и подтверждает чувствительные действия |
| 2. Агентный runtime | primary agent, subagents, `AGENTS.md`, skill tool, Code Mode, permissions, session context, LLM client | Маршрутизирует запрос, выбирает навыки и инструменты, собирает контекст |
| 3. Возможности | 90 навыков, 10 MCP-серверов (remote + local) | Дают агенту методологию и доступ к внешним системам |
| 4. Внешние системы | Context7, grep.app, Parallel, Chrome, npm/PyPI, локальные файлы | Источники данных, браузер, пакеты и постоянное хранилище |

## Маршрут запроса

1. `memory_search` поднимает проектный контекст, предпочтения и прошлые ошибки.
2. Prompt попадает в primary agent (`build` / `plan`).
3. `AGENTS.md` задаёт правила: язык, Context7, память, git, безопасность, приоритет процессных навыков.
4. Skill tool загружает `SKILL.md` по ID, если задача совпала с описанием навыка.
5. Code Mode (`execute`) вызывает MCP-инструмент; permissions решают, нужно ли подтверждение.
6. Результат возвращается в session context, сжимается при необходимости и уходит в LLM.
7. Subagents получают отдельную копию контекста и возвращают primary только результат.

## Память

| Тип | Где живёт | Время жизни |
|---|---|---|
| Session context | в процессе OpenCode | одна сессия; сжимается compaction |
| Subagent context | отдельный контекст subagent | одна подзадача |
| Long-term memory | `memory` MCP → `memory.json` | между сессиями и проектами |
| Instincts | навык `continuous-learning-v2` (опционально) | между сессиями, если включён |

`memory` MCP хранит граф фактов в `~/.local/share/opencode/memory/memory.json`.
Правила `AGENTS.md` используют три вида записей:

- `memory_project_save` — стек, конвенции, архитектура проекта;
- `memory_pref_save` — предпочтения в коде и инструментах;
- `memory_learning_save` — уроки из багов и инцидентов.

Перед нетривиальной задачей агент делает `memory_search`; после — сохраняет только durable-факты, а не временный шум сессии.

## MCP

| Тип | Серверы | Транспорт |
|---|---|---|
| Remote | `context7`, `gh_grep`, `parallel` | Streamable HTTP, OAuth через `/mcps` |
| Local | `browse`, `memory`, `sequential-thinking`, `drawio`, `word`, `excel`, `playwright` | stdio, процессы `npx` / `uvx` на хосте |

Инструменты доступны через Code Mode как `<server>_<tool>`. Подробности — в [mcp.md](mcp.md).

## Навыки

OpenCode ищет навыки по приоритету:

```text
built-in → ~/.claude/skills → ~/.agents/skills → ~/.config/opencode/skills → .opencode/skills → skills в конфиге
```

В этой конфигурации 72 предметных навыка лежат в `~/.config/opencode/skills`, 18 пакетов — в `~/.agents/skills`.
Процессные навыки (brainstorming, systematic-debugging, TDD, verification) применяются раньше доменных.
Полный список — в [skills-manifest.md](skills-manifest.md).

## Безопасность

- В репозитории нет ключей и токенов: только `{env:NAME}` и OAuth.
- Проверка перед коммитом: `./scripts/check-secrets.sh`.
- `browse` работает от имени пользователя; relay слушает только `127.0.0.1:19988`.
- `memory.json`, `.env`, `*.key`, `auth.json` исключены через `.gitignore`.

## Редактирование схемы

`architecture.drawio` — обычный draw.io XML. После правок обновите PNG-превью:

1. Откройте файл в draw.io.
2. File → Export as → PNG.
3. Сохраните как `docs/architecture.png` (светлая тема, прозрачный фон выключен).
