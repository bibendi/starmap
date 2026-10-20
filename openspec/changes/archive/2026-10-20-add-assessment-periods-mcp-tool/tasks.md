# Tasks

## 1. Авторизация метаданных периодов

- [x] 1.1 Добавить `AssessmentPeriodPolicy#index?` и `ApiClient::AssessmentPeriodPolicy#index?` для правил delta spec; добавить policy specs для всех четырёх ролей, nil identity, enabled/disabled ApiClient, `teams:read`, только `units:read` и пустых permissions. Проверка: новые policy specs проходят; административная policy не изменена, для неперсистентных policy-проверок используется `build`.
- [x] 1.2 Адаптировать формирование отказа `McpBaseTool#authorize` для model class, не меняя routing policies и штатный отказ для Team; добавить тесты class-level и instance-level отказа. Проверка: возвращается MCP `isError: true` без исключения, существующие тесты отказа `TeamMetricsTool` проходят.

## 2. Инструмент каталога

- [x] 2.1 Добавить `AssessmentPeriodsTool` с пустой input schema, annotations, предварительным `authorize(..., AssessmentPeriod, :index)`, чтением `AssessmentPeriod.ordered` и whitelist JSON `periods`. Добавить `spec/requests/mcp/assessment_periods_spec.rb`: все пять типов, все статусы, отсутствие командных оценок, порядок, точные ключи, ISO-даты, closed/current, отсутствие current, пустой каталог и отсутствие мутаций. Проверка: новый request spec проходит; общие persisted данные используют только top-level `let_it_be`, интервалы не пересекаются.
- [x] 2.2 Покрыть вызовы инструмента с User и ApiClient, включая запрещённые permissions и выключенного клиента; проверить, что при отказе каталог не возвращается. Проверка: авторизационные примеры request spec проходят с штатным MCP error response.

## 3. MCP discovery и пользовательский сценарий

- [x] 3.1 Зарегистрировать `AssessmentPeriodsTool` в `McpController`; добавить отдельные файлы в `spec/requests/mcp/` с проверками `tools/list` (имя, схема, annotations), `tools/call` с пустыми arguments, User session, User Bearer и ApiClient Bearer, отказов permissions и HTTP 401. Проверка: request spec проходит, `team_metrics` остаётся зарегистрированным.
- [x] 3.2 Обновить описание `TeamMetricsTool.period_id` и ошибку отсутствия текущего периода ссылкой на `assessment_periods`; добавить ожидания в `spec/requests/mcp/team_metrics_spec.rb`. Проверка: spec подтверждает подсказки, прежний successful payload, выбор current по умолчанию и ошибки невалидных ID.
- [x] 3.3 Добавить request-сценарии catalogue → выбор исторического периода → `team_metrics`, восстановления без current и запрета метрик чужой команды для ApiClient после discovery. Проверка: ответ метрик содержит ID и название выбранной записи, а чужая команда по-прежнему недоступна.
- [x] 3.4 Подготовить руководство по использованию в `docs/mcp.md`: инструменты, параметры, поля ответа, порядок периодов, все статусы и два JSON-RPC примера последовательного вызова; сослаться на `docs/auth.md` для настройки доступа. В `docs/auth.md` оставить только общие правила аутентификации и авторизации; права конкретных инструментов описать в `docs/mcp.md`. Проверка: названия и arguments примеров совпадают с request specs и опубликованной схемой; ясно указано, что `id` из каталога передаётся как `period_id`; назначение двух документов разделено, ссылка на настройку доступа корректна.

## 4. Интеграционная проверка

- [x] 4.1 Запустить новые policy/request specs вместе с `bundle exec rspec spec/requests/mcp/team_metrics_spec.rb spec/requests/mcp_spec.rb spec/requests/mcp` и RuboCop для изменённых Ruby-файлов. Проверка: все относящиеся к изменению тесты и lint проходят; внешние блокеры окружения явно зафиксированы, несвязанные ошибки не исправляются.
- [x] 4.2 Выполнить `openspec validate add-assessment-periods-mcp-tool --strict` и сверить реализацию с каждым сценарием delta spec. Проверка: validation проходит, все сценарии покрыты тестами или явно указанной проверкой.
