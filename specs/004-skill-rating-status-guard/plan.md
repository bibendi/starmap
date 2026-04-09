# Implementation Plan: Skill Rating Status Guard on Edit Page

**Branch**: `004-skill-rating-status-guard` | **Date**: 2026-04-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-skill-rating-status-guard/spec.md`

## Summary

Prevent engineers from editing approved skill ratings on the edit page, add a status column to the edit table (replacing "Target Experts"), and remove the redundant `locked` boolean field from `skill_ratings` — consolidating all editability logic on the `status` field alone.

## Technical Context

**Language/Version**: Ruby 3.2+
**Primary Dependencies**: Rails 8.1.1, Hotwire (Turbo + Stimulus), ViewComponent 4.2.0, Pundit, Devise
**Storage**: PostgreSQL 15+
**Testing**: RSpec with FactoryBot, Vitest + JSDOM for Stimulus
**Target Platform**: Web application (server-rendered HTML)
**Project Type**: Monolithic Rails web application
**Performance Goals**: N/A (form edit page, standard request/response)
**Constraints**: Must maintain existing approval workflow and role-based access
**Scale/Scope**: ~50-200 engineers per unit, one edit page, one migration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Server-Rendered First | PASS | All changes are ERB templates and server-side logic. No new JavaScript needed. |
| II. Authorization on Every Action | PASS | Pundit policy already checks `approved?` for engineers. Adding server-side guard in controller strengthens compliance. |
| III. Small, Focused Code | PASS | Changes are removing code (locked field) and adding small guard conditions. Methods stay under 5 lines. |
| IV. Behavior-Driven Testing | PASS | Tests will use RSpec + FactoryBot. Testing behavior (cannot save approved rating), not implementation. |
| V. Simplicity Over Cleverness | PASS | Removing a redundant field simplifies the system. No new gems or abstractions. |

**Security & Data Integrity**: Closing quarters auto-approves ratings — unchanged. Approved ratings become immutable for engineers — strengthens data integrity.

**No violations. No complexity tracking needed.**

## Project Structure

### Documentation (this feature)

```text
specs/004-skill-rating-status-guard/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
```

### Source Code (repository root)

```text
app/
├── models/
│   ├── skill_rating.rb          # Remove locked field, simplify can_be_edited?
│   └── quarter.rb               # Remove locked from handle_status_change
├── controllers/
│   └── skill_ratings_controller.rb  # Add approved guard in update_or_create_rating
├── policies/
│   └── skill_rating_policy.rb   # Already correct (checks approved?)
└── views/
    └── skill_ratings/
        ├── edit.html.erb        # Add status column, remove target_experts, disable approved rows
        └── show.html.erb        # No changes needed (already has status column)

db/
├── migrate/
│   └── YYYYMMDD_remove_locked_from_skill_ratings.rb  # New migration
└── seeds.rb                     # Remove locked assignments

spec/
├── factories/
│   └── skill_ratings.rb         # Remove locked field and :locked trait
├── models/
│   └── skill_rating_spec.rb     # Update tests removing locked references
├── policies/
│   └── skill_rating_policy_spec.rb  # Verify approved guard works
└── requests/
    └── skill_ratings_spec.rb    # Test approved rating cannot be updated by engineer
```

**Structure Decision**: Standard Rails monolith. All changes are within existing directories. No new directories or architectural patterns needed.
