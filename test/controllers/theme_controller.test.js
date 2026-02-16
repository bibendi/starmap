import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ThemeController from '../../app/frontend/controllers/theme_controller.js'
import { createCSRFToken, mockFetch } from '../helpers/fetch.js'
import { renderController } from '../helpers/stimulus.js'
import { getByTestId, userEvent } from '../helpers/testing-library.js'

describe('ThemeController', () => {
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

  function createThemeSwitcherHTML() {
    return `
      <button 
        data-theme-target="button" 
        data-action="click->theme#toggle"
        data-testid="theme-toggle">
      </button>
      <svg data-theme-target="iconLight" class="hidden" data-testid="icon-light"></svg>
      <svg data-theme-target="iconDark" class="hidden" data-testid="icon-dark"></svg>
      <svg data-theme-target="iconSystem" data-testid="icon-system"></svg>
    `
  }

  describe('initialization', () => {
    beforeEach(() => {
      delete document.body.dataset.theme
    })

    it('shows system icon by default', async () => {
      const result = await renderController(ThemeController, {
        html: createThemeSwitcherHTML(),
        controllerName: 'theme'
      })
      cleanup = result.cleanup

      expect(getByTestId('icon-system').classList.contains('hidden')).toBe(false)
      expect(getByTestId('icon-light').classList.contains('hidden')).toBe(true)
      expect(getByTestId('icon-dark').classList.contains('hidden')).toBe(true)
    })

    it('shows correct icon for dark theme', async () => {
      document.body.dataset.theme = 'dark'

      const result = await renderController(ThemeController, {
        html: createThemeSwitcherHTML(),
        controllerName: 'theme'
      })
      cleanup = result.cleanup

      expect(getByTestId('icon-dark').classList.contains('hidden')).toBe(false)
      expect(getByTestId('icon-light').classList.contains('hidden')).toBe(true)
      expect(getByTestId('icon-system').classList.contains('hidden')).toBe(true)
    })
  })

  describe('theme switching', () => {
    beforeEach(() => {
      delete document.body.dataset.theme
    })

    it('cycles through themes when clicked', async () => {
      const result = await renderController(ThemeController, {
        html: createThemeSwitcherHTML(),
        controllerName: 'theme'
      })
      cleanup = result.cleanup

      const button = getByTestId('theme-toggle')

      // Initial: system
      expect(getByTestId('icon-system').classList.contains('hidden')).toBe(false)

      // Click 1: system -> light
      await user.click(button)
      expect(getByTestId('icon-light').classList.contains('hidden')).toBe(false)
      expect(getByTestId('icon-system').classList.contains('hidden')).toBe(true)

      // Click 2: light -> dark
      await user.click(button)
      expect(getByTestId('icon-dark').classList.contains('hidden')).toBe(false)
      expect(getByTestId('icon-light').classList.contains('hidden')).toBe(true)

      // Click 3: dark -> system
      await user.click(button)
      expect(getByTestId('icon-system').classList.contains('hidden')).toBe(false)
      expect(getByTestId('icon-dark').classList.contains('hidden')).toBe(true)
    })
  })

  describe('server communication', () => {
    it('sends theme to server when changed', async () => {
      const result = await renderController(ThemeController, {
        html: createThemeSwitcherHTML(),
        controllerName: 'theme'
      })
      cleanup = result.cleanup

      const button = getByTestId('theme-toggle')
      await user.click(button)

      expect(fetch).toHaveBeenCalled()
    })

    it('works without CSRF token', async () => {
      document.head.innerHTML = ''

      const result = await renderController(ThemeController, {
        html: createThemeSwitcherHTML(),
        controllerName: 'theme'
      })
      cleanup = result.cleanup

      const button = getByTestId('theme-toggle')

      await expect(user.click(button)).resolves.not.toThrow()
    })
  })

  describe('cleanup', () => {
    it('handles element removal gracefully', async () => {
      const result = await renderController(ThemeController, {
        html: createThemeSwitcherHTML(),
        controllerName: 'theme'
      })
      cleanup = result.cleanup

      expect(() => result.container.remove()).not.toThrow()
    })
  })
})
