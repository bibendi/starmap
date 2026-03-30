# Research & Design Decisions

## Summary
- **Feature**: `admin-units-crud`
- **Discovery Scope**: Simple Addition
- **Key Findings**:
  - Существующие admin-контроллеры (Technologies, Users, Quarters) используют единый паттерн: `Admin::BaseController` → `authorize [:admin, Model]` → Pundit
  - `Admin::BasePolicy` предоставляет полный CRUD для admin-роли; пустой `Admin::TechnologyPolicy` наследует его
  - Navigation sidebar в `admin.html.erb` рендерит ссылки на основе `policy([:admin, Model]).index?`
  - Unit model имеет `has_many :teams, dependent: :nullify`, но по требованиям 4.2 удаление при наличии teams должно быть запрещено

## Research Log

### Анализ существующих паттернов админки
- **Context**: Необходимо определить стандартный подход к CRUD в админке
- **Sources Consulted**: `app/controllers/admin/technologies_controller.rb`, `app/policies/admin/base_policy.rb`, `app/views/admin/technologies/`, `config/routes.rb`, `app/views/layouts/admin.html.erb`
- **Findings**:
  - Контроллеры наследуют `Admin::BaseController`, используют `PER_PAGE = 25`, `before_action :set_<model>`, фильтры через приватные методы, пагинацию Kaminari
  - Авторизация: `authorize [:admin, Model]` во всех действиях
  - Views используют CSS-компоненты: `page-header`, `card`, `table`, `btn`, `badge`, `field`, `form-label`, `form-input`
  - Sidebar navigation в layout проверяет `policy([:admin, Model]).index?`
  - Destroy action обрабатывает ошибки через `redirect_to` с `alert`
- **Implications**: Units CRUD полностью повторяет паттерн Technologies, за исключением логики удаления (блокировка при наличии teams)

### Удаление sort_order
- **Context**: Колонка sort_order больше не нужна
- **Sources Consulted**: `app/models/unit.rb`, `db/schema.rb`
- **Findings**:
  - Model содержит: `validates :sort_order, numericality: {...}`, `scope :ordered, -> { order(:sort_order, :name) }`, `before_validation :set_default_sort_order`
  - В schema: индекс на `sort_order`, default `0`
  - Никакие другие модели не ссылаются на `Unit.ordered` напрямую
- **Implications**: Миграция удаляет колонку и индекс; scope `ordered` заменяется на `order(:name)`

## Design Decisions

### Decision: Блокировка удаления Unit при наличии teams
- **Context**: Требование 4.2 — нельзя удалить Unit с привязанными командами
- **Alternatives Considered**:
  1. `dependent: :nullify` — автоматическое отвязывание (текущее поведение модели)
  2. `dependent: :restrict_with_error` — стандартный Rails механизм блокировки
  3. Проверка в controller destroy — ручная проверка `teams.any?`
- **Selected Approach**: `dependent: :restrict_with_error` на модели; контроллер обрабатывает `!@unit.destroy` через redirect с alert (паттерн TechnologiesController)
- **Rationale**: Бизнес-правило живёт в модели (правильный слой), `restrict_with_error` — стандартный Rails-механизм, контроллеру не нужно знать о правиле
- **Trade-offs**: Нет дополнительных проверок в контроллере
- **Follow-up**: —

## Risks & Mitigations
- `dependent: :restrict_with_error` автоматически добавит ошибку к model и вернёт `false` из destroy — контроллеру достаточно стандартной обработки
- Удаление sort_order затрагивает scope `ordered` — нужно убедиться, что он нигде не вызывается в production коде

## References
- `app/controllers/admin/technologies_controller.rb` — эталонный CRUD контроллер
- `app/views/layouts/admin.html.erb` — sidebar navigation паттерн
- `app/policies/admin/base_policy.rb` — базовая политика авторизации
