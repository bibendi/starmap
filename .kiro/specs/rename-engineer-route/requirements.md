# Requirements Document

## Introduction
Изменение маршрута `/engineer` на `/users/:id` с полным рефакторингом связанных компонентов: контроллеров, политик, URL-хелперов и интернационализации.

## Requirements

### Requirement 1: Маршрут пользователя
**Objective:** As a **Developer**, I want **a consistent /users/:id route structure**, so that **URL naming follows Rails conventions and reflects the User model**

#### Acceptance Criteria
1. When [система получает запрос GET /users/:id], the [UserController] shall [вернуть страницу профиля пользователя]
2. The [system] shall [перенаправлять legacy-запросы /engineer на соответствующие /users/:id endpoints]
3. While [приложение обрабатывает запрос пользователя], the [system] shall [поддерживать обратную совместимость с существующими закладками]

### Requirement 2: Контроллер пользователя
**Objective:** As a **Team Lead**, I want **UsersController to handle all user-related HTTP requests**, so that **the codebase follows single responsibility principle and removes Engineer-specific naming**

#### Acceptance Criteria
1. When [получен запрос GET /users/:id], the [UsersController] shall [отрендерить профиль пользователя с соответствующими проверками политик]
2. If [авторизация для доступа к профилю пользователя не удалась], the [system] shall [вернуть статус 403 с сообщением об ошибке]
3. The [system] shall [использовать UserPolicy для всех решений по авторизации на ресурсах пользователя]

### Requirement 3: Политика авторизации пользователя
**Objective:** As an **Admin**, I want **UserPolicy to encapsulate user access rules**, so that **authorization logic is centralized and maintainable**

#### Acceptance Criteria
1. The [system] shall [использовать UserPolicy вместо EngineerPolicy для всей авторизации, связанной с пользователями]
2. Where [текущий пользователь имеет роль Engineer], the [UserPolicy] shall [разрешить доступ только к собственному профилю через /users/:id]
3. Where [текущий пользователь имеет роль Team Lead], the [UserPolicy] shall [разрешить доступ к профилям инженеров в их команде]
4. Where [текущий пользователь имеет роль Admin или Unit Lead], the [UserPolicy] shall [разрешить доступ ко всем профилям пользователей]

### Requirement 4: URL helpers
**Objective:** As a **Developer**, I want **all URL helpers updated to use user_*_path patterns**, so that **routes are consistent and maintainable across the codebase**

#### Acceptance Criteria
1. When [view или controller ссылаются на URL, связанный с инженером], the [system] shall [использовать хелперы user_path или users_path]
2. The [system] shall [не содержать ссылок на хелперы engineer_path или engineers_path после рефакторинга]

### Requirement 5: Интернационализация
**Objective:** As a **User**, I want **all i18n keys updated to reflect the new route structure**, so that **labels and messages remain accurate in all supported locales**

#### Acceptance Criteria
1. The [system] shall [обновить все i18n ключи, содержащие ссылки на engineer, на ключи с user]
2. Where [локализация для конкретной локали недоступна], the [system] shall [использовать fallback на дефолтную локаль]
