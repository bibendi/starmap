# Research: Team Member Management in Admin

## Research Tasks

### 1. How to manage team membership from the team edit form

**Decision**: Use a `member_ids` array parameter submitted with the form. The controller compares current `team.user_ids` with submitted `member_ids`, adds new members (setting their `team_id`), removes removed members (clearing their `team_id`).

**Rationale**: The existing data model uses a simple `team_id` foreign key on `users` — no join table. Nested attributes (`accepts_nested_attributes`) are not used anywhere in the codebase. An array of user IDs is the simplest approach that fits the existing patterns. The controller handles the diff, keeping the model layer thin.

**Alternatives considered**:
- `accepts_nested_attributes_for :users` — rejected: project has zero usage of nested attributes; would require bidirectional setup and complicated `reject_if` / `allow_destroy` logic for a simple FK update
- Join table (has_many :through) — rejected: overkill; the existing one-team-per-user model works fine, just needs centralized management UI
- Stimulus-only client-side management — rejected: team membership changes affect other teams (removing from old team); must be server-validated

### 2. Team lead dropdown restriction to team members

**Decision**: Populate the team lead `collection_select` from `@team.users` (current members) instead of querying all users. When members are added/removed client-side via Stimulus, re-render the dropdown options dynamically.

**Rationale**: The team lead must be a member of the team. Since the member list is now on the same form, we can derive the dropdown from the current member state. Server-side validation ensures consistency on save (auto-clear team_lead_id if the lead is not in member_ids).

**Alternatives considered**:
- Server-only validation (allow any selection, reject on save) — rejected: poor UX; user wouldn't know why save failed until after submission
- Separate AJAX call to refresh dropdown — rejected: unnecessary network request when we already have the member data in the form

### 3. Stimulus controller for dynamic member management

**Decision**: Create `team_members_controller.js` that:
- Maintains a list of current member IDs and their names
- Renders the member list with remove buttons
- Has an "add member" dropdown (unassigned engineers) that moves selected user into the member list
- Updates the team lead dropdown when members change (removes removed members from options, adds new members as options)

**Rationale**: No existing Stimulus controllers handle dynamic form elements. The project uses `local: true` forms (no Turbo). A Stimulus controller is the idiomatic Hotwire approach for progressive enhancement of server-rendered forms.

**Alternatives considered**:
- Turbo Frame for member list — rejected: the member list is part of a larger form, not independently submittable
- Full page round-trip for each add/remove — rejected: poor UX for a list management task

### 4. Filtering available members (unassigned engineers, scoped by unit)

**Decision**: Pass available users (unassigned engineers) from the controller to the form as an instance variable. Filter by unit for unit leads. Exclude unit_lead and admin roles.

**Rationale**: The server must control who is available to add. Unit leads should only see engineers in their unit. Admin users and unit lead users should never appear in the "add member" dropdown regardless.

**Alternatives considered**:
- AJAX search endpoint — rejected: overkill for expected user count; a pre-populated select is sufficient
- Include all users, filter client-side — rejected: would leak data across unit boundaries for unit leads

### 5. Removing team assignment from user admin form

**Decision**: Remove the `team_id` `collection_select` from `app/views/admin/users/_form.html.erb` and remove `:team_id` from `user_params` in `Admin::UsersController`.

**Rationale**: Team membership is now managed exclusively from the team edit form. Having two places to change it creates inconsistency and violates single responsibility. The `team_id` field on users becomes write-only through the team form.

**Alternatives considered**:
- Keep field but make it read-only — rejected: confusing UX; if you can see it, you expect to change it
- Keep field with validation preventing changes — rejected: dead UI element is worse than no element

### 6. Data integrity: team lead auto-clear when member removed

**Decision**: In the Team model, add a `sync_members(member_ids)` method (or handle in controller) that:
1. Sets `team_id` to `nil` for users being removed
2. If the removed user is the current team lead, sets `team_lead_id` to `nil`
3. Sets `team_id` to the team for users being added (also clears their team_lead_id from old team if applicable)

**Rationale**: Keeps the controller action atomic and avoids orphaned state. The team lead relationship becomes inconsistent if the lead user is removed from the team without also clearing `team_lead_id`.

**Alternatives considered**:
- Database constraint — rejected: no built-in PG constraint for this pattern; would require triggers
- Validation only (error on save) — rejected: auto-clear is better UX than forcing user to manually clear team lead first
