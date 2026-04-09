# UI Contract: Skill Ratings Edit Page

**Feature**: 004-skill-rating-status-guard
**Date**: 2026-04-09

## Edit Page Table Structure

### Columns (ordered)

| Position | Column Key | Header (i18n) | Content | Interactive |
|----------|-----------|---------------|---------|-------------|
| 1 | technology | `skill_ratings.edit.technology` | Technology name | No |
| 2 | criticality | `skill_ratings.edit.criticality` | Badge: high/normal/low | No |
| 3 | rating | `skill_ratings.edit.rating` | Radio buttons 0-3 | Conditional |
| 4 | level | `skill_ratings.edit.level` | Text description | No |
| 5 | status | NEW: `skill_ratings.edit.status` | Badge: draft/submitted/approved/rejected | No |

### Removed Columns

| Column | Reason |
|--------|--------|
| target_experts | Per spec FR-002: removed from edit page |

### Status Badge Mapping

| Status | Badge Class | i18n Key |
|--------|------------|----------|
| draft | `badge badge--secondary` | `skill_ratings.status.draft` |
| submitted | `badge badge--warning` | `skill_ratings.status.submitted` |
| approved | `badge badge--success` | `skill_ratings.status.approved` |
| rejected | `badge badge--danger` | `skill_ratings.status.rejected` |

### Radio Button Disabled Logic

Radio buttons for a technology row are disabled when:
- `skill_rating.approved? == true` AND `current_user == @target_user` (engineer editing own ratings)

Radio buttons are NOT disabled when:
- `current_user` is a Team Lead, Unit Lead, or Admin editing another user's ratings
- The rating status is draft, submitted, or rejected

### Save Button Behavior

When ALL ratings on the page are approved (for the target engineer):
- The save button SHOULD be hidden or disabled (all controls are non-interactive, no meaningful save action)

When at least one rating is editable:
- The save button displays normally
