# Starmap Style Guide

This document outlines the coding conventions and design principles for the Starmap application. It serves as a reference for maintaining consistency across the codebase.

## ViewComponents Styling

### Component-Based CSS System

Starmap uses a component-based CSS approach instead of inline Tailwind classes. This system provides:

- **Semantic class names** that describe purpose rather than visual appearance
- **Full dark mode support** built into all components
- **Consistent spacing, colors, and typography** across the application
- **Reduced inline class clutter** (60-70% reduction compared to inline Tailwind)

### Core Principles

1. **Component-First Approach**
   - Prefer CSS components over inline utility classes
   - Each component should have a single responsibility
   - Use BEM-like naming: `.component`, `.component--variant`, `.component__element`

2. **Dark Mode Consistency**
   - All components must support both light and dark themes
   - Use CSS custom properties or Tailwind's dark variants
   - Ensure proper contrast ratios in both themes

3. **Semantic Naming**
   - Names should describe function, not appearance
   - Avoid names that conflict with Tailwind utility classes
   - Use consistent naming patterns across components

4. **Design Tokens**
   - Use consistent spacing units (4px increments)
   - Maintain a consistent color palette
   - Follow typography scale for font sizes and weights

### Component Categories

#### Layout Components
- **Container components**: For grouping related elements
- **Flex utilities**: For alignment and distribution
- **Spacing utilities**: Consistent margins and padding

#### Typography Components
- **Heading components**: For titles and section headers
- **Text components**: For body content and labels
- **Helper text**: For subtitles and descriptions

#### UI Components
- **Cards**: Container components with borders and shadows
- **Tables**: Structured data presentation
- **Badges**: Status indicators and labels
- **Indicators**: Visual cues for changes and states
- **Forms**: Input elements and validation states

### Implementation Guidelines

#### When to Create a New Component
1. When a UI pattern appears in 3+ places
2. When the pattern has multiple visual states
3. When the pattern needs dark mode support
4. When the pattern combines multiple layout and style concerns

#### Component Documentation
Each component should be documented with:
- Purpose and usage examples
- Available variants and modifiers
- Dark mode behavior
- Accessibility considerations

#### Testing Components
- Test in both light and dark themes
- Verify hover/focus states
- Check for proper contrast ratios
- Ensure responsive behavior

### File Organization

CSS components are defined in `app/frontend/entrypoints/application.css` under the `@layer components` directive. Components are organized by category with clear section headers.

### Migration from Inline Classes

When migrating existing code:
1. Identify repeating patterns of inline classes
2. Create or use existing component classes
3. Replace inline classes with component classes
4. Verify visual consistency in both themes
5. Update any related tests

### Naming Conflicts

Avoid using class names that conflict with Tailwind utilities. For example, use `.card-item` instead of `.list-item` to avoid conflicts with Tailwind's `list-item` display property.

### Accessibility

All components must:
- Maintain proper contrast ratios
- Support keyboard navigation
- Include appropriate ARIA attributes when needed
- Work with screen readers

### Performance

- Keep component definitions concise
- Avoid deeply nested selectors
- Use CSS custom properties for theming
- Minimize specificity conflicts

### Versioning

The component system follows semantic versioning. Breaking changes to component APIs should be documented and communicated.

---

*Last updated: February 1, 2026*