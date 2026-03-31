# Tasks: Unit Lead Team Creation in Admin

**Input**: Design documents from `/specs/001-unit-lead-create-teams/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Not explicitly requested. Test tasks included since Constitution Principle IV (Behavior-Driven Testing) requires RSpec coverage and existing test files need updating.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No new infrastructure needed. All dependencies (Pundit, RSpec, FactoryBot) already exist.

> No setup tasks required — the project already has Rails 8, Pundit, RSpec, and all admin infrastructure in place.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Policy changes that ALL user stories depend on.

- [X] T001 Override `Admin::TeamPolicy` in `app/policies/admin/team_policy.rb`: add `can_manage?` that returns true for `admin?` OR `unit_lead?`; override `Scope#resolve` to return `scope.by_unit(user.unit)` for unit leads and `scope.all` for admins; add `unit_lead_owns_record?` private method checking `record&.unit_id == user.unit&.id`; override `show?`, `edit?`, `update?`, `destroy?` to call `can_manage?` AND `unit_lead_owns_record?` (for unit leads only, admins bypass record check)

**Checkpoint**: Policy gates open for unit leads — user story implementation can begin.

---

## Phase 3: User Story 1 - Unit Lead Creates a New Team (Priority: P1)

**Goal**: Unit Lead can create a new team within their unit via the admin panel, with unit pre-selected and form submission creating the team in their unit.

**Independent Test**: Log in as Unit Lead, navigate to `/admin/teams/new`, fill form, submit, verify team created in their unit.

### Tests for User Story 1

- [X] T002 [P] [US1] Add unit lead context to `spec/policies/admin/team_policy_spec.rb`: add `let(:unit_lead)` factory creating a unit lead with a unit; update `permissions` block to test that unit lead is granted access; add tests that team_lead and engineer are still denied; add Scope tests for unit lead returning only their unit's teams and returning none for team lead/engineer
- [X] T003 [P] [US1] Add unit lead creation tests to `spec/requests/admin/teams_spec.rb`: add `let_it_be(:unit_lead_user)` with unit; test GET /admin/teams/new succeeds for unit lead; test POST /admin/teams creates team; test created team has unit_id matching unit lead's unit; test POST with empty name returns unprocessable_content

### Implementation for User Story 1

- [X] T004 [US1] Add `force_unit_for_unit_lead` before_action in `app/controllers/admin/teams_controller.rb`: in `create` action, if `current_user.unit_lead?` then merge `unit_id: current_user.unit.id` into `team_params` (defense in depth); apply same logic in `update` action to prevent unit reassignment
- [X] T005 [US1] Scope form dropdowns in `app/views/admin/teams/_form.html.erb`: for unit dropdown (line 33), when `current_user.unit_lead?` use `[current_user.unit]` as the collection and add `disabled: true` to prevent changing; for team_lead dropdown (line 49), when `current_user.unit_lead?` scope to users within their unit's teams via `User.joins(:team).where(teams: {unit_id: current_user.unit.id}).order(:first_name, :last_name)`

**Checkpoint**: Unit Lead can create teams scoped to their unit — User Story 1 independently testable.

---

## Phase 4: User Story 2 - Unit Lead Views and Manages Teams in Admin (Priority: P2)

**Goal**: Unit Lead sees only their unit's teams in the admin teams index and can access team detail pages.

**Independent Test**: Log in as Unit Lead, navigate to `/admin/teams`, verify only own unit's teams shown; click a team, verify detail page loads.

### Tests for User Story 2

- [X] T006 [P] [US2] Add unit lead index/show tests to `spec/requests/admin/teams_spec.rb`: test GET /admin/teams for unit lead returns only teams from their unit (create teams in other unit and verify they are absent in response body); test GET /admin/teams/:id for unit lead's own team succeeds; test GET /admin/teams/:id for another unit's team returns 404

### Implementation for User Story 2

- [X] T007 [US2] Scope unit filter dropdown in `app/views/admin/teams/index.html.erb`: when `current_user.unit_lead?` use `[current_user.unit]` as the collection for the unit_id filter (line 33) instead of `Unit.order(:name)`, or hide the filter entirely since unit lead only sees one unit

**Checkpoint**: Unit Lead can view only their unit's teams — User Story 2 independently testable.

---

## Phase 5: User Story 3 - Unit Lead Edits and Deletes Teams (Priority: P2)

**Goal**: Unit Lead can edit team properties and delete empty teams within their unit.

**Independent Test**: Log in as Unit Lead, edit a team's name, verify saved; delete an empty team, verify removed; try deleting team with users, verify blocked.

### Tests for User Story 3

- [X] T008 [P] [US3] Add unit lead edit/delete tests to `spec/requests/admin/teams_spec.rb`: test GET /admin/teams/:id/edit for unit lead's own team succeeds; test PATCH /admin/teams/:id updates team; test PATCH with empty name returns unprocessable_content; test unit lead cannot update team's unit_id to another unit; test DELETE on empty team succeeds; test DELETE on team with users redirects with alert

### Implementation for User Story 3

> No additional implementation needed — policy (T001) handles record-level authorization for edit/update/destroy, and controller defense-in-depth (T004) prevents unit reassignment. Form scoping (T005) ensures correct dropdowns.

**Checkpoint**: Unit Lead can edit and delete teams within their unit — User Story 3 independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation and cleanup across all user stories.

- [X] T009 [P] Run `bundle exec rspec spec/policies/admin/team_policy_spec.rb spec/requests/admin/teams_spec.rb` and fix any failures
- [X] T010 [P] Run `bundle exec brakeman` to verify no new security findings
- [X] T011 Run quickstart.md verification steps manually or via system test

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — BLOCKS all user stories
- **User Stories (Phases 3-5)**: All depend on Phase 2 (T001 policy override)
  - US1 (Phase 3) and US2 (Phase 4) can proceed in parallel (different files)
  - US3 (Phase 5) depends on US1 (T004 controller defense-in-depth)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Depends on T001 only. Self-contained.
- **US2 (P2)**: Depends on T001 only. Self-contained.
- **US3 (P2)**: Depends on T001 and T004 (controller unit forcing from US1).

### Within Each User Story

- Tests [P] can run in parallel with each other
- Tests should be written and FAIL before implementation
- Implementation tasks are sequential within a story

### Parallel Opportunities

- T002 + T003 can run in parallel (different files)
- T006 + T008 can run in parallel (different test contexts, same file — merge carefully)
- T005 + T007 can run in parallel (different view files)
- T009 + T010 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch both test tasks together:
Task T002: "Update policy spec with unit lead tests in spec/policies/admin/team_policy_spec.rb"
Task T003: "Add unit lead creation tests to spec/requests/admin/teams_spec.rb"

# Then sequentially implement:
Task T004: "Add controller unit forcing in app/controllers/admin/teams_controller.rb"
Task T005: "Scope form dropdowns in app/views/admin/teams/_form.html.erb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: T001 (policy override)
2. Complete Phase 3: T002-T005 (unit lead creates teams)
3. **STOP and VALIDATE**: Unit Lead can create teams in `/admin/teams/new`

### Incremental Delivery

1. T001 (policy) → Foundation ready
2. T002-T005 (US1) → Unit Lead can create teams → **Deploy (MVP)**
3. T006-T007 (US2) → Unit Lead can view scoped teams → **Deploy**
4. T008 (US3) → Unit Lead can edit/delete → **Deploy**
5. T009-T011 (Polish) → Final validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- No database migrations needed — all entities already exist
- `Admin::BasePolicy` is intentionally NOT modified (other admin resources must remain admin-only)
- The admin sidebar (`layouts/admin.html.erb`) auto-shows/hides links via `policy([:admin, Team]).index?` — no layout changes needed
