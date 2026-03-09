# Project Structure

## Organization Philosophy

**Standard Rails MVC** with domain-driven organization. Core entities (User, Team, Technology, Quarter) drive folder structure. Features organized by domain concern rather than technical layer.

## Directory Patterns

### Models (`app/models/`)
**Location**: `app/models/`  
**Purpose**: Domain entities with business logic, validations, and associations  
**Example**: `User` (roles: engineer, team_lead, unit_lead, admin), `SkillRating` (0-3 scale with approval workflow)

### Controllers (`app/controllers/`)
**Location**: `app/controllers/`  
**Purpose**: HTTP request handling, parameter filtering, policy enforcement  
**Example**: `SkillRatingsController` manages rating lifecycle, `TeamsController` for team management

### Components (`app/components/`)
**Location**: `app/components/`  
**Purpose**: Reusable UI components using ViewComponent gem  
**Example**: `CoverageIndexComponent`, `RedZonesCardComponent`, `TeamSkillMatrixComponent`

### Policies (`app/policies/`)
**Location**: `app/policies/`  
**Purpose**: Pundit authorization rules - role-based and record-level access  
**Example**: `SkillRatingPolicy` (edit own ratings in active quarters), `DashboardPolicy` (role-based dashboard access)

### Jobs (`app/jobs/`)
**Location**: `app/jobs/`  
**Purpose**: Solid Queue background job classes  
**Example**: Metric recalculation jobs after rating changes

### JavaScript (`app/javascript/`)
**Location**: `app/javascript/`  
**Purpose**: Stimulus controllers and Turbo integration  
**Example**: `controllers/` directory for Stimulus, minimal JavaScript philosophy

### Tests (`spec/`, `test/`)
**Location**: `spec/` for Ruby, `test/` for JavaScript  
**Purpose**: RSpec for Ruby (factories, models, components, system tests), Vitest for Stimulus controllers  
**Example**: Component specs with `render_inline`, Stimulus tests with JSDOM

## Naming Conventions

- **Models**: PascalCase (e.g., `SkillRating`, `ActionPlan`)
- **Controllers**: snake_case with `_controller` suffix (e.g., `skill_ratings_controller.rb`)
- **Components**: PascalCase with `Component` suffix (e.g., `RedZonesCardComponent`)
- **Policies**: snake_case with `_policy` suffix matching model (e.g., `skill_rating_policy.rb`)
- **Database Tables**: snake_case, plural (e.g., `skill_ratings`, `action_plans`)

## Import Organization

### Ruby
```ruby
# No custom path aliases - standard Rails autoloading
# Standard library first
require 'some_gem'

# Then gems
require 'devise'
require 'pundit'

# Application code autoloaded by Rails
```

### JavaScript
```javascript
// Stimulus controllers use standard import maps
import { Controller } from "@hotwired/stimulus"
import { get, post } from "@rails/request.js"
```

## Code Organization Principles

**Single Responsibility**: Small methods (< 5 lines), focused classes. Each model/controller/component has one clear purpose.

**Policy Enforcement**: All controller actions check Pundit policies. Policies encapsulate role logic (Engineer, Team Lead, Unit Lead, Admin).

**Quarter State Machine**: All ratings tied to Quarter with statuses (draft → active → closed → archived). Business logic respects quarter state for edit permissions.

**Component Reusability**: Dashboard cards and metrics as ViewComponents. Components accept data objects, render HTML, contain no business logic.

**Testing Philosophy**: 
- Behavior testing over implementation details
- Component tests verify rendered output
- Stimulus tests verify DOM interactions, not internal APIs
- Factory-based test data, not fixtures

---
_Document patterns, not file trees. New files following patterns shouldn't require updates_
