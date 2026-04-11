# Implementation Plan: Team Skill Matrix Redesign

**Branch**: `005-team-skill-matrix-redesign` | **Date**: 2026-04-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-team-skill-matrix-redesign/spec.md`

## Summary

Redesign the TeamSkillMatrixComponent: rename to «Компетенции команды», remove per-member columns, add Coverage progress bar column. Create a new route `/teams/:team_id/technologies/:id` with a member ratings table. Fix unit_lead navigation visibility for the "Команда" menu item.

## Technical Context

**Language/Version**: Ruby 3.2+, Rails 8.1.1
**Primary Dependencies**: ViewComponent 4.2.0, Pundit, Hotwire (Turbo + Stimulus), Vite Rails, Kaminari
**Storage**: PostgreSQL 15+
**Testing**: RSpec + FactoryBot (Ruby), Vitest + JSDOM (JS Stimulus)
**Target Platform**: Web (server-rendered HTML)
**Project Type**: Monolithic Rails web application
**Performance Goals**: Page load < 1s for team dashboard with up to 20 technologies and 15 members
**Constraints**: No new gem dependencies, no SPA frameworks, server-rendered first
**Scale/Scope**: ~5 teams, ~50 users, ~100 technologies — small corporate app

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Server-Rendered First | PASS | All changes are ERB + ViewComponent. No JS framework introduced. |
| II. Authorization on Every Action | PASS | New `TeamTechnologiesController#show` requires Pundit policy. Navigation fix uses existing NavigationPolicy. |
| III. Small, Focused Code | PASS | Coverage calculation added as small private methods on existing component. New controller stays thin. |
| IV. Behavior-Driven Testing | PASS | RSpec component tests updated, new request spec for route, factory-based data. |
| V. Simplicity Over Cleverness | PASS | No new gems, no service objects. Coverage reuses existing ExpertConstants. Direct ActiveRecord queries. |

**Gate result**: PASS — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/005-team-skill-matrix-redesign/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── team-technology-route.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/
├── components/
│   └── team_skill_matrix_component.rb       # MODIFY: add coverage calculation, remove member methods
│   └── team_skill_matrix_component.html.erb # MODIFY: remove member columns, add Coverage column
├── controllers/
│   └── team_technologies_controller.rb      # NEW: show action for /teams/:team_id/technologies/:id
├── views/
│   └── team_technologies/
│       └── show.html.erb                    # NEW: member ratings table
│   └── layouts/
│       └── application.html.erb             # MODIFY: fix nav link for unit_lead without team
├── policies/
│   └── team_technology_policy.rb            # NEW: authorize show action
├── frontend/
│   └── entrypoints/
│       └── application.css                  # MODIFY: add progress-bar CSS component
├── models/                                   # NO CHANGES
config/
├── routes.rb                                # MODIFY: add nested route
├── locales/
│   ├── ru.yml                               # MODIFY: rename title, add coverage key, add new page keys
│   └── en.yml                               # MODIFY: same
spec/
├── components/
│   └── team_skill_matrix_component_spec.rb  # MODIFY: update for new column structure
├── requests/
│   └── team_technologies_spec.rb            # NEW: request spec for new route
├── policies/
│   └── team_technology_policy_spec.rb       # NEW: policy spec
```

**Structure Decision**: Standard Rails MVC. New route nested under teams resource. No new models or database changes.
