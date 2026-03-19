# Requirements Document

## Project Description (Input)
переименовать маршрут /units в resources :units с доступом по id. Обратная совместимость не нужна.

## Requirements

### Requirement 1: Замена маршрута /units на resources :units

**Objective:** As a developer, I want изменить маршрут с /units на resources :units, so that использовать стандартную RESTful структуру Rails.

#### Acceptance Criteria
1. When маршруты загружаются, система должна иметь маршруты resources :units вместо get "/units".
2. When запрос отправлен на /units, система должна вернуть код 404 (обратная совместимость не нужна).
3. When запрос отправлен на /units/:id, система должна направить его в соответствующий контроллер для обработки.