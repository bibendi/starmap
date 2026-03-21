# Implementation Plan

## Task Format

### Major + Sub-task structure

- [ ] 1. Create AdminUserPolicy for admin-only access control
- [x] 1.1 (P) Create Admin::UserPolicy class with admin-only rules
  - Inherit from Admin::BasePolicy
  - Override can_manage? to check user.admin?
  - Add Scope class for policy scoping
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 2. Implement user listing functionality
- [x] 2.1 (P) Create index action in AdminUsersController
  - Add policy_scope([:admin, User])
  - Implement filter_by_role, filter_by_status, search, sort methods
  - Add pagination with Kaminari (PER_PAGE = 25)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2.2 (P) Create index.html.erb view
  - Page header with title and "New User" button
  - Filter form for role and status
  - Search input for name and email
  - Table with columns: name, email, position, role, team, status
  - Sortable column headers
  - Action links to show and edit
  - Kaminari pagination
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 3. Implement user details functionality
- [x] 3.1 (P) Create show action in AdminUsersController
  - Find user by id
  - Authorize with Admin::UserPolicy
  - Render show view
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 3.2 (P) Create show.html.erb view
  - Page header with title and Edit button
  - User attributes card (name, email, position, role, team, status)
  - Sign-in info (current_sign_in_at)
  - Audit trail (created_at, updated_at)
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 4. Implement user creation functionality
- [x] 4.1 (P) Create new and create actions in AdminUsersController
  - new action: build empty User, authorize, render form
  - create action: build User with params, authorize, save or render with errors
  - Redirect to index with success message on save
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 4.2 (P) Create shared _form.html.erb partial
  - Fields: first_name, last_name, email, position, role, team_id, active
  - Password fields (only on new user form)
  - Role validation: team required for team_lead
  - Email uniqueness validation
  - Password minimum length validation
  - Validation error display
  - Submit button and Cancel link
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 4.1, 4.2, 4.3, 6.1, 6.2, 6.3, 6.4_

- [x] 4.3 (P) Create new.html.erb view
  - Render page header
  - Render _form partial with url: admin_users_path, method: POST
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 5. Implement user edit functionality
- [x] 5.1 (P) Create edit and update actions in AdminUsersController
  - edit action: find user, authorize, render form
  - update action: find user, authorize, update attributes, redirect or render errors
  - Redirect to show with success message on update
  - Handle deactivation (active = false)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 5.1, 5.2, 5.3, 5.4_

- [x] 5.2 (P) Create edit.html.erb view
  - Render page header
  - Render _form partial with url: admin_user_path(@user), method: PATCH
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 6. Add integration and unit tests
- [x] 6.1 (P) Write Admin::UserPolicy unit tests
  - Test admin user can access all actions
  - Test non-admin user receives 403 Forbidden
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 6.2 (P) Write AdminUsersController request specs
  - Test all CRUD actions with authentication
  - Test filtering, sorting, search in index
  - Test validation errors display
  - Test deactivation and reactivation
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3_

- [ ] 6.3 (P) Write system specs for user management flow (N/A - system tests not planned)
  - Test create user → view → edit → deactivate flow
  - Test admin-only access for non-admin users
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3_
