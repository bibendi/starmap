# Feature Specification: Unit Lead Team Creation in Admin

**Feature Branch**: `001-unit-lead-create-teams`  
**Created**: 2026-03-31  
**Status**: Draft  
**Input**: User description: "разрешить создавать teams юнит-лидам в админке"

## Clarifications

### Session 2026-03-31

- Q: Should Unit Leads see and manage all teams or only teams belonging to their unit? → A: Unit Leads should see and manage only teams within their own unit

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unit Lead Creates a New Team (Priority: P1)

A Unit Lead needs to create a new team within their unit to organize engineers as the team grows or restructures. They navigate to the admin panel, create the team with a name, optional description, and assign it to their unit.

**Why this priority**: This is the core feature request — enabling Unit Leads to create teams without relying on an Admin.

**Independent Test**: Can be fully tested by logging in as a Unit Lead, navigating to the team creation form in the admin panel, filling in the required fields, and verifying the team appears in the list.

**Acceptance Scenarios**:

1. **Given** a Unit Lead is logged in and has at least one unit, **When** they navigate to the admin teams page and click "New Team", **Then** they see the team creation form with name, description, and team lead fields (unit is pre-selected to their unit)
2. **Given** a Unit Lead is on the new team form, **When** they fill in the required fields and submit, **Then** the team is created within their unit and they are redirected to the team's detail page with a success message
3. **Given** a Unit Lead submits invalid data (e.g., empty name), **When** the form is submitted, **Then** validation errors are displayed and the team is not created

---

### User Story 2 - Unit Lead Views and Manages Teams in Admin (Priority: P2)

A Unit Lead can view the list of teams within their unit, filter them, and access team details through the admin panel to manage their unit's team structure. Teams from other units are not visible.

**Why this priority**: Viewing teams is a prerequisite for effective team management and complements the creation ability.

**Independent Test**: Can be tested by logging in as a Unit Lead, navigating to the admin teams list, and verifying they can see teams and access team details.

**Acceptance Scenarios**:

1. **Given** a Unit Lead is logged in, **When** they navigate to the admin teams index page, **Then** they see a paginated list of only their unit's teams with filtering options
2. **Given** a Unit Lead is on the teams list, **When** they click on a team from their unit, **Then** they see the team's detail page

---

### User Story 3 - Unit Lead Edits and Deletes Teams (Priority: P2)

A Unit Lead can edit existing team properties and delete teams within their unit that have no assigned members.

**Why this priority**: Full CRUD access allows Unit Leads to independently manage their unit's team structure.

**Independent Test**: Can be tested by editing an existing team's name/description and by deleting an empty team.

**Acceptance Scenarios**:

1. **Given** a Unit Lead is viewing a team, **When** they click "Edit" and modify team fields, **Then** the changes are saved and visible on the team detail page
2. **Given** a Unit Lead attempts to delete a team with assigned members, **When** they confirm deletion, **Then** the deletion is rejected with an appropriate error message
3. **Given** a Unit Lead deletes an empty team, **When** they confirm deletion, **Then** the team is removed and they are redirected to the teams list

---

### Edge Cases

- What happens when a Unit Lead tries to create a team without a unit? (Validation should require a unit; unit should be pre-selected to their own unit)
- What happens when a Unit Lead tries to delete a team that has users assigned? (Deletion should be blocked with a message)
- What happens when a Unit Lead is deactivated? (They should lose access to admin team management)
- What happens when a Unit Lead tries to access a team from another unit? (Access should be denied)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST restrict Unit Leads to seeing only teams belonging to their unit in the admin teams index
- **FR-002**: System MUST allow Unit Leads to create new teams only within their own unit via the admin panel
- **FR-003**: System MUST allow Unit Leads to view team details only for teams within their unit
- **FR-004**: System MUST allow Unit Leads to edit only teams within their unit via the admin panel
- **FR-005**: System MUST allow Unit Leads to delete only teams within their unit that have no assigned members
- **FR-006**: System MUST enforce that only teams with no assigned users can be deleted
- **FR-007**: System MUST restrict Engineers and Team Leads from accessing team management in the admin panel
- **FR-008**: System MUST validate required team fields (name, unit) on creation and edit
- **FR-009**: System MUST display appropriate success and error messages for all team management operations
- **FR-010**: System MUST deny Unit Leads access to teams outside their unit (show not found or redirect)

### Key Entities

- **Team**: Represents a group of engineers managed by a team lead. Key attributes: name, description, active status, associated unit, assigned team lead
- **Unit Lead**: A user role responsible for managing one or more units and their teams

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Unit Lead can create a team in under 1 minute from the admin panel
- **SC-002**: Unit Lead can complete a full team CRUD cycle (create, view, edit, delete) without requiring Admin assistance
- **SC-003**: 100% of team management authorization rules are enforced — Engineers, Team Leads cannot access admin team management actions; Unit Leads cannot access teams outside their unit

## Assumptions

- Unit Leads already have the `unit_lead` role assigned in the system
- The admin panel navigation already exists and only needs access control updates
- Unit Leads are scoped to their own unit — they see and manage only teams within their unit in the admin panel
- The existing team validation rules (name required, etc.) remain unchanged
- When a Unit Lead creates a team, the unit is automatically set to their own unit
