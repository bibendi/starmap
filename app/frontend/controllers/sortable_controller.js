import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ['list', 'form']

  connect() {
    this.sortable = Sortable.create(this.listTarget, {
      animation: 150,
      handle: '.sortable-handle',
      ghostClass: 'sortable-ghost',
      chosenClass: 'sortable-chosen',
      dragClass: 'sortable-drag'
    })
  }

  disconnect() {
    this.sortable?.destroy()
    this.sortable = null
  }

  submit() {
    const form = this.hasFormTarget ? this.formTarget : this.element.querySelector('form')
    if (!form) return

    this.itemIds.forEach((id) => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'ids[]'
      input.value = id
      form.appendChild(input)
    })
  }

  get itemIds() {
    return Array.from(this.listTarget.querySelectorAll('[data-id]')).map((el) => el.dataset.id)
  }
}
