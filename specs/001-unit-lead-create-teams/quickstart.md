# Quickstart: Unit Lead Team Creation in Admin

## What Changed

Unit Leads can now create, view, edit, and delete teams in the admin panel, scoped to their own unit.

## Files Modified

| File | Change |
|------|--------|
| `app/policies/admin/team_policy.rb` | Override `can_manage?` to allow unit leads; add record-level checks for show/edit/update/destroy; override `Scope` to filter by unit |
| `app/controllers/admin/teams_controller.rb` | Force `unit_id` to current user's unit for unit leads on create/update |
| `app/views/admin/teams/_form.html.erb` | Scope unit dropdown and team lead dropdown for unit leads |
| `app/views/admin/teams/index.html.erb` | Scope unit filter dropdown for unit leads |
| `spec/policies/admin/team_policy_spec.rb` | Add unit lead authorization and scope tests |
| `spec/requests/admin/teams_spec.rb` | Add unit lead CRUD tests with unit scoping |

## Testing

```bash
# Run admin team policy specs
bundle exec rspec spec/policies/admin/team_policy_spec.rb

# Run admin teams request specs
bundle exec rspec spec/requests/admin/teams_spec.rb

# Run all specs
bundle exec rspec
```

## Verification Steps

1. Log in as a Unit Lead
2. Navigate to `/admin` — the "Teams" sidebar link should appear
3. Click "Teams" — only teams from the unit lead's unit should be listed
4. Click "New Team" — the unit dropdown should be pre-selected and disabled
5. Create a team — it should appear in the list
6. Click "Edit" on a team from the unit — form should open with pre-selected unit
7. Try accessing `/admin/teams/:id` for a team from another unit — should get not found
8. Log in as an Engineer — the "Teams" sidebar link should NOT appear
