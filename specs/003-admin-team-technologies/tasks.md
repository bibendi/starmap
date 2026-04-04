# Tasks: Admin Team Technologies Management

**Input**: Design documents from `/specs/003-admin-team-technologies/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ui.md, quickstart.md

**Tests**: RSpec tests are included — the AGENTS.md constitution mandates `bundle exec rspec` passing before merge, and the quickstart.md specifies test files to create.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Route and I18n foundation shared by all user stories

- [x] T001 Add nested `team_technologies` resource under `teams` in `config/routes.rb` — only `:create, :update, :destroy` actions per research decision R6
- [x] T002 [P] Add `admin.team_technologies` I18n keys for both locales in `config/locales/en.yml` — keys listed in `contracts/ui.md` section "I18n Keys Required"
- [x] T003 [P] Add `admin.team_technologies` I18n keys for both locales in `config/locales/ru.yml` — keys listed in `contracts/ui.md` section "I18n Keys Required"

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Authorization policy and controller skeleton that all user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create `Admin::TeamTechnologyPolicy` in `app/policies/admin/team_technology_policy.rb` — inherit from `Admin::BasePolicy`, override `can_manage?` to include `unit_lead?`, add `unit_lead_owns_record?` checking parent team's `unit_id`, add Scope class filtering by unit for unit leads (follow `Admin::TeamPolicy` pattern exactly)
- [x] T005 Create `Admin::TeamTechnologiesController` in `app/controllers/admin/team_technologies_controller.rb` — inherit from `Admin::BaseController`, implement `create`, `update`, `destroy` actions with `authorize [:admin, record]`, use `permitted_attributes([:admin, TeamTechnology])`, redirect to `admin_team_path(@team)` on success, render errors on failure

**Checkpoint**: Foundation ready — user story view and interaction tasks can now begin

---

## Phase 3: User Story 1 - View Team Technologies (Priority: P1) MVP

**Goal**: Display all technologies assigned to a team on the team detail page with criticality badges and target expert counts

**Independent Test**: Navigate to `/admin/teams/:id` and verify assigned technologies appear in a table with criticality badges and target_experts values. Team with no technologies shows empty state.

### Implementation for User Story 1

- [x] T006 [US1] Create `_row.html.erb` partial in `app/views/admin/team_technologies/_row.html.erb` — renders a single table row with technology name, category (or "-"), criticality badge (high=danger, normal=warning, low=secondary), target_experts value, edit and delete action buttons. Local: `team_technology`. Follow existing admin table patterns: `table__cell` for columns, `badge badge--*` for criticality, `btn btn--small btn--secondary` for edit, `btn btn--small btn--danger` for delete with `turbo_confirm`.
- [x] T007 [US1] Add technologies card section to team show page in `app/views/admin/teams/show.html.erb` — below existing team attributes card, add a new `card` containing: page-header-style title row with "Technologies" heading, `overflow-x-auto` table listing `@team.team_technologies.includes(:technology)` using `_row` partial. Handle empty state with message and "Add Technology" button (will be functional after US2). Load team_technologies in controller show action via `@team.team_technologies.includes(:technology)`.

### Tests for User Story 1

- [x] T008 [P] [US1] Write policy spec for `Admin::TeamTechnologyPolicy` in `spec/policies/admin/team_technology_policy_spec.rb` — test: admin can manage any team's technologies, unit_lead can manage technologies for teams in their unit but not other units, engineer/team_lead cannot manage, scope filters correctly
- [x] T009 [P] [US1] Write request spec for viewing team technologies in `spec/requests/admin/team_technologies_spec.rb` — test: admin sees technologies table on team show page, unit_lead sees technologies for their unit's teams, empty state displayed when no technologies assigned, unauthorized roles get redirected

**Checkpoint**: User Story 1 complete — team detail page shows technologies table with badges. Independently verifiable.

---

## Phase 4: User Story 2 - Add Technology to Team (Priority: P1)

**Goal**: Admin/Unit Lead can assign an active technology from the catalog to a team via inline form

**Independent Test**: From the team technologies section, click "Add Technology", select a technology from dropdown, submit. Technology appears in the list with inherited defaults. Duplicate selection is prevented.

### Implementation for User Story 2

- [x] T010 [US2] Create `_add_form.html.erb` partial in `app/views/admin/team_technologies/_add_form.html.erb` — Turbo Frame containing a form with `select` dropdown for technology (options: active technologies not yet assigned to this team, ordered by name), submit button, cancel link. Form posts to `admin_team_team_technologies_path(team)`. Include error display div. Use existing CSS classes: `form--vertical`, `form-label`, `form-field`, `form-input`, `btn btn--primary`, `btn btn--ghost`.
- [x] T011 [US2] Integrate add form into team show page in `app/views/admin/teams/show.html.erb` — wrap "Add Technology" area in `turbo_frame_tag "add_team_technology"`, clicking "Add" button replaces frame content with `_add_form` partial via Turbo navigation. After successful create, Turbo redirects back to team show (table refreshes).
- [x] T012 [US2] Implement `create` action in `app/controllers/admin/team_technologies_controller.rb` — find team by `params[:team_id]`, authorize `[:admin, TeamTechnology]`, build `@team.team_technologies.build(permitted_attributes)`, on save redirect to team show with notice, on failure render `_add_form` within Turbo Frame with unprocessable_entity status. Permitted attrs: `:technology_id` (criticality/target_experts inherit from model defaults per `set_defaults` callback).

### Tests for User Story 2

- [x] T013 [US2] Write request spec for adding technology in `spec/requests/admin/team_technologies_spec.rb` — test: successful create redirects with notice and shows new technology, duplicate technology_id shows validation error, inactive technology cannot be selected (filtered from options), unit_lead cannot add to team outside their unit

**Checkpoint**: User Story 2 complete — technologies can be added to teams. Independently testable on top of US1.

---

## Phase 5: User Story 3 - Edit Team Technology Settings (Priority: P1)

**Goal**: Admin/Unit Lead can change criticality and target_experts for a team-specific technology via inline Turbo Frame edit form

**Independent Test**: Click "Edit" on a team technology row, row transforms into edit form with criticality dropdown and target_experts number input. Change values, submit. Updated values displayed immediately.

### Implementation for User Story 3

- [x] T014 [US3] Create `_form.html.erb` edit partial in `app/views/admin/team_technologies/_form.html.erb` — Turbo Frame containing form with criticality `select` (high/normal/low), target_experts `number_field`, save and cancel buttons. Form patches to `admin_team_team_technology_path(team, team_technology)`. Include error display div. Use existing CSS classes.
- [x] T015 [US3] Update `_row.html.erb` in `app/views/admin/team_technologies/_row.html.erb` — wrap each row in `turbo_frame_tag dom_id(team_technology)`, edit button navigates to edit form replacing the row frame. This enables inline edit via Turbo Frame.
- [x] T016 [US3] Implement `update` action in `app/controllers/admin/team_technologies_controller.rb` — find TeamTechnology by id, authorize, update with permitted_attributes (`:criticality`, `:target_experts`), on success redirect to team show with notice, on failure render `_form.html.erb` within Turbo Frame with unprocessable_entity status. Add `turbo_stream` response format that updates the specific row frame.

### Tests for User Story 3

- [x] T017 [US3] Write request spec for editing team technology in `spec/requests/admin/team_technologies_spec.rb` — test: successful update shows new values, invalid target_experts (0, -1, non-integer) shows validation error, invalid criticality shows validation error, unit_lead cannot edit technology on team outside their unit

**Checkpoint**: User Story 3 complete — criticality and target_experts can be edited inline. Core feature fully functional.

---

## Phase 6: User Story 4 - Remove Technology from Team (Priority: P2)

**Goal**: Admin/Unit Lead can remove a technology from a team with confirmation dialog. Removal blocked when skill ratings exist.

**Independent Test**: Click delete on a team technology, confirm dialog. Technology removed from list. If skill ratings exist, deletion is prevented with error message.

### Implementation for User Story 4

- [x] T018 [US4] Add delete functionality to destroy action in `app/controllers/admin/team_technologies_controller.rb` — find TeamTechnology, authorize, attempt destroy. If successful redirect with notice "destroyed". If destroy fails (restrict_with_error from skill_ratings), redirect with alert "cannot_delete_with_ratings". The `button_to` with `turbo_confirm` is already in the `_row.html.erb` partial from US1.

### Tests for User Story 4

- [x] T019 [US4] Write request spec for removing technology in `spec/requests/admin/team_technologies_spec.rb` — test: successful destroy redirects with notice and technology no longer in list, destroy with associated skill_ratings redirects with alert error, unit_lead cannot remove technology from team outside their unit

**Checkpoint**: All user stories complete. Full CRUD lifecycle for team technologies.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup across all user stories

- [x] T020 Run `bundle exec rspec` and fix any failures — ensure all specs pass including existing suite
- [x] T021 Verify I18n completeness — ensure all `t()` calls in views have corresponding keys in both `en.yml` and `ru.yml`, no missing translations in production

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001 routes) — BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 → US2 → US3 → US4 sequential (each builds on previous UI)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (View)**: Foundation only — adds the table display
- **US2 (Add)**: Depends on US1 — adds the create form into the existing section
- **US3 (Edit)**: Depends on US1 — modifies the row partial to support inline edit
- **US4 (Remove)**: Depends on US1 — delete button already in row, just needs action logic

### Within Each User Story

- Tests can run in parallel with implementation (test-first or test-after)
- Views depend on controller actions being defined
- Controller depends on policy existing

### Parallel Opportunities

- T002 + T003 (I18n en + ru) can run in parallel
- T008 + T009 (US1 tests) can run in parallel
- Within Phase 2: T004 (policy) and T005 (controller skeleton) are sequential (controller references policy)

---

## Parallel Example: Setup Phase

```
Parallel batch 1: T002 (en.yml), T003 (ru.yml)
Sequential: T001 (routes) → T004 (policy) → T005 (controller)
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 + 3)

1. Complete Phase 1: Setup (routes + I18n)
2. Complete Phase 2: Foundational (policy + controller)
3. Complete Phase 3: User Story 1 (view table)
4. Complete Phase 4: User Story 2 (add technology)
5. Complete Phase 5: User Story 3 (edit settings)
6. **STOP and VALIDATE**: Full core workflow works — view, add, edit
7. Add User Story 4 (remove) if needed

### Incremental Delivery

1. Setup + Foundational → Routes and auth ready
2. US1 → Table visible on team page (minimal value)
3. US2 → Can add technologies (core workflow starts)
4. US3 → Can edit criticality/target_experts (core requirement met)
5. US4 → Can remove technologies (full CRUD)

---

## Notes

- No database migrations needed — `team_technologies` table already exists with all required columns
- `TeamTechnology` factory already exists in `spec/factories/team_technologies.rb` with `:high_criticality` and `:low_criticality` traits
- Follow `Admin::TeamPolicy` pattern exactly for policy and controller authorization
- All views must support dark mode (inherited from admin layout)
- Turbo Frame IDs: `dom_id(team_technology)` for edit rows, `"add_team_technology"` for add form
