# Data Model: Unit Lead Team Creation in Admin

## Overview

No schema migrations required. This feature uses existing entities and adds authorization scoping rules.

## Existing Entities (No Changes)

### Team

| Attribute | Type | Notes |
|-----------|------|-------|
| id | integer (PK) | Auto-generated |
| name | string | Required, validated for presence |
| description | text | Optional |
| active | boolean | Default: true |
| unit_id | integer (FK) | Required, references units |
| team_lead_id | integer (FK) | Optional, references users |
| created_at | datetime | |
| updated_at | datetime | |

**Relationships**:
- `belongs_to :unit` (required)
- `belongs_to :team_lead, class_name: "User"` (optional)
- `has_many :users, dependent: :restrict_with_error`

**Existing scopes used**:
- `by_unit(unit)` — filters teams by unit
- `ordered` — orders by name
- `active` — filters active teams

### User

| Attribute | Type | Notes |
|-----------|------|-------|
| id | integer (PK) | Auto-generated |
| role | string | One of: admin, unit_lead, team_lead, engineer |
| team_id | integer (FK) | Optional, references teams |

**Existing methods used**:
- `unit_lead?` — checks if role is unit_lead
- `unit` — returns `Unit.find_by(unit_lead_id: id)` for unit leads
- `unit_lead_of_unit?(unit)` — checks `unit.unit_lead_id == id`

### Unit

| Attribute | Type | Notes |
|-----------|------|-------|
| id | integer (PK) | Auto-generated |
| name | string | Required, unique |
| unit_lead_id | integer (FK) | Optional, references users |
| active | boolean | |

**Relationships**:
- `has_many :teams, dependent: :restrict_with_error`
- `belongs_to :unit_lead, class_name: "User"` (optional)

## Authorization Rules (New — via Policy)

### Admin::TeamPolicy

| Action | Admin | Unit Lead | Team Lead | Engineer |
|--------|-------|-----------|-----------|----------|
| index | All teams | Own unit's teams | Denied | Denied |
| show | Any team | Own unit's teams | Denied | Denied |
| new | Allowed | Allowed | Denied | Denied |
| create | Any unit | Own unit only | Denied | Denied |
| edit | Any team | Own unit's teams | Denied | Denied |
| update | Any team | Own unit only | Denied | Denied |
| destroy | Any team (no users) | Own unit's teams (no users) | Denied | Denied |

**Scope resolution**:
- Admin → `scope.all`
- Unit Lead → `scope.by_unit(user.unit)`
- Others → `scope.none`
