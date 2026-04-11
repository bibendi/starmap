# Quickstart: Team Skill Matrix Redesign

**Feature Branch**: `005-team-skill-matrix-redesign`
**Date**: 2026-04-11

## Prerequisites

- Ruby 3.2+, Rails 8.1.1, PostgreSQL 15+
- Run `bin/rails db:migrate` (no new migrations, but ensure schema is current)
- Run `bundle install` (no new gems)

## Files to Create

| File | Purpose |
|------|---------|
| `app/controllers/team_technologies_controller.rb` | Show action for team technology page |
| `app/views/team_technologies/show.html.erb` | Member ratings table template |
| `app/policies/team_technology_policy.rb` | Authorization for show action |
| `spec/requests/team_technologies_spec.rb` | Request specs for new route |
| `spec/policies/team_technology_policy_spec.rb` | Policy specs |

## Files to Modify

| File | Change |
|------|--------|
| `app/components/team_skill_matrix_component.rb` | Add `coverage_for(tech_id)` method, remove unused member iteration methods |
| `app/components/team_skill_matrix_component.html.erb` | Remove member columns, add Coverage progress bar column, make tech name a link |
| `app/frontend/entrypoints/application.css` | Add `.progress-bar` component styles |
| `config/routes.rb` | Add nested `resources :technologies, only: [:show]` under teams |
| `config/locales/ru.yml` | Rename title, add `coverage` key, add new page i18n keys |
| `config/locales/en.yml` | Same changes in English |
| `app/views/layouts/application.html.erb` | Fix nav link for unit_lead without team |
| `spec/components/team_skill_matrix_component_spec.rb` | Update for new column structure |

## Implementation Order

1. **Routes & Controller**: Add route, create `TeamTechnologiesController#show`, create policy
2. **Navigation fix**: Update `application.html.erb` for unit_lead nav visibility
3. **Component redesign**: Modify `TeamSkillMatrixComponent` — add coverage, remove members, add links
4. **CSS**: Add progress bar styles
5. **i18n**: Update locale files
6. **Template**: Create `team_technologies/show.html.erb`
7. **Tests**: Update component spec, add request spec, add policy spec

## Verification

```bash
bin/rails routes | grep technology        # Verify route exists
bundle exec rspec spec/components/        # Component tests
bundle exec rspec spec/requests/team_technologies_spec.rb  # New route
bundle exec rspec spec/policies/          # Policy tests
bundle exec rspec                         # Full suite
```

## Key Patterns to Follow

- **Coverage calculation**: Private method on component, reuses `expert_counts_by_technology_and_quarter`
- **Policy**: Mirror `TeamPolicy#show?` logic, add technology-team association check
- **Template**: Reuse existing CSS classes (`.table`, `.rating-indicator`, `.card`, etc.)
- **i18n**: All user-facing strings via `t()` with keys under `components.team_skill_matrix` and `team_technologies`
