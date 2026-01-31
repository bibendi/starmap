# Test Helpers

Reusable helpers for testing Stimulus controllers with Vitest using data-testid pattern.

## Stimulus Helpers (`stimulus.js`)

```javascript
import { renderController, waitForStimulus } from './helpers/stimulus.js'
import { mockFetch, createCSRFToken } from './helpers/fetch.js'

describe('MyController', () => {
  let cleanup
  
  afterEach(() => {
    cleanup?.()
  })
  
  it('renders and interacts', async () => {
    createCSRFToken()
    mockFetch()
    
    const result = await renderController(MyController, {
      html: '<button data-testid="submit">Click</button>',
      controllerName: 'my'
    })
    
    cleanup = result.cleanup
    // test interactions...
  })
})
```

## Testing Library Helpers (`testing-library.js`)

```javascript
import { getByTestId, userEvent } from './helpers/testing-library.js'

const user = userEvent()

// Find by data-testid
const button = getByTestId('submit')
const icon = getByTestId('loading-spinner')

// Interact
await user.click(button)
```

## Fetch Helpers (`fetch.js`)

```javascript
import { mockFetch, mockFetchError, assertFetchCalled, createCSRFToken } from './helpers/fetch.js'

// Basic mock
mockFetch()

// CSRF token for Rails forms
const csrfMeta = createCSRFToken()

// Error mock
mockFetchError(new Error('Network failed'))

// Assertions
assertFetchCalled()
```

## Best Practices

1. **Test behavior, not implementation**
   - Use `data-testid` to find elements (stable API)
   - Check visibility/state, not CSS classes when possible
   - Don't assert on internal method calls

2. **Use data-testid pattern**
   - Add `data-testid` attributes to key interactive elements
   - Use semantic names: `theme-toggle`, `submit-button`, `error-message`
   - Don't test implementation details (CSS classes, internal targets)

3. **Reusable patterns**
   - Always use `renderController()` helper
   - Clean up with `cleanup()` in `afterEach`
   - Mock fetch with `mockFetch()` for HTTP calls

## Writing Tests

```javascript
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import MyController from '../../app/frontend/controllers/my_controller.js'
import { renderController } from '../helpers/stimulus.js'
import { mockFetch, createCSRFToken } from '../helpers/fetch.js'
import { getByTestId, userEvent } from '../helpers/testing-library.js'

describe('MyController', () => {
  let cleanup
  const user = userEvent()
  
  beforeEach(() => {
    createCSRFToken()
    mockFetch()
  })
  
  afterEach(() => {
    cleanup?.()
    vi.clearAllMocks()
  })
  
  it('toggles visibility on click', async () => {
    const result = await renderController(MyController, {
      html: `
        <button data-testid="toggle">Show</button>
        <div data-testid="content" class="hidden">Content</div>
      `,
      controllerName: 'my'
    })
    cleanup = result.cleanup
    
    const content = getByTestId('content')
    expect(content.classList.contains('hidden')).toBe(true)
    
    const button = getByTestId('toggle')
    await user.click(button)
    
    expect(content.classList.contains('hidden')).toBe(false)
  })
})
```
