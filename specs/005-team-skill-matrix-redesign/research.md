# Research: Team Skill Matrix Redesign

**Feature Branch**: `005-team-skill-matrix-redesign`
**Date**: 2026-04-11

## R1: Coverage Calculation for Single Technology

**Decision**: Coverage = `(expert_count / target_experts * 100).round(0)` capped at 100%, where expert_count = count of team members with approved rating >= EXPERT_MIN_RATING for the technology in the current quarter.

**Rationale**: Reuses the exact same algorithm as `CoverageIndexComponent` but scoped to a single `TeamTechnology` record instead of aggregating across all team technologies. The existing `expert_counts_by_technology_and_quarter` method in `TeamSkillMatrixComponent` already loads expert counts per technology — the `bus_factor_for` method already has `count` and `target`. Coverage is just `(count.to_f / target * 100).round` using data already available.

**Alternatives considered**:
- Separate query per technology — rejected: N+1 risk, data already loaded by bus factor calculation
- Extracting CoverageCalculation service object — rejected: violates Simplicity Over Cleverness (Principle V). A private method on the component is sufficient.

## R2: Progress Bar Visual Design

**Decision**: Inline CSS progress bar using existing color tokens (danger/warning/success) matching Bus Factor risk levels. Compact size (full cell width, ~8px height).

**Rationale**: The application uses a component CSS system (no Tailwind inline classes in templates). New `.progress-bar`, `.progress-bar__track`, `.progress-bar__fill` CSS classes in `application.css` under `@layer components`. Color thresholds match Bus Factor: 0-49% danger, 50-79% warning, 80-100% success. Dark mode support required per constitution.

**Alternatives considered**:
- External progress bar library — rejected: violates Principle V (no new dependencies)
- Reusing existing badge component — rejected: badges are discrete labels, not continuous indicators

## R3: Route Design for Team Technology Page

**Decision**: Nested route under teams: `resources :teams, only: [:index, :show] do; resources :technologies, only: [:show]; end` producing `/teams/:team_id/technologies/:id`.

**Rationale**: RESTful nesting follows Rails conventions. The technology page is always in the context of a specific team (same technology can have different ratings per team). Controller named `TeamTechnologiesController` (namespace: `team_technologies`).

**Alternatives considered**:
- Shallow route `/technologies/:id` — rejected: loses team context needed for authorization and team name display
- Separate `TeamTechnology` controller with `team_technology_id` — rejected: confusing, the page shows team + technology data, not just the join record

## R4: Navigation Fix for Unit Lead

**Decision**: Change the condition in `application.html.erb` from `current_user.team` to handle both cases: if unit_lead has a team → link to that team; if not → link to `/teams`.

**Rationale**: The current code (`<% if policy(:navigation).show_team? && current_user.team %>`) hides the link entirely for unit_leads without team membership. Unit leads manage multiple teams and should always see "Команда" pointing to `/teams` index. The fix is conditional: users with a team go to their team page; users without (unit_leads managing multiple teams) go to `/teams`.

**Alternatives considered**:
- Always link to `/teams` for unit_lead — rejected: unit_lead who is also a team member loses direct access to their own team
- Add `current_user.teams.first` logic — rejected: ambiguous which team to pick; `/teams` index is cleaner

## R5: Technology Name as Link in Matrix

**Decision**: Wrap the existing technology name `<span>` in a `link_to team_technology_path(team, tech)`.

**Rationale**: Minimal template change. The technology name is already rendered in a `<span class="text-heading">`. Wrapping it in a link preserves the visual style while adding navigation. The `tech` object is already available in the loop.

**Alternatives considered**:
- Separate link column — rejected: adds visual clutter, technology name is the natural click target
- Turbo Frame navigation — rejected: unnecessary complexity for a full page transition
