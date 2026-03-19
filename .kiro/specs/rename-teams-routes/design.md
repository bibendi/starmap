# Design Document

## Overview

**Purpose**: This feature refactors the Teams routing from custom DSL routes to RESTful resource routes following Rails conventions.

**Users**: All users navigating to team pages will be affected by this change.

**Impact**: Changes the routing from `get "/team"` and `get "/teams"` to `resources :teams, only: [:index, :show]`, which changes URL structure from `/team` (singular, name-based) to `/teams/:id` (plural, id-based).

## Goals
- Replace custom `/team` and `/teams` routes with RESTful `resources :teams, only: [:index, :show]`
- Update all URL helpers from `team_path(name: ...)` to `team_path(team)`
- Ensure all views, controllers, and tests use the new resource-based routes
- No backward compatibility required

## Non-Goals
- Creating new team functionality (index, show only)
- Modifying team authorization logic
- Changing team data model

## Architecture

### Existing Architecture Analysis

Current routes in `config/routes.rb`:
```ruby
get "/teams", to: "teams#index", as: :teams
get "/team", to: "teams#show", as: :team
```

Current `TeamsController#show` finds team by name:
```ruby
def set_team
  @team = if params[:name].present?
    Team.find_by!(name: params[:name])
  elsif current_user.team.present?
    current_user.team
  else
    redirect_to teams_path and return
  end
end
```

### Architecture Pattern

**Pattern**: RESTful Resource Routes (Rails standard)

**New routes**:
```ruby
resources :teams, only: [:index, :show]
```

| HTTP Method | Path | Action | Helper |
|-------------|------|--------|--------|
| GET | /teams | index | teams_url, teams_path |
| GET | /teams/:id | show | team_url(id), team_path(id) |

**URL Helper Changes**:
| Old Helper | New Helper | Notes |
|------------|------------|-------|
| `teams_url` / `teams_path` | `teams_url` / `teams_path` | Unchanged |
| `team_url` / `team_path` | `team_url(id)` / `team_path(id)` | Now requires id parameter |
| `team_path(name: team.name)` | `team_path(team)` | Pass Team object instead of name string |

### Technology Stack

| Layer | Choice | Role |
|-------|--------|------|
| Backend | Rails 8.1.1 | Route configuration |
| Routing | RESTful resources | Standard Rails routing |

## Components and Interfaces

### 1. Route Configuration (`config/routes.rb`)

**Change**: Replace lines 14-15:
```ruby
# OLD
get "/teams", to: "teams#index", as: :teams
get "/team", to: "teams#show", as: :team

# NEW
resources :teams, only: [:index, :show]
```

**Requirement Coverage**: Requirement 1, Requirement 5

### 2. TeamsController (`app/controllers/teams_controller.rb`)

**Change**: Update `set_team` method to use `params[:id]` instead of `params[:name]`:
```ruby
def set_team
  @team = Team.find(params[:id])
  authorize @team
end
```

**Note**: The fallback to `current_user.team` is removed since the new routing always provides `:id`.

**Files to Update**: `app/controllers/teams_controller.rb`

**Requirement Coverage**: Requirement 1

### 3. URL Helper Updates

**Files to Update**:

| File | Line | Old Code | New Code |
|------|------|----------|----------|
| `app/views/layouts/application.html.erb` | 40 | `team_path` | `team_path(current_user.team) if current_user.team` |
| `app/views/units/index.html.erb` | 49 | `team_path(name: team.name)` | `team_path(team)` |
| `app/views/users/show.html.erb` | 39 | `team_path(name: @user.team.name)` | `team_path(@user.team)` |
| `app/views/units/show.html.erb` | 36 | `team_path(name: team.name)` | `team_path(team)` |
| `app/views/teams/index.html.erb` | 25 | `team_path(name: team.name)` | `team_path(team)` |
| `app/components/red_zones_details_component.html.erb` | 41 | `team_path(name: red_zone[:team]&.name)` | `team_path(red_zone[:team])` |
| `app/controllers/application_controller.rb` | 56 | `team_path` | `team_path(current_user.team) if current_user.team` |

**Important**: Navigation link must handle case when user has no team. Use conditional rendering or fallback to teams_path.

**Requirement Coverage**: Requirement 2, Requirement 3, Requirement 4

### 4. Test Updates (`spec/requests/teams_spec.rb`)

**Change**: Update all `team_path` calls to use team objects instead of name params.

Current patterns to replace:
- `get team_path` → `get team_path(team)` (no params → with team object)
- `get team_path, params: {name: team.name}` → `get team_path(team)`

**Requirement Coverage**: Requirement 3

## Root Route Change

Current `root "teams#show"` points to `/team`. After change, this still works but will use the new `team_path(team)` helper. The root route itself does not need changes.

## Requirements Traceability

| Requirement | Components |
|-------------|------------|
| 1. Реструктуризация маршрутов | `config/routes.rb` |
| 2. Обновление URL-хелперов | All view files, controller |
| 3. Поиск и замена в представлениях | All ERB files listed above |
| 4. Поиск и замена в контроллерах | `application_controller.rb` |
| 5. Удаление старых маршрутов | `config/routes.rb` |

## Testing Strategy

### Unit Tests
- Verify routes are configured correctly: `resources :teams, only: [:index, :show]`
- Verify URL helpers generate correct paths

### Integration Tests
- Update `spec/requests/teams_spec.rb` to use new route helpers
- Verify all team links navigate correctly

### Manual Verification
- Navigate to `/teams` — should show teams list
- Navigate to `/teams/:id` — should show specific team
- Root path should still work and redirect to team page
