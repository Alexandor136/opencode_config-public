# Global Rules

## Output Language
Always respond in Russian. Keep technical terms, code, and commands in English.

## Context7 (Auto-Invoke)
Always use Context7 MCP for library/API documentation, setup, or config steps —
without me asking. Use `resolve-library-id` then `query-docs`. One concept per query.

## Memory (Persistent)
Use `memory` MCP to persist durable facts:
- Project stack, conventions, architecture → `memory_project_save`
- My coding preferences → `memory_pref_save`
- Lessons from bugs → `memory_learning_save`
Before non-trivial work, `memory_search` for relevant context.

## Sequential Thinking
Use `sequential_thinking` MCP for architectural decisions, multi-file refactors,
and complex debugging (3+ steps). Skip for simple fixes.

## Code Search
Use `gh_grep` MCP for real-world usage examples from public repos.

## Diagrams
Architecture/system diagrams → `drawio-architecture` skill + `drawio` MCP.
Flowcharts/process diagrams → `drawio-flowchart`.

## Code Style
- Python: full type hints (PEP 604, `X | None`), `pathlib`, `dataclass`.
- No mutable default arguments. f-strings only.

## Git
- Branches: `feat/`, `fix/`, `chore/`, `refactor/`.
- Never push to `main` directly.
- Commits: imperative mood, English.

## Security
- Never commit secrets, API keys, or credentials.
- Parameterized queries only — never string-interpolated SQL.

## Verification
Before claiming any task complete:
- Run linter + full test suite. Show output — no "should pass".
- Python: `pytest` passes, `mypy --strict` clean.

## Skills Priority
Follow Superpowers workflow skills when they apply:
- Creative work → `brainstorming` first.
- Bug → `systematic-debugging` first.
- Feature → `test-driven-development`.
- Completion claims → `verification-before-completion`.
Process skills come before domain skills.
