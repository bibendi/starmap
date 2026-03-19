# Design Document

## Overview

Данная задача выполняет замену Rails маршрута `/units` на RESTful ресурс `resources :units, only: [:index, :show]`. Изменение затрагивает только файл маршрутов `config/routes.rb`, без модификации контроллера или модели.

### Goals
- Заменить `get "/units"` и `get "/unit"` на `resources :units, only: [:index, :show]` в config/routes.rb

### Non-Goals
- Реализация новых экшнов контроллера (new, edit, create, update, destroy)
- Изменение UnitsController

## Architecture

### Existing Architecture Analysis
Текущая конфигурация в `config/routes.rb`:
```ruby
get "/units", to: "units#index", as: :units
get "/unit", to: "units#show", as: :unit
```

### Architecture Pattern & Boundary Map
Простое изменение маршрута без архитектурных изменений. Единственная точка модификации — `config/routes.rb`.

## Components and Interfaces

### config/routes.rb

| Field | Detail |
|-------|--------|
| Intent | Замена маршрутов units на RESTful ресурс |
| Requirements | 1.1, 1.2, 1.3 |
| Owner / Reviewers | (optional) |

**Responsibilities & Constraints**
- Единственная точка изменения
- Маршруты должны корректно загружаться после изменения

**Dependencies**
- Inbound: UnitsController — существующий контроллер

**Contracts**: нет

**Implementation Notes**
- Изменение: заменить две строки `get "/units"` и `get "/unit"` на одну строку `resources :units, only: [:index, :show]`
- Валидация: `bin/rails routes | grep units` для проверки маршрутов

## Requirements Traceability

| Requirement | Summary | Components |
|-------------|---------|------------|
| 1.1 | resources :units, only: [:index, :show] | routes.rb |
| 1.2 | /units без параметров -> 404 | routes.rb |
| 1.3 | /units/:id -> UnitsController#show | routes.rb → UnitsController |

## Testing Strategy

### Unit Tests
- `bin/rails routes | grep units` возвращает только:
  - GET `/units` -> UnitsController#index
  - GET `/units/:id` -> UnitsController#show