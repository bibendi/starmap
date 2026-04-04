# Data Model: Admin Team Technologies Management

No database migrations are required. The existing `team_technologies` table already has all necessary columns.

## Existing Entities

### TeamTechnology (no schema changes)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint PK | auto, NOT NULL | |
| team_id | bigint FK → teams | NOT NULL, unique with technology_id | |
| technology_id | bigint FK → technologies | NOT NULL, unique with team_id | |
| criticality | string | NOT NULL, default "normal", inclusion: high/normal/low | Per-team override |
| target_experts | integer | NOT NULL, default 2, > 0 | Per-team override |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Relationships**:
- `belongs_to :team` — the engineering team
- `belongs_to :technology` — the global technology catalog entry

**Validation rules** (already exist in model):
- `criticality`: presence, inclusion in `%w[high normal low]`
- `target_experts`: presence, numericality (integer, > 0)
- Unique constraint on `[:team_id, :technology_id]` at DB level

**Default values on create** (already exist in model):
- `criticality` inherits from `technology.criticality` or falls back to `"normal"`
- `target_experts` defaults based on criticality level (high→3, normal→2, low→1)

**Existing associations**:
- `Team has_many :team_technologies, dependent: :destroy`
- `Team has_many :technologies, through: :team_technologies`
- `Technology has_many :team_technologies, dependent: :restrict_with_error`
- `Technology has_many :teams, through: :team_technologies`

## New Code Artifacts

### Model Changes

None. The `TeamTechnology` model is fully functional as-is.

### Controller: Admin::TeamTechnologiesController

Actions: `create`, `update`, `destroy`

- `create`: Finds team by params[:team_id], authorizes, builds TeamTechnology with permitted attributes, redirects to team show
- `update`: Finds TeamTechnology by id, authorizes, updates permitted attributes, redirects to team show
- `destroy`: Finds TeamTechnology by id, authorizes, destroys (or shows error from restrict_with_error), redirects to team show

Strong params (via Pundit): `[:technology_id, :criticality, :target_experts]`

### Policy: Admin::TeamTechnologyPolicy

Inherits from `Admin::BasePolicy`. Key rules:
- `can_manage?`: admin? || unit_lead?
- `unit_lead_owns_record?`: unit_lead? && team_record.unit_id == user.unit&.id
- Actions: create/update/destroy all require can_manage? + ownership check for unit leads
- Scope: unit_lead sees technologies for teams in their unit; admin sees all

### Routes

Nested under teams:
```ruby
resources :teams do
  resources :team_technologies, only: [:create, :update, :destroy]
end
```

Generated paths:
- `admin_team_team_technologies_path(team)` → POST /admin/teams/:team_id/team_technologies
- `admin_team_team_technology_path(team, tt)` → PATCH/DELETE /admin/teams/:team_id/team_technologies/:id
