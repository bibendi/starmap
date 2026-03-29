# Implementation Plan

- [x] 1. Category model and data migration
- [x] 1.1 Create reversible migration: categories table, add nullable category_id to technologies, populate from distinct string values, drop old category column
  - Create categories table with id, name (NOT NULL, UNIQUE), timestamps
  - Add category_id column to technologies (nullable for backward compatibility)
  - Insert Category records for each distinct value in technologies.category (backend, frontend, database, devops, cloud)
  - Update technologies.category_id by matching old string value to new category record
  - Remove the old category string column from technologies
  - Ensure down method reverses: add column back, copy names from categories, drop FK, drop table
  - _Requirements: 2.3, 2.5_

- [x] 1.2 Write Category model specs (TDD)
- [x] 1.3 Create Category model with validations and association
- [x] 1.4 Write Technology model specs for updated association (TDD)
- [x] 1.5 Update Technology model for category association
  - Add belongs_to :category, optional: true
  - Update by_category scope to filter by category_id instead of string value
  - Replace all references to technology.category (string) with technology.category&.name throughout the codebase
  - _Requirements: 2.3, 2.6_

- [x] 2 (P). i18n, routes and seeds configuration
- [x] 2.2 (P) Expand admin routes for full technologies CRUD
- [x] 2.3 (P) Update db/seeds.rb to create Category records and associate technologies
  - Create Category records for backend, frontend, database, devops, cloud before creating technologies
  - Update technology creation to use category: Category.find_by(name: ...) instead of string value
  - _Requirements: 2.7_

- [ ] 3. Admin technologies CRUD and views
- [ ] 3.1 Write admin technologies controller request specs (TDD)
  - Index: filters (active, name, category), pagination, sort
  - Create: valid creation with created_by, invalid with validation error
  - Update: valid update, invalid with error
  - Destroy: successful deletion, not found handling
  - Authorization: non-admin user denied access
  - _Requirements: 3.1-3.6, 4.1-4.5, 5.1, 5.2_

- [ ] 3.2 Implement TechnologiesController with full CRUD
  - Add PER_PAGE constant, set_technology before_action, and strong params (name, description, category_id, criticality, target_experts, sort_order, active)
  - Implement index: policy_scope, filter_by_active, filter_by_name (ILIKE), filter_by_category, sort (default: sort_order asc, name asc), paginate
  - Implement show, new, create (set created_by), edit, update, destroy with authorization via authorize [:admin, Technology]
  - Remove skip_after_action :verify_authorized
  - _Requirements: 3.1-3.6, 4.1-4.5, 5.1, 5.2_

- [ ] 3.3 Build index view with filters, table, and pagination
  - Page header with localized title and New Technology button
  - Filter form with active status select, name text search, category collection_select, submit and clear buttons
  - Hidden fields in filter form to preserve filter state across pagination
  - Table with columns: name, category (badge), criticality (badge), active (badge), target_experts, sort_order, actions (edit/delete)
  - Kaminari pagination
  - _Requirements: 1.2, 3.1, 4.1-4.5_

- [ ] 3.4 Build shared form partial for create and edit
  - form_with model: [:admin, @technology], local: true
  - Error display block with full_messages
  - Fields: name, description (textarea), category (collection_select from Category.ordered), criticality (select), target_experts (number), sort_order (number), active (checkbox)
  - Grid layout, submit and cancel buttons
  - _Requirements: 3.2, 3.3, 3.7_

- [ ] 3.5 Build show view and new/edit page wrappers
  - Show view: page header with edit/delete buttons, definition list with badges for criticality and active status
  - New and edit pages: page header with localized title, render shared form partial
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 3.6 Write system specs for technologies CRUD flow and filtering (TDD)
  - Full CRUD flow: create, view, edit, delete technology
  - Filter by active status, name search, category with preserved state across pagination
  - _Requirements: 3.1-3.4, 4.1-4.5_
