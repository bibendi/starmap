# Feature Specification: Team Member Management in Admin

**Feature Branch**: `002-team-member-management`
**Created**: 2026-04-01
**Status**: Draft
**Input**: User description: "В админке на форме редактирования team необходимо сделать изменение состава команды. Также нужно внести ограничение для выбора руководителя - сейчас им может быть кто-угодно, а нужно сделать, чтобы мог быть только член команды."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manage Team Membership from Team Edit Form (Priority: P1)

An admin or unit lead opens the team edit form in the admin panel and sees the current team members listed. They can add new members to the team by selecting users from a list of available (unassigned) users, and remove existing members from the team. Changes to team membership are saved when the form is submitted.

**Why this priority**: This is the core capability requested — currently team composition can only be changed by editing individual users one by one. Centralizing this on the team form dramatically improves admin workflow.

**Independent Test**: Can be fully tested by navigating to a team edit form, adding/removing members, saving, and verifying the member list reflects changes.

**Acceptance Scenarios**:

1. **Given** a team with 3 members, **When** the admin opens the team edit form, **Then** all 3 current members are displayed in the member list
2. **Given** a team edit form with the member list, **When** the admin adds a new user to the team and saves, **Then** the new member appears in the team and their previous team (if any) is updated accordingly
3. **Given** a team edit form with the member list, **When** the admin removes a member and saves, **Then** the user is no longer a member of that team
4. **Given** a team with a designated team lead, **When** the admin removes the team lead member from the team, **Then** the team lead field is cleared and a warning message is displayed

---

### User Story 2 - Restrict Team Lead Selection to Team Members (Priority: P1)

An admin or unit lead editing a team sees the team lead dropdown. The dropdown only contains users who are currently members of that team. If the team has no members, the dropdown is empty. When a new member is added to the team via the member list, they immediately become available in the team lead dropdown.

**Why this priority**: This is a data integrity constraint directly requested — currently any user can be assigned as team lead regardless of team membership, which leads to inconsistent state.

**Independent Test**: Can be fully tested by editing a team, verifying the team lead dropdown only shows current members, adding a new member, and confirming the new member appears in the dropdown.

**Acceptance Scenarios**:

1. **Given** a team with members Alice, Bob, and Charlie, **When** the admin views the team lead dropdown, **Then** only Alice, Bob, and Charlie appear as options (plus a blank "no lead" option)
2. **Given** a team with no members, **When** the admin views the team lead dropdown, **Then** only the blank "no lead" option is available
3. **Given** a team where the current team lead is removed from the member list, **When** the form is saved, **Then** the team lead assignment is automatically cleared

---

### Edge Cases

- What happens when removing a team member who has existing skill ratings for the current quarter? Their ratings should remain but they are no longer associated with the team for future quarters.
- What happens when a user is the team lead of their current team and is being moved to another team via the member list? The team lead field on the source team should be cleared.
- What happens when the team lead dropdown has a selected value but the team lead member is removed before saving? The form should display a validation error or auto-clear the selection.
- What happens when an admin assigns a user who is already a member of another team to a new team? The user is moved from their old team to the new one (each user belongs to exactly one team).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The team edit form in the admin panel MUST display the current list of team members
- **FR-002**: The team edit form MUST allow adding users to the team by selecting from a list of unassigned engineers (users without a team and with role "engineer")
- **FR-003**: The team edit form MUST allow removing existing members from the team
- **FR-004**: When a user is removed from a team, their team membership MUST be cleared (they become unassigned)
- **FR-005**: The team lead dropdown on the team edit form MUST only contain users who are current members of that team
- **FR-006**: The team lead dropdown MUST include a blank option to allow clearing the team lead assignment
- **FR-007**: If the currently assigned team lead is removed from the team's member list, the team lead assignment MUST be cleared upon save
- **FR-008**: Unassigned engineers (users without a team, role "engineer") are available to be added to any team by both admins and unit leads
- **FR-009**: Admins MUST be able to add any unassigned engineer to any team regardless of unit
- **FR-010**: The user admin form MUST NOT allow changing a user's team assignment — team membership is managed exclusively from the team edit form

### Key Entities

- **Team**: A group of users within a unit. Has a name, optional description, active status, optional team lead, and belongs to a unit.
- **User**: An account that can be a member of at most one team. Has a role (engineer, team_lead, unit_lead, admin).
- **Team Lead**: A user who is both a member of a team and designated as its leader. The team lead relationship is stored on the team record but the user must also be a team member.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Admin can add or remove team members in under 30 seconds from the team edit form
- **SC-002**: Team lead dropdown never shows users who are not members of the current team
- **SC-003**: Removing a team member who is also the team lead automatically clears the team lead field — no manual step required
- **SC-004**: Zero cases of inconsistent state where a team lead is not a member of their own team

## Assumptions

- Each user can belong to at most one team (existing constraint preserved)
- Users without a team assignment and with role "engineer" are considered "unassigned" and available for adding to any team. Users with roles "unit_lead" and "admin" must NOT appear in the available members list.
- The team edit form is the ONLY place to manage team membership. The user admin form must not allow changing a user's team assignment.
- Removing a member from a team does not delete the user account or their historical data (skill ratings, action plans)
- When a user is moved between teams (added to a new team while already assigned), they are removed from their previous team
- Only admins and unit leads have access to the team edit form in the admin panel
