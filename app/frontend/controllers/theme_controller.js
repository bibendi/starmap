import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "iconLight", "iconDark", "iconSystem"]
  static values = { current: String }

  connect() {
    this.isStoring = false
    this.pendingTheme = null
    this.initializeTheme()
    this.previousTheme = this.currentValue
    this.setupSystemPreferenceListener()
    this.setupTurboListener()
  }

  disconnect() {
    if (this.systemMediaQuery && this.systemListener) {
      this.systemMediaQuery.removeEventListener('change', this.systemListener)
    }
    if (this.turboListener) {
      document.removeEventListener('turbo:load', this.turboListener)
    }
  }

  setupTurboListener() {
    this.turboListener = () => this.initializeTheme()
    document.addEventListener('turbo:load', this.turboListener)
  }

  initializeTheme() {
    const stored = this.getStoredTheme()
    this.currentValue = stored || 'system'
    this.applyTheme()
    this.updateIcon()
  }

  getStoredTheme() {
    const theme = document.documentElement.dataset.theme
    if (theme && ['light', 'dark', 'system'].includes(theme)) {
      return theme
    }
    return null
  }

  setTheme(theme) {
    this.previousTheme = this.currentValue
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
    if (!window.matchMedia) return false
    return window.matchMedia('(prefers-color-scheme: dark)').matches
  }

  updateIcon() {
    this.iconLightTarget.classList.toggle('hidden', this.currentValue !== 'light')
    this.iconDarkTarget.classList.toggle('hidden', this.currentValue !== 'dark')
    this.iconSystemTarget.classList.toggle('hidden', this.currentValue !== 'system')
  }

  storeTheme(theme) {
    // If a request is already in flight, save the latest theme and exit
    if (this.isStoring) {
      this.pendingTheme = theme
      return
    }

    this.isStoring = true
    const csrfToken = this.csrfToken()
    
    // Check CSRF token presence
    if (!csrfToken) {
      console.error('CSRF token not found')
      this.rollbackTheme()
      this.isStoring = false
      return
    }

    fetch(`/theme/${theme}`, {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken },
      credentials: 'same-origin'
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`)
        }
      })
      .catch(err => {
        console.error('Failed to store theme:', err)
        // Rollback only if there's no pending theme (user hasn't selected another theme yet)
        if (!this.pendingTheme) {
          this.rollbackTheme()
        }
      })
      .finally(() => {
        this.isStoring = false
        
        // Process pending theme if any
        if (this.pendingTheme) {
          const nextTheme = this.pendingTheme
          this.pendingTheme = null
          // Use setTimeout to avoid recursion in the same call stack
          setTimeout(() => this.storeTheme(nextTheme), 0)
        }
      })
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }

  rollbackTheme() {
    if (this.previousTheme && this.previousTheme !== this.currentValue) {
      this.currentValue = this.previousTheme
      this.applyTheme()
      this.updateIcon()
    }
  }

  setupSystemPreferenceListener() {
    if (!window.matchMedia) return
    
    this.systemMediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    this.systemListener = () => {
      if (this.currentValue === 'system') {
        this.applyTheme()
      }
    }
    this.systemMediaQuery.addEventListener('change', this.systemListener)
  }
}
