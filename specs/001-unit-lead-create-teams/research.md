# Research: Unit Lead Team Creation in Admin

## Decision 1: Policy Override Strategy

**Decision**: Override `can_manage?` and `Scope` in `Admin::TeamPolicy` rather than modifying `Admin::BasePolicy`.

**Rationale**: `Admin::BasePolicy` is shared by all admin resources (Quarter, Technology, Unit, User). Changing it to allow unit leads would grant unit leads access to ALL admin panels, which is not desired. The team resource is the only one unit leads should manage.

**Alternatives considered**:
- Modify `Admin::BasePolicy#can_manage?` to include `unit_lead?` — rejected because it would open all admin resources to unit leads
- Create a new `Admin::UnitLeadTeamPolicy` class — rejected because Pundit already resolves `Admin::TeamPolicy` for `[:admin, Team]` namespace; a separate class would require controller changes

## Decision 2: Scope Filtering — Unit Lead's Unit

**Decision**: Override `Admin::TeamPolicy::Scope#resolve` to return `scope.where(unit_id: user.unit.id)` for unit leads, using the existing `Team#by_unit` scope.

**Rationale**: `User#unit` already returns the Unit where the user is the unit lead (`Unit.find_by(unit_lead_id: id)`). The `Team#by_unit` scope already exists. This is the simplest approach — one scope override.

**Alternatives considered**:
- Pass unit_id as a query param and filter in controller — rejected because it's less secure; a unit lead could manipulate the param to see other units' teams
- Add a `managed_teams` association on User — rejected as unnecessary; the existing `by_unit` scope + `User#unit` method are sufficient

## Decision 3: Record-Level Authorization for Show/Edit/Destroy

**Decision**: Add record-level checks in `Admin::TeamPolicy` for `show?`, `edit?`, `update?`, `destroy?` to verify the team belongs to the unit lead's unit.

**Rationale**: The scope filters the index list, but a unit lead could craft a direct URL to a team in another unit. Record-level checks prevent this. The `index?` and `create?` actions don't need record-level checks (index is scope-filtered, create is unit-scoped by controller).

**Alternatives considered**:
- Rely on scope only (no record-level checks) — rejected because Pundit's `authorize` with a record needs explicit checks; otherwise it passes if `can_manage?` returns true regardless of which record

## Decision 4: Form Dropdown Scoping

**Decision**: Scope the `_form.html.erb` dropdowns:
- **Unit dropdown**: For unit leads, pre-select and disable (or hide) the unit field, defaulting to `current_user.unit`
- **Team lead dropdown**: For unit leads, show only users who belong to teams within their unit

**Rationale**: Unit leads should not be able to assign a team to a different unit or select a team lead from another unit. The simplest approach is to scope the dropdowns in the view based on the current user's role.

**Alternatives considered**:
- Remove unit field entirely for unit leads — rejected because `unit_id` is required; it's cleaner to keep the field but make it read-only/pre-selected
- Add a `before_action` in the controller to force `unit_id` — considered as a defense-in-depth measure alongside view scoping

## Decision 5: Controller Changes

**Decision**: Minimal controller changes in `Admin::TeamsController`:
- Add a `before_action` to force `unit_id` to `current_user.unit.id` for unit leads on create/update (defense in depth)
- No changes needed for index/show/edit/destroy — Pundit handles authorization, Scope handles filtering

**Rationale**: Even if the form is scoped, a unit lead could manipulate the form data. Forcing `unit_id` at the controller level ensures data integrity.

**Alternatives considered**:
- No controller changes — rejected because form data can be manipulated; defense in depth is needed
- Create a separate controller for unit leads — rejected as overkill; the same controller with policy-based access is simpler
