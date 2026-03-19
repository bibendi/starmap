# Technical Design Document

## Overview

Переименование маршрута `/engineer` в `/users/:id` с полным рефакторингом связанных компонентов. Данная задача является рефакторингом существующей функциональности для приведения именования в соответствие с Rails конвенциями и доменной моделью (User вместо Engineer).

**Users**: Разработчики и системные администраторы будут использовать обновленные маршруты и политики.

**Impact**: Изменяет нейминг маршрутов, контроллеров, политик и i18n ключей без изменения бизнес-логики.

## Goals

- Заменить маршрут `/engineer` на `/users/:id`
- Рефакторинг `EngineersController` → `UsersController`
- Рефакторинг `EngineerPolicy` → `UserPolicy`
- Обновить все URL helpers в views и controllers
- Обновить i18n ключи для соответствия новой структуре

## Non-Goals

- Изменение бизнес-логики авторизации
- Изменение поведения отображения профилей
- Добавление новых функций
- Изменение структуры базы данных

## Architecture

### Existing Architecture Analysis

Текущая архитектура использует:
- `EngineersController` для обработки запросов профилей инженеров
- `EngineerPolicy` для авторизации доступа к профилям
- Маршрут `/engineer` без параметра id (получает текущего пользователя)

**Integration Points**:
- Navigation link в `application.html.erb`
- Links в `teams/show.html.erb` для отображения членов команды
- Redirects в `skill_ratings_controller.rb`
- Тесты в `spec/requests/engineers_spec.rb` и `spec/requests/skill_ratings_spec.rb`

**Technical Debt**: Нейминг "engineer" не соответствует доменной модели User и создает путаницу.

### Architecture Pattern & Boundary Map

**Selected pattern**: Standard Rails MVC с Pundit авторизацией

**Changes**:
- Controller renaming без изменения логики
- Policy renaming с сохранением правил авторизации
- Route structure: от `/engineer` к `/users/:id`

**Steering compliance**: 
- Соответствует стандартам Rails MVC из structure.md
- Использует существующий шаблон Pundit политик
- Следует naming conventions (snake_case для controllers/policies)

### Technology Stack

| Layer | Choice / Version | Role in Feature | Notes |
|-------|------------------|-----------------|-------|
| Backend | Ruby on Rails 8.1.1 | Framework | Без изменений |
| Authorization | Pundit | Policy-based auth | Переименование политики |
| Routing | Rails Router | URL mapping | Новый маршрут + redirect |
| Localization | I18n (en, ru) | Translation keys | Обновление ключей |

## Requirements Traceability

| Requirement | Summary | Components | Interfaces | Flows |
|-------------|---------|------------|------------|-------|
| 1.1 | Маршрут /users/:id | UsersController | GET /users/:id | Profile display |
| 1.2 | Legacy redirect | Routes | GET /engineer → /users/:id | Redirect flow |
| 2.1 | UsersController show | UsersController | #show action | Authorization check |
| 2.2 | 403 на ошибку авторизации | UsersController, UserPolicy | Pundit::NotAuthorizedError | Error handling |
| 3.1 | Замена EngineerPolicy | UserPolicy | Policy methods | Authorization logic |
| 3.2 | Engineer доступ к себе | UserPolicy#show? | User role check | Self-access only |
| 3.3 | Team Lead доступ к команде | UserPolicy#show? | Team membership check | Team access |
| 3.4 | Admin/Unit Lead полный доступ | UserPolicy#show? | Role check | Full access |
| 4.1 | URL helpers user_path | Views, Controllers | user_path, users_path | Link generation |
| 4.2 | Удаление engineer_path | All files | N/A | Code cleanup |
| 5.1 | Обновление i18n ключей | Locale files | config/locales/*.yml | Translation keys |
| 5.2 | Fallback локализации | I18n config | Default locale | Error handling |

## Components and Interfaces

| Component | Domain/Layer | Intent | Req Coverage | Key Dependencies | Contracts |
|-----------|--------------|--------|--------------|------------------|-----------|
| UsersController | Backend | Обработка запросов профилей | 1.1, 2.1, 2.2 | UserPolicy (P0), User model (P0) | Controller |
| UserPolicy | Backend | Авторизация доступа к профилям | 3.1-3.4 | User model (P0), Pundit (P0) | Policy |
| Routes | Backend | URL routing и redirects | 1.1, 1.2 | UsersController (P0) | Route |
| Locale Files | Config | Переводы интерфейса | 5.1, 5.2 | I18n (P0) | Config |

### UsersController

| Field | Detail |
|-------|--------|
| Intent | Обработка HTTP запросов для отображения профилей пользователей |
| Requirements | 1.1, 2.1, 2.2 |

**Responsibilities & Constraints**
- Обработка GET /users/:id
- Проверка авторизации через UserPolicy
- Рендеринг профиля пользователя
- Редирект на страницу 403 при отказе в доступе

**Dependencies**
- Inbound: Router — HTTP requests (P0)
- Outbound: UserPolicy — authorization decisions (P0)
- Outbound: User model — data retrieval (P0)

**Contracts**: Controller

##### Controller Interface
```ruby
class UsersController < ApplicationController
  def show
    # Params: id (user identifier)
    # Authorization: UserPolicy#show?
    # Response: Renders user profile or redirects to root with alert
  end
end
```
- Preconditions: User существует в базе данных
- Postconditions: Профиль отрендерен или редирект выполнен
- Invariants: Авторизация проверяется до рендеринга

**Implementation Notes**
- Integration: Замена EngineersController без изменения логики
- Validation: Все тесты должны проходить с новыми маршрутами
- Risks: Пропущенные ссылки на engineer_path в views

### UserPolicy

| Field | Detail |
|-------|--------|
| Intent | Инкапсуляция правил авторизации доступа к профилям пользователей |
| Requirements | 3.1, 3.2, 3.3, 3.4 |

**Responsibilities & Constraints**
- Определение доступа к профилю пользователя
- Role-based authorization: Engineer, Team Lead, Unit Lead, Admin
- Record-level permissions

**Dependencies**
- Inbound: UsersController — authorization checks (P0)
- Outbound: User model — role and team data (P0)

**Contracts**: Policy

##### Policy Interface
```ruby
class UserPolicy < ApplicationPolicy
  def show?
    # Returns: Boolean
    # Logic: 
    #   - Admin/Unit Lead: true
    #   - Team Lead: user.team == record.team
    #   - Engineer: user == record
  end
end
```

**Implementation Notes**
- Integration: Замена EngineerPolicy с идентичной логикой
- Validation: Policy specs должны проходить без изменений
- Risks: Убедиться что все вызовы EngineerPolicy обновлены

### Routes

| Field | Detail |
|-------|--------|
| Intent | URL routing для пользовательских профилей |
| Requirements | 1.1, 1.2, 4.1 |

**Responsibilities & Constraints**
- Маршрутизация GET /users/:id к UsersController#show
- Редирект legacy /engineer на /users/:id
- Генерация URL helpers user_path и users_path

**Dependencies**
- Outbound: UsersController — action dispatch (P0)

**Contracts**: Route

##### Route Contract
```ruby
# config/routes.rb
resources :users, only: [:show]
get '/engineer', to: redirect('/users/%{id}') # или controller redirect
```

**Implementation Notes**
- Integration: Добавить resources :users, удалить или редиректить /engineer
- Validation: Route specs должны проходить
- Risks: Старые закладки должны продолжать работать

## Testing Strategy

### Unit Tests
- Policy specs: UserPolicy должен иметь те же тесты что и EngineerPolicy
- Controller specs: UsersController#show с проверкой авторизации

### Integration Tests
- Request specs: GET /users/:id возвращает профиль
- Request specs: GET /engineer редиректит на /users/:id
- Request specs: 403 при отсутствии доступа

### E2E/UI Tests
- Навигационная ссылка ведет на /users/:id
- Ссылки на профили в teams/show работают

## Migration Strategy

**Phase 1**: Создание UsersController и UserPolicy (duplicate logic)
**Phase 2**: Обновление routes с добавлением /users/:id и redirect /engineer
**Phase 3**: Обновление всех views (engineer_path → user_path)
**Phase 4**: Обновление всех controllers (engineer_path → user_path)
**Phase 5**: Обновление i18n ключей
**Phase 6**: Обновление тестов
**Phase 7**: Удаление EngineersController и EngineerPolicy

**Rollback**: Вернуть routes, восстановить старые controllers/policies

**Validation Checkpoints**:
- Все тесты проходят
- Ручная проверка навигации
- Проверка ссылок в teams/show
