# Proposal

## Why

MCP-агент может передать `period_id` в `team_metrics`, но не может узнать идентификаторы исторических периодов через MCP. Если текущий период не назначен, рекомендация указать `period_id` также не даёт агенту способа продолжить работу.

## What Changes

- Добавить read-only MCP tool `assessment_periods` без обязательных аргументов, возвращающий общий каталог периодов всех типов и статусов в хронологическом порядке.
- Возвращать `id`, `name`, `period_kind`, `status`, `start_date`, `end_date`, `evaluation_start_date`, `evaluation_end_date`, `is_current`, чтобы агент мог выбрать период по датам и передать его ID в `team_metrics`.
- Разрешить чтение метаданных всем аутентифицированным ролям User и включённым ApiClient с `teams:read`, через отдельные Pundit policies без расширения прав администрирования.
- Зарегистрировать инструмент на существующем MCP endpoint и сделать его обнаружимым из описания `period_id` и ошибки отсутствия текущего периода.
- Покрыть контракт, авторизацию и последовательность discovery → metrics тестами; документировать использование.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `assessment-periods`: добавить MCP discovery каталога периодов для существующего выбора периода по ID.

## Impact

- Новый `AssessmentPeriodsTool` в `app/tools/`, регистрация в `McpController`, уточнение подсказок `TeamMetricsTool`.
- Новые read-only policies для User и ApiClient; безопасная обработка class-level авторизации в `McpBaseTool`, если используется `authorize(identity, AssessmentPeriod, :index)`.
- Specs инструмента, policies и `POST /mcp`; руководство по использованию MCP в `docs/mcp.md` со ссылкой на `docs/auth.md` для настройки доступа. В `docs/auth.md` — только актуализация правил аутентификации и авторизации.
- Без миграций, новых зависимостей, изменений формул метрик или контракта ответа `team_metrics`.
- Вне scope: изменение периодов через MCP, фильтры, пагинация, поиск команд и автоматическое толкование естественного языка на сервере.
