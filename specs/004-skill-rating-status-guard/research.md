# Research: Skill Rating Status Guard

**Feature**: 004-skill-rating-status-guard
**Date**: 2026-04-09

## R1: How to prevent editing approved ratings on the server side

**Decision**: Skip approved ratings in the `update_or_create_rating` controller method. Do not modify them at all.

**Rationale**: The controller's `update_or_create_rating` method currently unconditionally sets `status: "draft"` on every save. The simplest fix is to skip records that are already approved (for engineers). Team Leads and above bypass this via the policy's `update?` method which returns `true` for them without checking `approved?`.

**Implementation approach**:
1. In `update_or_create_rating`, after finding the existing record, check if it is `approved?`
2. If approved AND the current user is an engineer (not admin/unit_lead/team_lead of the user's team), skip the record with `next`
3. This keeps the method under 5 lines per constitution

**Alternatives considered**:
- Adding a model-level validation: Rejected because Team Leads need to be able to modify approved ratings, so a blanket model validation would block legitimate use cases.
- Moving the check to a before_action: Rejected because the check needs to be per-rating, not per-request (a single form submission contains multiple ratings with different statuses).

## R2: How to handle the `locked` field removal in quarter status transitions

**Decision**: Remove `locked: true` from the quarter close transition. Remove the `elsif status == "draft"` unlock branch entirely. When a quarter reopens to "draft", ratings stay in their current status — no automatic unlock needed.

**Rationale**: Currently when a quarter closes:
1. Draft/submitted ratings → set to approved + locked
2. When quarter reopens to draft → unlocked

After removing `locked`:
1. Draft/submitted ratings → set to approved (status only)
2. When quarter reopens to draft → ratings are still approved, which is correct because approved ratings should stay approved even if the quarter reopens. Team Leads and Admins can still edit them via the policy.

The reopen-to-draft branch (`skill_ratings.update_all(locked: false)`) becomes unnecessary because:
- Approved ratings should remain approved (Team Leads/Admins can edit them)
- The editability is controlled by the policy + status, not a separate lock flag

**Alternatives considered**:
- Resetting all ratings to "draft" when quarter reopens: Rejected because it would destroy the approval history. Team Leads explicitly approved those ratings.
- Keeping a separate reopen mechanism via status: Rejected as over-engineering. The policy already allows Team Leads to edit any rating.

## R3: How to disable approved rating radio buttons in the UI

**Decision**: Add a `disabled` attribute to radio buttons for approved ratings when the current user is an engineer. Use the existing `skill_rating.approved?` check in the ERB template.

**Rationale**: The `disabled` HTML attribute is the standard way to prevent form input interaction. It is server-rendered (no JavaScript needed), accessible, and visually communicates non-editability through browser defaults. Combined with the `peer-checked:` Tailwind classes already in use, the disabled state is visually obvious.

**Implementation approach**:
1. Pass the `current_user` role context to the template (already available via `current_user` in controllers)
2. In the radio_button_tag call, add `disabled: true` when `skill_rating.approved? && current_user == @target_user`
3. Add `disabled:` variant CSS to visually mute the disabled radio buttons (opacity reduction)

**Alternatives considered**:
- Hiding the row entirely: Rejected because the user needs to see all their ratings including approved ones.
- Using JavaScript to disable: Rejected per Constitution Principle I (Server-Rendered First).
- Using a Stimulus controller: Rejected — the `disabled` attribute handles this natively in HTML.

## R4: How to display the status column on the edit page

**Decision**: Reuse the exact same status badge pattern from the show page (`app/views/skill_ratings/show.html.erb` lines 78-96), adapted for the edit page layout.

**Rationale**: The show page already has a working status badge implementation with proper localization keys (`t("skill_ratings.status.draft")`, etc.) and visual styling (badge--secondary, badge--warning, badge--success, badge--danger). Copying this pattern ensures consistency and requires no new CSS or translations.

**Alternatives considered**:
- Creating a ViewComponent for the status badge: Rejected as over-engineering for this scope — the pattern is simple and already duplicated only once.
- Using text instead of badges: Rejected because badges provide better visual distinction, especially in a dense table.

## R5: Scope of `can_be_edited?` method

**Decision**: Remove `can_be_edited?` entirely. It has zero callers in the codebase.

**Rationale**: The method is defined on `SkillRating` (line 77-78) but is never called from controllers, policies, views, or specs. The policy's `update?` method directly checks `!record.approved?` for engineers. Removing dead code aligns with Constitution Principle V (Simplicity Over Cleverness).

**Alternatives considered**:
- Simplifying to `!approved?`: Rejected because it has no callers — keeping it would be YAGNI.
- Keeping it as a convenience method: Rejected per Principle V — no concrete problem it solves today.
