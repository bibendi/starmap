# Requirements Document

## Project Description (Input)
переименовать маршруты /team(s) в resources :teams, only: [:index, :show]. Обратная совместимость не нужна. Поиск и замена url helpers для teams

## Introduction
Данная спецификация описывает требования к рефакторингу маршрутов Rails для сущности Team. Необходимо преобразовать маршруты из /team(s) в ресурсный стиль `resources :teams` с ограничением до действий index и show, а также обновить все URL-хелперы в кодовой базе.

## Requirements

### Requirement 1: Реструктуризация маршрутов
**Objective:** As a developer, I want использовать стандартные ресурсные маршруты Rails для Teams, so that упростить конфигурацию роутинга и следовать соглашениям Rails

#### Acceptance Criteria
1. The system shall have routes configured as `resources :teams, only: [:index, :show]`
2. The routes shall respond to GET `/teams` for index action
3. The routes shall respond to GET `/teams/:id` for show action
4. The system shall NOT have any other routes for teams resource (no new, create, edit, update, destroy)

### Requirement 2: Обновление URL-хелперов
**Objective:** As a developer, I want использовать一致的URL-хелперы после рефакторинга, so that обеспечить корректную навигацию во всём приложении

#### Acceptance Criteria
1. Where teams_url is used in views, the system shall use `teams_url` helper
2. Where team_url is used in views, the system shall use `team_url(team)` helper
3. The system shall have `teams_path` available for index links
4. The system shall have `team_path(team)` available for show links

### Requirement 3: Поиск и замена хелперов в представлениях
**Objective:** As a developer, I want найти и обновить все ссылки на teams в представлениях, so that приложение сохраняет корректную навигацию

#### Acceptance Criteria
1. When a view contains `teams_url` or `teams_path`, the system shall update to use correct resource-based helpers
2. When a view contains `team_url(id)` or `team_path(id)`, the system shall update to use `team_path(team)` with ActiveRecord object
3. The system shall update all ERB templates referencing teams routes
4. The system shall update all partials referencing teams routes

### Requirement 4: Поиск и замена хелперов в контроллерах и других местах
**Objective:** As a developer, I want найти и обновить все ссылки на teams в коде приложения, so that обеспечить корректную генерацию URL везде

#### Acceptance Criteria
1. When a controller uses `teams_url` or `teams_path`, the system shall update to use correct resource-based helpers
2. When a controller uses `team_url(id)` or `team_path(id)`, the system shall update to use `team_path(team)`
3. The system shall update all redirect_to calls referencing teams routes
4. The system shall update all references in mailers, jobs, and other non-controller code

### Requirement 5: Удаление старых маршрутов
**Objective:** As a developer, I want удалить все старые маршруты team, so that избежать конфликтов и конфузии в конфигурации

#### Acceptance Criteria
1. The system shall NOT have `get 'team'` route
2. The system shall NOT have `get 'teams'` route (if it existed separately)
3. The system shall NOT have `get 'team/:id'` route
4. The routes configuration shall contain only `resources :teams, only: [:index, :show]`
