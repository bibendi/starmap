# Data Model: Team Skill Matrix Redesign

**Feature Branch**: `005-team-skill-matrix-redesign`
**Date**: 2026-04-11

## No Schema Changes

This feature introduces **no new database tables, columns, or migrations**. All data required already exists in the current schema.

## Existing Entities Used

### TeamTechnology (join model)

| Field | Type | Usage in Feature |
|-------|------|------------------|
| team_id | FK | Route context (`/teams/:team_id/technologies/:id`) |
| technology_id | FK | Identifies the technology for Coverage calculation |
| target_experts | integer (>0) | Denominator for Coverage percentage |
| criticality | enum (high/normal/low) | Displayed in matrix table |

### SkillRating

| Field | Type | Usage in Feature |
|-------|------|------------------|
| user_id | FK | Identifies team member |
| technology_id | FK | Filter for specific technology |
| quarter_id | FK | Current quarter filter |
| rating | integer (0-3) | Numerator component: ratings >= 2 count as experts |
| status | enum | Only `approved` ratings count |
| team_id | FK | Team scoping |

### Technology

| Field | Type | Usage in Feature |
|-------|------|------------------|
| id | PK | Route parameter |
| name | string | Displayed in matrix and page header |
| category_id | FK | Displayed below technology name |
| criticality | enum | Displayed as badge |

### User (as team member)

| Field | Type | Usage in Feature |
|-------|------|------------------|
| id | PK | Member identification |
| full_name | string | Displayed in member ratings table |
| team_id | FK | Team membership filter |

## Derived Data (No Persistence)

### Coverage (per technology, per team)

- **Calculation**: `(count of approved SkillRatings where rating >= 2 for this team+technology+quarter) / TeamTechnology.target_experts * 100`
- **Type**: Integer percentage (0-100)
- **Color threshold**: 0-49 danger, 50-79 warning, 80-100 success
- **Computed at**: Render time in `TeamSkillMatrixComponent`
- **Not persisted**: Derived from existing data on each page load

### Member Rating (per technology, per user)

- **Source**: `SkillRating.rating` for current quarter
- **Display**: 0-3 with color indicator, or "—" if no rating
- **Computed at**: Render time in `TeamTechnologiesController#show`
