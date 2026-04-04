# Feature Specification: Admin Team Technologies Management

**Feature Branch**: `003-admin-team-technologies`
**Created**: 2026-04-04
**Status**: Draft
**Input**: User description: "Добавляем возможность управления team technologies в админке. Я пока не знаю как и где это должно выглядет и распологаться. Это нужно решить. Что нужно точно: возможность задавать: criticality, target_experts"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Team Technologies (Priority: P1)

As an Admin or Unit Lead, I want to see all technologies assigned to a team on the team detail page, so that I can review the current technology coverage and their per-team settings.

**Why this priority**: Without visibility into team technologies, admins cannot effectively manage team composition and criticality settings. This is the foundation for all management operations.

**Independent Test**: Navigate to a team's admin detail page and verify that all assigned technologies are displayed in a table with their criticality level and target expert count.

**Acceptance Scenarios**:

1. **Given** a team with 3 assigned technologies, **When** the admin opens the team detail page, **Then** they see a "Technologies" section listing all 3 technologies with their criticality badges and target expert counts
2. **Given** a team with no assigned technologies, **When** the admin opens the team detail page, **Then** they see an empty state message with a prompt to add technologies

---

### User Story 2 - Add Technology to Team (Priority: P1)

As an Admin or Unit Lead, I want to assign a technology to a team, so that it becomes part of that team's competency tracking with appropriate default settings.

**Why this priority**: Assigning technologies is the primary action required to set up team competency tracking. Without it, the feature has no data to manage.

**Independent Test**: From the team technologies section, add a technology to the team. Verify it appears in the list with default criticality and target experts inherited from the technology.

**Acceptance Scenarios**:

1. **Given** a team with existing technologies, **When** the admin adds a new technology from the catalog, **Then** the technology appears in the team's list with criticality and target_experts inherited from the technology's global settings
2. **Given** a technology already assigned to the team, **When** the admin tries to add it again, **Then** the system prevents the duplicate and shows a validation message

---

### User Story 3 - Edit Team Technology Settings (Priority: P1)

As an Admin or Unit Lead, I want to change criticality and target_experts for a technology on a specific team, so that I can tailor coverage requirements per team context.

**Why this priority**: This is the core requirement explicitly stated by the user. Adjusting criticality and target experts per team is the primary management action.

**Independent Test**: Click edit on a team technology, change criticality from "normal" to "high" and target_experts from 2 to 3. Verify the changes persist after saving.

**Acceptance Scenarios**:

1. **Given** a team technology with criticality "normal" and target_experts 2, **When** the admin changes criticality to "high" and target_experts to 3, **Then** the updated values are saved and displayed immediately
2. **Given** an admin editing a team technology, **When** they enter an invalid target_experts value (0 or negative), **Then** the system shows a validation error and does not save

---

### User Story 4 - Remove Technology from Team (Priority: P2)

As an Admin or Unit Lead, I want to remove a technology from a team, so that I can keep the team's technology list accurate when a technology is no longer relevant.

**Why this priority**: Removal is a necessary lifecycle operation but less critical than adding and editing. Teams need cleanup capability for accuracy.

**Independent Test**: Remove a technology from a team. Verify it no longer appears in the team's technology list. The technology itself remains in the global catalog.

**Acceptance Scenarios**:

1. **Given** a team technology with associated skill ratings, **When** the admin attempts to remove it, **Then** the system prevents removal and shows a message that the technology has associated data
2. **Given** a team technology with no associated skill ratings, **When** the admin removes it, **Then** the technology is removed from the team list

---

### Edge Cases

- What happens when a technology is deleted from the global catalog while assigned to teams?
- What happens when the number of assigned technologies exceeds what can fit on the team detail page (pagination needed)?
- How does the system handle concurrent edits by two admins on the same team technology settings?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display all technologies assigned to a team on the team detail page in the admin area
- **FR-002**: System MUST allow Admin to add an active technology from the global catalog to a team
- **FR-003**: System MUST inherit criticality and target_experts defaults from the technology's global settings when adding to a team
- **FR-004**: System MUST allow Admin to edit criticality (high, normal, low) for a team-specific technology
- **FR-005**: System MUST allow Admin to edit target_experts (positive integer) for a team-specific technology
- **FR-006**: System MUST prevent duplicate technology assignment to the same team
- **FR-007**: System MUST validate that target_experts is a positive integer (> 0)
- **FR-008**: System MUST validate that criticality is one of: high, normal, low
- **FR-009**: System MUST prevent removal of a team technology that has associated skill ratings
- **FR-010**: System MUST restrict access to team technology management to Admin and Unit Lead users
- **FR-010a**: Unit Lead MUST only manage technologies for teams within their own unit
- **FR-011**: System MUST show an empty state when a team has no assigned technologies
- **FR-012**: System MUST show criticality values with visual distinction (color-coded badges)

### Key Entities

- **TeamTechnology**: Junction record linking a Team and a Technology with per-team overrides. Has `criticality` (high/normal/low) and `target_experts` (positive integer). Inherits defaults from Technology on creation.
- **Technology**: Global technology catalog entry with its own `criticality` and `target_experts` defaults, plus name, category, description, and active status.
- **Team**: Engineering team grouping users. Has many Technologies through TeamTechnology.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Admin can assign a technology to a team and see it appear in the team's technology list within 2 seconds
- **SC-002**: Admin can update criticality and target_experts for a team technology in a single edit action
- **SC-003**: 100% of validation errors are communicated to the user via inline messages near the relevant field
- **SC-004**: Duplicate assignment and invalid data are prevented with clear error messages

## Assumptions

- Team technology management is embedded within the existing team detail page (admin/teams/:id/show), not as a separate standalone page
- Only active technologies from the global catalog are available for assignment to teams
- Unit Lead can manage technologies for teams within their own unit (consistent with existing team management permissions)
- The technology catalog (admin/technologies) is managed separately; this feature only manages the team-technology linkage
- Removal of a team technology does NOT affect the global technology record
- Skill ratings referencing a team technology are a hard constraint preventing deletion (existing `restrict_with_error` behavior)
