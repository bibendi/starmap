# Research & Design Decisions

---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.
---

## Summary
- **Feature**: admin-users
- **Discovery Scope**: Simple Addition (CRUD UI)
- **Key Findings**:
  - Admin::UsersController already exists as stub with placeholder view
  - User model has all required fields: first_name, last_name, email, position, role, team, active, current_sign_in_at
  - User uses `active` boolean for status, not enum; `admin` boolean for admin flag
  - Existing patterns: Admin::BaseController, Admin::BasePolicy, resource-based authorize pattern

## Research Log

### Existing Admin Architecture
- **Context**: Understanding existing admin panel structure
- **Sources Consulted**: app/controllers/admin/, app/policies/admin/, app/views/admin/
- **Findings**:
  - Admin controllers inherit from Admin::BaseController (auth + layout)
  - Admin::BasePolicy provides can_manage? check (admin? || unit_lead?)
  - Admin::QuarterPolicy extends BasePolicy with record-specific rules
  - Views use component CSS system with cards, forms, tables
- **Implications**: Follow same controller/policy patterns for consistency

### User Model Attributes
- **Context**: Verifying all fields needed for requirements exist
- **Sources Consulted**: db/migrate/20251103212524_create_users.rb, db/schema.rb
- **Findings**:
  - position: string field exists
  - current_sign_in_at: datetime field exists (Devise trackable)
  - active: boolean field exists for status
  - role: string with enum values (engineer, team_lead, unit_lead, admin)
  - team_id: foreign key to teams
- **Implications**: No schema changes required for basic user management

### Policy Authorization Rules
- **Context**: Understanding authorization requirements
- **Sources Consulted**: app/policies/admin/base_policy.rb, app/policies/user_policy.rb
- **Findings**:
  - Admin::BasePolicy allows admin or unit_lead to manage
  - UserPolicy already has admin-only update rule (AdminPolicy not used for User)
  - audit tracking via Audited gem on User model (implicit via ApplicationRecord)
- **Implications**: May need dedicated Admin::UserPolicy for granular rules

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Standard CRUD | RESTful controller with views | Simple, Rails convention | May lack flexibility | Chosen for this feature |

## Design Decisions

### Decision: Admin-only access model
- **Context**: Requirements specify only admin role can manage users
- **Alternatives Considered**:
  1. Use Admin::BasePolicy (admin || unit_lead) — too permissive
  2. Dedicated Admin::UserPolicy (admin only) — follows least privilege
- **Selected Approach**: Admin::UserPolicy requiring admin role explicitly
- **Rationale**: Requirements state "only admin role", unit_leads should not manage user accounts
- **Trade-offs**: Slightly more code but explicit security
- **Follow-up**: Verify unit tests for policy

### Decision: No email notifications
- **Context**: User requested admin sets password directly, no email delivery
- **Alternatives Considered**:
  1. Devise invitation flow — adds complexity, external dependency
  2. Direct password set — simple, meets requirements
- **Selected Approach**: Admin sets password directly on user creation
- **Rationale**: Simpler flow, matches explicit requirement
- **Trade-offs**: User must receive password securely (out of scope)

## Risks & Mitigations
- Risk: Role change to team_lead without team assignment — Proposed mitigation: form validation requiring team for team_lead role
- Risk: Deactivated user still has active session — Proposed mitigation: Devise tracks active status, session invalidation handled by Devise

## References
- [Devise Database Authenticatable](https://devise.plataformatec.com.br/rdoc/classes/Devise/Models/DatabaseAuthenticatable.html)
- [Pundit Authorization](https://github.com/varvet/pundit)
