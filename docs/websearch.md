# Веб-поиск

В OpenCode есть встроенный инструмент `websearch` — отдельный MCP для простого поиска не нужен. В этой конфигурации к нему добавлен Parallel MCP как второй индекс и как источник research.

## Встроенный `websearch`

Провайдеры:

| Провайдер | ID | Переменная |
|---|---|---|
| Exa | `exa` | `EXA_API_KEY` |
| Firecrawl | `firecrawl` | `FIRECRAWL_API_KEY` |
| Parallel | `parallel` | `PARALLEL_API_KEY` |
| Tavily | `tavily` | `TAVILY_API_KEY` |
| TinyFish | `tinyfish` | `TINYFISH_API_KEY` (опционально) |

Подключение — через `/connect` в TUI или переменную окружения. Принудительный выбор:

```jsonc
{ "websearch": { "provider": "parallel" } }
```

`"random"` выбирает доступного провайдера и переключается на другого при `429`; каждый сеанс помнит свой выбор, пока не упрётся в лимит.

Отключить совсем:

```jsonc
{ "websearch": false }
```

Права:

```jsonc
{ "permissions": [
  { "action": "websearch", "resource": "*", "effect": "ask" }
]}
```

## Parallel MCP

```sh
opencode mcp add parallel --global --url https://mcp.parallel.ai/mcp
```

| Инструмент | Что делает | Оплата |
|---|---|---|
| `web_search` | Поиск: `objective` + 1–3 коротких `search_queries` | бесплатно, лимиты |
| `web_fetch` | Чтение до 20 URL с общим `objective` | бесплатно, лимиты |
| `web_decisions` | Вероятность / выбор / оценка по живому вебу | бесплатно, лимиты |
| `image_search` | Поиск изображений (URL, не описание) | бесплатно, лимиты |
| `find_verticals` / `search_vertical` | PubMed, ClinicalTrials, bioRxiv, ChEMBL, NPI | бесплатно |
| `web_research` | Ответ с цитатами за один вызов | вход + оплата |

Вход: `/mcps` → `parallel` (OAuth) или ключ `PARALLEL_API_KEY`. Для более высоких лимитов и research — `https://mcp.parallel.ai/mcp?login`.

### Как формулировать запрос

- `objective` — цель человеческим языком, одна.
- `search_queries` — 2–3 ключевых запроса по 3–6 слов.
- Не дублировать вопрос в оба поля — это главная ошибка по документации Parallel.
- `site:` принимает домен без пути; кавычки не использовать.

## `parallel-cli` и deep research

```sh
curl -fsSL https://parallel.ai/install.sh | bash
parallel-cli login          # device-код, подтверждение в браузере
parallel-cli search "opencode mcp" --json
```

Даёт доступ к Task API: длительные исследования с готовым отчётом и цитатами. **Платно**, тарифицируется на аккаунт.

## Что выбирать

| Задача | Инструмент | Цена |
|---|---|---|
| Быстрый факт, «что нового» | `websearch` или `parallel.web_search` | бесплатно |
| Прочитать 5–10 страниц | `parallel.web_fetch` | бесплатно |
| Отчёт с цитатами, 3+ источника | навык `deep-research` на бесплатных инструментах | бесплатно |
| Исчерпывающий отчёт, много шагов | `parallel-deep-research` (Task API) | платно |
| Документация библиотеки | `context7` | бесплатно |
| Код из реальных репозиториев | `gh_grep` | бесплатно |
| Платный/авторизованный контент | `browse` в вашем Chrome | бесплатно |

## Ограничения, проверенные на практике

- Бесплатный тир Parallel иногда отдаёт шумные URL (например, порт в хосте); после login выдача чище.
- Встроенный `websearch` при `429` без `"random"` просто падает — ротация помогает только с несколькими подключёнными провайдерами.
- `web_fetch` режет очень большие страницы; для полного текста используйте `webfetch` или `browse`.
