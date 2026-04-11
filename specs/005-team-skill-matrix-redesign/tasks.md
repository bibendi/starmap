# Tasks: Team Skill Matrix Redesign

**Input**: Design documents from `/specs/005-team-skill-matrix-redesign/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/team-technology-route.md, quickstart.md

**Tests**: Test tasks included per project constitution (Principle IV: Behavior-Driven Testing).

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Route, i18n, and CSS foundation needed by multiple user stories.

- [x] T001 Add nested route `resources :technologies, only: [:show]` under teams in `config/routes.rb`
- [x] T002 [P] Rename `components.team_skill_matrix.title` from «Карта навыков команды» to «Компетенции команды» in `config/locales/ru.yml` and `config/locales/en.yml`
- [x] T003 [P] Add i18n keys for Coverage column (`coverage`) under `components.team_skill_matrix` in `config/locales/ru.yml` and `config/locales/en.yml`
- [x] T004 [P] Add i18n keys for team technology show page under new `team_technologies` namespace in `config/locales/ru.yml` and `config/locales/en.yml` (title, team_link, member, rating, change, no_data, no_active_quarter, legend entries)
- [x] T005 [P] Add `.progress-bar`, `.progress-bar__track`, `.progress-bar__fill` CSS component styles with danger/warning/success variants and dark mode support in `app/frontend/entrypoints/application.css` under `@layer components`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T006 Create `TeamTechnologyPolicy` with `show?` method mirroring `TeamPolicy#show?` access rules (admin: all, unit_lead: own unit, team_lead/engineer: own team) plus technology-team association check, in `app/policies/team_technology_policy.rb`
- [x] T007 Create `TeamTechnologiesController` with `show` action: load `@team`, verify technology belongs to team via `TeamTechnology`, load `@current_quarter`, `@team_members` (lead first), `@skill_ratings` (approved, keyed by user_id), `@previous_ratings` for change indicators, authorize with Pundit, in `app/controllers/team_technologies_controller.rb`

**Checkpoint**: Route + policy + controller ready. User stories can begin.

---

## Phase 3: User Story 1 — Redesigned Competencies Table (Priority: P1) 🎯 MVP

**Goal**: Team page shows «Компетенции команды» card with Technology, Bus Factor, and Coverage progress bar columns — no member columns.

**Independent Test**: Open any team page → see 3 columns (Technology, Bus Factor, Coverage) with progress bars, no member name columns.

### Tests for User Story 1

- [x] T008 [US1] Update `spec/components/team_skill_matrix_component_spec.rb`: remove assertions for member name columns and per-member rating cells; add tests for `#coverage_for` returning correct percentage (0%, 67%, 100%); add rendering tests for Coverage progress bar column with correct CSS color classes (danger/warning/success); verify technology name renders as link to `team_technology_path`; verify no member columns in table header

### Implementation for User Story 1

- [x] T009 [US1] Add `coverage_for(technology_id)` public method to `app/components/team_skill_matrix_component.rb`: calculates `(bus_factor_data[:count].to_f / bus_factor_data[:target] * 100).round` using existing bus_factor data, returns integer 0-100
- [x] T010 [US1] Remove member columns from `app/components/team_skill_matrix_component.html.erb`: delete the `<% team_members.each do |member| %>` header loop and the corresponding rating cell loop in tbody; remove the `change_for` calls for members; add Coverage column header using `t('components.team_skill_matrix.coverage')`; add Coverage cell rendering progress bar with `.progress-bar` classes and color variant based on threshold (0-49 danger, 50-79 warning, 80-100 success); wrap technology name in `link_to team_technology_path(team, tech)`

**Checkpoint**: US1 complete — team page shows redesigned matrix with Coverage column, no member columns.

---

## Phase 4: User Story 2 — Team Technology Detail Page (Priority: P1)

**Goal**: Clicking a technology name navigates to `/teams/:team_id/technologies/:id` showing member ratings table with team link under header.

**Independent Test**: Click any technology in the matrix → see member ratings table with color indicators and clickable team name.

### Tests for User Story 2

- [x] T011 [P] [US2] Create `spec/policies/team_technology_policy_spec.rb`: test `show?` returns true for admin (any team), unit_lead (own unit team), team_lead (own team), engineer (own team); returns false for team_lead of different team, engineer of different team, technology not associated with team
- [x] T012 [P] [US2] Create `spec/requests/team_technologies_spec.rb`: test GET `/teams/:team_id/technologies/:id` returns 200 for authorized user, 403 for unauthorized, 404 for technology not in team; verify page contains team name link, member names, rating indicators, legend

### Implementation for User Story 2

- [x] T013 [US2] Create `app/views/team_technologies/show.html.erb`: page header with technology name (`@technology.name`) as h1, team name as clickable subheading linking to `team_path(@team)`, member ratings table using existing `.table`, `.rating-indicator`, `.change-indicator` CSS classes with color coding for ratings 0-3, sorted with team lead first; include legend using existing legend CSS; handle no-current-quarter and no-ratings states

**Checkpoint**: US2 complete — technology detail page shows member ratings with navigation back to team.

---

## Phase 5: User Story 3 — Navigation Fix for Unit Lead (Priority: P2)

**Goal**: Unit lead always sees «Команда» menu item, linking to `/teams` when not assigned to a specific team.

**Independent Test**: Log in as unit_lead without team → see «Команда» in nav → click → arrive at `/teams`.

### Implementation for User Story 3

- [x] T014 [US3] Fix navigation link condition in `app/views/layouts/application.html.erb` (line 39): change `<% if policy(:navigation).show_team? && current_user.team %>` to show link when policy passes; update the link target: if `current_user.team` present → `team_path(current_user.team)`, else → `teams_path`; update active class logic accordingly

**Checkpoint**: US3 complete — unit_lead always sees and can navigate via «Команда».

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup.

- [x] T015 [P] Run `bundle exec rspec` and fix any failures
- [x] T016 [P] Run `bundle exec brakeman` and verify no high-severity findings
- [x] T017 Run full verification per `quickstart.md`: `bin/rails routes | grep technology`, component specs, request specs, policy specs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (route needed for controller)
- **User Story 1 (Phase 3)**: Depends on Phase 1 (i18n, CSS) and Phase 2 (policy used indirectly)
- **User Story 2 (Phase 2)**: Depends on Phase 2 (controller + policy)
- **User Story 3 (Phase 5)**: Independent — can run after Phase 1
- **Polish (Phase 6)**: Depends on all user stories

### User Story Dependencies

- **US1 (P1)**: Phase 1 + 2 → then T008 → T009 → T010
- **US2 (P1)**: Phase 1 + 2 → T011/T012 (parallel) → T013
- **US3 (P2)**: Phase 1 → T014 (independent of US1/US2)
- US1 and US2 can run in **parallel** after Phase 2
- US3 can run in **parallel** with US1/US2

### Within Each User Story

- Tests before implementation (T008 before T009-T010, T011-T012 before T013)
- Component Ruby before template (T009 before T010)

### Parallel Opportunities

- T002, T003, T004, T005 (Phase 1) — all different files
- T011, T012 (Phase 4) — different spec files
- US1 (Phase 3) and US2 (Phase 4) and US3 (Phase 5) — all different files
- T015, T016 (Phase 6) — different tools

---

## Parallel Example: Phase 1

```text
Task: "Rename i18n title in config/locales/ru.yml and config/locales/en.yml"
Task: "Add coverage i18n keys in config/locales/ru.yml and config/locales/en.yml"
Task: "Add team_technologies i18n keys in config/locales/ru.yml and config/locales/en.yml"
Task: "Add progress-bar CSS in app/frontend/entrypoints/application.css"
```

## Parallel Example: User Stories (after Phase 2)

```text
# Developer A:
Task: "Add coverage_for to TeamSkillMatrixComponent, update template"

# Developer B:
Task: "Create team_technologies/show.html.erb with member ratings table"

# Developer C (or parallel):
Task: "Fix navigation link for unit_lead in application.html.erb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (route, i18n, CSS)
2. Complete Phase 2: Foundational (controller, policy)
3. Complete Phase 3: User Story 1 (redesigned matrix)
4. **STOP and VALIDATE**: Open team page, verify Coverage column, verify no member columns
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Redesigned matrix with Coverage (MVP!)
3. Add US2 → Technology detail page with member ratings
4. Add US3 → Navigation fix for unit_lead
5. Polish → Full suite green, brakeman clean

---

## Notes

- No database changes — Coverage is computed at render time from existing data
- Policy mirrors `TeamPolicy#show?` — avoid duplication by referencing the same scoping logic
- Template for US2 reuses existing CSS classes (`.table`, `.rating-indicator`, `.card`, `.legend`)
- Component spec cleanup: remove all `let_it_be` and contexts related to per-member rendering
- All i18n keys use `t()` — no hardcoded strings
