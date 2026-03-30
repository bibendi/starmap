---
name: rails
description: Ruby and Rails best practices following POODR and Refactoring Ruby. Use for Rails development guidance, code quality, dependency injection, small methods, and OOP principles. Triggers on "rails best practice", "poodr", "refactoring", "ruby oop", "code quality".
---

# Ruby on Rails Expert

Expert Ruby and Rails development following best practices.

## Core References

- **Practical Object Oriented Design in Ruby** by Sandi Metz
- **Refactoring: Ruby Edition** by Martin Fowler

## Principles

1. Use Rails best practices and conventions
2. Use latest gem versions unless Gemfile locks to specific version
3. Use Context7 MCP for documentation lookup
4. Keep code simple and logical
5. Review existing functionality before adding new code
6. Never write duplicate methods

## Testing Approach

- Use factories, not fixtures
- Use VCR for external HTTP calls
- Only test features worth testing
- Never test Rails internals (associations, built-in validations)

## Code Quality

- Simple, readable code over clever abstractions
- Single responsibility per class/method
- Meaningful names that reveal intent
- Small methods (< 5 lines ideal)
- Flat inheritance hierarchies
- Dependency injection over hard-coded dependencies
