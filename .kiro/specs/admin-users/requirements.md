# Requirements Document

## Introduction

Система управления пользователями в административной панели. Предоставляет администраторам и HR возможность просматривать, создавать, редактировать и деактивировать учетные записи пользователей. Функциональность ограничена ролью admin.

## Requirements

### Requirement 1: Листинг пользователей

**Objective:** As an admin, I want to view a list of all users, so that I can manage user accounts efficiently

#### Acceptance Criteria
1. When admin accesses the users section, the system shall display a paginated list of users with name, email, position, role, team, and status
2. The list shall support sorting by name, email, role, and created_at date
3. The list shall support filtering by role (engineer, team_lead, unit_lead, admin) and status (active, inactive)
4. The list shall support text search by name and email
5. Each row shall provide a link to view user details and a link to edit user

### Requirement 2: Карточка пользователя

**Objective:** As an admin, I want to view detailed user information, so that I can verify account details and activity

#### Acceptance Criteria
1. When admin opens a user details page, the system shall display all user attributes: name, email, position, role, team, status, created_at, current_sign_in_at
2. The details page shall display audit trail of recent changes (created by, updated by, timestamps)
3. The details page shall provide an edit button visible only to admin role

### Requirement 3: Форма редактирования пользователя

**Objective:** As an admin, I want to edit user information, so that I can maintain accurate user data and manage access

#### Acceptance Criteria
1. When admin opens the edit form, the system shall display fields for: name, email, position, role, team, status
2. The form shall validate that email is unique and properly formatted
3. The form shall allow role change between engineer, team_lead, unit_lead, admin
4. The form shall allow team assignment (nullable for users without team)
5. The form shall allow status change between active and inactive
6. When admin submits valid form, the system shall update user and redirect to user details with success message
7. When admin submits invalid form, the system shall display validation errors without redirecting

### Requirement 4: Создание нового пользователя

**Objective:** As an admin, I want to create new user accounts, so that new employees can access the system

#### Acceptance Criteria
1. When admin accesses the new user form, the system shall display fields for: name, email, role, team, status, password
2. The form shall allow admin to set password directly with validation (minimum length, complexity requirements)
3. When admin submits valid form, the system shall create user with specified password and redirect to users list with success message

### Requirement 5: Деактивация пользователя

**Objective:** As an admin, I want to deactivate user accounts, so that former employees cannot access the system while preserving their data

#### Acceptance Criteria
1. When admin changes user status to inactive, the system shall prevent the user from signing in
2. When admin deactivates a user, the system shall preserve all user data including ratings and action plans
3. The system shall allow reactivation of a deactivated user by changing status to active
4. Deactivated users shall be hidden from default listing but visible when filtering by "inactive" status

### Requirement 6: Управление ролями

**Objective:** As an admin, I want to manage user roles, so that users have appropriate access levels

#### Acceptance Criteria
1. The system shall allow admin to assign one of the following roles: engineer, team_lead, unit_lead, admin
2. When role changes, the system shall immediately update Pundit policy permissions for the user
3. If a team_lead is reassigned from their team, the system shall require reassigning their team members to another team_lead first
4. The system shall log all role changes with actor, target user, old role, and new role

### Requirement 7: Авторизация доступа

**Objective:** As a system, I want to enforce authorization, so that only admin role can manage users

#### Acceptance Criteria
1. All user management actions (list, view, create, edit, deactivate) shall be protected by Pundit policy requiring admin role
2. Non-admin users shall receive a 403 Forbidden response when attempting to access user management features
3. All user management actions shall be logged with actor, action, target user, and timestamp
