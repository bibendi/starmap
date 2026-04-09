# Tasks: Skill Rating Status Guard on Edit Page

**Input**: Design documents from `/specs/004-skill-rating-status-guard/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Remove the `locked` database column and clean up all model-level references. This is the foundational prerequisite that unblocks both UI stories.

- [x] T001 Create migration to remove `locked` column from `skill_ratings` table in `db/migrate/YYYYMMDD_remove_locked_from_skill_ratings.rb` per data-model.md migration spec
- [x] T002 Run `bin/rails db:migrate` and verify migration succeeds

---

## Phase 2: Foundational — Remove `locked` from model, quarter, factory, seeds

**Purpose**: Remove all `locked` field references from application code. MUST complete before UI stories can be implemented (model methods are used by views).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Remove `locked` references from `app/models/skill_rating.rb`: delete `scope :locked`, `scope :unlocked`, `can_be_edited?`, `lock!`, `unlock!`, `lock_all_for_quarter`, `unlock_all_for_quarter`, `after_update :handle_lock_change` callback, and `handle_lock_change` private method
- [x] T004 [P] Remove `locked` references from `app/models/quarter.rb`: simplify `handle_status_change` — remove `locked: true` from `update_all` on close, remove the entire `elsif status == "draft"` unlock branch
- [x] T005 [P] Remove `locked { false }` attribute and `trait :locked` from `spec/factories/skill_ratings.rb`
- [x] T006 [P] Remove all 4 `rating.locked = ...` assignments from `db/seeds.rb` (lines 528, 550, 646, 668)

**Checkpoint**: Foundation ready — `grep -r "locked" app/ spec/factories/ db/seeds.rb` returns zero results

---

## Phase 3: User Story 1 — Engineer sees status-aware edit form (Priority: P1) 🎯 MVP

**Goal**: Display a Status column on the edit page and remove the Target Experts column, so engineers can immediately see which ratings are editable.

**Independent Test**: Open the edit page with a mix of draft/submitted/approved/rejected ratings and verify status badges appear correctly in the new column, and the Target Experts column is gone.

### Implementation for User Story 1

- [x] T007 [US1] Add i18n key for status column header in `config/locales/skill_ratings.yml` (key: `skill_ratings.edit.status`) if not already present
- [x] T008 [US1] Update `app/views/skill_ratings/edit.html.erb` table header: remove `target_experts` column header, add `status` column header using `t("skill_ratings.edit.status")`
- [x] T009 [US1] Update `app/views/skill_ratings/edit.html.erb` table body: remove `target_experts` cell, add status badge cell using the same badge pattern from `app/views/skill_ratings/show.html.erb` lines 78-96 (badge--secondary for draft, badge--warning for submitted, badge--success for approved, badge--danger for rejected)

**Checkpoint**: At this point, the edit page displays status badges and no longer shows the Target Experts column. User Story 1 is complete.

---

## Phase 4: User Story 2 — Engineer cannot modify approved ratings (Priority: P1)

**Goal**: Prevent engineers from changing approved ratings both in the UI (disabled radio buttons) and on the server (skip in controller).

**Independent Test**: Open the edit page as an engineer with an approved rating — radio buttons are disabled. Submit a tampered request to change an approved rating — server preserves the original value.

### Implementation for User Story 2

- [x] T010 [US2] Update `app/controllers/skill_ratings_controller.rb` `update_or_create_rating` method: skip records where the existing rating is `approved?` and the current user is the target user (engineer editing own ratings) — add `next if skill_rating.approved? && current_user == @target_user` before the `assign_attributes` call
- [x] T011 [US2] Update `app/views/skill_ratings/edit.html.erb` radio buttons: add `disabled: true` to `radio_button_tag` when `skill_rating.approved? && current_user == @target_user`
- [x] T012 [US2] Update `app/views/skill_ratings/edit.html.erb` save button: hide or disable the submit button when all ratings for the target user are approved (`@skill_ratings_data.all? { |d| d[:skill_rating].approved? }`)

**Checkpoint**: At this point, engineers cannot modify approved ratings via UI or server. User Stories 1 AND 2 are both complete.

---

## Phase 5: User Story 3 — Remove "locked" field and consolidate on status (Priority: P2)

**Goal**: Verify the `locked` field removal is complete and quarter status transitions still work correctly without it.

**Independent Test**: Run `grep -r "locked" app/ spec/factories/ db/seeds.rb` — zero results. Close a quarter and verify draft/submitted ratings become approved. Reopen and verify behavior is correct.

### Implementation for User Story 3

- [x] T013 [US3] Verify no `locked` references remain: run `grep -r "locked" app/ spec/factories/ db/seeds.rb` and confirm zero results (excluding historical migrations in `db/migrate/`)
- [x] T014 [US3] Run `bundle exec rspec` and verify all existing tests pass after `locked` field removal

**Checkpoint**: All user stories are complete. The `locked` field is fully removed and system works correctly.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [x] T015 Run `bundle exec rspec` — all tests pass
- [x] T016 Run `bundle exec brakeman` — no security issues
- [x] T017 Verify quickstart.md validation: `bin/rails db:migrate` succeeds, `grep -r "locked" app/ spec/factories/ db/seeds.rb` returns zero results

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (migration must exist first) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 (model cleanup must be done)
- **User Story 2 (Phase 4)**: Depends on Phase 3 (edits same ERB template)
- **User Story 3 (Phase 5)**: Depends on Phase 2 (verification requires locked field removed)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 — no dependencies on other stories
- **US2 (P1)**: Depends on US1 (edits same `edit.html.erb` template)
- **US3 (P2)**: Depends on Phase 2 — can run in parallel with US1/US2 (verification only, different files)

### Within Each User Story

- Controller changes before view changes (server-side guard before UI disable)
- Model before controller (model methods used by controller)
- Core implementation before verification

### Parallel Opportunities

- T004, T005, T006 can run in parallel (different files: quarter.rb, factory, seeds)
- US3 verification (T013, T014) can run in parallel with US1 (T007-T009) after Phase 2

---

## Parallel Example: Phase 2

```text
# Launch all foundational cleanup tasks together:
Task T003: "Remove locked from app/models/skill_rating.rb"
Task T004: "Remove locked from app/models/quarter.rb"       [P]
Task T005: "Remove locked from spec/factories/skill_ratings.rb"  [P]
Task T006: "Remove locked from db/seeds.rb"                   [P]
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Migration
2. Complete Phase 2: Remove `locked` from all code
3. Complete Phase 3: User Story 1 (status column + remove target_experts)
4. **STOP and VALIDATE**: Open edit page, verify status badges and missing target_experts column
5. Deploy/demo if ready

### Incremental Delivery

1. Phase 1 + Phase 2 → Foundation ready
2. Add Phase 3 (US1) → Edit page shows status column → Deploy/Demo (MVP!)
3. Add Phase 4 (US2) → Approved ratings are protected → Deploy/Demo
4. Add Phase 5 (US3) → Verify locked field fully removed → Deploy/Demo
5. Phase 6 → Polish and final validation

---

## Notes

- No new gems or JavaScript required — all changes are server-rendered ERB and Ruby
- The Pundit policy (`skill_rating_policy.rb`) already checks `!record.approved?` for engineers — no policy changes needed
- The show page (`show.html.erb`) already has a status column — no changes needed there
- The `can_be_edited?` method has zero callers and is removed entirely (not simplified)
- Historical migration files in `db/migrate/` should NOT be modified
