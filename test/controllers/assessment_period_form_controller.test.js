import { afterEach, describe, expect, it } from 'vitest'
import AssessmentPeriodFormController from '../../app/frontend/controllers/assessment_period_form_controller.js'
import { renderController } from '../helpers/stimulus.js'

describe('AssessmentPeriodFormController', () => {
  let cleanup
  afterEach(() => cleanup?.())

  async function render(kind = 'quarterly') {
    const result = await renderController(AssessmentPeriodFormController, {
      controllerName: 'assessment-period-form',
      dataset: { today: '2026-10-18' },
      html: `<select data-testid="period-kind" data-action="change->assessment-period-form#changeKind">
          ${['monthly', 'quarterly', 'semiannual', 'annual', 'custom'].map((value) => `<option ${kind === value ? 'selected' : ''}>${value}</option>`).join('')}
        </select>
        <div data-period-section="calendar"><input data-testid="calendar-year" value="2025"></div>
        <div data-period-section="number"><input data-testid="calendar-number" value="2"></div>
        <div data-period-section="custom"><input data-testid="start-date"><input data-testid="end-date"></div>`
    })
    cleanup = result.cleanup
    return result.container
  }

  it('preserves existing calendar selection on connect', async () => {
    const container = await render()
    expect(container.querySelector('[data-testid="calendar-year"]').value).toBe('2025')
    expect(container.querySelector('[data-testid="start-date"]').disabled).toBe(true)
    expect(container.querySelector('[data-testid="calendar-number"]').max).toBe('4')
  })

  it.each([
    ['monthly', '2026', '9', '12'],
    ['quarterly', '2026', '3', '4'],
    ['semiannual', '2026', '1', '2'],
    ['annual', '2025', '1', '1']
  ])('defaults %s to the last completed interval', async (kind, year, number, max) => {
    const container = await render()
    const select = container.querySelector('select')
    select.value = kind
    select.dispatchEvent(new Event('change', { bubbles: true }))
    expect(container.querySelector('[data-testid="calendar-year"]').value).toBe(year)
    expect(container.querySelector('[data-testid="calendar-number"]').value).toBe(number)
    expect(container.querySelector('[data-testid="calendar-number"]').max).toBe(max)
    expect(container.querySelector('[data-testid="calendar-number"]').disabled).toBe(
      kind === 'annual'
    )
  })

  it('enables explicit custom dates and disables irrelevant required fields', async () => {
    const container = await render('custom')
    expect(container.querySelector('[data-period-section="custom"]').hidden).toBe(false)
    expect(container.querySelector('[data-testid="start-date"]').required).toBe(true)
    expect(container.querySelector('[data-testid="calendar-year"]').disabled).toBe(true)
    expect(container.querySelector('[data-testid="calendar-number"]').required).toBe(false)
  })
})
