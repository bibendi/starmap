import { Controller } from "@hotwired/stimulus"

function debounce(func, delay) {
  let timeoutId
  return function (...args) {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => func.apply(this, args), delay)
  }
}

export default class extends Controller {
  static targets = ["search", "quarter", "user", "technology", "status", "form"]
  static values = { autoSubmit: Boolean, debounceMs: { type: Number, default: 500 } }

  connect() {
    this.debouncedSubmit = debounce(this.submit.bind(this), this.debounceMsValue)
    this.bindEvents()
  }

  bindEvents() {
    if (this.hasSearchTarget) {
      this.searchTarget.addEventListener("input", this.debouncedSubmit)
    }
    if (this.hasQuarterTarget) {
      this.quarterTarget.addEventListener("change", this.submit.bind(this))
    }
    if (this.hasUserTarget) {
      this.userTarget.addEventListener("change", this.submit.bind(this))
    }
    if (this.hasTechnologyTarget) {
      this.technologyTarget.addEventListener("change", this.submit.bind(this))
    }
    if (this.hasStatusTarget) {
      this.statusTarget.addEventListener("change", this.submit.bind(this))
    }
  }

  submit() {
    if (this.autoSubmitValue) {
      this.formTarget.requestSubmit()
    }
  }

  clearFilters() {
    if (this.hasSearchTarget) this.searchTarget.value = ""
    if (this.hasQuarterTarget) this.quarterTarget.value = ""
    if (this.hasUserTarget) this.userTarget.value = ""
    if (this.hasTechnologyTarget) this.technologyTarget.value = ""
    if (this.hasStatusTarget) this.statusTarget.value = ""
    this.submit()
  }
}
