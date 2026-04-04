# Implementation Plan: Admin Team Technologies Management

**Branch**: `003-admin-team-technologies` | **Date**: 2026-04-04 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-admin-team-technologies/spec.md`

## Summary

Add CRUD management for TeamTechnology records within the admin area. Admins and Unit Leads can view, add, edit, and remove technologies assigned to teams. Each team-technology link has per-team `criticality` (high/normal/low) and `target_experts` (positive integer) overrides that default from the global technology settings. The feature embeds within the existing team detail page following established admin patterns.

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.1.1
**Primary Dependencies**: Pundit (authorization), ViewComponent (UI), Kaminari (pagination), Hotwire (Turbo)
**Storage**: PostgreSQL 15+ (existing `team_technologies` table, no migrations needed)
**Testing**: RSpec (Ruby), Vitest + JSDOM (JS, if needed)
**Target Platform**: Linux server (monolithic Rails web app)
**Project Type**: Web application (monolithic Rails, server-rendered)
**Performance Goals**: Standard admin page responsiveness (<2s page load)
**Constraints**: Follow existing admin UI patterns, Pundit authorization, I18n (en/ru), dark mode support
**Scale/Scope**: ~10-50 technologies per team, ~5-20 teams per unit, ~4 admin/Unit Lead users

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Server-Rendered First | PASS | ERB views with Turbo for partial updates, no JS frameworks |
| II. Authorization on Every Action | PASS | Pundit policy (`Admin::TeamTechnologyPolicy`) on all controller actions |
| III. Small, Focused Code | PASS | Controller delegates to model, policy is focused, views follow component pattern |
| IV. Behavior-Driven Testing | PASS | RSpec with FactoryBot factory (already exists), behavior-focused assertions |
| V. Simplicity Over Cleverness | PASS | Direct ActiveRecord usage, no new gems, nested routes under existing teams resource |

All gates pass. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/003-admin-team-technologies/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (UI contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
app/
├── controllers/admin/
│   └── team_technologies_controller.rb   # NEW: CRUD for team technologies
├── policies/admin/
│   └── team_technology_policy.rb         # NEW: Admin + Unit Lead authorization
├── views/admin/teams/
│   └── show.html.erb                     # MODIFY: add technologies section
├── views/admin/team_technologies/
│   ├── _form.html.erb                    # NEW: edit form for criticality/target_experts
│   ├── _row.html.erb                     # NEW: table row partial
│   └── new.html.erb                      # NEW: add technology form
config/
├── routes.rb                              # MODIFY: nested team_technologies under teams
├── locales/
│   ├── en.yml                             # MODIFY: add admin.team_technologies keys
│   └── ru.yml                             # MODIFY: add admin.team_technologies keys
spec/
├── policies/admin/
│   └── team_technology_policy_spec.rb    # NEW: policy tests
├── requests/admin/
│   └── team_technologies_spec.rb         # NEW: request specs for all actions
└── factories/
    └── team_technologies.rb               # EXISTS: no changes needed
```

**Structure Decision**: Standard Rails MVC within the existing `admin` namespace. Team technologies are nested under teams resource, consistent with their parent-child relationship. No new directories at the top level — all new files follow existing admin patterns.
