# Quickstart: Skill Rating Status Guard

**Feature**: 004-skill-rating-status-guard
**Date**: 2026-04-09

## What This Feature Does

1. Engineers can no longer modify approved skill ratings on the edit page
2. The edit page now shows a "Status" column (replaces "Target Experts" column)
3. The redundant `locked` boolean field is removed from `skill_ratings`

## Files to Change

### Must Modify

| File | Change |
|------|--------|
| `app/views/skill_ratings/edit.html.erb` | Add status column, remove target_experts column, disable approved radio buttons |
| `app/models/skill_rating.rb` | Remove locked field, scopes, methods, callbacks (10 items) |
| `app/models/quarter.rb` | Remove `locked: true` and unlock branch from `handle_status_change` |
| `app/controllers/skill_ratings_controller.rb` | Skip approved ratings for engineers in `update_or_create_rating` |
| `spec/factories/skill_ratings.rb` | Remove `locked` attribute and `:locked` trait |
| `db/seeds.rb` | Remove 4 lines setting `rating.locked` |

### Must Create

| File | Purpose |
|------|---------|
| `db/migrate/YYYYMMDD_remove_locked_from_skill_ratings.rb` | Drop locked column + index |

### No Changes Needed

| File | Reason |
|------|--------|
| `app/policies/skill_rating_policy.rb` | Already checks `!record.approved?` for engineers |
| `app/views/skill_ratings/show.html.erb` | Already has status column |

## Implementation Order

1. **Migration**: Create and run the migration to remove `locked` column
2. **Model cleanup**: Remove all `locked` references from `SkillRating` and `Quarter`
3. **Controller guard**: Add approved-rating skip logic in `update_or_create_rating`
4. **UI changes**: Update `edit.html.erb` — add status column, remove target_experts, disable approved rows
5. **Factory + seeds**: Remove `locked` references
6. **Tests**: Verify all specs pass, add new tests for approved rating protection

## Verification Commands

```bash
bin/rails db:migrate
bundle exec rspec
grep -r "locked" app/ spec/factories/ db/seeds.rb
```

The `grep` should return zero results (excluding historical migration files in `db/migrate/`).
