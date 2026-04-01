import { afterEach, describe, expect, it } from 'vitest'
import TeamMembersController from '../../app/frontend/controllers/team_members_controller.js'
import { renderController } from '../helpers/stimulus.js'
import { userEvent } from '../helpers/testing-library.js'

describe('TeamMembersController', () => {
  let cleanup
  const user = userEvent()

  afterEach(() => {
    cleanup?.()
  })

  function createHTML({ members = [], availableMembers = [], teamLeadId = '' } = {}) {
    const memberRows = members
      .map(
        (m) => `
        <div data-member-id="${m.id}" data-member-name="${m.name}" data-member-row="${m.id}" class="member-list__row">
          <span class="member-list__name">${m.name}</span>
          <button type="button" class="btn btn--small btn--secondary member-list__remove" data-action="click->team-members#remove">
            Remove
          </button>
        </div>`
      )
      .join('')

    const availableOptions = availableMembers
      .map((m) => `<option value="${m.id}">${m.name}</option>`)
      .join('')

    const teamLeadOptions = members
      .map(
        (m) => `<option value="${m.id}"${m.id === teamLeadId ? ' selected' : ''}>${m.name}</option>`
      )
      .join('')

    return `
      <div data-team-members-target="memberList" class="member-list">
        ${memberRows}
      </div>

      <select data-team-members-target="addSelect">
        <option value="">-- Add member --</option>
        ${availableOptions}
      </select>
      <button type="button" data-action="click->team-members#add" data-testid="add-button">Add member</button>

      <select data-team-members-target="teamLeadSelect">
        <option value=""></option>
        ${teamLeadOptions}
      </select>

      ${members.map((m) => `<input type="hidden" name="team[member_ids][]" value="${m.id}" />`).join('')}
    `
  }

  describe('connect', () => {
    it('initializes member data from existing member rows', async () => {
      const members = [
        { id: '1', name: 'Alice' },
        { id: '2', name: 'Bob' }
      ]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members }),
        controllerName: 'team-members'
      }))

      const hiddenInputs = document.querySelectorAll('input[name="team[member_ids][]"]')
      expect(hiddenInputs.length).toBe(2)
      expect(Array.from(hiddenInputs).map((i) => i.value)).toEqual(['1', '2'])
    })

    it('initializes empty state when no members', async () => {
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members: [] }),
        controllerName: 'team-members'
      }))

      const hiddenInputs = document.querySelectorAll('input[name="team[member_ids][]"]')
      expect(hiddenInputs.length).toBe(1)
      expect(hiddenInputs[0].value).toBe('')
    })
  })

  describe('add', () => {
    it('adds a member to the list when option is selected', async () => {
      const members = [{ id: '1', name: 'Alice' }]
      const available = [{ id: '2', name: 'Bob' }]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members, availableMembers: available }),
        controllerName: 'team-members'
      }))

      const select = document.querySelector('[data-team-members-target="addSelect"]')
      select.value = '2'
      await user.click(document.querySelector('[data-testid="add-button"]'))

      const rows = document.querySelectorAll('.member-list__row')
      expect(rows.length).toBe(2)

      const hiddenInputs = document.querySelectorAll('input[name="team[member_ids][]"]')
      expect(Array.from(hiddenInputs).map((i) => i.value)).toEqual(['1', '2'])
    })

    it('does nothing when no option is selected', async () => {
      const members = [{ id: '1', name: 'Alice' }]
      const available = [{ id: '2', name: 'Bob' }]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members, availableMembers: available }),
        controllerName: 'team-members'
      }))

      const select = document.querySelector('[data-team-members-target="addSelect"]')
      select.value = ''
      await user.click(document.querySelector('[data-testid="add-button"]'))

      const hiddenInputs = document.querySelectorAll('input[name="team[member_ids][]"]')
      expect(hiddenInputs.length).toBe(1)
    })

    it('disables the option in add select after adding', async () => {
      const members = [{ id: '1', name: 'Alice' }]
      const available = [{ id: '2', name: 'Bob' }]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members, availableMembers: available }),
        controllerName: 'team-members'
      }))

      const select = document.querySelector('[data-team-members-target="addSelect"]')
      select.value = '2'
      await user.click(document.querySelector('[data-testid="add-button"]'))

      const bobOption = select.querySelector('option[value="2"]')
      expect(bobOption.disabled).toBe(true)
    })

    it('prevents adding the same member twice', async () => {
      const members = [{ id: '1', name: 'Alice' }]
      const available = [{ id: '2', name: 'Bob' }]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members, availableMembers: available }),
        controllerName: 'team-members'
      }))

      const select = document.querySelector('[data-team-members-target="addSelect"]')
      select.value = '2'
      await user.click(document.querySelector('[data-testid="add-button"]'))

      select.value = '2'
      await user.click(document.querySelector('[data-testid="add-button"]'))

      const hiddenInputs = document.querySelectorAll('input[name="team[member_ids][]"]')
      expect(hiddenInputs.length).toBe(2)
    })

    it('adds new member to team lead dropdown options', async () => {
      const members = [{ id: '1', name: 'Alice' }]
      const available = [{ id: '2', name: 'Bob' }]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members, availableMembers: available }),
        controllerName: 'team-members'
      }))

      const leadSelect = document.querySelector('[data-team-members-target="teamLeadSelect"]')
      expect(leadSelect.querySelector('option[value="2"]')).toBeNull()

      const addSelect = document.querySelector('[data-team-members-target="addSelect"]')
      addSelect.value = '2'
      await user.click(document.querySelector('[data-testid="add-button"]'))

      expect(leadSelect.querySelector('option[value="2"]')).not.toBeNull()
      expect(leadSelect.querySelector('option[value="2"]').textContent).toBe('Bob')
    })
  })

  describe('remove', () => {
    it('removes a member from the list', async () => {
      const members = [
        { id: '1', name: 'Alice' },
        { id: '2', name: 'Bob' }
      ]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members }),
        controllerName: 'team-members'
      }))

      const removeButton = document.querySelectorAll(
        '[data-action="click->team-members#remove"]'
      )[1]
      await user.click(removeButton)

      const rows = document.querySelectorAll('.member-list__row')
      expect(rows.length).toBe(1)

      const hiddenInputs = document.querySelectorAll('input[name="team[member_ids][]"]')
      expect(Array.from(hiddenInputs).map((i) => i.value)).toEqual(['1'])
    })

    it('re-enables the option in add select after removing', async () => {
      const members = [
        { id: '1', name: 'Alice' },
        { id: '2', name: 'Bob' }
      ]
      const available = [{ id: '3', name: 'Charlie' }]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members, availableMembers: available }),
        controllerName: 'team-members'
      }))

      const removeButton = document.querySelectorAll(
        '[data-action="click->team-members#remove"]'
      )[1]
      await user.click(removeButton)

      const select = document.querySelector('[data-team-members-target="addSelect"]')
      const bobOption = select.querySelector('option[value="2"]')
      expect(bobOption).toBeNull()
    })

    it('clears team lead selection when team lead member is removed', async () => {
      const members = [
        { id: '1', name: 'Alice' },
        { id: '2', name: 'Bob' }
      ]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members, teamLeadId: '2' }),
        controllerName: 'team-members'
      }))

      const leadSelect = document.querySelector('[data-team-members-target="teamLeadSelect"]')
      expect(leadSelect.value).toBe('2')

      const removeButton = document.querySelectorAll(
        '[data-action="click->team-members#remove"]'
      )[1]
      await user.click(removeButton)

      expect(leadSelect.value).toBe('')
    })

    it('removes member from team lead dropdown options', async () => {
      const members = [
        { id: '1', name: 'Alice' },
        { id: '2', name: 'Bob' }
      ]
      ;({ cleanup } = await renderController(TeamMembersController, {
        html: createHTML({ members }),
        controllerName: 'team-members'
      }))

      const leadSelect = document.querySelector('[data-team-members-target="teamLeadSelect"]')
      expect(leadSelect.querySelector('option[value="2"]')).not.toBeNull()

      const removeButton = document.querySelectorAll(
        '[data-action="click->team-members#remove"]'
      )[1]
      await user.click(removeButton)

      expect(leadSelect.querySelector('option[value="2"]')).toBeNull()
    })
  })
})
