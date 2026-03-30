# Implementation Plan

- [x] 1. Unit model cleanup and sort_order removal
  - Remove sort_order validation, before_validation callback, old ordered scope from Unit model
  - Add new ordered scope ordering by name
  - Change teams association from dependent: :nullify to dependent: :restrict_with_error
  - Create and run migration to remove sort_order column and its index from units table
  _Requirements: 4.2, 4.3, 5.1, 5.2, 5.3_

- [x] 2. (P) Admin Unit authorization policy
  - Create Admin::UnitPolicy inheriting from Admin::BasePolicy following TechnologyPolicy pattern
  _Requirements: 6.1, 6.2_

- [x] 3. (P) Admin routes for Units
  - Add resources :units to admin namespace in routes.rb
  _Requirements: 1.1, 2.1, 3.1, 4.1_

- [x] 4. Admin Units controller
  - Create Admin::UnitsController inheriting Admin::BaseController with all CRUD actions
  - Implement filtering by active status and name, sorting by name, pagination
  - Handle create/update validation failures with form re-render
  - Handle destroy failure when teams exist via restrict_with_error pattern
  _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2_

- [x] 5. Admin views for Units
- [x] 5.1 (P) Create index view with table, filters, pagination, and create link
  - Table columns: name, description, active status, unit lead, actions
  - Filters: active status (select), name (text search)
  - Pagination and link to create new Unit
  _Requirements: 1.1, 1.4_
- [x] 5.2 (P) Create show view with Unit details and action buttons
  - Display: name, description, active, unit lead, created_at, updated_at
  - Edit and delete action buttons with turbo_confirm on delete
  _Requirements: 1.2, 4.1_
- [x] 5.3 (P) Create form partial with all fields and error display
  - Fields: name, description, active (select), unit_lead (collection_select from User)
  - Validation error display block following Technologies form pattern
  _Requirements: 2.2, 2.3, 2.4, 3.3_
- [x] 5.4 Create new and edit wrapper views rendering the form partial
  _Requirements: 2.1, 3.1_

- [x] 6. (P) Sidebar navigation and i18n for admin Units
  - Add Units link to admin layout sidebar between Technologies and Users with policy check
  - Add admin.units.* and admin.sidebar.units translation keys to ru.yml and en.yml following technologies structure
  _Requirements: 1.1, 2.1, 4.1_

- [x] 7. Tests for admin Units
- [x] 7.1 Write request specs for admin Units CRUD
  - Cover index (filtering, sorting, pagination), show, create (valid + duplicate/empty name), update, destroy (success + blocked with teams)
  - Verify non-admin users are denied access to all actions
  _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 6.1, 6.2_
- [x] 7.2 Write policy spec for Admin::UnitPolicy
  - Verify admin has access to all actions, non-admin is denied
  _Requirements: 6.1, 6.2_
