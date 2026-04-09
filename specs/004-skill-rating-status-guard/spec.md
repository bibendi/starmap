# Feature Specification: Skill Rating Status Guard on Edit Page

**Feature Branch**: `004-skill-rating-status-guard`
**Created**: 2026-04-09
**Status**: Draft
**Input**: User description: "На странице редактирования оценок users/:id/skill_ratings/edit во время периода квартальных оценок ни как не учитывается статус оценки. as is: user может менять оценку в не зависимости от статуса. to be: нельзя изменить approved оценку, удалить использование поля locked таблицы skill_ratings, в UI убрать колонку Количества экспертов, добавить - Статус оценки"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Engineer sees status-aware edit form (Priority: P1)

As an engineer editing my skill ratings during an evaluation period, I want to see the status of each rating directly on the edit page, so that I can immediately understand which ratings I can still modify and which have been approved and are locked.

**Why this priority**: This is the core UX improvement. Without a visible status indicator, the user has no way to distinguish editable from non-editable ratings until they attempt a save. This is the primary source of confusion described in the problem statement.

**Independent Test**: Can be fully tested by opening the edit page with a mix of draft and approved ratings and verifying that status badges appear correctly next to each technology row.

**Acceptance Scenarios**:

1. **Given** an engineer has ratings with statuses "draft", "submitted", "approved", and "rejected" in the current quarter, **When** they open the edit page, **Then** each row displays a status badge matching its current status (draft, submitted, approved, or rejected).
2. **Given** an engineer opens the edit page, **When** they view the table header, **Then** they see columns: Technology, Criticality, Rating, Level, and Status — and do NOT see a "Target Experts" column.

---

### User Story 2 - Engineer cannot modify approved ratings (Priority: P1)

As an engineer, I must not be able to change a rating that has already been approved by my Team Lead. Approved ratings should be visually and functionally locked on the edit form.

**Why this priority**: This is the primary bug fix. Currently the system ignores the approval status, allowing engineers to overwrite approved ratings. This undermines the entire approval workflow and data integrity.

**Independent Test**: Can be tested by attempting to change and save an approved rating, and verifying the system prevents it both in the UI (disabled controls) and on the server (rejected request).

**Acceptance Scenarios**:

1. **Given** an engineer has an approved rating for a technology, **When** they open the edit page, **Then** the radio buttons for that technology are disabled (non-clickable, visually muted).
2. **Given** an engineer has an approved rating, **When** they submit the form with a modified value for that rating (e.g., via manual request tampering), **Then** the server rejects the change and preserves the original approved rating.
3. **Given** an engineer has a draft rating, **When** they change the value on the edit page, **Then** the new value is saved successfully and the rating remains in "draft" status.

---

### User Story 3 - Remove "locked" field and consolidate on status (Priority: P2)

As a system, all editability decisions should be based solely on the rating's status field, removing the redundant "locked" boolean field that creates ambiguity and is not consistently enforced.

**Why this priority**: This is a data model cleanup that eliminates the dual-gate confusion (locked + approved). It is necessary for long-term maintainability but does not directly change user-facing behavior beyond what P1 stories address.

**Independent Test**: Can be verified by confirming that the "locked" column is removed from the database, all code references to it are eliminated, and quarter status transitions (close, reopen) still correctly protect ratings via the status field alone.

**Acceptance Scenarios**:

1. **Given** the system uses the status field to determine editability, **When** a quarter transitions to "closed", **Then** all draft/submitted ratings are set to "approved" status (without using a separate locked flag).
2. **Given** a quarter is reverted from "closed" to "draft", **When** the transition occurs, **Then** ratings become editable again based on their status alone.
3. **Given** the "locked" field has been removed, **When** the application runs, **Then** no code references `locked`, `lock!`, `unlock!`, `locked?`, or `can_be_edited?` that depend on the removed field.

---

### Edge Cases

- What happens when a Team Lead or Admin edits ratings for a user — should approved ratings still be editable for them? Team Leads and above can edit any rating regardless of status (existing policy behavior).
- What happens when all ratings are approved — the edit page still opens but all controls are disabled, and the save button is hidden or disabled.
- What happens with a "rejected" rating — the engineer should still be able to edit it (change the value and save, which resets to "draft").

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The edit page MUST display a "Status" column showing the current status badge (draft, submitted, approved, rejected) for each rating row.
- **FR-002**: The edit page MUST NOT display the "Target Experts" column.
- **FR-003**: For engineers, radio buttons for approved ratings MUST be disabled (non-interactive) on the edit page.
- **FR-004**: The server MUST reject any attempt to update an approved rating for a user who is not a Team Lead or above.
- **FR-005**: Draft, submitted, and rejected ratings MUST remain editable by the owning engineer.
- **FR-006**: The `locked` boolean field on `skill_ratings` MUST be removed from the database, model, scopes, callbacks, factories, seeds, and all related code.
- **FR-007**: Quarter status transitions MUST continue to work without the `locked` field — closing a quarter sets draft/submitted ratings to "approved" status; reopening makes ratings editable again based on status.
- **FR-008**: The `can_be_edited?` method MUST be updated to check only the status field (not approved) instead of both `locked` and `approved?`.

### Key Entities

- **SkillRating**: The core entity being modified. Key attributes: `status` (draft/submitted/approved/rejected), `rating` (0-3), `quarter_id`, `user_id`, `technology_id`. The `locked` boolean is being removed.
- **Quarter**: Governs the evaluation period. Transitions to "closed" auto-approve remaining ratings. The quarter's status change handler currently sets both `status` and `locked`; after this change it sets only `status`.
- **User (roles)**: Engineers are restricted from editing approved ratings. Team Leads, Unit Leads, and Admins retain the ability to edit any rating.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Engineers cannot modify approved ratings — attempting to save a change to an approved rating is rejected 100% of the time.
- **SC-002**: The edit page displays the correct status badge for every rating row, matching the stored status value.
- **SC-003**: The "Target Experts" column is completely removed from the edit page view.
- **SC-004**: No code references to the `locked` field remain in the application (model, controller, views, policies, jobs, seeds, tests).
- **SC-005**: All existing tests pass after removing the `locked` field and related code.

## Assumptions

- Team Leads, Unit Leads, and Admins retain the ability to edit ratings regardless of status — only Engineers are restricted from modifying approved ratings. This follows the existing Pundit policy pattern.
- When a quarter closes, all draft/submitted ratings are auto-approved. This is the current behavior and remains unchanged — only the mechanism (using status alone instead of status + locked) changes.
- The `can_be_edited?` method will simplify to `!approved?`, since the `locked` field is being removed.
- The `handle_lock_change` callback (currently a no-op) will be removed along with the `locked` field.
- Existing seeds that set `locked` values will be updated to remove those assignments.
