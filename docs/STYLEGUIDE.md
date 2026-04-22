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
- **Dialogs**: Modal overlays using native `<dialog>` element

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

## Dialog Pattern

Starmap uses the native HTML `<dialog>` element with a reusable Stimulus controller hierarchy. This pattern must be followed for all modal/popup interactions.

### Architecture

```
DialogController (base, registered as 'dialog')
  ├── open() / close() / onBackdropClick() / onDialogClose()
  ├── Manages <dialog> lifecycle + focus restoration
  └── Can be used standalone for simple dialogs

CoverageIndexHistoryController extends DialogController
  ├── Adds data fetching + Chart.js rendering
  └── Other dialog controllers follow the same pattern
```

**Location**: `app/frontend/controllers/dialog_controller.js`

### Two Usage Modes

1. **Standalone** (simple confirmation/info dialogs): Use `data-controller="dialog"` directly in ERB. No subclass needed.
2. **Extended** (data fetching, charts, forms): Create a new controller that extends `DialogController`, register it under its own name.

### CSS Classes

All dialogs use the `.dialog` class family. These are reusable across any dialog in the application:

| Class | Purpose |
|-------|---------|
| `.dialog` | Base `<dialog>` element: rounded, shadow, max-width 600px, centered |
| `.dialog::backdrop` | Semi-transparent overlay (bg-black/50) |
| `.dialog__header` | Top bar with title and close button |
| `.dialog__title` | Dialog heading text |
| `.dialog__close` | Close icon button in header |
| `.dialog__close-icon` | SVG icon sizing inside close button |
| `.dialog__body` | Content area with padding |
| `.dialog__body--centered` | Vertically centered content (loading, empty, error states) |
| `.dialog__body--error` | Error state text color (red) |
| `.dialog__spinner` | Loading spinner animation |
| `.dialog__message` | Text inside body states |
| `.dialog__retry` | Retry action button |

Feature-specific body variants (like chart heights) should be defined in their own CSS sections, not in the `.dialog` family.

**Important**: `margin: auto` is required on `.dialog` because Tailwind's preflight resets `margin: 0` on all elements, which breaks native `<dialog>` centering.

### Stimulus Controller Rules

1. **Always inherit from `DialogController`** — never manage `<dialog>` directly
2. **Always call `event.stopPropagation()`** in `open()` and `close()` — the dialog lives inside the trigger element in the DOM; without stopPropagation, clicks bubble from dialog back to trigger
3. **Backdrop click closing** is handled by `onBackdropClick` — it checks `event.target === this.dialogTarget` and calls `stopPropagation` + `close`
4. **Override `onDialogClose()`** for cleanup (destroy charts, reset state). Always call `super.onDialogClose()` to preserve focus restoration
5. **Extend static targets** with `[...super.targets, 'your', 'targets']`
6. **Focus restoration** is automatic — `DialogController` saves the trigger element in `open()` and restores focus in `onDialogClose()`
7. **Never add interactive elements inside the dialog body without `stopPropagation`** on their click handlers — otherwise clicks bubble to the trigger wrapper and re-open the dialog

### ERB Template Structure

```erb
<div data-controller="your-dialog"
     data-action="click->your-dialog#open keydown->your-dialog#open"
     role="button"
     tabindex="0"
     aria-haspopup="dialog"
     aria-label="<%= t('your.open_label') %>">
  <!-- Trigger content -->
  <div class="metric-card">...</div>

  <!-- Dialog -->
  <dialog data-your-dialog-target="dialog"
          data-action="click->your-dialog#onBackdropClick"
          class="dialog">
    <div class="dialog__header">
      <h3 class="dialog__title"><%= t('your.title') %></h3>
      <button type="button" class="dialog__close"
              data-action="click->your-dialog#close"
              aria-label="<%= t('your.close') %>">
        <svg class="dialog__close-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
    <!-- Body content -->
  </dialog>
</div>
```

### Dialog Types

#### Confirmation Dialog (standalone, no subclass)

Use `data-controller="dialog"` directly. Body contains the message and action buttons:

```erb
<div data-controller="dialog"
     data-action="click->dialog#open keydown->dialog#open"
     role="button" tabindex="0" aria-haspopup="dialog">
  <button class="btn btn--danger">Delete</button>
  <dialog data-dialog-target="dialog" data-action="click->dialog#onBackdropClick" class="dialog">
    <div class="dialog__header">
      <h3 class="dialog__title">Confirm deletion</h3>
      <button type="button" class="dialog__close" data-action="click->dialog#close">...</button>
    </div>
    <div class="dialog__body">
      <p>Are you sure?</p>
      <%= button_to "Delete", path, method: :delete, class: "btn btn--danger" %>
    </div>
  </dialog>
</div>
```

#### Form Dialog (Turbo Frame inside dialog)

Wrap form content in a Turbo Frame for server-side validation:

```erb
<dialog data-dialog-target="dialog" data-action="click->dialog#onBackdropClick" class="dialog">
  <div class="dialog__header">...</div>
  <%= turbo_frame_tag "edit_form" do %>
    <%= form_with model: @record do |f| %>
      <!-- form fields -->
      <%= f.submit %>
    <% end %>
  <% end %>
</dialog>
```

Server responds with Turbo Stream to update the frame on validation errors, or redirects on success.

### Gotchas

- **Tailwind preflight kills centering**: `margin: auto` must be explicit on `.dialog` — do not remove it
- **Click bubbling**: Dialog is a child of the trigger wrapper; every click inside dialog bubbles to trigger. All dialog actions must call `event.stopPropagation()`
- **Enter key double-fire**: Pressing Enter on `role="button"` fires both `keydown` and `click`. The `open()` method handles both via `event.type` check
- **Chart.js cleanup**: Controllers that create Chart.js instances must destroy them in `onDialogClose()` to prevent memory leaks
- **`tag.attributes` for data values**: Use Rails `tag.attributes` helper when outputting JSON into `data-*` attributes to prevent XSS. Never use raw `<%= data.to_json %>` in attribute values
- **Focus restoration**: `DialogController.onDialogClose()` calls `this.triggerElement?.focus()`. Subclasses must call `super.onDialogClose()` if they override it
- **Fetch timeouts**: Controllers that fetch data should use `AbortController` with a timeout to prevent indefinite loading spinners

---

*Last updated: April 22, 2026*