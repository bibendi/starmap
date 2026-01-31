import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "iconLight", "iconDark", "iconSystem"]
  static values = { current: String }

  connect() {
    this.initializeTheme()
    this.setupSystemPreferenceListener()
    this.setupTurboListener()
  }

  setupTurboListener() {
    document.addEventListener('turbo:load', () => {
      this.initializeTheme()
    })
  }

  initializeTheme() {
    const stored = this.getStoredTheme()
    this.currentValue = stored || 'system'
    this.applyTheme()
    this.updateIcon()
  }

  getStoredTheme() {
    const match = document.cookie.match(/theme=([^;]+)/)
    const result = match ? match[1] : null
    // Trim and validate
    if (result && ['light', 'dark', 'system'].includes(result.trim())) {
      return result.trim()
    }
    return null
  }

  setTheme(theme) {
    this.currentValue = theme
    this.applyTheme()
    this.updateIcon()
    this.storeTheme(theme)
  }

  setLight() {
    this.setTheme('light')
  }
  setDark() {
    this.setTheme('dark')
  }
  setSystem() {
    this.setTheme('system')
  }

  toggle() {
    const order = ['light', 'dark', 'system']
    const currentIndex = order.indexOf(this.currentValue)
    const nextIndex = (currentIndex + 1) % order.length
    this.setTheme(order[nextIndex])
  }

  applyTheme() {
    const shouldDark = this.shouldApplyDark()
    document.documentElement.classList.toggle('dark', shouldDark)
  }

  shouldApplyDark() {
    if (this.currentValue === 'light') {
      return false
    }
    if (this.currentValue === 'dark') {
      return true
    }
    // system
    return window.matchMedia('(prefers-color-scheme: dark)').matches
  }

  updateIcon() {
    this.iconLightTarget.classList.toggle('hidden', this.currentValue !== 'light')
    this.iconDarkTarget.classList.toggle('hidden', this.currentValue !== 'dark')
    this.iconSystemTarget.classList.toggle('hidden', this.currentValue !== 'system')
  }

  storeTheme(theme) {
    const csrfToken = this.csrfToken()
    fetch(`/theme/${theme}`, {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken },
      credentials: 'same-origin'
    })
      .then(response => {
        if (response.ok) {
          // Reload to apply server-side changes
          // Turbo.visit(window.location.href)
        } else {
          console.error('Failed to store theme:', response.status)
        }
      })
      .catch(err => console.error('Failed to store theme:', err))
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }

  setupSystemPreferenceListener() {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (this.currentValue === 'system') {
        this.applyTheme()
      }
    })
  }
}
