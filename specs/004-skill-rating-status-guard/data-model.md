# Data Model: Skill Rating Status Guard

**Feature**: 004-skill-rating-status-guard
**Date**: 2026-04-09

## Entity Changes

### SkillRating — Column Removal

| Column | Type | Action | Notes |
|--------|------|--------|-------|
| `locked` | boolean | REMOVE | Redundant with `status` field |
| (index on `locked`) | index | REMOVE |伴随 column removal |

No new columns added. The `status` field (string, not null, default "draft") becomes the sole determinant of editability.

### SkillRating — Method Removals

| Method | Type | Action | Notes |
|--------|------|--------|-------|
| `can_be_edited?` | instance | REMOVE | Zero callers in codebase |
| `lock!` | instance | REMOVE | Replaced by status-based logic |
| `unlock!` | instance | REMOVE | Replaced by status-based logic |
| `handle_lock_change` | private callback | REMOVE | No-op, never used |
| `lock_all_for_quarter` | class | REMOVE | Replaced by status-based logic |
| `unlock_all_for_quarter` | class | REMOVE | Replaced by status-based logic |
| `scope :locked` | scope | REMOVE | No longer applicable |
| `scope :unlocked` | scope | REMOVE | No longer applicable |

### SkillRating — Callback Removals

| Callback | Action | Notes |
|----------|--------|-------|
| `after_update :handle_lock_change, if: :locked_changed?` | REMOVE | Callback + handler both removed |

### Quarter — Method Changes

**`handle_status_change`** (lines 279-289 of `quarter.rb`):

Before:
```ruby
def handle_status_change
  return unless status_changed?
  if status == "closed"
    skill_ratings.where(status: %w[draft submitted])
      .update_all(status: "approved", locked: true)
  elsif status == "draft"
    skill_ratings.update_all(locked: false)
  end
end
```

After:
```ruby
def handle_status_change
  return unless status_changed?
  if status == "closed"
    skill_ratings.where(status: %w[draft submitted])
      .update_all(status: "approved")
  end
end
```

Changes:
- Remove `locked: true` from the `update_all` call on close
- Remove the entire `elsif status == "draft"` branch (reopening quarters no longer needs to toggle a lock)

## State Transitions

### SkillRating Status (unchanged)

```text
draft ──→ submitted ──→ approved
  ↑           │              │
  │           ↓              │ (immutable for engineers)
  └────── rejected ──────────┘ (engineers can edit → resets to draft)
```

### Editability Rules (by role)

| Status | Engineer | Team Lead | Unit Lead / Admin |
|--------|----------|-----------|-------------------|
| draft | Editable | Editable | Editable |
| submitted | Editable | Editable | Editable |
| approved | NOT editable | Editable | Editable |
| rejected | Editable | Editable | Editable |

## Migration

Single migration to remove the `locked` column and its index:

```ruby
class RemoveLockedFromSkillRatings < ActiveRecord::Migration[8.1]
  def change
    remove_column :skill_ratings, :locked, :boolean, default: false, null: false
  end
end
```

Note: `remove_column` automatically removes the associated index.
