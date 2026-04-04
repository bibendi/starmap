# UI Contract: Team Technologies Section

## Location

Admin team detail page: `/admin/teams/:id`

## Section: Technologies Card

Placed below the existing team attributes card on the team show page.

### States

#### 1. List State (default)

A card containing a table of assigned technologies.

**Table columns**:
| Column | Content |
|--------|---------|
| Technology | Technology name (text) |
| Category | Technology category name or "-" |
| Criticality | Badge: high=danger(red), normal=warning(amber), low=secondary(gray) |
| Target Experts | Integer value |
| Actions | Edit button, Delete button (with turbo_confirm) |

**Empty state**: When team has no technologies, show a message with "Add Technology" button.

**Footer**: "Add Technology" button that toggles the create form (via Turbo Frame).

#### 2. Create Form State (inline via Turbo Frame)

Displayed within a Turbo Frame replacing the "Add Technology" button area.

**Fields**:
| Field | Type | Options |
|-------|------|---------|
| Technology | Select dropdown | Active technologies not yet assigned to this team |

On submit: POST to `admin_team_team_technologies_path(team)`. On success: redirect to team show. On error: re-render form with validation messages.

#### 3. Edit Form State (inline via Turbo Frame)

Displayed within a Turbo Frame replacing the table row being edited.

**Fields**:
| Field | Type | Options |
|-------|------|---------|
| Criticality | Select dropdown | high, normal, low |
| Target Experts | Number input | Positive integer |

On submit: PATCH to `admin_team_team_technology_path(team, team_technology)`. On success: redirect to team show. On error: re-render form with validation messages.

#### 4. Delete Confirmation

Native `turbo_confirm` dialog on click. On confirm: DELETE to `admin_team_team_technology_path(team, team_technology)`. On error (restrict_with_error): flash alert message, redirect to team show.

## Accessibility

- All form fields have associated labels
- Badges use appropriate ARIA roles
- Delete action uses confirmation dialog
- Form errors are announced to screen readers
- Dark mode supported (inherited from admin layout)

## I18n Keys Required

```
admin.team_technologies.title
admin.team_technologies.add
admin.team_technologies.edit
admin.team_technologies.remove
admin.team_technologies.confirm_destroy
admin.team_technologies.created
admin.team_technologies.updated
admin.team_technologies.destroyed
admin.team_technologies.cannot_delete_with_ratings
admin.team_technologies.empty_state
admin.team_technologies.attributes.technology
admin.team_technologies.attributes.criticality
admin.team_technologies.attributes.target_experts
admin.team_technologies.attributes.category
admin.team_technologies.create
admin.team_technologies.cancel
admin.team_technologies.save
```
