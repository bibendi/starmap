# Spec Delta

## ADDED Requirements

### Requirement: MCP period catalogue
Система SHALL предоставлять read-only MCP tool `assessment_periods` без входных аргументов. Успешный ответ SHALL содержать JSON-объект с массивом `periods`, включающим все периоды независимо от типа, статуса, наличия оценок и команды. Порядок SHALL быть возрастающим по `start_date`, `end_date`, `id`. Пустой каталог SHALL возвращать `periods: []`, а не ошибку.

#### Scenario: Discover mixed periods
- **WHEN** авторизованный клиент вызывает `assessment_periods` с пустыми аргументами при наличии периодов разных типов и статусов
- **THEN** ответ содержит каждый существующий период ровно один раз в указанном хронологическом порядке
- **AND** в список включаются draft и archived, а также периоды без оценок команды
- **AND** вызов не изменяет периоды, оценки или признак текущего

#### Scenario: Empty catalogue
- **WHEN** авторизованный клиент вызывает инструмент при отсутствии периодов
- **THEN** получает успешный ответ с `{"periods": []}`

### Requirement: MCP period metadata
Каждая запись каталога SHALL содержать только `id`, `name`, `period_kind`, `status`, `start_date`, `end_date`, `evaluation_start_date`, `evaluation_end_date`, `is_current`. `id` SHALL быть целым числом, пригодным для `team_metrics.period_id`; `name` SHALL совпадать с `period_name` метрик для этого периода, даты SHALL быть ISO 8601 `YYYY-MM-DD`, `is_current` SHALL отражать сохранённый флаг, а не вычисляться из статуса или дат.

#### Scenario: Complete metadata
- **WHEN** клиент получает запись периода любого поддерживаемого типа
- **THEN** запись содержит все перечисленные поля с указанными типами и форматом
- **AND** ответ не содержит данных пользователей, оценок или служебных полей записи

#### Scenario: No current flag and closed current period
- **WHEN** ни один период не отмечен текущим
- **THEN** каталог остаётся доступен, а у всех записей `is_current` равен false
- **WHEN** текущим отмечен закрытый период
- **THEN** его запись сохраняет `status: "closed"` и `is_current: true`

### Requirement: MCP catalogue authorization
Каталог SHALL быть доступен всем аутентифицированным ролям User и включённым ApiClient с разрешением `teams:read`. ApiClient без этого разрешения или выключенный MUST NOT получать каталог. Каталог SHALL быть общим для команд и не расширять права на их метрики или администрирование периодов. Неаутентифицированный запрос к MCP SHALL сохранять HTTP 401; отказ policy SHALL возвращать MCP `isError: true` без метаданных.

#### Scenario: Users and machine clients
- **WHEN** engineer, team_lead, unit_lead, admin либо включённый ApiClient с `teams:read` запрашивает каталог
- **THEN** получает метаданные периодов без требования административной роли или имени команды

#### Scenario: Insufficient machine permissions
- **WHEN** аутентифицированный ApiClient имеет только `units:read` или не имеет разрешений
- **THEN** получает MCP ошибку доступа без каталога периодов

#### Scenario: Disabled or unauthenticated identity
- **WHEN** запрос к endpoint не проходит аутентификацию, в том числе из-за выключенного ApiClient
- **THEN** endpoint возвращает HTTP 401
- **AND** прямая проверка доступа выключенного ApiClient также запрещает чтение каталога

#### Scenario: Team scope remains enforced
- **WHEN** ApiClient получает ID периода из общего каталога и запрашивает метрики недоступной команды
- **THEN** `team_metrics` возвращает прежнюю ошибку доступа без метрик

### Requirement: MCP period discovery workflow
`assessment_periods` SHALL быть доступен через `tools/list` и `tools/call` существующего MCP endpoint с признаками read-only, non-destructive, idempotent и closed-world. Описание `team_metrics.period_id` и ошибка отсутствия текущего периода SHALL указывать на `assessment_periods` как источник ID. Контракт успешного ответа метрик и выбор текущего периода по умолчанию SHALL сохраняться.

#### Scenario: Discover and select a historical period
- **WHEN** агент обнаруживает `assessment_periods`, вызывает его и передаёт ID выбранного исторического периода в `team_metrics` для доступной команды
- **THEN** метрики содержат `period_id`, равный ID выбранной записи, и `period_name`, равный её `name`

#### Scenario: Recover without a current period
- **WHEN** текущий период не назначен и агент вызывает `team_metrics` без `period_id`
- **THEN** получает ошибку отсутствия текущего периода с указанием `assessment_periods`
- **AND** может получить каталог и запросить метрики существующего периода по ID
