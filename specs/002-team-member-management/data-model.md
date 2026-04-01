# Data Model: Team Member Management in Admin

## Existing Entities (no schema changes)

### Team

| Attribute | Type | Notes |
|-----------|------|-------|
| id | bigint | PK |
| name | string | Unique, required |
| description | string | Optional |
| active | boolean | Default: true |
| team_lead_id | bigint | FK → users, optional |
| unit_id | bigint | FK → units, required |
| created_at | datetime | |
| updated_at | datetime | |

**Relationships**:
- `belongs_to :team_lead` (User, optional)
- `belongs_to :unit` (required)
- `has_many :users` (dependent: :restrict_with_error)

### User

| Attribute | Type | Notes |
|-----------|------|-------|
| id | bigint | PK |
| team_id | integer | FK → teams, optional (this is the membership link) |
| role | string | One of: engineer, team_lead, unit_lead, admin |
| active | boolean | Default: true |
| ... | ... | Other Devise/standard fields |

**Relationships**:
- `belongs_to :team` (optional) — this IS the team membership

## Key Relationships (no changes)

```
Unit (1) ──── (N) Team
                  │
                  │ team_lead_id
                  ▼
Team (1) ──── (N) User  (via users.team_id)
                  │
                  │ role = "team_lead"
                  ▼
              Team Lead (a User who is both team_lead role + team member)
```

## Validation Rules

| Rule | Entity | Description |
|------|--------|-------------|
| `name` presence + uniqueness | Team | Existing, unchanged |
| `only_one_team_lead_per_team` | User | Existing — fires when `role = team_lead` AND (`role_changed?` OR `team_id_changed?`) |
| Team lead must be a team member | Team | **New** — validated on save: if `team_lead_id` is set, that user must be in `member_ids` |
| Available members must be unassigned engineers | Team form | **New** — controller-level filtering, not a model validation |

## State Transitions

### Member Lifecycle

```
Unassigned ──────► Member of Team A
(engineer,       (user.team_id = team_a.id)
 team_id: null)
     ▲                   │
     │                   │
     └──── Remove ◄──────┘
        from Team A
     (user.team_id = nil)
```

### Team Lead on Member Removal

```
Member + Team Lead ──remove──► Not a member + Team lead cleared
(user.team_id = team.id,      (user.team_id = nil,
 team.team_lead_id = user.id)  team.team_lead_id = nil)
```

## No Schema Changes Required

The existing `users.team_id` foreign key already supports the membership model. No new tables, columns, or indexes are needed.
