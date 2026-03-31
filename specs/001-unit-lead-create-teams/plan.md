# Implementation Plan: Unit Lead Team Creation in Admin

**Branch**: `001-unit-lead-create-teams` | **Date**: 2026-03-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-unit-lead-create-teams/spec.md`

## Summary

Grant Unit Leads CRUD access to teams in the admin panel, scoped to their own unit only. This requires overriding `Admin::TeamPolicy` to allow unit leads, scoping the team list to the unit lead's unit, and scoping form dropdowns (unit, team lead) to the unit lead's unit.

## Technical Context

**Language/Version**: Ruby 3.2+  
**Primary Dependencies**: Rails 8.1.1, Pundit (authorization), ViewComponent (UI)  
**Storage**: PostgreSQL 15+  
**Testing**: RSpec (Ruby), FactoryBot (factories), Shoulda Matchers  
**Target Platform**: Web application (server-rendered)  
**Project Type**: Monolithic Rails application (Hotwire: Turbo + Stimulus)  
**Performance Goals**: Standard web responsiveness, no specific targets  
**Constraints**: Must follow Pundit namespace policy pattern (`[:admin, Team]`)  
**Scale/Scope**: Small organizational app (~50-200 users)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Server-Rendered First | PASS | No new JS needed; policy + view scoping changes only |
| II. Authorization on Every Action | PASS | All admin team actions already use `authorize [:admin, Team]`; policy will enforce role + scope |
| III. Small, Focused Code | PASS | Changes are small: one policy override, controller scoping, view dropdown scoping |
| IV. Behavior-Driven Testing | PASS | RSpec request specs for policy enforcement, factory-based test data |
| V. Simplicity Over Cleverness | PASS | Leverages existing `Team#by_unit` scope and `User#unit` method; no new gems or abstractions |

**No violations.** No complexity tracking entries needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-unit-lead-create-teams/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (not needed - no external interfaces)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
app/
├── controllers/admin/
│   └── teams_controller.rb       # Add unit-scope filtering for unit leads
├── policies/admin/
│   └── team_policy.rb            # Override can_manage? and Scope for unit leads
├── views/admin/teams/
│   ├── index.html.erb            # Scope unit filter dropdown
│   └── _form.html.erb            # Scope unit & team_lead dropdowns
app/models/
├── team.rb                       # Existing by_unit scope (no changes needed)
app/models/
├── user.rb                       # Existing unit method (no changes needed)
spec/
├── policies/admin/
│   └── team_policy_spec.rb       # Update: add unit lead scenarios
├── requests/admin/
│   └── teams_spec.rb             # Update: add unit lead CRUD + scoping tests
```

**Structure Decision**: No new files needed except test updates. All changes modify existing files in the standard Rails admin namespace. The `Team#by_unit` scope and `User#unit` method already exist and will be reused.

## Complexity Tracking

No violations. Table intentionally empty.
