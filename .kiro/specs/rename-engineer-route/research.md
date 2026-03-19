# Research & Design Decisions

## Summary
- **Feature**: rename-engineer-route
- **Discovery Scope**: Extension (existing system refactoring)
- **Key Findings**:
  - EngineersController и EngineerPolicy существуют и активно используются
  - 40+ ссылок на engineer/engineer_path в codebase
  - User модель уже существует, роли определены (engineer, team_lead, unit_lead, admin)
  - Паттерн Pundit политик стандартизирован в проекте

## Research Log

### Codebase Analysis
- **Context**: Необходимо найти все точки использования engineer-related кода
- **Sources Consulted**: grep по codebase
- **Findings**:
  - `app/controllers/engineers_controller.rb` - единственный action #show
  - `app/policies/engineer_policy.rb` - авторизация с проверкой ролей
  - Views: `application.html.erb` (nav), `teams/show.html.erb` (member cards), `skill_ratings/show.html.erb` (redirects)
  - Controllers: `skill_ratings_controller.rb` (redirects)
  - Tests: `spec/requests/engineers_spec.rb`, `spec/requests/skill_ratings_spec.rb`, `spec/policies/engineer_policy_spec.rb`
- **Implications**: Необходимо систематически обновить все файлы, сохраняя функциональность

### Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Full Rename | Полная замена всех сущностей | Чистый код, соответствие naming conventions | Риск пропустить ссылки, требует полного тестирования | Рекомендуется |
| Dual Support | Оставить оба маршрута | Безопасная миграция | Технический долг, дублирование кода | Не рекомендуется |
| Gradual Migration | Пошаговое обновление | Меньше рисков при деплое | Дольше выполнение, промежуточное состояние | Возможно, но сложнее |

## Design Decisions

### Decision: Full Rename vs Dual Support
- **Context**: Нужно обновить маршрут /engineer на /users/:id
- **Alternatives Considered**:
  1. Full Rename - полная замена с redirect для backward compatibility
  2. Dual Support - поддержка обоих маршрутов одновременно
- **Selected Approach**: Full Rename с redirect для legacy URLs
- **Rationale**: Соответствует Rails конвенциям, устраняет технический долг, единообразие
- **Trade-offs**: Требует внимательного обновления всех ссылок
- **Follow-up**: Проверить все тесты после рефакторинга

### Decision: Controller/Policy Renaming Strategy
- **Context**: EngineersController и EngineerPolicy нужно переименовать
- **Alternatives Considered**:
  1. Создать новые классы, скопировать логику, удалить старые
  2. Использовать class alias (EngineersController = UsersController)
- **Selected Approach**: Создание новых классов с копированием логики
- **Rationale**: Чистый код, понятная структура, соответствует naming conventions
- **Trade-offs**: Двойная работа по копированию кода

### Decision: Route Structure
- **Context**: Маршрут /engineer без параметра vs /users/:id
- **Alternatives Considered**:
  1. resources :users с параметром id (требует id в URL)
  2. resource :user без id (использует current_user)
- **Selected Approach**: resources :users, only: [:show] с id параметром
- **Rationale**: Более гибкая структура, позволяет просматривать любые профили по id
- **Trade-offs**: Необходимо передавать id в URL (уже делается в текущих ссылках)

## Risks & Mitigations

- **Risk**: Пропущенные ссылки на engineer_path в views или controllers
  - **Mitigation**: Использовать grep для поиска всех вхождений, добавить тесты на маршруты
  
- **Risk**: Нарушение авторизации после переименования политики
  - **Mitigation**: Убедиться что UserPolicy дублирует логику EngineerPolicy точно
  
- **Risk**: Старые закладки пользователей перестанут работать
  - **Mitigation**: Добавить redirect с /engineer на /users/:id
  
- **Risk**: Тесты упадут из-за изменения маршрутов
  - **Mitigation**: Обновить все тестовые вызовы engineer_path на user_path

## References

- [Rails Routing Guide](https://guides.rubyonrails.org/routing.html) - конвенции маршрутизации
- [Pundit Documentation](https://github.com/varvet/pundit) - авторизация
- Project steering: `tech.md`, `structure.md` - архитектурные паттерны
