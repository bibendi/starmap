import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "content", "list", "filter", "item"]
  static values = {
    expanded: { type: Boolean, default: false },
    animationDuration: { type: Number, default: 300 }
  }

  connect() {
    this.updateDisplay()
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
    }

    this.expandedValue = !this.expandedValue
    this.updateDisplay()
  }

  filter(event) {
    const filterType = event.currentTarget.dataset.filterType || "all"
    this.applyFilter(filterType)
  }

  updateDisplay() {
    if (this.hasToggleTarget) {
      const icon = this.toggleTarget.querySelector("i")
      if (icon) {
        icon.classList.toggle("fa-chevron-down", !this.expandedValue)
        icon.classList.toggle("fa-chevron-up", this.expandedValue)
      }
    }

    if (this.hasContentTarget) {
      if (this.expandedValue) {
        this.expandContent()
      } else {
        this.collapseContent()
      }
    }
  }

  expandContent() {
    if (!this.hasContentTarget) return

    this.contentTarget.classList.remove("hidden")
    this.contentTarget.style.maxHeight = "0"
    this.contentTarget.style.overflow = "hidden"
    this.contentTarget.style.transition = `max-height ${this.animationDurationValue}ms ease-out`

    // Force reflow
    this.contentTarget.offsetHeight

    // Calculate max height
    const scrollHeight = this.contentTarget.scrollHeight
    this.contentTarget.style.maxHeight = `${scrollHeight}px`

    // Remove max-height after animation
    setTimeout(() => {
      if (this.hasContentTarget) {
        this.contentTarget.style.maxHeight = "none"
      }
    }, this.animationDurationValue)

    // Animate items
    this.animateItems("in")
  }

  collapseContent() {
    if (!this.hasContentTarget) return

    const scrollHeight = this.contentTarget.scrollHeight
    this.contentTarget.style.maxHeight = `${scrollHeight}px`
    this.contentTarget.style.overflow = "hidden"
    this.contentTarget.style.transition = `max-height ${this.animationDurationValue}ms ease-in`

    // Force reflow
    this.contentTarget.offsetHeight

    this.contentTarget.style.maxHeight = "0"

    setTimeout(() => {
      if (this.hasContentTarget && !this.expandedValue) {
        this.contentTarget.classList.add("hidden")
        this.contentTarget.style.maxHeight = "none"
        this.contentTarget.style.overflow = ""
      }
    }, this.animationDurationValue)

    // Animate items
    this.animateItems("out")
  }

  animateItems(direction) {
    if (!this.hasItemTargets) return

    this.itemTargets.forEach((item, index) => {
      if (direction === "in") {
        item.style.opacity = "0"
        item.style.transform = "translateY(-10px)"
        item.style.transition = `opacity ${this.animationDurationValue}ms ease-out, transform ${this.animationDurationValue}ms ease-out`

        setTimeout(() => {
          item.style.opacity = "1"
          item.style.transform = "translateY(0)"
        }, index * 50)
      } else {
        item.style.opacity = "0"
        item.style.transform = "translateY(-10px)"
      }
    })
  }

  applyFilter(filterType) {
    if (!this.hasItemTargets) return

    // Update filter buttons
    if (this.hasFilterTargets) {
      this.filterTargets.forEach(button => {
        const isActive = button.dataset.filterType === filterType
        button.classList.toggle("bg-blue-600", isActive)
        button.classList.toggle("text-white", isActive)
        button.classList.toggle("bg-gray-100", !isActive)
        button.classList.toggle("text-gray-700", !isActive)
      })
    }

    // Filter items
    this.itemTargets.forEach(item => {
      const itemType = item.dataset.changeType || "all"
      const shouldShow = filterType === "all" || itemType === filterType

      if (shouldShow) {
        item.classList.remove("hidden")
        // Animate in
        item.style.opacity = "0"
        item.style.transform = "translateX(-10px)"
        setTimeout(() => {
          item.style.opacity = "1"
          item.style.transform = "translateX(0)"
        }, 10)
      } else {
        // Animate out
        item.style.opacity = "0"
        item.style.transform = "translateX(10px)"
        setTimeout(() => {
          item.classList.add("hidden")
        }, 200)
      }
    })
  }

  getChangeTypeIcon(changeType) {
    const icons = {
      rating: "fa-star",
      status: "fa-flag",
      comment: "fa-comment",
      created: "fa-plus-circle",
      updated: "fa-edit"
    }
    return icons[changeType] || "fa-circle"
  }

  getChangeTypeColor(changeType) {
    const colors = {
      rating: "text-yellow-600 bg-yellow-50",
      status: "text-blue-600 bg-blue-50",
      comment: "text-green-600 bg-green-50",
      created: "text-purple-600 bg-purple-50",
      updated: "text-gray-600 bg-gray-50"
    }
    return colors[changeType] || "text-gray-600 bg-gray-50"
  }
}
