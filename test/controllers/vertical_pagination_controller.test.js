import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import VerticalPaginationController from '../../app/frontend/controllers/vertical_pagination_controller.js'
import { renderController } from '../helpers/stimulus.js'
import { getByTestId, userEvent } from '../helpers/testing-library.js'

describe('VerticalPaginationController', () => {
  let cleanup
  const user = userEvent()

  afterEach(() => {
    cleanup?.()
  })

  function createVerticalPaginationHTML(itemsCount = 12, itemsPerPage = 6) {
    const items = Array.from(
      { length: itemsCount },
      (_, i) =>
        `<div data-vertical-pagination-target="item" data-testid="item-${i + 1}" class="item">
        Item ${i + 1}
      </div>`
    ).join('')

    return `
      <div data-controller="vertical-pagination" 
           data-vertical-pagination-items-per-page-value="${itemsPerPage}">
        <div data-vertical-pagination-target="container" data-testid="container">
          ${items}
        </div>
        <button data-vertical-pagination-target="prevButton"
                data-action="click->vertical-pagination#prev"
                data-testid="prev-button">
          Previous
        </button>
        <button data-vertical-pagination-target="nextButton"
                data-action="click->vertical-pagination#next"
                data-testid="next-button">
          Next
        </button>
      </div>
    `
  }

  describe('initialization', () => {
    it('shows only first page items on connect', async () => {
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(12, 6),
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup

      // First 6 items should be visible
      for (let i = 1; i <= 6; i++) {
        expect(getByTestId(`item-${i}`).classList.contains('hidden')).toBe(false)
      }
      // Items 7-12 should be hidden
      for (let i = 7; i <= 12; i++) {
        expect(getByTestId(`item-${i}`).classList.contains('hidden')).toBe(true)
      }
    })

    it('disables prev button on first page', async () => {
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(12, 6),
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup

      expect(getByTestId('prev-button').disabled).toBe(true)
      expect(getByTestId('next-button').disabled).toBe(false)
    })

    it('enables both buttons when not on first or last page', async () => {
      // Create with items that would be on second page
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(12, 4), // 4 items per page, total 3 pages
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup

      // Click next to go to page 2
      await user.click(getByTestId('next-button'))

      expect(getByTestId('prev-button').disabled).toBe(false)
      expect(getByTestId('next-button').disabled).toBe(false)
    })
  })

  describe('navigation', () => {
    beforeEach(async () => {
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(12, 6),
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup
    })

    it('moves to next page when next button clicked', async () => {
      // Initially on page 1
      expect(getByTestId('item-1').classList.contains('hidden')).toBe(false)
      expect(getByTestId('item-7').classList.contains('hidden')).toBe(true)

      await user.click(getByTestId('next-button'))

      // Now on page 2
      expect(getByTestId('item-1').classList.contains('hidden')).toBe(true)
      expect(getByTestId('item-7').classList.contains('hidden')).toBe(false)
    })

    it('moves to previous page when prev button clicked', async () => {
      // Go to page 2 first
      await user.click(getByTestId('next-button'))
      expect(getByTestId('item-1').classList.contains('hidden')).toBe(true)
      expect(getByTestId('item-7').classList.contains('hidden')).toBe(false)

      // Go back to page 1
      await user.click(getByTestId('prev-button'))
      expect(getByTestId('item-1').classList.contains('hidden')).toBe(false)
      expect(getByTestId('item-7').classList.contains('hidden')).toBe(true)
    })

    it('does not go beyond last page', async () => {
      // Go to page 2 (last page for 12 items, 6 per page)
      await user.click(getByTestId('next-button'))
      expect(getByTestId('next-button').disabled).toBe(true)

      // Try to go beyond
      await user.click(getByTestId('next-button'))

      // Should still be on page 2
      expect(getByTestId('item-7').classList.contains('hidden')).toBe(false)
      expect(getByTestId('item-1').classList.contains('hidden')).toBe(true)
    })

    it('does not go before first page', async () => {
      // Already on page 1
      expect(getByTestId('prev-button').disabled).toBe(true)

      // Try to go before
      await user.click(getByTestId('prev-button'))

      // Should still be on page 1
      expect(getByTestId('item-1').classList.contains('hidden')).toBe(false)
      expect(getByTestId('item-7').classList.contains('hidden')).toBe(true)
    })
  })

  describe('items per page', () => {
    it('handles custom items per page value', async () => {
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(12, 4), // 4 items per page
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup

      // Should show first 4 items
      for (let i = 1; i <= 4; i++) {
        expect(getByTestId(`item-${i}`).classList.contains('hidden')).toBe(false)
      }
      // Items 5-12 should be hidden
      for (let i = 5; i <= 12; i++) {
        expect(getByTestId(`item-${i}`).classList.contains('hidden')).toBe(true)
      }
    })

    it('handles fewer items than items per page', async () => {
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(3, 6), // Only 3 items, 6 per page
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup

      // All items should be visible
      for (let i = 1; i <= 3; i++) {
        expect(getByTestId(`item-${i}`).classList.contains('hidden')).toBe(false)
      }
      // Next button should be disabled (only one page)
      expect(getByTestId('next-button').disabled).toBe(true)
      expect(getByTestId('prev-button').disabled).toBe(true)
    })

    it('handles exact multiple of items per page', async () => {
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(12, 4), // 12 items, 4 per page = 3 pages exactly
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup

      // Go to last page
      await user.click(getByTestId('next-button'))
      await user.click(getByTestId('next-button'))

      // Should be on page 3 (last page)
      expect(getByTestId('item-9').classList.contains('hidden')).toBe(false)
      expect(getByTestId('item-12').classList.contains('hidden')).toBe(false)
      expect(getByTestId('next-button').disabled).toBe(true)
    })
  })

  describe('button state updates', () => {
    it('updates button states after navigation', async () => {
      const result = await renderController(VerticalPaginationController, {
        html: createVerticalPaginationHTML(12, 4), // 3 pages
        controllerName: 'vertical-pagination'
      })
      cleanup = result.cleanup

      // Page 1
      expect(getByTestId('prev-button').disabled).toBe(true)
      expect(getByTestId('next-button').disabled).toBe(false)

      // Page 2
      await user.click(getByTestId('next-button'))
      expect(getByTestId('prev-button').disabled).toBe(false)
      expect(getByTestId('next-button').disabled).toBe(false)

      // Page 3 (last)
      await user.click(getByTestId('next-button'))
      expect(getByTestId('prev-button').disabled).toBe(false)
      expect(getByTestId('next-button').disabled).toBe(true)

      // Back to page 2
      await user.click(getByTestId('prev-button'))
      expect(getByTestId('prev-button').disabled).toBe(false)
      expect(getByTestId('next-button').disabled).toBe(false)
    })
  })
})
