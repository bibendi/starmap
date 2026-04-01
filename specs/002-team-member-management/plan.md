# Implementation Plan: Team Member Management in Admin

**Branch**: `002-team-member-management` | **Date**: 2026-04-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-team-member-management/spec.md`

## Summary

Add team membership management (add/remove members) to the team edit form in the admin panel, restrict team lead selection to current team members only, and remove the team assignment field from the user admin form.

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.1.1
**Primary Dependencies**: Pundit (authorization), ViewComponent (UI), Stimulus (JS), Kaminari (pagination)
**Storage**: PostgreSQL 15+
**Testing**: RSpec (Ruby), Vitest + JSDOM (Stimulus controllers)
**Target Platform**: Web application (server-rendered HTML via Hotwire)
**Project Type**: Web application (monolithic Rails)
**Performance Goals**: Standard web app response times
**Constraints**: Each user belongs to at most one team; unit leads scoped to their unit; admins have full access
**Scale/Scope**: Admin/Unit Lead facing feature; small number of concurrent admins

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Server-Rendered First | PASS | Team edit form remains server-rendered; Stimulus controller only for add/remove member interactions |
| II. Authorization on Every Action | PASS | Admin::TeamPolicy already governs team edit; adding member_ids to permitted attributes |
| III. Small, Focused Code | PASS | Stimulus controller for dynamic form elements; controller changes are minimal (add member_ids handling) |
| IV. Behavior-Driven Testing | PASS | Request specs for member management; Stimulus tests for dynamic form; policy specs unchanged |
| V. Simplicity Over Cleverness | PASS | Uses `member_ids` array param processed in controller; no nested attributes, no service objects |

**Security & Data Integrity**: Team lead auto-cleared when lead member removed; foreign key integrity maintained; no raw SQL.

**Development Workflow**: CSS follows existing component-based system; dark mode supported via existing classes.

## Project Structure

### Documentation (this feature)

```text
specs/002-team-member-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - internal admin UI)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
app/
├── controllers/admin/
│   └── teams_controller.rb          # Modified: handle member_ids in update
│   └── users_controller.rb          # Modified: remove team_id from user_params
├── models/
│   └── team.rb                      # Modified: add sync_members method
├── policies/admin/
│   └── team_policy.rb               # Modified: add member_ids to permitted attributes
├── views/admin/teams/
│   └── _form.html.erb               # Modified: add member management UI, fix team lead dropdown
├── views/admin/users/
│   └── _form.html.erb               # Modified: remove team_id field
├── frontend/controllers/
│   └── team_members_controller.js   # New: Stimulus controller for add/remove members
└── frontend/entrypoints/
    └── application.css              # Modified: add member list styles

spec/
├── requests/admin/
│   └── teams_spec.rb                # Modified: add member management scenarios
├── policies/admin/
│   └── team_policy_spec.rb          # Modified: verify member_ids in permitted attributes
└── factories/
    └── teams.rb                     # Potentially modified: traits for member testing

test/
└── controllers/
    └── team_members_controller_test.js  # New: Stimulus controller tests
```

**Structure Decision**: Standard Rails MVC structure. No new directories needed. The feature fits within existing admin namespacing.

## Complexity Tracking

No constitution violations. No complexity justification needed.
