# Route Contract: Team Technology Show

**Feature Branch**: `005-team-skill-matrix-redesign`
**Date**: 2026-04-11

## Endpoint

**Route**: `GET /teams/:team_id/technologies/:id`
**Route helper**: `team_technology_path(team, technology)`
**Controller**: `TeamTechnologiesController#show`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| team_id | integer | yes | Team primary key |
| id | integer | yes | Technology primary key |

## Authorization

**Policy**: `TeamTechnologyPolicy#show?`
**Access rules** (same as `TeamPolicy#show?`):
- Admin: any team
- Unit Lead: teams in own unit
- Team Lead: own team only
- Engineer: own team only

Additional check: Technology must belong to the team (via `TeamTechnology` join record). If technology is not associated with the team, return 404.

## Response

**Success (200)**: HTML page with:

```
Page Header
├── Technology name (h1)
├── Team name as clickable link → /teams/:team_id (subheading)

Member Ratings Table
├── Columns: Member Name | Rating (0-3 with color indicator) | Change vs previous quarter
├── Sorted: team lead first, then alphabetically
└── Legend: Expert(3) / Proficient(2) / Basic(1) / No knowledge(0)
```

**Redirect (302)**: If no current quarter → redirect to team page with alert

**Not Found (404)**: If technology not associated with team

**Forbidden (403)**: If user lacks access to the team

## Data Loaded by Controller

```ruby
@team          # Team.find(params[:team_id])
@technology    # Technology.find(params[:id]) — verified via TeamTechnology
@current_quarter = Quarter.current
@team_members  # @team.users ordered (lead first)
@skill_ratings # Approved ratings for this team+technology+current_quarter, keyed by user_id
@previous_ratings # Previous quarter ratings for change indicators, keyed by user_id
```

## Route Registration

```ruby
# config/routes.rb
resources :teams, only: [:index, :show] do
  resources :technologies, only: [:show]
end
```

This produces:
- `team_technology_path(team, technology)` → `/teams/:team_id/technologies/:id`
- `team_technology_url(team, technology)` → full URL
