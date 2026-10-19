import { Chart } from 'chart.js/auto'
import { afterEach, describe, expect, it, vi } from 'vitest'
import CoverageController from '../../app/frontend/controllers/coverage_index_history_controller.js'
import MaturityController from '../../app/frontend/controllers/maturity_index_history_controller.js'
import { renderController, waitForStimulus } from '../helpers/stimulus.js'

vi.mock('chart.js/auto', () => ({
  Chart: vi.fn(function () {
    this.destroy = vi.fn()
  })
}))

describe.each([
  ['coverage-index-history', CoverageController, 'coverage_index'],
  ['maturity-index-history', MaturityController, 'maturity_index']
])('%s period history', (name, Controller, metric) => {
  let cleanup
  afterEach(() => {
    cleanup?.()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
    vi.clearAllMocks()
  })

  async function open(history) {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, json: async () => ({ history }) }))
    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue({})
    Object.defineProperty(HTMLDialogElement.prototype, 'showModal', {
      configurable: true,
      value() {
        this.open = true
      }
    })
    const result = await renderController(Controller, {
      controllerName: name,
      html: `<button data-testid="open" data-action="click->${name}#open">Open</button>
        <dialog data-${name}-target="dialog">
          <div class="hidden" data-${name}-target="loading"></div>
          <div class="hidden" data-testid="error" data-${name}-target="error"></div>
          <div class="hidden" data-testid="empty" data-${name}-target="empty"></div>
          <div class="hidden" data-testid="chart" data-${name}-target="chartContainer"><canvas data-${name}-target="canvas"></canvas></div>
        </dialog>`
    })
    cleanup = result.cleanup
    result.container.querySelector('[data-testid="open"]').click()
    await waitForStimulus()
    return result.container
  }

  it('shows mixed period labels in order and retains the ten latest points', async () => {
    const labels = [
      '2024',
      '2025 H1',
      '2025 H2',
      '2026 Q1',
      '2026-04',
      '2026-05',
      '2026-06',
      '2026 Q3',
      '2026-10',
      '2026-11',
      '2026-12'
    ]
    const container = await open(labels.map((period_name) => ({ period_name, [metric]: 2 })))
    expect(container.querySelector('[data-testid="chart"]').classList.contains('hidden')).toBe(
      false
    )
    expect(Chart.mock.calls.at(-1)[1].data.labels).toEqual(labels.slice(-10))
    expect(Chart.mock.calls.at(-1)[1].options.scales.x.title.text).toBe('Period')
  })

  it('shows the existing empty state for an empty history', async () => {
    const container = await open([])
    expect(container.querySelector('[data-testid="empty"]').classList.contains('hidden')).toBe(
      false
    )
    expect(Chart).not.toHaveBeenCalled()
  })
})
