# Quickstart: Team Member Management in Admin

## Overview

Manage team membership and team lead assignment from the team edit form in the admin panel. Team lead selection is restricted to current team members. Team assignment is removed from the user admin form.

## Changed Files

### Backend

| File | Change |
|------|--------|
| `app/controllers/admin/teams_controller.rb` | Handle `member_ids` param in `update`; set `@available_members` instance variable for form |
| `app/controllers/admin/users_controller.rb` | Remove `:team_id` from `user_params` |
| `app/models/team.rb` | Add `team_lead_must_be_member` validation; add `sync_members!` method |
| `app/policies/admin/team_policy.rb` | Add `:member_ids` to `base_permitted_attributes` |
| `app/views/admin/teams/_form.html.erb` | Add member list UI, fix team lead dropdown to use team members, wire up Stimulus |
| `app/views/admin/users/_form.html.erb` | Remove `team_id` field |
| `config/locales/en.yml` | Add i18n keys for member management |
| `config/locales/ru.yml` | Add i18n keys for member management |

### Frontend

| File | Change |
|------|--------|
| `app/frontend/controllers/team_members_controller.js` | New Stimulus controller for add/remove members and team lead dropdown sync |
| `app/frontend/entrypoints/application.css` | Add styles for member list (badge + remove button per row) |

### Tests

| File | Change |
|------|--------|
| `spec/requests/admin/teams_spec.rb` | Add specs for member add/remove via team form, team lead restriction |
| `spec/requests/admin/users_spec.rb` | Update specs to not send `team_id` param |
| `spec/policies/admin/team_policy_spec.rb` | Verify `member_ids` in permitted attributes |
| `spec/models/team_spec.rb` | Add `team_lead_must_be_member` and `sync_members!` specs |
| `test/controllers/team_members_controller_test.js` | New Stimulus controller tests |

## Implementation Order

1. Model layer: `Team#team_lead_must_be_member` validation, `Team#sync_members!`
2. Policy: add `member_ids` to permitted attributes
3. Controller: handle `member_ids` in `TeamsController#update`, set `@available_members`
4. Remove `team_id` from user form and controller
5. Stimulus controller: `team_members_controller.js`
6. View: update team form with member management UI, fix team lead dropdown
7. CSS: member list styles
8. i18n: add locale keys
9. Tests: model specs, request specs, policy specs, Stimulus tests
10. Verify: `bundle exec rspec`, `npm test`

## Running the Feature

1. `bin/dev` to start the application
2. Log in as admin or unit lead
3. Navigate to Admin → Teams → Edit any team
4. The form now shows:
   - Current team members list (with remove buttons)
   - "Add member" dropdown (unassigned engineers)
   - Team lead dropdown (filtered to current members)
5. User admin form no longer has a team assignment field

## Key Behaviors

- Adding a member: select from "Add member" dropdown → user appears in member list and team lead dropdown
- Removing a member: click remove button → user disappears from list; if they were team lead, lead is auto-cleared
- Team lead validation: cannot save with a team lead who is not in the member list
- Unit lead scope: available members dropdown only shows unassigned engineers in the unit lead's unit
- Admin scope: available members dropdown shows all unassigned engineers
