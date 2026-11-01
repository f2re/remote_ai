# Безопасность Remote AI

## Модель доверия

Remote AI соединяет локальный Mac с пользовательским удалённым сервером через стандартный OpenSSH, синхронизирует файлы Mutagen и управляет существующим Claude Code через tmux. Приложение не является прокси авторизации Claude.

## Credentials

Remote AI не должен:

- читать, копировать, проксировать или сохранять Claude OAuth/session credentials;
- просить API key для замены обычного Claude Code login;
- записывать credentials в Warp config, logs или sync tree.

Авторизация выполняется самим `claude` CLI на удалённой машине.

## SSH

- использовать стандартную OpenSSH trust model;
- `StrictHostKeyChecking=no` запрещён;
- shell values обязаны проходить validation/quoting;
- явный SSH key path не означает, что ключ копируется на сервер;
- нестандартную identity для Mutagen рекомендуется задавать через `~/.ssh/config`.

## Синхронизация

- режим по умолчанию — `two-way-safe`;
- conflict является видимой блокирующей ошибкой;
- устаревшие route sessions приостанавливаются, а не удаляются;
- перед Stop выполняется успешный flush;
- `.git` не синхронизируется по умолчанию.

## Status plugin

Session-only plugin Remote AI записывает только state token + timestamp. Hook stdin отбрасывается. Prompts, responses, tool input и transcript не сохраняются приложением.

## Сообщение об уязвимости

Не публикуйте credential leakage, command injection или data-loss exploit с рабочими секретами в публичном issue. Создайте минимальный отчёт без чувствительных данных через доступный владельцу приватный канал GitHub/Security. Если приватный канал недоступен, откройте issue только с просьбой связаться по вопросам безопасности, без exploit details/secrets.

## Приоритет исправлений

Критическими считаются: утечка credentials, arbitrary command execution за пределами ожидаемого SSH boundary, silent data loss, отключение host-key verification и silent conflict resolution.
