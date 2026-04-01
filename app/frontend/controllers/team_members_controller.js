import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['memberList', 'teamLeadSelect']

  connect() {
    this.memberData = new Map()
    this.currentMemberIds = []

    this.memberListTarget.querySelectorAll('[data-member-id]').forEach((el) => {
      const id = el.dataset.memberId
      const name = el.dataset.memberName
      this.memberData.set(id, { name })
      this.currentMemberIds.push(id)
    })

    this.renderHiddenInputs()
  }

  add(event) {
    event.preventDefault()
    const select = this.addSelectElement
    if (!select) return

    const option = select.selectedOptions[0]
    if (!option || !option.value) return

    const id = option.value
    if (this.currentMemberIds.includes(id)) return

    const name = option.textContent.trim()
    this.memberData.set(id, { name })
    this.currentMemberIds.push(id)

    option.disabled = true
    select.value = ''

    this.renderMemberList()
    this.updateTeamLeadOptions()
  }

  remove(event) {
    event.preventDefault()
    const button = event.currentTarget
    const row = button.closest('[data-member-row]')
    if (!row) return

    const id = row.dataset.memberRow
    this.memberData.delete(id)
    this.currentMemberIds = this.currentMemberIds.filter((mid) => mid !== id)

    const select = this.addSelectElement
    if (select) {
      const option = select.querySelector(`option[value="${id}"]`)
      if (option) option.disabled = false
    }

    if (this.hasTeamLeadSelectTarget && this.teamLeadSelectTarget.value === id) {
      this.teamLeadSelectTarget.value = ''
    }

    this.renderMemberList()
    this.updateTeamLeadOptions()
  }

  renderMemberList() {
    const container = this.memberListTarget
    container.innerHTML = ''

    this.currentMemberIds.forEach((id) => {
      const data = this.memberData.get(id)
      if (!data) return

      const row = document.createElement('div')
      row.setAttribute('data-member-row', id)
      row.className = 'member-list__row'

      const nameSpan = document.createElement('span')
      nameSpan.className = 'member-list__name'
      nameSpan.textContent = data.name

      const removeBtn = document.createElement('button')
      removeBtn.type = 'button'
      removeBtn.className = 'btn btn--small btn--secondary member-list__remove'
      removeBtn.textContent = this.element.dataset.removeText || 'Remove'
      removeBtn.setAttribute('data-action', 'click->team-members#remove')

      row.appendChild(nameSpan)
      row.appendChild(removeBtn)
      container.appendChild(row)
    })

    this.renderHiddenInputs()
  }

  renderHiddenInputs() {
    this.element.querySelectorAll('input[name="team[member_ids][]"]').forEach((input) => {
      input.remove()
    })

    if (this.currentMemberIds.length === 0) {
      const marker = document.createElement('input')
      marker.type = 'hidden'
      marker.name = 'team[member_ids][]'
      marker.value = ''
      this.element.appendChild(marker)
      return
    }

    this.currentMemberIds.forEach((id) => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'team[member_ids][]'
      input.value = id
      this.element.appendChild(input)
    })
  }

  updateTeamLeadOptions() {
    const select = this.teamLeadSelectTarget
    if (!select) return

    const currentValue = select.value
    const blankOption = select.querySelector('option[value=""]')
    const options = blankOption ? [blankOption.outerHTML] : ['<option value=""></option>']

    this.currentMemberIds.forEach((id) => {
      const data = this.memberData.get(id)
      if (!data) return
      const selected = id === currentValue ? ' selected' : ''
      options.push(`<option value="${id}"${selected}>${data.name}</option>`)
    })

    select.innerHTML = options.join('')
  }

  get addSelectElement() {
    return this.element.querySelector('[data-team-members-target="addSelect"]')
  }
}
