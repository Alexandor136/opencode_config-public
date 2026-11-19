# browse — ваш реальный Chrome

`browse` подключает OpenCode к обычному Chrome через расширение. Агент видит ваши логины, расширения и открытые вкладки — это не headless-браузер и не копия профиля.

## Установка

```sh
curl -fsSL https://opencode.ai/browse/install | bash
```

Что происходит:

1. Бинарник ставится в `~/.local/bin/browse`.
2. MCP-сервер `browse` прописывается в `~/.config/opencode/opencode.jsonc`.
3. Открывается Chrome со страницей расширения; после установки расширение подключается к локальному relay.
4. Установщик ждёт соединения (до 90 секунд).

Проверка:

```sh
browse status
```

```text
Relay: http://127.0.0.1:19988 (0.0.17)
Extension: connected (0.0.16)
Extension protocol: 3 (compatible)
```

## Как это устроено

```text
OpenCode → MCP stdio → browse mcp → browse serve (relay, 127.0.0.1:19988)
                                           ↕ WebSocket
                                   Chrome extension → вкладки
```

- Relay — демон `browse serve`, живёт в cgroup приложения OpenCode. Закрыли OpenCode — relay остановился; при следующем вызове поднимется снова.
- Пэйринг сохраняется в `~/.config/browse` и `~/.local/share/browse`, поэтому повторно код вводить не нужно.
- Расширение обязано быть подключено: закрыли Chrome — инструмент недоступен.

## Модель безопасности

- Relay слушает **только loopback** (`127.0.0.1:19988`), в локальную сеть не выставлен.
- Доступ есть у **любого процесса вашего пользователя**: токен лежит открытым файлом `~/.config/browse/relay-token`.
- Агент действует в браузере **от вашего имени** — с вашими сессиями и правами. Это и есть смысл, и это же риск.

Полезные команды:

```sh
browse pair --list                       # какие браузеры привязаны
browse pair --revoke chrome-<host>       # отвязать браузер
browse uninstall                         # удалить всё, что поставил install
```

Для браузера на другой машине (осознанно, только по необходимости):

```sh
browse install --remote          # включит relay на 0.0.0.0 и выдаст одноразовый код
browse set hostname 127.0.0.1    # вернуть loopback
```

## Работа из агента

```js
await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
const title = await page.title();
```

- Сначала `snapshot()` — получить ссылки-`ref`, потом действовать по ним.
- Для логина, 2FA, капчи, оплаты — `handoff("что должен сделать человек")`, а не попытки обойти.
- Ограничивайте сессию доменами (`session_new` с `allowedOrigins`), если задача узкая.

## Особенности

| Симптом | Причина / решение |
|---|---|
| `browse status` показывает `connected`, но `goto` зависает | навигация подвисла на первой попытке — повторите; проверьте `browse status` |
| Агент «потерял» вкладку | вы закрыли отладочную панель Chrome — browse отключился от всех вкладок; откройте вкладку заново через кнопку browse в тулбаре |
| `extension 0.0.16 differs from CLI 0.0.17` | версии разошлись; протокол совместим, но расширение стоит обновить в Chrome Web Store |
| После перезагрузки нет соединения | Chrome не запущен либо relay ещё не поднят — первый вызов MCP стартует его |

## Ссылки

- Официальная страница: <https://opencode.ai/browse>
- `browse --help` — все команды: `install`, `pair`, `status`, `execute`, `extension`, `update`, `uninstall`.
