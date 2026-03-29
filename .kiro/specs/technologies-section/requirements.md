# Requirements Document

## Introduction
Раздел «Компетенции» в админке — центральный инструмент для управления каталогом навыков команды. Требуется заменить текущую заглушку на полнофункциональный раздел с CRUD, фильтрацией и управлением категориями. Категория технологий рефакторится из строкового поля в отдельную сущность для обеспечения консистентности данных. Название раздела в UI меняется на «Компетенции» через i18n, при этом модель и таблица `Technology` остаются без изменений.

## Requirements

### 1. Переименование раздела в «Компетенции»
**Objective:** As an Admin, I want the admin section to be named «Компетенции», so that the naming reflects that it covers various skills, not only specific libraries.

#### Acceptance Criteria
1. The Admin Panel shall display the name «Компетенции» instead of «Технологии» in the sidebar navigation via i18n key `admin.sidebar.technologies`.
2. The Admin Panel shall display «Компетенции» as the page heading in the technologies index view via i18n.
3. The system shall not rename the `Technology` model, `technologies` database table, or any code references — only i18n keys are changed.

### 2. Сущность Category
**Objective:** As an Admin, I want technology categories to be a separate entity, so that category names are consistent, validated, and manageable independently.

#### Acceptance Criteria
1. The system shall provide a `Category` model with attributes: `name` (string, presence, uniqueness) and `timestamps`.
2. The `Category` model shall have a `has_many :technologies` association.
3. The `Technology` model shall belong to a `Category` via `category_id` foreign key (nullable for migration compatibility).
4. When a Category is destroyed, the system shall prevent destruction if associated technologies exist.
5. The system shall migrate existing string `category` values from `technologies` table to corresponding `Category` records.
6. The `Technology` model shall have a scope `by_category(category_id)` that filters by the `category_id` association.
7. The system shall update `db/seeds.rb` to create Category records and associate technologies with them.

### 3. CRUD технологий в админке
**Objective:** As an Admin, I want to create, read, update, and delete technologies, so that the technology catalog is always up-to-date.

#### Acceptance Criteria
1. The Admin Panel shall display a list of technologies on the index page with columns: name, category, criticality, active status, target experts, sort order.
2. The Admin Panel shall support creating a new technology via a form with fields: name, description, category (select from existing categories), criticality, target experts, sort order, active toggle.
3. The Admin Panel shall support editing an existing technology via a form with the same fields as creation.
4. The Admin Panel shall support deleting a technology.
5. The Admin Panel shall paginate the technologies list.
6. The Admin Panel shall sort technologies by sort order ascending, then by name ascending by default.
7. If the technology name is not unique, the system shall display a validation error and prevent saving.

### 4. Фильтрация в листинге технологий
**Objective:** As an Admin, I want to filter technologies by status, name, and category, so that I can quickly find specific technologies in a large catalog.

#### Acceptance Criteria
1. The Admin Panel shall provide a filter by `active` status (all / active / inactive).
2. The Admin Panel shall provide a text filter by technology name (partial match, case-insensitive).
3. The Admin Panel shall provide a filter by category (select from existing categories).
4. When multiple filters are applied simultaneously, the Admin Panel shall combine them with AND logic.
5. When filters are applied, the Admin Panel shall preserve filter state across pagination.

### 5. Авторизация
**Objective:** As an Admin, I want technology management to be restricted to admin users only, so that unauthorized users cannot modify the catalog.

#### Acceptance Criteria
1. The Admin Panel shall allow only users with the `admin` role to access the technologies CRUD actions.
2. If a non-admin user attempts to access technology management, the system shall deny access via Pundit policy.
