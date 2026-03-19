# Research & Design Decisions

## Summary
- **Feature**: rename-units-route
- **Discovery Scope**: Simple Addition
- **Key Findings**:
  - Текущий маршрут `get "/units"` требуется заменить на `resources :units, only: [:index, :show]`
  - Существующий контроллер `UnitsController` уже существует и обрабатывает действия index/show
  - CRUD операции (new, edit, create, update, destroy) будут в отдельном админском контроллере

## Research Log

### Анализ текущих маршрутов
- **Context**: Необходимо понять текущую структуру маршрутов units
- **Sources Consulted**: config/routes.rb
- **Findings**:
  - `get "/units", to: "units#index", as: :units` — текущий маршрут списка
  - `get "/unit", to: "units#show", as: :unit` — текущий маршрут показа одного юнита (использует `/unit` без s)
- **Implications**: При замене на `resources :units` получим стандартные маршруты: index, show, new, create, edit, update, destroy

### Rails resources
- **Context**: Проверка стандартного поведения resources :units
- **Sources Consulted**: Rails Routing Guide
- **Findings**:
  - `resources :units` создаёт маршруты: GET /units, GET /units/:id, POST /units, PUT/PATCH /units/:id, DELETE /units/:id
  - Вместо `get "/unit"` (singular) получаем `get "/units/:id"` (через resources)
- **Implications**: Изменение URL с `/unit` на `/units/:id` — это ожидаемое поведение Rails resources

## Design Decisions

### Decision: Замена get на resources
- **Context**: Требуется RESTful маршрутизация для Units
- **Alternatives Considered**:
  1. `get "/units"` + `get "/units/:id"` — дублирование resources без преимуществ
  2. `resources :units` — полный CRUD, не нужен
  3. `resources :units, only: [:index, :show]` — только нужные экшны
- **Selected Approach**: `resources :units, only: [:index, :show]`
- **Rationale**: Соответствует Rails conventions, следует steering принципам простоты, CRUD будет в отдельном контроллере
- **Trade-offs**: Нет
- **Follow-up**: Проверить, что контроллер обрабатывает экшны index и show

## Risks & Mitigations
- Существующие ссылки на `/unit` (без s) — нет риска: обратная совместимость не нужна
- Изменение формата URL — нет риска: это именно цель задачи

## References
- [Rails Routing Guide](https://guides.rubyonrails.org/routing.html) — ресурсы и стандартные маршруты