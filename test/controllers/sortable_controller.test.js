import { Application } from '@hotwired/stimulus'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { clearFetchMocks } from '../helpers/fetch.js'
import { waitForStimulus } from '../helpers/stimulus.js'
import { getByTestId } from '../helpers/testing-library.js'

vi.mock('sortablejs', () => ({
  default: {
    create: vi.fn(() => ({ destroy: vi.fn() }))
  }
}))

import SortableController from '../../app/frontend/controllers/sortable_controller.js'

describe('SortableController', () => {
  let application
  let container

  function createSortableHTML(technologies = ['Ruby', 'Python', 'Go']) {
    const items = technologies
      .map(
        (name, index) => `
        <div data-sortable-target="item" data-id="${index + 1}" data-testid="item-${index}" class="sortable-item">
          <span data-testid="item-name-${index}">${name}</span>
        </div>
      `
      )
      .join('')

    return `
      <div data-controller="sortable">
        <form data-sortable-target="form" data-testid="sort-form" data-turbo="false">
          <div data-sortable-target="list" data-testid="sortable-list" class="sortable-list">
            ${items}
          </div>
          <button type="submit" data-action="click->sortable#submit" data-testid="save-button">Save</button>
        </form>
      </div>
    `
  }

  async function setup(html = createSortableHTML()) {
    application = Application.start()
    application.register('sortable', SortableController)

    container = document.createElement('div')
    container.innerHTML = html
    document.body.appendChild(container)

    await waitForStimulus()
  }

  function teardown() {
    application?.stop()
    container?.remove()
  }

  afterEach(() => {
    teardown()
    clearFetchMocks()
  })

  describe('initialization', () => {
    it('reads item IDs from data-id attributes', async () => {
      await setup()

      const list = getByTestId('sortable-list')
      const items = list.querySelectorAll('[data-id]')
      expect(items.length).toBe(3)
      expect(items[0].dataset.id).toBe('1')
    })
  })

  describe('submit', () => {
    beforeEach(async () => {
      await setup()
    })

    it('populates form with current order as hidden inputs', () => {
      const form = getByTestId('sort-form')
      const button = getByTestId('save-button')

      button.click()

      const inputs = form.querySelectorAll('input[name="ids[]"]')
      expect(inputs.length).toBe(3)
      expect(inputs[0].value).toBe('1')
      expect(inputs[1].value).toBe('2')
      expect(inputs[2].value).toBe('3')
    })

    it('populates form with reordered IDs after DOM change', () => {
      const list = getByTestId('sortable-list')
      const items = list.querySelectorAll('[data-id]')
      list.insertBefore(items[2], items[0])

      const form = getByTestId('sort-form')
      const button = getByTestId('save-button')
      button.click()

      const inputs = form.querySelectorAll('input[name="ids[]"]')
      expect(inputs.length).toBe(3)
      expect(inputs[0].value).toBe('3')
      expect(inputs[1].value).toBe('1')
      expect(inputs[2].value).toBe('2')
    })

    it('appends new hidden inputs on each submit', () => {
      const form = getByTestId('sort-form')
      const button = getByTestId('save-button')

      button.click()
      button.click()

      const inputs = form.querySelectorAll('input[name="ids[]"]')
      expect(inputs.length).toBe(6)
    })
  })
})
