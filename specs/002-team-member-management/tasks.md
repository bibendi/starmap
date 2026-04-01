# Tasks: Team Member Management in Admin

**Input**: Design documents from `/specs/002-team-member-management/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested — no test-only tasks generated.

**Organization**: US1 (team membership management) and US2 (team lead restriction) are tightly coupled on the same form and implemented together as a single cohesive phase. The user form cleanup (FR-010) is a separate, independent story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No setup tasks needed — no new gems, no schema migrations, no new directories. The feature uses existing infrastructure.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Model and policy changes that MUST complete before view/controller work.

**⚠️ CRITICAL**: No view or controller work can begin until this phase is complete.

- [x] T001 [US1] Add `team_lead_must_be_member` validation to `app/models/team.rb` — if `team_lead_id` is set, validate that the user is in the team's current user IDs; add corresponding i18n error message in `config/locales/en.yml` and `config/locales/ru.yml`
- [x] T002 [US1] Add `sync_members!(member_ids)` method to `app/models/team.rb` — accepts array of user IDs, adds new members by setting `user.team_id` to the team, removes removed members by clearing their `team_id`, auto-clears `team_lead_id` if the lead user is not in `member_ids`, handles old-team lead cleanup when moving a user between teams
- [x] T003 [US1] Add `:member_ids` to `base_permitted_attributes` in `app/policies/admin/team_policy.rb`

**Checkpoint**: Model and policy ready — view/controller implementation can begin

---

## Phase 3: User Story 1 + 2 — Team Membership Management & Team Lead Restriction (Priority: P1) 🎯 MVP

**Goal**: Admin/unit lead can manage team members (add/remove) on the team edit form, and team lead dropdown is restricted to current team members only.

**Independent Test**: Open team edit form, add/remove members, verify team lead dropdown updates accordingly, save, verify changes persist.

### Implementation for User Story 1 + 2

- [x] T004 [US1] Update `app/controllers/admin/teams_controller.rb` — set `@available_members` in `edit` and `new` actions (unassigned engineers, scoped by unit for unit leads); set `@available_members` in `update` on validation failure (re-render); call `@team.sync_members!(member_ids)` in `update` action before `@team.update`
- [x] T005 [P] [US2] Remove `team_id` field from `app/views/admin/users/_form.html.erb` — delete the `team_id` `collection_select` block and its surrounding grid column
- [x] T006 [P] [US2] Remove `:team_id` from `user_params` in `app/controllers/admin/users_controller.rb`
- [x] T007 [P] [US1] Add i18n keys for member management in `config/locales/en.yml` — keys for "Members", "Add member", "No available members", "Remove member", member count label under `admin.teams.attributes`
- [x] T008 [P] [US1] Add i18n keys for member management in `config/locales/ru.yml` — Russian translations for the same keys
- [x] T009 [US1] Create Stimulus controller `app/frontend/controllers/team_members_controller.js` — manages member list state, add member action (moves selected user from available dropdown to member list), remove member action (moves user back to available dropdown), updates team lead dropdown options when members change (add new member as option, remove departed member from options, auto-clear team lead selection if that member was removed)
- [x] T010 [US1] Add member list styles to `app/frontend/entrypoints/application.css` — styles for member list container, member row (name + remove button), using existing BEM classes (`card`, `badge`, `btn--small`, `btn--secondary`) with dark mode support
- [x] T011 [US1] Rebuild team edit form `app/views/admin/teams/_form.html.erb` — add `data-controller="team-members"` to the form; add hidden inputs for `member_ids[]` populated by Stimulus; add member list section showing `@team.users` with remove buttons; add "Add member" dropdown populated from `@available_members`; change team lead `collection_select` to use `@team.users` instead of querying all users; wire add/remove actions via `data-action="team-members#..."`

**Checkpoint**: At this point, the team edit form fully supports member management and team lead restriction. The user form no longer shows team assignment.

---

## Phase 4: User Story 3 — Remove Team Assignment from User Admin Form (Priority: P1)

**Goal**: Team membership is managed exclusively from the team edit form. The user admin form no longer has a team assignment field.

**Independent Test**: Open user admin edit form, confirm no team field exists; update user, confirm save works without team_id param.

### Implementation for User Story 3

> **NOTE**: T005 and T006 in Phase 3 already implement the core changes for this story (removing the field and the param). This phase covers remaining cleanup.

- [x] T012 [P] [US3] Update `spec/requests/admin/users_spec.rb` — remove any tests that verify `team_id` assignment via user form; update existing update tests to not include `team_id` in params

**Checkpoint**: All user stories complete. Team membership managed only from team edit form.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation and final checks.

- [x] T013 Run `bundle exec rspec` and fix any failing tests caused by the changes (especially existing tests that may send `team_id` in user params or rely on old team lead dropdown behavior)
- [x] T014 Run `npm test` and verify Stimulus controller tests pass
- [x] T015 Run `bundle exec brakeman` to verify no new security vulnerabilities introduced

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — can start immediately
- **Phase 3 (US1+US2)**: Depends on Phase 2 completion — T001, T002, T003 must be done first
- **Phase 4 (US3)**: Depends on T005, T006 from Phase 3 (but these are marked [P] and can run early)
- **Polish (Phase 5)**: Depends on all implementation phases

### User Story Dependencies

- **US1 + US2 (Phase 3)**: Tightly coupled — implemented together in the same form. US2 (team lead restriction) depends on US1 (member list) since the dropdown derives from member state.
- **US3 (Phase 4)**: Independent of US1/US2. T005 and T006 can run in parallel with other Phase 3 tasks.

### Within Each Phase

- T001, T002 must be sequential (T002 uses validation from T001 conceptually, but they're in the same file — do together)
- T003 is independent of T001/T002 (different file) — parallelizable
- T005, T006, T007, T008 are all [P] — different files, no dependencies
- T009 depends on T010, T011 conceptually (Stimulus controller must match the DOM structure in the view)

### Parallel Opportunities

- T003 [P] can run alongside T001+T002
- T004 depends on T001+T002 (model methods)
- T005, T006, T007, T008 [P] can all run in parallel
- T009, T010 [P] can run in parallel (but both must complete before T011)

---

## Parallel Example: Phase 3

```bash
# After Phase 2 completes, launch these in parallel:
Task: "T003 Add :member_ids to base_permitted_attributes in team_policy.rb"
Task: "T005 Remove team_id field from user form"
Task: "T006 Remove :team_id from user_params in users_controller.rb"
Task: "T007 Add i18n keys for member management in en.yml"
Task: "T008 Add i18n keys for member management in ru.yml"
Task: "T009 Create Stimulus controller team_members_controller.js"
Task: "T010 Add member list styles to application.css"

# Then sequentially:
Task: "T004 Update teams_controller.rb"
Task: "T011 Rebuild team edit form _form.html.erb"
```

---

## Implementation Strategy

### MVP First (Phase 2 + Phase 3 Only)

1. Complete Phase 2: Model validation + sync method + policy
2. Complete Phase 3: Controller, Stimulus, view, i18n, CSS
3. **STOP and VALIDATE**: Open team edit form, add/remove members, verify team lead dropdown, save
4. The team form is fully functional at this point

### Incremental Delivery

1. Phase 2 → Model/policy foundation ready
2. Phase 3 → Team form with member management + team lead restriction (MVP!)
3. Phase 4 → User form cleanup (remove team_id)
4. Phase 5 → Test validation and security check

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US1 and US2 are implemented together because they share the same form — separating them would create conflicts in the same files
- No schema migrations needed — `users.team_id` FK already exists
- No new gems needed — Stimulus is already in the stack
- The form uses `local: true` (no Turbo), so the Stimulus controller manages all dynamic behavior client-side
