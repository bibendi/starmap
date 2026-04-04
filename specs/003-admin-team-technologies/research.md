# Research: Admin Team Technologies Management

## R1: How should team technologies be embedded in the team detail page?

**Decision**: Add a "Technologies" card section below the existing team attributes on the `admin/teams/show` page. The section contains a table of assigned technologies with inline edit/remove actions and an "Add Technology" button.

**Rationale**: The spec explicitly states management is embedded in the team detail page. Adding a card section follows the existing pattern (the team show page already uses a single card). A table with actions is consistent with the admin index pages pattern.

**Alternatives considered**:
- Separate dedicated page for team technologies → rejected: over-engineering for 2 fields per record, adds unnecessary navigation
- Turbo modal/dialog for add/edit → rejected: adds complexity for a simple form, can revisit if UX feedback demands it

## R2: How should "Add Technology" work when adding to a team?

**Decision**: Dedicated `new` view with a select dropdown for choosing an active technology not yet assigned to the team. On submit, creates a TeamTechnology with defaults from the technology, then redirects back to the team show page.

**Rationale**: The technology catalog can be large; a simple select dropdown with only unassigned active technologies is straightforward. The `new` action filters out already-assigned and inactive technologies.

**Alternatives considered**:
- Inline form on the team show page → rejected: clutters the view, harder to show validation errors
- Autocomplete/search for technology → rejected: overkill for current scale, can revisit later

## R3: How should editing criticality and target_experts work?

**Decision**: Inline edit via Turbo Frame. Clicking "Edit" on a team technology row replaces the row with an edit form (within a Turbo Frame). The form updates only the `criticality` and `target_experts` fields, then redirects back to the team show page which re-renders the table.

**Rationale**: Editing 2 fields per record justifies an inline Turbo Frame approach over a separate page. This is a common Hotwire pattern and avoids full page reloads.

**Alternatives considered**:
- Separate edit page → rejected: too heavy for 2 fields
- Direct inline editing (contenteditable) → rejected: complex JS, poor accessibility

## R4: How should removal be handled?

**Decision**: Button with `turbo_confirm` dialog on each row. If the TeamTechnology has associated SkillRatings, the existing `restrict_with_error` on the association prevents deletion and the error is displayed via flash message.

**Rationale**: The `team_technologies` model already has no dependent destroy on `skill_ratings` (the Technology model uses `restrict_with_error`). Team's `has_many :team_technologies, dependent: :destroy` allows removal when no skill ratings reference it. A confirmation dialog before destructive action is standard admin UX.

**Alternatives considered**:
- Soft delete → rejected: no requirement, adds complexity
- Bulk removal → rejected: not in spec, can revisit later

## R5: Authorization pattern for Unit Lead

**Decision**: Follow the exact `Admin::TeamPolicy` pattern. `Admin::TeamTechnologyPolicy` inherits from `Admin::BasePolicy`, overrides `can_manage?` to include `unit_lead?`, and uses `unit_lead_owns_record?` to check that the team belongs to the Unit Lead's unit.

**Rationale**: This matches the established authorization pattern already used for teams. Unit Lead can manage technologies only for teams within their unit.

**Alternatives considered**:
- Separate non-admin controller → rejected: violates existing pattern, doubles code
- Reusing TeamPolicy → rejected: TeamTechnology is a different record type with different semantics

## R6: Route structure

**Decision**: Nest `team_technologies` under `teams` within the admin namespace:
```ruby
resources :teams do
  resources :team_technologies, only: [:create, :update, :destroy]
end
```
The edit form renders inline via Turbo Frame on the team show page. A separate `new` action is not needed; instead, the create action handles adding via a form embedded in the show page.

**Rationale**: Since the management is embedded in the team show page, we only need create/update/destroy endpoints. No separate index/new/edit pages are required. The create form is part of the team show view.

**Alternatives considered**:
- Full RESTful nested resource (index, new, create, edit, update, destroy) → rejected: unnecessary for inline management
- Standalone admin/team_technologies resource → rejected: doesn't reflect the parent-child relationship
