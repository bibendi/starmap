# Research & Design Decisions

---
**Feature**: `admin-quarter-creation`  
**Discovery Scope**: Extension (существующая модель Quarter, создание административного интерфейса)  
**Date**: 2026-03-09
---

## Summary

Функция расширяет существующую систему управления кварталами, добавляя административный интерфейс для создания и управления кварталами. Ключевые находки:

1. **Модель Quarter полностью реализована** с валидациями, связями, коллбеками и методами копирования рейтингов
2. **QuarterPolicy существует** с методами для управления правами (admin?, unit_lead? для create/update)
3. **Административный контроллер отсутствует** - все управление кварталами сейчас через фоновые процессы
4. **Архитектура проекта** следует стандартным Rails паттернам с ViewComponent для UI

## Research Log

### Анализ существующей модели Quarter

**Context**: Понимание текущей реализации модели Quarter для проектирования админ-интерфейса

**Sources Consulted**:
- `/app/models/quarter.rb` - полная реализация модели
- `/app/policies/quarter_policy.rb` - существующие политики доступа
- `/db/migrate/20251104074618_create_quarters.rb` - схема базы данных

**Findings**:
- Quarter имеет полный набор валидаций (name, year, quarter_number, dates)
- Реализована машина состояний через callbacks (handle_status_change)
- Метод `copy_previous_ratings(from_quarter)` для копирования данных
- Статусы: draft → active → closed → archived
- Поля: name, year (1-4), start_date, end_date, evaluation_start_date, evaluation_end_date, status, is_current, previous_quarter_id

**Implications**:
- Не нужно менять модель или миграции - функциональность уже есть
- Нужно создать контроллер и UI для управления через админ-панель
- Можно переиспользовать существующие методы модели (copy_previous_ratings, activate! и т.д.)

### Анализ архитектуры контроллеров

**Context**: Понимание паттернов проектирования контроллеров в проекте

**Sources Consulted**:
- `/app/controllers/application_controller.rb` - базовый контроллер
- `/app/controllers/teams_controller.rb` - пример обычного контроллера
- `/app/controllers/skill_ratings_controller.rb` - пример контроллера с политиками

**Findings**:
- Все контроллеры наследуются от `ApplicationController`
- Используется Devise для аутентификации (`before_action :authenticate_user!`)
- Pundit интегрирован на уровне `ApplicationController` (verify_authorized, verify_policy_scoped)
- Политики проверяются через `authorize` и `policy_scope`
- Используются коллбеки для установки контекста (`before_action :set_*`)

**Implications**:
- Новый контроллер должен следовать этим паттернам
- Нужно создать отдельный namespace `Admin::QuartersController`
- Проверка прав через `authorize @quarter` и политики

### Анализ ViewComponent паттернов

**Context**: Понимание как создавать компоненты для UI

**Sources Consulted**:
- `/app/components/coverage_index_component.rb` - пример компонента
- `/app/components/coverage_index_component.html.erb` - шаблон компонента

**Findings**:
- Компоненты наследуются от `ViewComponent::Base`
- Используются модули констант (`include ExpertConstants`)
- В конструкторе передаются данные, расчеты в приватных методах
- Шаблоны используют CSS классы (metric-card, badge и т.д.)
- Интернационализация через `I18n.t()`

**Implications**:
- Для списка кварталов можно создать `QuarterListItemComponent`
- Для метрик квартала - `QuarterMetricsComponent`
- Использовать существующие CSS классы для консистентности UI

## Design Decisions

### Decision: Архитектура контроллера

**Context**: Где разместить логику администрирования кварталов

**Alternatives Considered**:
1. `QuartersController` в корневом пространстве - добавить admin-действия в существующий контроллер
2. `Admin::QuartersController` в отдельном namespace - изолировать админ-функциональность
3. `Admin::BaseController` + наследование - полноценная админ-панель

**Selected Approach**: Option 2 - `Admin::QuartersController`

**Rationale**:
- Четкое разделение ответственности: публичный интерфейс vs административный
- Проще управлять правами доступа через namespace-level политики
- Соответствует принципу единой ответственности (Single Responsibility)
- Подготовка к будущему расширению админ-панели

**Trade-offs**:
- Плюс: Чистая архитектура, изоляция админ-логики
- Минус: Дополнительный уровень вложенности в routes и файловой структуре

### Decision: Сервисный объект для управления статусами

**Context**: Где разместить бизнес-логику переходов между статусами квартала

**Alternatives Considered**:
1. Оставить логику в модели Quarter (сейчас там handle_status_change callback)
2. Создать `QuarterStatusService` для сложных переходов
3. Использовать State Machine gem (AASM или similar)

**Selected Approach**: Option 2 - Сервисный объект `QuarterStatusService`

**Rationale**:
- Модель Quarter уже достаточно большая (335 строк)
- Переходы между статусами требуют дополнительных действий (копирование рейтингов, уведомления)
- Сервисный объект улучшает тестируемость изолированной логики
- Соответствует принципу Single Responsibility

**Trade-offs**:
- Плюс: Чище модель, изолированная тестируемая логика
- Минус: Дополнительный класс, небольшое усложнение архитектуры

### Decision: Использование ViewComponent для UI

**Context**: Как организовать отображение списка кварталов и метрик

**Alternatives Considered**:
1. Чистые ERB partials - простой Rails подход
2. ViewComponent как в остальном проекте - reusable, тестируемые компоненты

**Selected Approach**: Option 2 - ViewComponent

**Rationale**:
- Проект уже использует ViewComponent (coverage_index_component и др.)
- Компоненты обеспечивают инкапсуляцию логики и представления
- Легче тестировать через `render_inline`
- Консистентность с существующей кодовой базой

**Components to create**:
- `Admin::QuarterListComponent` - таблица списка кварталов
- `Admin::QuarterStatusBadgeComponent` - отображение статуса
- `Admin::QuarterFormComponent` - форма создания/редактирования
- `Admin::QuarterMetricsComponent` - метрики квартала

### Decision: Turbo Frames для inline-редактирования

**Context**: UX для редактирования кварталов - полная перезагрузка vs AJAX

**Alternatives Considered**:
1. Полная перезагрузка страницы - просто, но медленнее
2. Turbo Frames (Hotwire) - частичное обновление без полной перезагрузки
3. SPA подход с React/Vue - слишком сложно для этого проекта

**Selected Approach**: Option 2 - Turbo Frames

**Rationale**:
- Проект использует Hotwire (Turbo + Stimulus) согласно tech.md
- Turbo Frames позволяют редактировать квартал без перезагрузки списка
- Минимум JavaScript, максимум серверного рендеринга
- Соответствует философии проекта (Hotwire over SPA)

**Implementation**:
- Обернуть список кварталов в `turbo_frame_tag "quarters_list"`
- Обернуть форму в `turbo_frame_tag "quarter_form"`
- Использовать `data-turbo-frame` для навигации

## Risks & Mitigations

1. **Риск**: Создание дублирующегося квартала (один год + номер квартала)  
   **Mitigation**: Использовать существующую валидацию `uniqueness: {scope: [:year]}` в модели Quarter

2. **Риск**: Некорректный переход статуса (например, archived → active)  
   **Mitigation**: Валидации в `QuarterStatusService`, явный список разрешенных переходов

3. **Риск**: Удаление квартала с существующими рейтингами  
   **Mitigation**: dependent: :destroy настроен в модели, но нужно добавить подтверждение в UI и soft-delete для безопасности

4. **Риск**: Производительность при копировании большого количества рейтингов  
   **Mitigation**: Метод `copy_previous_ratings` уже оптимизирован через batch insert, если нужно - добавить progress bar

## References

- [Rails Hotwire Documentation](https://hotwired.dev/) - Turbo Frames и Stimulus
- [ViewComponent Documentation](https://viewcomponent.org/) - паттерны компонентов
- [Pundit README](https://github.com/varvet/pundit) - авторизация
- [EARS Syntax Guide](https://ears-syntax.com/) - формат требований

---

## Supporting Information

### Quarter Model Key Methods

```ruby
# Методы состояния
draft?, active?, closed?, archived?
current?, evaluation_period?, within_quarter_period?

# Методы данных
copy_previous_ratings(from_quarter)
total_skill_ratings, completed_skill_ratings, draft_skill_ratings
team_maturity_data, technology_risk_data, coverage_index_data

# Классовые методы
Quarter.current, Quarter.find_or_create_current
Quarter.close_old_quarters, Quarter.activate_current_quarter
```

### QuarterPolicy Permissions Matrix

| Action | Engineer | Team Lead | Unit Lead | Admin |
|--------|----------|-----------|-----------|-------|
| index? | ✅ | ✅ | ✅ | ✅ |
| show? | ✅ | ✅ | ✅ | ✅ |
| create? | ❌ | ❌ | ✅ | ✅ |
| update? | ❌ | ❌ | ✅ | ✅ |
| destroy? | ❌ | ❌ | ❌ | ✅ |
| activate? | ❌ | ❌ | ✅ | ✅ |
| close? | ❌ | ❌ | ✅ | ✅ |

### Routes Structure

```ruby
# config/routes.rb
namespace :admin do
  resources :quarters do
    member do
      post :activate
      post :close
      post :archive
      post :copy_ratings
    end
  end
end
```
