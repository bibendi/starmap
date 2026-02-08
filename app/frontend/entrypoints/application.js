// Entry point for the Vite bundle for Starmap application

// Import styles
import './application.css'

import { Application } from '@hotwired/stimulus'
import { session } from '@hotwired/turbo'

session.start()

// Import Stimulus controllers
import ThemeController from '../controllers/theme_controller.js'
import TreemapChartController from '../controllers/treemap_chart_controller.js'
import VerticalPaginationController from '../controllers/vertical_pagination_controller.js'

// Register Stimulus controllers
const application = Application.start()
application.register('theme', ThemeController)
application.register('vertical-pagination', VerticalPaginationController)
application.register('treemap-chart', TreemapChartController)

// Custom application JavaScript
document.addEventListener('DOMContentLoaded', () => {
  // Initialize any global functionality here
  initializeGlobalHandlers()
})

function initializeGlobalHandlers() {
  // Handle any global application events
  document.addEventListener('turbo:load', () => {})

  // Handle form submissions with loading states
  document.addEventListener('submit', (event) => {
    const form = event.target
    const submitButton = form.querySelector('button[type="submit"]')

    if (submitButton && !form.dataset.noloading) {
      submitButton.disabled = true
      submitButton.classList.add('loading')

      // Re-enable after a timeout in case of errors
      setTimeout(() => {
        submitButton.disabled = false
        submitButton.classList.remove('loading')
      }, 3000)
    }
  })
}

// Utility functions
window.Starmap = {
  // Show flash message
  showFlash: (type, message) => {
    const flashContainer = document.getElementById('flash')
    if (flashContainer) {
      const flashDiv = document.createElement('div')
      flashDiv.className = `flash-message flash-${type} p-4 mb-4 rounded-md`
      flashDiv.innerHTML = message
      flashContainer.appendChild(flashDiv)

      // Auto remove after 5 seconds
      setTimeout(() => {
        flashDiv.remove()
      }, 5000)
    }
  },

  // Format date for display
  formatDate: (dateString) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  },

  // Debounce function for search inputs
  debounce: (func, wait) => {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
}
