# Requirements Document

## Introduction
Создание раздела управления Unit (подразделениями) в административной панели приложения Starmap. Реализация полного CRUD для Units с удалением колонки `sort_order` из модели. Раздел следует существующим паттернам админ-панели (Technologies, Users, Quarters).

## Requirements

### Requirement 1: Просмотр списка Units
**Objective:** Как администратор, я хочу видеть список всех Units с фильтрацией и сортировкой, чтобы эффективно находить и анализировать подразделения.

#### Acceptance Criteria
1. The Admin Panel shall display a list of all Units on the index page with columns: name, description, active status, unit lead.
2. When administrator clicks on a Unit in the list, the Admin Panel shall navigate to the Unit detail page.
3. When the list of Units is displayed, the Admin Panel shall order Units by name alphabetically.
4. The Admin Panel shall provide a link to create a new Unit from the index page.

### Requirement 2: Создание Unit
**Objective:** Как администратор, я хочу создавать новые Units, чтобы добавлять подразделения в систему.

#### Acceptance Criteria
1. When administrator submits valid Unit data, the Admin Panel shall create a new Unit and redirect to the Unit list.
2. If administrator submits Unit with duplicate name, the Admin Panel shall display validation error and preserve entered data.
3. If administrator submits Unit with empty name, the Admin Panel shall display validation error and preserve entered data.
4. The Admin Panel shall provide a form with fields: name (required), description (optional), active (boolean), unit lead (select from users).

### Requirement 3: Редактирование Unit
**Objective:** Как администратор, я хочу редактировать существующие Units, чтобы обновлять информацию о подразделениях.

#### Acceptance Criteria
1. When administrator submits valid updated Unit data, the Admin Panel shall save changes and redirect to the Unit list.
2. If administrator submits duplicate name on edit, the Admin Panel shall display validation error and preserve entered data.
3. When editing a Unit, the Admin Panel shall pre-fill the form with current Unit data.

### Requirement 4: Удаление Unit
**Objective:** Как администратор, я хочу удалять Units, чтобы убирать нерелевантные подразделения.

#### Acceptance Criteria
1. When administrator confirms Unit deletion, the Admin Panel shall delete the Unit and redirect to the Unit list.
2. If Unit has associated teams, the Admin Panel shall reject deletion and display error message.
3. If Unit has an assigned unit_lead, the Admin Panel shall clear the unit_lead assignment before deletion.

### Requirement 5: Удаление колонки sort_order
**Objective:** Как администратор, я хочу убрать колонку sort_order, так как ручная сортировка не используется.

#### Acceptance Criteria
1. The system shall remove the `sort_order` column from the `units` table via migration.
2. The Unit model shall remove all references to `sort_order` including validations, scopes, callbacks, and index.
3. The default ordering of Units shall be by `name` after `sort_order` removal.

### Requirement 6: Авторизация
**Objective:** Как система, я хочу ограничить доступ к управлению Units только для администраторов, чтобы предотвратить несанкционированные изменения.

#### Acceptance Criteria
1. If non-admin user attempts to access admin Units pages, the system shall deny access.
2. The Admin Panel shall restrict all Unit CRUD operations to users with admin role.
