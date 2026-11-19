# Навыки (skills)

Навык — это папка с `SKILL.md` и, опционально, скриптами и справочниками. Он не добавляет новых инструментов, а **меняет поведение агента**: последовательность шагов, критерии качества, форматы вывода.

## Формат

```text
~/.config/opencode/skills/git-release/
├── SKILL.md
├── scripts/changelog.ts
└── references/release-policy.md
```

```markdown
---
name: Git Release
description: Prepare release notes, version bumps, and GitHub releases
---

## Workflow

1. Read `references/release-policy.md`.
2. ...
```

- ID навыка = имя каталога (`git-release`), а не `name` из frontmatter.
- Без `description` навык не показывается модели.
- `metadata.opencode/autoinvoke: false` — скрыть из авто-выбора, но оставить доступным по ID.

## Где OpenCode ищет навыки

| Приоритет | Путь | Кто кладёт |
|---|---|---|
| 1 (низший) | встроенные | OpenCode |
| 2 | `~/.claude/skills` | Claude-совместимые пакеты |
| 3 | `~/.agents/skills` | `npx skills add` |
| 4 | `~/.config/opencode/skills` | ручная установка, эта конфигурация |
| 5 | `.opencode/skills` (проект) | проект |
| 6 (высший) | `skills` в конфиге | явные пути и HTTP-каталоги |

Дубликаты решаются по ID: побеждает источник с более высоким приоритетом.

## Что установлено

| Путь | Кол-во | Состав |
|---|---|---|
| `~/.config/opencode/skills` | 72 | Предметные эксперты: языки, фреймворки, БД, DevOps, безопасность, тестирование, дизайн |
| `~/.agents/skills` | 18 | Parallel (15), `deep-research`, `context7-mcp`, `find-skills` |

Полный список — [skills-manifest.md](skills-manifest.md).

### Что делает `install.sh`

```sh
npx -y skills add parallel-web/parallel-agent-skills --all --global -y
npx -y skills add https://github.com/firecrawl/web-agent --skill deep-research -g -y
```

`-g` = глобально (`~/.agents/skills`), `-y` = без вопросов.

`context7-mcp` и `find-skills` установщик не воспроизводит — их пакеты в репозитории не зафиксированы. Перенести вручную:

```sh
cp -r ~/.agents/skills/context7-mcp ~/.agents/skills/find-skills ~/.agents/skills/
```

## Как этим пользоваться

| Задача | Что просить |
|---|---|
| Обычный поиск | «найди в вебе …» → `websearch` или `parallel` |
| Исследование | «исследуй …» / «сравни X и Y» → `deep-research` |
| Дорогое исследование | «сделай deep research по …» → `parallel-deep-research` (платно) |
| Документация | ничего не просить: Context7 вызывается по правилам `AGENTS.md` |
| Своя методология | создать `~/.config/opencode/skills/<id>/SKILL.md` |

## Проверка

```sh
npx -y skills ls -g          # глобальные, с путями
npx -y skills list           # проектные
```

В сессии: список доступных навыков приходит в системном контексте; загрузка — инструментом `skill` по точному ID.

## Типичные ошибки

- **Навык не виден** — проверьте точное имя каталога, наличие `description`, не скрыт ли `autoinvoke`.
- **Загрузился не тот** — одноимённый навык из источника с более высоким приоритетом перекрыл ваш.
- **Установка пишет `PromptScript does not support global skill installation`** — это сторонний агент, на OpenCode не влияет: копия в `~/.agents/skills` уже создана.

## Права

```jsonc
{ "permissions": [
  { "action": "skill", "resource": "*", "effect": "allow" },
  { "action": "skill", "resource": "experimental-*", "effect": "ask" }
]}
```

Работает так же, как для инструментов: последнее совпавшее правило выигрывает.
