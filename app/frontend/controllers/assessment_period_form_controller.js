import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { today: String }

  connect() {
    this.updateFields()
  }

  changeKind() {
    const kind = this.element.querySelector('[data-testid="period-kind"]').value
    const months = { monthly: 1, quarterly: 3, semiannual: 6, annual: 12 }[kind]
    if (months) {
      const [year, month] = this.todayValue.split('-').map(Number)
      const previousIndex = Math.floor((month - 1) / months) - 1
      const count = 12 / months
      this.element.querySelector('[data-testid="calendar-year"]').value =
        previousIndex < 0 ? year - 1 : year
      this.element.querySelector('[data-testid="calendar-number"]').value =
        ((previousIndex + count) % count) + 1
    }
    this.updateFields()
  }

  updateFields() {
    const kind = this.element.querySelector('[data-testid="period-kind"]').value
    for (const section of this.element.querySelectorAll('[data-period-section]')) {
      const name = section.dataset.periodSection
      const visible =
        name === 'custom'
          ? kind === 'custom'
          : kind !== 'custom' && (name !== 'number' || kind !== 'annual')
      section.hidden = !visible
      for (const input of section.querySelectorAll('input')) {
        input.disabled = !visible
        input.required = visible
      }
    }
    this.element.querySelector('[data-testid="calendar-number"]').max =
      { monthly: 12, quarterly: 4, semiannual: 2, annual: 1 }[kind] || 12
  }
}
