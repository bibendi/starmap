import { Controller } from '@hotwired/stimulus'

// Subclasses: use static targets = [...super.targets, 'your', 'targets']
export default class DialogController extends Controller {
  static targets = ['dialog']

  connect() {
    this.dialogTarget.addEventListener('close', () => this.onDialogClose())
  }

  open(event) {
    if (event.type === 'keydown' && !['Enter', ' '].includes(event.key)) return
    if (this.dialogTarget.open) return

    this.triggerElement = event.currentTarget
    event.stopPropagation()
    this.dialogTarget.showModal()
  }

  close(event) {
    event.stopPropagation()
    this.dialogTarget.close()
  }

  onBackdropClick(event) {
    if (event.target !== this.dialogTarget) return

    event.stopPropagation()
    this.dialogTarget.close()
  }

  onDialogClose() {
    this.triggerElement?.focus()
  }
}
