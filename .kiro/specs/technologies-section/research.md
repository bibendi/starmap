# Research & Design Decisions

## Summary
- **Feature**: `technologies-section`
- **Discovery Scope**: Extension (существующая админка + новая сущность Category)
- **Key Findings**:
  - Существующие паттерны admin CRUD (Users, Quarters) полностью покрывают потребности
  - Category — новая сущность, управляемая только в рамках технологий (отдельный CRUD не требуется)
  - Миграция строкового `category` в `category_id` требует data migration

## Research Log

### Анализ существующих паттернов admin CRUD
- **Context**: Необходимо определить паттерны для TechnologiesController и views
- **Sources**: `app/controllers/admin/users_controller.rb`, `app/controllers/admin/quarters_controller.rb`, `app/views/admin/users/*`, `app/views/admin/quarters/*`
- **Findings**:
  - Authorization: `authorize [:admin, Model]` + `policy_scope([:admin, Model])` в каждом действии
  - Pagination: `PER_PAGE = 25` + Kaminari
  - Фильтры: `form_tag` GET с `select_tag` + `onchange: "this.form.submit()"`, private filter methods в controller
  - Forms: `form_with model: [:admin, @record], local: true`, shared `_form` partial
  - Views: `page-header` > `page-main` > `card` > `card__body` layout
  - Errors: `alert alert--error` с `full_messages`
  - Sort: default direction toggle в params
- **Implications**: TechnologiesController должен точно следовать этим паттернам

### Рефакторинг category: string → association
- **Context**: Текущий `category` — строковое поле с 5 значениями в seeds (backend, frontend, database, devops, cloud)
- **Sources**: `app/models/technology.rb`, `db/migrate/20251104074554_create_technologies.rb`, `db/seeds.rb`
- **Findings**:
  - Текущий scope `by_category` принимает строку: `where(category: category)`
  - В модели 294 строки бизнес-логики, `category` используется в аналитических методах
  - seeds используют `category:` как строку при создании Technology
  - Индекс на `category` уже существует
- **Implications**:
  - Миграция в 3 этапа: добавить `category_id` → data migration → удалить `category`
  - Обновить scope `by_category` для работы с `category_id`
  - Обновить все обращения к `technology.category` в коде на `technology.category&.name`

### Существующий Admin::TechnologyPolicy
- **Context**: Политика уже существует, наследует Admin::BasePolicy
- **Sources**: `app/policies/admin/technology_policy.rb`
- **Findings**: Пустой класс, наследует полный CRUD для admin-роли
- **Implications**: Дополнительные изменения в policy не требуются

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Inline category management | Category создается/выбирается только в форме Technology | Простота, нет лишнего UI | Нет управления категориями отдельно | Соответствует текущей задаче |
| Separate admin CRUD for Category | Полноценный раздел Categories в админке | Гибкость управления | Избыточность для 5-10 категорий | Не требуется по требованиям |

## Design Decisions

### Decision: Category без отдельного admin UI
- **Context**: Requirements говорят только об управлении категориями в контексте технологий
- **Alternatives Considered**:
  1. Отдельный CRUD для Category в админке
  2. Inline создание категории через форму Technology
- **Selected Approach**: Category создаются в seeds; в форме Technology — `collection_select` из существующих категорий. При необходимости можно добавить создание категории позже.
- **Rationale**: В requirements не указан CRUD для Category. Текущие 5 категорий покрывают потребности.
- **Trade-offs**: Создание новой категории требует db change или future enhancement
- **Follow-up**: Если потребуется управление категориями — добавить отдельный endpoint

### Decision: Многошаговая миграция category
- **Context**: Переход от string column к belongs_to association
- **Alternatives Considered**:
  1. Single migration (add column + migrate data + remove old column)
  2. Двухшаговая: добавить column + data migration, затем удалить старый column
- **Selected Approach**: Single reversible migration с `up`/`down`: добавить `category_id`, data migration, удалить `category` column
- **Rationale**: Приложение в разработке, нет production data. Реверсивная миграция достаточна.
- **Trade-offs**: При наличии production данных потребовалась бы более осторожная стратегия

### Decision: Форма через shared partial
- **Context**: UsersController использует `_form` partial, QuartersController — inline
- **Alternatives Considered**:
  1. Shared `_form` partial (users pattern)
  2. Inline form в new/edit (quarters pattern)
- **Selected Approach**: Shared `_form` partial для new и edit
- **Rationale**: Форма идентична для создания и редактирования, partial уменьшает дублирование

## Risks & Mitigations
- Ссылки на `technology.category` в аналитических методах модели — обновить на `technology.category&.name` в рамках миграции
- Фильтр по категории может быть пустым если нет Category records — seeds создают категории до технологий

## References
- Existing admin patterns: `app/controllers/admin/users_controller.rb`, `app/controllers/admin/quarters_controller.rb`
- Technology model: `app/models/technology.rb`
