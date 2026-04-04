# Quickstart: Admin Team Technologies Management

## Feature Overview

This feature adds the ability for Admins and Unit Leads to manage technologies assigned to teams within the admin area. The management is embedded in the team detail page.

## Files to Create

1. `app/controllers/admin/team_technologies_controller.rb` — CRUD controller (create, update, destroy)
2. `app/policies/admin/team_technology_policy.rb` — Authorization policy
3. `app/views/admin/team_technologies/_form.html.erb` — Edit form for criticality/target_experts
4. `app/views/admin/team_technologies/_add_form.html.erb` — Form to add new technology to team
5. `app/views/admin/team_technologies/_row.html.erb` — Table row partial
6. `spec/policies/admin/team_technology_policy_spec.rb` — Policy tests
7. `spec/requests/admin/team_technologies_spec.rb` — Request specs

## Files to Modify

1. `config/routes.rb` — Add nested `team_technologies` resource under `teams`
2. `app/views/admin/teams/show.html.erb` — Add technologies card section
3. `config/locales/en.yml` — Add `admin.team_technologies` I18n keys
4. `config/locales/ru.yml` — Add `admin.team_technologies` I18n keys

## No Database Changes

The `team_technologies` table already exists with all required columns. No migrations needed.

## Implementation Order

1. Routes (add nested resource)
2. Policy (authorization rules)
3. Controller (CRUD actions)
4. Views (modify team show, add partials)
5. I18n (both locales)
6. Tests (policy + request specs)

## Verification

```bash
bundle exec rspec spec/policies/admin/team_technology_policy_spec.rb
bundle exec rspec spec/requests/admin/team_technologies_spec.rb
```
